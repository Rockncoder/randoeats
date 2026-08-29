# Implementation Plan: Durable cache for the Places proxy

**Branch**: `002-bff-durable-cache` | **Date**: 2026-08-28 | **Spec**: [spec.md](./spec.md)

## Summary

Add a `RedisCache` implementing the existing `ICache`, select the backend from
config, and fall back to in-memory whenever the store is unavailable. No change
to `PlacesService`.

## Technical Context

**Depends on**: 001 (tests to grade both backends)
**Client**: Drogon ships a Redis client (`drogon::nosql::RedisClient`) — no new dependency
**Config**: `bff/config.json` (untracked; `config.example.json` is the tracked template)
**Existing TTLs**: nearby 3600s, details 21600s, `cache_max_entries` 2000
**Host**: shared `tekadept-bff` Linode — Redis must be added there or the feature reconsidered

## Constitution Check

| Principle | Assessment |
|---|---|
| I. ADRs are binding | **ADR-0004** (device-local storage, no accounts, no server-side user data) requires an explicit statement: cached Places responses are upstream catalogue data keyed by query — not user data, not tied to an identity, and already transmitted to every client that asks. The cache MUST NOT begin storing anything user-identifying; if it ever needs to, that is a superseding ADR, not a config change. **ADR-0003** unaffected: the key stays server-side and is never cached. |
| II. Conventions | `RedisCache` follows the existing `ICache` implementation style. |
| III. `just check` is the verdict | Both backends must pass 001's suite. |
| V. Spec Kit specs ≠ ADRs | Introducing a network dependency to the deployment is arguably architectural. If Redis is adopted on the shared host, **write an ADR** — it changes the operational topology `deploy/randoeats.caddy` documents. |

## Project Structure

```
bff/services/
├── ICache.h              # unchanged — the seam already exists
├── RedisCache.h/.cc      # NEW
├── InMemoryCache.h/.cc   # unchanged (remains the fallback and the local default)
└── CacheFactory.h/.cc    # NEW: config -> ICache, with fallback on failure
bff/config.example.json   # MODIFIED: cache_backend + connection block
deploy/                   # MODIFIED if Redis joins the host topology
```

## Design decisions

1. **Factory, not conditional construction in `main`.** Keeps backend selection
   in one testable place and keeps `main.cc` thin.
2. **Fallback is silent to callers, loud in logs.** A request must never fail
   because the cache is down (FR-005), but the degradation must be visible.
3. **TTL enforced by the store.** Redis `SETEX`-style expiry rather than the BFF
   sweeping, so a restart cannot extend a TTL (spec scenario 2).
4. **Namespaced keys.** `randoeats:v1:nearby:...` so a shared Redis on the
   TekAdept host cannot collide across services or across schema changes.

## Complexity Tracking

| Change | Why needed | Simpler alternative rejected because |
|---|---|---|
| Redis dependency on the host | The cache must outlive the process | An on-disk cache reimplements expiry, eviction and concurrency badly |
| CacheFactory | Backend choice must be configurable and testable | Branching in `main.cc` is untestable and grows with each backend |
