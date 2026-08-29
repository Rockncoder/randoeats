# Feature Specification: Durable cache for the Places proxy

**Feature Branch**: `002-bff-durable-cache`
**Created**: 2026-08-28
**Status**: Draft
**Input**: `InMemoryCache` is per-process, single-threaded (`threads: 1`), capped at 2000 entries, and cold on every restart or redeploy. `ICache.h` already states the interface exists so "a Redis-backed cache can be dropped in later" — the seam is built, the implementation is not.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The cache survives a restart (Priority: P1)

As the operator, I want cached Places responses to survive a BFF restart or
redeploy, so that routine deploys do not force a wave of paid Google calls.

**Why this priority**: Every deploy currently discards the entire cache. With a
1-hour nearby TTL, a deploy at a busy moment re-buys an hour of traffic.

**Acceptance Scenarios**:

1. **Given** a warm cache, **When** the BFF process restarts, **Then** a repeat
   request is still a HIT and makes no upstream call.
2. **Given** a cached entry, **When** its TTL elapses across a restart, **Then**
   the entry is gone and the request is a MISS — restart must not extend a TTL.
3. **Given** the durable store is unreachable at startup, **When** the BFF
   starts, **Then** it serves correctly using the in-memory cache and logs the
   degradation, rather than failing to start.
4. **Given** the durable store becomes unreachable while running, **When** a
   request arrives, **Then** it is served (via upstream if necessary) and no
   request fails solely because the cache is down.

### User Story 2 - Capacity is no longer a hard 2000 (Priority: P2)

As the operator, I want cache capacity to be governed by the store rather than
a hardcoded 2000-entry ceiling, so that a wider spread of regions and places
stays cached.

**Acceptance Scenarios**:

1. **Given** more than 2000 distinct cached requests, **When** the 2001st is
   made, **Then** earlier entries are not silently evicted purely by that limit.
2. **Given** a configured maximum, **When** it is reached, **Then** eviction
   follows the store's policy and is observable in logs or metrics.

### User Story 3 - The backend is a configuration choice (Priority: P3)

As a developer, I want to run the BFF locally with no Redis, so that local work
and tests do not require extra infrastructure.

**Acceptance Scenarios**:

1. **Given** `cache_backend: "memory"`, **When** the BFF starts, **Then** it
   behaves exactly as today.
2. **Given** `cache_backend: "redis"` with connection settings, **When** the BFF
   starts, **Then** all cache reads and writes go to Redis.
3. **Given** an unrecognized backend value, **When** the BFF starts, **Then** it
   fails fast with a clear message rather than silently choosing a default.

### Edge Cases

- Two BFF processes sharing one Redis MUST NOT collide with each other or with
  another TekAdept service on the same host — keys need a namespace.
- A cached value is a pre-serialized JSON string; the durable store must round
  trip it byte-for-byte, including any non-ASCII in place names.
- Redis latency on a HIT must stay far below an upstream call, or the cache
  stops being a win. The Caddy access log's HIT/MISS split (~1ms vs ~100-300ms)
  is the existing reference point.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `RedisCache` MUST implement `ICache` without changing the
  interface. `PlacesService` MUST NOT be modified to know which backend is in
  use.
- **FR-002**: The backend MUST be selected by configuration, defaulting to
  in-memory so existing deployments and local runs are unaffected until opted in.
- **FR-003**: Existing TTL semantics MUST be preserved exactly — `nearby_ttl_seconds`
  (3600) and `details_ttl_seconds` (21600) continue to govern, applied by the
  store so expiry is enforced without the BFF sweeping.
- **FR-004**: All keys MUST carry a namespace prefix identifying this service.
- **FR-005**: Cache unavailability MUST degrade to serving from upstream, never
  to a failed request. Startup MUST NOT be blocked by an unreachable store.
- **FR-006**: The Places API key MUST NOT be written to the cache, and cached
  payloads MUST contain only what the client already receives.
- **FR-007**: Tests from feature 001 MUST pass against both backends, with the
  Redis path covered by a test double or an ephemeral instance — never a shared
  one.

### Key Entities

- **RedisCache** — an `ICache` over Drogon's Redis client, translating
  `set(key, value, ttl)` onto a TTL-bearing write and `get` onto a read that
  returns `nullopt` for missing or expired keys.
- **Cache backend configuration** — the config block naming the backend and its
  connection parameters.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a restart with a warm cache, hit rate over the first minute
  is materially unchanged, versus 0% today.
- **SC-002**: A HIT served from Redis returns in under 10ms end to end, keeping
  the HIT/MISS gap that makes the access log meaningful.
- **SC-003**: With the store stopped, the BFF still answers every request
  correctly, falling back to upstream.
- **SC-004**: No change to `PlacesService`'s cache-related code is required to
  switch backends.

## Assumptions

- Redis is available on the shared `tekadept-bff` host, or can be added there.
  If it cannot, this feature should be reconsidered rather than worked around —
  the plan must not invent a bespoke on-disk cache as a substitute.
- ADR-0004 ("device-local storage, no accounts, no server-side user data") is
  **not** contradicted: cached Places responses are upstream catalogue data
  keyed by query, not user data. The plan's Constitution Check must state this
  explicitly, and the cache MUST NOT begin storing anything user-identifying.
