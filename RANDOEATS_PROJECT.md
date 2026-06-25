# RandoEats — Project Reference

> Consolidated reference covering all conversations from concept through BFF spec.  
> Last updated: June 25, 2026

---

## Table of Contents

1. [Concept & Problem Statement](#1-concept--problem-statement)
2. [App Identity & Branding](#2-app-identity--branding)
3. [Tech Stack Overview](#3-tech-stack-overview)
4. [Data Source Decision](#4-data-source-decision)
5. [API Cost Model](#5-api-cost-model)
6. [Architecture: Why a BFF?](#6-architecture-why-a-bff)
7. [BFF: Endpoints](#7-bff-endpoints)
8. [BFF: Field Masks & SKU Tiers](#8-bff-field-masks--sku-tiers)
9. [BFF: Response Shape (Normalized Contract)](#9-bff-response-shape-normalized-contract)
10. [BFF: Caching Strategy](#10-bff-caching-strategy)
11. [BFF: Performance Metrics Logging](#11-bff-performance-metrics-logging)
12. [BFF: Project Structure](#12-bff-project-structure)
13. [BFF: Deployment Target](#13-bff-deployment-target)
14. [Flutter Client: Caching Strategy](#14-flutter-client-caching-strategy)
15. [Flutter Client: Location Services](#15-flutter-client-location-services)
16. [Flutter Client: Map Library Decision](#16-flutter-client-map-library-decision)
17. [Planned Features & Bugs (Backlog)](#17-planned-features--bugs-backlog)
18. [Open Decisions (Pre-Build Blockers)](#18-open-decisions-pre-build-blockers)
19. [Pipeline & CI/CD](#19-pipeline--cicd)
20. [Housekeeping Notes](#20-housekeeping-notes)

---

## 1. Concept & Problem Statement

RandoEats solves a single, specific problem: **where to eat when your group can't decide.**

Two (or more) people want to go out but have no specific restaurant in mind. They open RandoEats, it finds well-rated local restaurants, factors in where they've been recently, and surfaces suggestions. The app is intended to be fun — colorful, animated, full of sound effects, with a strong retro-futuristic personality.

**Core features:**
- Nearby restaurant discovery using the device's current location
- Filters by rating, price level, and cuisine type
- Memory of recently visited places (avoid repetition)
- Group preference support (eventual goal)
- "Surprise me" instant pick button
- AdMob ads (for learning and experimentation, not revenue expectation)

---

## 2. App Identity & Branding

**Aesthetic:** Groovy 60s / retro-futuristic / space-age  
**Vibe:** Fun, spontaneous, optimistic — the "Googie" architecture of apps  
**Tagline:** "Your space-age food finder that randomly selects local restaurants, turning every mealtime into a cosmic adventure."

**UI personality:**
- Lots of color, sound effects, and animation
- Psychedelic spin animations on buttons
- Swipe interactions with audio feedback
- Possible animated mascot (peace-sign character)
- "Far Out Eats" mode for adventurous suggestions
- "Groovy Vibes" filter (ambient/chill restaurants)

**cspell note:** Add `// cspell:ignore Randoeats randoeats` to the top of `README.md` to suppress spell-check CI failures on the app name.

---

## 3. Tech Stack Overview

| Layer | Technology |
|-------|-----------|
| Mobile/Web client | Flutter (Dart) |
| BFF (Backend For Frontend) | C++ / Drogon framework |
| Hosting | Linode Nanode 1 GB |
| Restaurant data | Google Places API (New) |
| On-device JSON cache | Hive |
| On-device photo cache | flutter_cache_manager |
| Ads | Google AdMob |
| CI/CD | GitHub Actions + Fastlane |
| App distribution | TestFlight (iOS), Firebase App Distribution (Android dev), Play Store internal track |

---

## 4. Data Source Decision

**Chosen: Google Places API (New)**  
Not the legacy Google Places API — the new version uses different endpoints and a different billing model.

**Why Google over Yelp:**
- More generous free tier for small apps
- Better global coverage
- Field masks give you fine-grained cost control (you pay per field group, not per call)
- Simpler integration with Flutter ecosystem
- Yelp ended free access in 2024; paid tiers start at $7.99/1,000 calls

**Why not the legacy Google Places API:**  
Legacy cannot be enabled on new projects. The BFF targets Places API (New) exclusively — the endpoints, field names, and billing SKUs are completely different.

---

## 5. API Cost Model

Google Places API (New) bills per field group (SKU tier), not per call. The field mask you send determines which tier you're charged at.

**SKU tiers relevant to RandoEats:**

| SKU Tier | Triggers | Free calls/month (Essentials) |
|----------|----------|-------------------------------|
| Basic | `id`, `name`, `formattedAddress`, `location` | 10,000 |
| Pro | `currentOpeningHours`, `photos` | 5,000 |
| Enterprise | `rating`, `userRatingCount`, `priceLevel` | 1,000 |
| Enterprise + Atmosphere | `reviews`, `reviewSummary` | 1,000 |

**Critical finding from spec work:** Including `rating`, `userRatingCount`, or `priceLevel` in your Nearby Search field mask bumps the entire call to the Enterprise SKU — not Pro as originally assumed. The reviews endpoint triggers the most expensive tier (Enterprise + Atmosphere).

**Cost control decisions made:**
- Reviews are a separate BFF endpoint (`GET /reviews/{place_id}`) so they don't inflate the cost of standard list/detail page loads
- Field masks are the minimum needed per endpoint, documented with SKU tier in code comments
- Photos are proxied by the BFF but not cached server-side (memory constraint on Nanode) — cached client-side instead
- Set a billing budget alert and daily quota cap in Google Cloud Console **before going live**

---

## 6. Architecture: Why a BFF?

The Flutter app originally called Google Places directly. This is a problem for three reasons:

1. **API key exposure.** The key would be in the compiled app binary, extractable by anyone who decompiles it. They could rack up charges on your account.
2. **No shared caching.** Every user's search hits Google even if someone nearby just searched the same area. You pay per SKU call.
3. **Client complexity.** The app has to handle normalization, error mapping, and Google's raw JSON shape. Swapping providers later means touching the app.

**The BFF pattern:** A server-side proxy layer built specifically for one client (the Flutter app). It speaks the exact language the app needs — pre-shaped, stable response contracts. The app calls your BFF; your BFF calls Google. Google is never touched directly by the client.

```
Flutter App  →  RandoEats BFF (Drogon/C++)  →  Google Places API (New)
                     ↓
               InMemoryCache (TTL-based)
                     ↓
               MetricsLogger (JSONL)
```

**Architecture rule:** A single class — `GooglePlacesClient` — is the **only** component permitted to make upstream calls to Google. All other service and controller code goes through it. This is enforced by a §0 declaration in the spec (see BFF spec document) and makes the code auditable: one file to check for all outbound calls.

---

## 7. BFF Endpoints

Base path: `/api/v1`. All responses JSON unless noted.

| Method | Path | Maps to | Notes |
|--------|------|---------|-------|
| GET | `/api/v1/restaurants/nearby` | Places Nearby Search (POST upstream) | Params: `lat`, `lng`, `radius` (default 5000m, max 50000m), `type` (default `restaurant`), `max` (default 20) |
| GET | `/api/v1/restaurants/{place_id}` | Places Details | Returns single normalized restaurant object. 404 if Google returns not-found. |
| GET | `/api/v1/restaurants/{place_id}/photo` | Places Photo | Params: `photo_ref` (required), `max_width` (default 400, max 1600). Proxies image bytes, not JSON. |
| GET | `/api/v1/restaurants/{place_id}/reviews` | Places Details (reviews fields only) | Separate endpoint to isolate Enterprise + Atmosphere SKU billing. |
| GET | `/api/v1/health` | (none) | Returns `{"status":"ok","version":"..."}`. For Linode/uptime monitoring. |

**Google upstream mapping:**

| # | Purpose | HTTP Method | Google Path |
|---|---------|------------|-------------|
| 1 | Nearby Search | POST | `/v1/places:searchNearby` |
| 2 | Place Details | GET | `/v1/places/{PLACE_ID}` |
| 3 | Place Photo | GET | `/v1/{photoName}/media?maxWidthPx=...` |

---

## 8. BFF: Field Masks & SKU Tiers

**Nearby Search field mask (list view — minimizes per-place cost):**
```
places.id,places.displayName,places.formattedAddress,places.location,
places.rating,places.userRatingCount,places.priceLevel,places.primaryType,
places.currentOpeningHours.openNow,places.photos
```
→ **Enterprise SKU** (due to `rating`, `userRatingCount`, `priceLevel`)

**Place Details field mask (detail view):**
```
id,displayName,formattedAddress,location,rating,userRatingCount,priceLevel,
primaryType,currentOpeningHours,nationalPhoneNumber,websiteUri,photos
```
→ **Enterprise SKU**

**Reviews field mask (reviews endpoint only):**
```
reviews,reviewSummary
```
→ **Enterprise + Atmosphere SKU**

Document the SKU tier in a code comment at every upstream call site. This is mandatory per the §0 declaration in the spec.

---

## 9. BFF: Response Shape (Normalized Contract)

The client must never see raw Google JSON. All responses are normalized to a stable contract so Google can be swapped out later without touching the app.

**Restaurant object (nearby list and detail view):**
```json
{
  "id": "ChIJ...",
  "name": "Some Diner",
  "address": "123 Main St, Orange, CA",
  "location": { "lat": 33.78, "lng": -117.85 },
  "rating": 4.3,
  "ratingCount": 812,
  "priceLevel": 2,
  "type": "restaurant",
  "openNow": true,
  "photoRefs": ["places/ChIJ.../photos/ATpl..."]
}
```

**Reviews response:**
```json
{
  "placeId": "ChIJ...",
  "reviews": [
    {
      "author": "Jane D.",
      "authorUri": "https://maps.google.com/...",
      "rating": 5,
      "text": "Amazing tacos.",
      "publishTime": "2026-05-01T12:00:00Z",
      "mapsUri": "https://maps.google.com/..."
    }
  ],
  "reviewSummary": {
    "text": "Reviewers love the tacos and friendly staff.",
    "disclosureText": "Summarized with Gemini",
    "reviewsUri": "https://maps.google.com/..."
  }
}
```

**Normalization rules:**
- `reviewSummary` is omitted if Google did not return one (not guaranteed for all places)
- Google's `priceLevel` enum (`PRICE_LEVEL_MODERATE` etc.) maps to int 0–4
- `displayName.text` → `name`
- Missing fields → omit or null, never crash
- Nearby list response: `{ "restaurants": [ ... ] }`; detail view: bare object

**Attribution requirement (mandatory per Google ToS):**  
When `reviewSummary` is present, the Flutter UI **must** display `disclosureText` ("Summarized with Gemini") and a link from `reviewsUri`. This is not optional.

---

## 10. BFF: Caching Strategy

The BFF uses an in-memory cache (`InMemoryCache`) behind an `ICache` interface. In-memory is appropriate for a single-instance Nanode at current scale. The interface allows swapping to Redis later without changing the service layer.

**Cache is bounded** at 2,000 entries (configurable via `cache_max_entries` in `config.json`) with LRU-style eviction to prevent memory exhaustion on the 1 GB Nanode.

**TTLs:**

| Data | Server-side TTL | Rationale |
|------|----------------|-----------|
| Nearby search results | 1 hour | Restaurants don't open/close that fast |
| Place details | 6 hours | Hours, ratings change slowly |
| Reviews | 6 hours | Same as details |
| Photos | Not cached server-side | Proxied directly; cached client-side |

**Cache key scheme:**
- Nearby: `nearby:{lat_rounded}:{lng_rounded}:{radius}:{type}`  
  Round lat/lng to 3 decimal places (~110m precision) to maximize cache hits for searches in the same vicinity.
- Details: `details:{place_id}`
- Reviews: `reviews:{place_id}`
- Photo: not cached (proxied bytes)

**Google ToS constraint:** Google's platform terms restrict caching most Places content beyond 30 days. Place IDs are the exception (they can be cached indefinitely). All BFF TTLs sit far under 30 days. Do not "optimize" TTLs upward past that limit.

**`Cache-Control` header:** The BFF returns a `Cache-Control` header on every response carrying the TTL value. This lets the Flutter client know the TTL without hardcoding it in the app.

**Photo caching note:** In-memory photo byte caching was removed from the BFF spec due to memory constraints on the Nanode. Photos are proxied directly and cached on-device via `flutter_cache_manager` (see §14).

---

## 11. BFF: Performance Metrics Logging

Metrics logging is a **first-class concern** — it establishes a Phase 0 baseline before caching is fully active, enabling objective before/after comparison.

**Implementation:** A `MetricsFilter` Drogon filter wraps every request, measures timing, and writes a structured JSON Lines record to a log file after each response is sent.

**Log schema (one JSON object per line):**
```json
{
  "ts": "2026-06-25T10:30:00.123Z",
  "method": "GET",
  "path": "/api/v1/restaurants/nearby",
  "status": 200,
  "total_ms": 145,
  "upstream_ms": 140,
  "cache": "MISS",
  "upstream_endpoint": "nearby_search"
}
```

- `cache`: `HIT`, `MISS`, or `NONE` (endpoints with no cache, like `/health` or `/photo`)
- `upstream_ms`: time spent waiting for Google (0 on cache HIT)
- `total_ms`: full request-to-response time including serialization

**Log path:** Configurable via `config.json`:
```json
"metrics_log_path": "/var/log/randoeats/metrics.jsonl"
```

**Log rotation** (`/etc/logrotate.d/randoeats`):

```
/var/log/randoeats/metrics.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    create 640 randoeats randoeats
}
```

`copytruncate` is required because `MetricsLogger` holds the file open as a persistent `ofstream`. Standard logrotate (rename + new file) would leave the process writing to the renamed file. `copytruncate` copies then truncates the live file in place — brief theoretical window of 1–2 lost lines, acceptable for metrics.

**Analysis tool:** `tools/analyze_metrics.py` — stdlib-only Python script that reads the JSONL log and computes latency percentiles (p50, p95, p99) and cache hit rates. Run before adding caching (Phase 0 baseline) and after (Phase 1+) to measure the actual improvement.

---

## 12. BFF: Project Structure

```
randoeats-bff/
├── CMakeLists.txt
├── config.json              # not committed — contains API key
├── config.example.json      # committed — template with placeholder values
├── .gitignore               # must include config.json
├── README.md
├── main.cc
├── controllers/
│   └── RestaurantController.{h,cc}
├── services/
│   ├── PlacesService.{h,cc}
│   ├── GooglePlacesClient.{h,cc}   ← sole upstream choke point
│   ├── ICache.h                    ← interface; swap in Redis later
│   ├── InMemoryCache.{h,cc}
│   └── MetricsLogger.{h,cc}
├── filters/
│   └── MetricsFilter.{h,cc}        ← Drogon pre/post filter for timing
└── tools/
    └── analyze_metrics.py
```

**Layer call rule:** Controller → Service → {GooglePlacesClient, CacheService}. Controllers never call GooglePlacesClient directly. This keeps the upstream logic in one place.

---

## 13. BFF: Deployment Target

**Linode Nanode 1 GB**  
$5/month · 1 vCPU · 1 GB RAM · 25 GB SSD

This is a shared Linode that already runs VendorBliss and other TekAdept services.

- Default port: **8848** (confirm this is free before deploying)
- Run as a dedicated Linux service user (`randoeats` or similar — TBD)
- Log directory: `/var/log/randoeats/` (create with correct ownership before first run)
- Config file lives outside the repo; never committed

---

## 14. Flutter Client: Caching Strategy

Two complementary cache layers — the BFF cache and on-device cache serve different purposes and both are needed.

| | BFF Cache | On-device Cache |
|--|-----------|-----------------|
| Purpose | Reduces Google API calls / cost | Eliminates network round-trips / speed |
| Scope | Shared across all users | Per device |
| Tool | `InMemoryCache` (C++) | `hive` (JSON) + `flutter_cache_manager` (photos) |

**On-device TTLs (intentionally shorter than BFF):**

| Data | On-device TTL |
|------|--------------|
| Nearby results | 15 minutes |
| Place details | 2 hours |
| Photos | 7 days |

**Photo caching:** `flutter_cache_manager` handles binary content to disk, respects TTL, handles re-validation. This is the biggest single win since photos are the most expensive bytes to re-fetch and the most static.

**JSON caching:** A simple TTL wrapper around `hive`. Key scheme mirrors the BFF (rounded lat/lng for nearby, `place_id` for details).

The BFF's `Cache-Control` header carries the TTL value so the client doesn't hardcode it.

> **Status:** Designed, not yet implemented. Noted as a backlog item.

---

## 15. Flutter Client: Location Services

Package: `geolocator`

```dart
Future<Position?> getUserLocation() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null; // handle gracefully in UI
  }
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
  );
}
```

`LocationAccuracy.medium` is correct for a restaurant app — GPS-survey precision is unnecessary and high accuracy noticeably drains battery.

---

## 16. Flutter Client: Map Library Decision

**⚠️ Open decision — must be made before Flutter client spec is written.**

| | `google_maps_flutter` | `flutter_map` |
|--|----------------------|---------------|
| Tile source | Google Maps (separate billing SKU) | OpenStreetMap (free) |
| API key required | Yes — separate Maps key | No |
| Visual | Familiar Google Maps look | Configurable |
| Vendor lock-in | Google | None |

Since you're already using Google Places, Google Maps tiles give visual consistency and the key is already managed. But `flutter_map` + OSM keeps a second billing surface entirely off the table, which fits the TekAdept "no vendor lock-in" philosophy. This is a deliberate call — don't default to Google without deciding.

---

## 17. Planned Features & Bugs (Backlog)

### Features

**Reviews UI (designed, not built)**
- Restaurant detail screen has two horizontally swipable lists stacked vertically
- Good reviews (4+ stars) on top, critical reviews (under 4 stars) on bottom
- Divider between them
- Each list is a `PageView` — swipe left/right to move between cards
- Animated dot indicators below each section label
- Cards: author name, rating stars, review text (truncated ~4 lines), relative time
- Color coded: green tint for good, red tint for critical
- Empty state handled gracefully if one bucket has no reviews
- `PageController` must be disposed to avoid memory leaks
- Split threshold (`rating >= 4.0`) is configurable later

**On-device caching** (designed, not built — see §14)

**Group preference support** (eventual goal — not yet designed)

**"Surprise me" button** (planned UX — not yet designed)

### Bugs

**Duplicate splash screen**  
Two splash screens appear in sequence. Likely cause: Flutter's native splash (configured in `AndroidManifest.xml` / `LaunchScreen.storyboard`) plus a secondary Dart-side splash widget running on top.

Resolution plan: Keep native splash only, remove Dart splash widget. If async init is needed (loading prefs, checking auth), hold the native splash using `flutter_native_splash` until ready, then go straight to home screen.

---

## 18. Open Decisions (Pre-Build Blockers)

These must be resolved before handing the BFF spec to Claude Code:

**Design decisions:**
1. **Map library** — `google_maps_flutter` (Google Maps SKU, consistent look) vs `flutter_map` (OSM, free, no lock-in)
2. **CORS allowed origins** — What is the RandoEats web domain? The BFF spec has a placeholder. Without a real value, Claude Code will default to something permissive or leave it blank.
3. **Reviews scope** — Individual reviews only (up to 5), or individual reviews + Gemini AI summary? The summary requires mandatory attribution UI in Flutter (`disclosureText` + `reviewsUri` link). Confirm before building so normalization code is right the first time.

**Google Cloud Console:**
4. **Enable Places API (New)** — confirm it's enabled on your project, not the legacy version
5. **Create a server-side API key** — restrict it by IP to the Linode's address; unrestricted keys are a liability
6. **Set a billing budget alert and daily quota cap** — especially critical given the Enterprise + Atmosphere SKU the reviews endpoint triggers. Set before going live, not after the first surprise invoice.

**Linode:**
7. **Confirm port 8848 is free** — shared box with VendorBliss and other services
8. **Create `/var/log/randoeats/`** with correct ownership before first run
9. **Decide the Linux service user account** for the BFF process

---

## 19. Pipeline & CI/CD

Initial pipeline design from early planning:

**GitHub Actions workflows:**

| Trigger | What runs |
|---------|-----------|
| Every push/PR | `flutter analyze`, `flutter test`, `flutter format` check |
| Release tag | Build Android APK/AAB, build iOS IPA, build web, deploy web, upload to Play Store internal track, upload to TestFlight |

**Tools in use:**
- GitHub Actions (free tier)
- Fastlane (iOS/Android automation)
- Firebase App Distribution (dev/QA builds)
- TestFlight (iOS beta)
- Google Play Console internal track (Android)

**analysis_options.yaml** — linting rules configured at project root.

---

## 20. Housekeeping Notes

- **cspell:** Add `// cspell:ignore Randoeats randoeats` to the top of `README.md` to prevent CI spell-check failures
- **API key in config.json:** Never commit `config.json`. It must be in `.gitignore`. The repo contains only `config.example.json` with placeholder values.
- **Google ToS / caching limit:** Most Places content cannot be cached beyond 30 days per Google's platform terms. Place IDs are the exception. Do not increase cache TTLs past that threshold.
- **Linode shared box:** The BFF shares a box with VendorBliss and other TekAdept services. Be mindful of port conflicts and memory. The `cache_max_entries` bound (default 2,000) exists specifically to prevent the BFF from crowding other services on the 1 GB Nanode.
- **The BFF spec document** (`randoeats-bff-spec.md`) is the implementation handoff artifact for Claude Code. This project reference document is the human-readable history and decision log. Keep both.
