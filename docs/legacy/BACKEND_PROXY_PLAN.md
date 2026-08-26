# rand-o-eats — Backend Proxy & Caching Plan

> Design draft only. No implementation. Goal: move Google Places **web-service**
> calls behind our own backend to (1) keep API keys off the client, (2) reduce
> Google call volume/cost via compliant caching, and (3) give us a control point
> for rate-limiting, analytics, and provider flexibility.

## 1. Goals / non-goals

**Goals**
- Remove the Google Places **web-service** key from the shipped app.
- Cut redundant Google calls (popular areas, repeated identical searches).
- Centralize request shaping (field masks, filters) and usage logging.
- Stay within Google Maps Platform Terms (caching rules).

**Non-goals (for v1)**
- Replacing the on-device **Maps SDK** rendering key (must stay client-side;
  see §3).
- Building a permanent mirror of Google content / a competing dataset (not
  allowed).
- User accounts / server-side personalization.

## 2. Current state (what we're changing)

- App calls Google directly from `lib/services/places_service.dart` using
  `String.fromEnvironment('GOOGLE_PLACES_API_KEY')` baked into the build →
  extractable from the IPA/APK.
- Two call shapes: **Nearby Search** and **Text Search** (Places API New),
  selected by whether a cuisine/mood keyword exists.
- **Photos** are loaded via `getPhotoUrl(...)` which embeds `&key=<API key>` in
  the image URL → the key also leaks through photo requests. The proxy must
  front photos too, not just search.

## 3. Two-key split (important)

| Key | Used for | Where it lives | Restriction |
|-----|----------|----------------|-------------|
| **Maps SDK key** (iOS/Android) | rendering the map widget (`google_maps_flutter`, region-draw/detail) | **client** (Info.plist / AndroidManifest) | restrict by bundle id / SHA-1 |
| **Places web-service key** | Nearby/Text Search, Place Details, Photos | **server only** | restrict by server IP/service account; never shipped |

Only the second key moves server-side. The map-rendering key has to be on the
device by design, so we just lock it down.

## 4. Architecture

```
Flutter app ──HTTPS──▶  rand-o-eats API (our backend)  ──▶ Google Places API (New)
                          │
                          ├─ cache (search results by geo-cell, short TTL)
                          ├─ photo proxy (or signed short-lived redirects)
                          ├─ rate limit + App Check verification
                          └─ usage logging / metrics
```

The app's `PlacesService` is refactored to call our endpoints instead of
`places.googleapis.com`. Response shape stays close to today's `Restaurant`
model so the rest of the app is unaffected.

## 5. Proposed API surface (our backend)

Mirror what the app already needs; keep it small.

- `GET /v1/restaurants`
  - params: `lat`, `lng`, `radius`, `maxResults`, `keyword?` (mood/cuisine),
    `openNow?`, `minRating?`, `priceLevels?`, atmosphere flags, `excludeIds?`
  - returns: list of restaurants (same fields we map today) + a `cache` hint
    (age/fresh) so the client can show "as of X".
  - server decides Nearby vs Text Search (same logic we have now).
- `GET /v1/places/{placeId}` (Place Details) — live, uncached for volatile
  fields (hours/phone) — used when opening the detail screen.
- `GET /v1/photo?ref=<photoName>&w=<px>` — proxies/redirects the photo so the
  Google key never reaches the client.
- `GET /healthz` — readiness.

Auth: every call carries a **Firebase App Check** token (or equivalent
attestation) so only our app can use the backend.

## 6. Caching design (the core value, and the compliance-sensitive part)

**What Google's Terms allow (verify against current Terms before building):**
- ✅ **Place IDs** — store **indefinitely**.
- ⚠️ **Other Place content** (name, rating, address, photos, hours) — only
  **limited temporary caching for performance** (commonly cited as ≤30 days for
  some fields; must refresh). No permanent mirror.
- ⛔ **`openNow` / hours** — volatile; do **not** serve stale.

**Our cache (compliant + high value): cache the search *result list* per area.**
- **Key:** `(geocell, radius_bucket, normalized_filters, openNowBucket)`
  - `geocell` = lat/lng rounded to a grid (geohash ~6–7 chars, ≈150 m) so nearby
    users share an entry.
  - `radius_bucket` / `filters` normalized so equivalent searches collapse.
- **Value:** ordered **Place IDs** (+ minimal display fields) for that search.
- **TTL:**
  - With `openNow` involved → **short** (e.g. 2–10 min).
  - Without volatile fields → longer (still bounded; refresh well under the
    Terms' cap).
- **Detail screen:** always fetch **live** Place Details by id (fresh
  hours/phone). Optionally cache the *non-volatile* parts briefly.
- **Place IDs:** may be persisted long-term to power favorites/recents cheaply.

This collapses the dominant cost driver (repeat searches in busy areas) while
keeping `openNow` honest — directly complementary to the "most places closed"
banner we just shipped.

**Cache store options:** start with in-process LRU (simplest, per-instance);
upgrade to a shared store (Memorystore/Redis or Firestore TTL collection) once
there are multiple instances.

## 7. Hosting options

| Option | Pros | Cons | Fit |
|--------|------|------|-----|
| **Cloud Run** | autoscale, container, easy Redis/Memorystore, good for proxy + cache | needs container build/CD | **Recommended** |
| **Cloud Functions / Firebase Functions** | quick, integrates with App Check/Firebase | cold starts, per-instance cache only, time limits | good MVP |
| Existing VPS/server | full control | ops burden, scaling | only if one already exists |

Given the app already uses Firebase (App Distribution / likely Analytics),
**Firebase Functions for an MVP → Cloud Run when traffic grows** is a clean path.

## 8. Security & abuse prevention

- Google key in **Secret Manager**, injected at runtime; never in the repo or app.
- **Firebase App Check** (DeviceCheck/App Attest on iOS, Play Integrity on
  Android) so only genuine app installs hit the backend.
- **Rate limiting** per App Check token / IP; quotas to cap blast radius.
- Restrict the Google key to the backend service account / IP.
- Strip/validate params; never proxy arbitrary upstream URLs (photo endpoint
  only accepts a Google photo `name`, validated by prefix).

## 9. Cost model

- Caching cuts **request volume** (the main lever).
- Keep the **field-mask discipline** we already have (atmosphere fields only when
  a filter needs them) to stay in cheaper SKUs.
- Backend hosting cost is small relative to Places savings at scale; add a
  budget alert.

## 10. Observability

- Log per request: SKU type, cache hit/miss, geocell, latency.
- Metrics: cache hit ratio, Google calls/day, cost/day, error rate.
- Alert on error rate + daily Google spend.

## 11. Migration plan (phased)

1. **Stand up backend** with `/v1/restaurants` + `/v1/photo` (no cache yet),
   key in Secret Manager, App Check on. Parity with current behavior.
2. **Point the app** at the backend behind a feature flag / new build; keep the
   direct-Google path as a fallback during rollout.
3. **Add caching** (geocell result-list cache, short TTL) + metrics.
4. **Add Place Details** endpoint; detail screen uses it for fresh data.
5. **Remove** the Places key from the client build entirely; rotate the old key.
6. Tune TTLs / cell size from real hit-ratio data.

## 12. Decisions needed from you

- Hosting: **Firebase Functions (MVP)** vs **Cloud Run** (recommended target)?
- Cache store: in-process to start, or Redis/Firestore from day one?
- App Check: on from v1? (recommended)
- Do we keep a temporary client→Google fallback during migration, or hard cut?
- Budget ceiling + who owns the GCP project / Secret Manager.

## 13. Risks / watch-items

- **Terms compliance** on caching — confirm current Google Maps Platform Terms
  language before persisting any non-Place-ID content; keep TTLs conservative.
- **`openNow` staleness** — keep volatile fields live or very short-TTL.
- **Photo proxying** can add bandwidth cost — prefer short-lived redirects if
  Google permits, else cache image bytes briefly.
- **Single point of failure** — backend down = no search; mitigate with health
  checks, autoscale, and (optionally) a short client fallback window.
