# Feature Specification: Durable cache for the Places proxy

**Feature Branch**: `002-bff-durable-cache`
**Created**: 2026-08-28
**Revised**: 2026-08-29 — retargeted from Redis to the PostgreSQL already on the host
**Status**: Draft
**Input**: `InMemoryCache` is per-process, single-threaded (`threads: 1`), capped at 2000 entries, and cold on every restart or redeploy. `ICache.h` already states the interface exists so a persistent cache "can be dropped in later" — the seam is built, the implementation is not.

## Why not Redis

The first draft of this spec assumed Redis, because `ICache.h`'s comment names
it. That was the wrong default and is corrected here.

A check of `tekadept-bff-prod` on 2026-08-29 found **no Redis and no Valkey** —
no binaries, no container, nothing listening on 6379 — but **PostgreSQL 16
running** on 5432, already there for another tenant.

Everything this feature needs is a keyed lookup with an expiry, at a few reads
per minute. Postgres does that in well under a millisecond on localhost. Adding
Redis would mean installing, securing, memory-capping, monitoring and backing up
a second datastore to save time no user can perceive.

The honest cost of choosing Postgres: **TTL expiry and eviction become our
code** rather than `SETEX` and `maxmemory-policy`. That is roughly twenty lines
of SQL and one periodic sweep, and it is a smaller cost than a second service.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The cache survives a restart (Priority: P1)

As the operator, I want cached Places responses to survive a BFF restart or
redeploy, so that routine deploys do not force a wave of paid Google calls.

**Why this priority**: Every deploy currently discards the entire cache. Four
deploys on 2026-08-29 alone each threw away a warm cache and re-bought that
traffic from Google.

**Acceptance Scenarios**:

1. **Given** a warm cache, **When** the BFF container is restarted or replaced,
   **Then** a repeat request is still a HIT (`X-Cache: HIT`) and makes no
   upstream call.
2. **Given** a cached entry, **When** its TTL elapses across a restart, **Then**
   the entry is not served — a restart must never extend a TTL.
3. **Given** Postgres is unreachable at startup, **When** the BFF starts,
   **Then** it starts anyway, serves correctly from the in-memory cache, and
   logs the degradation.
4. **Given** Postgres becomes unreachable while running, **When** a request
   arrives, **Then** it is served (via upstream if necessary) and no request
   fails solely because the cache is down.

### User Story 2 - Capacity is governed, not hardcoded (Priority: P2)

As the operator, I want cache capacity governed by configuration and enforced by
a sweep, rather than a hardcoded 2000-entry ceiling.

**Acceptance Scenarios**:

1. **Given** more than 2000 distinct cached requests, **When** the 2001st is
   made, **Then** earlier entries are not evicted purely by that limit.
2. **Given** a configured maximum row count, **When** it is exceeded, **Then**
   the sweep removes expired rows first and only then the least recently read.
3. **Given** the sweep has never run, **When** a read finds an expired row,
   **Then** it is treated as a miss regardless — expiry must not depend on the
   sweep having run.

### User Story 3 - The backend is a configuration choice (Priority: P3)

As a developer, I want to run the BFF and its tests with no database, so local
work needs no extra infrastructure.

**Acceptance Scenarios**:

1. **Given** `cache_backend: "memory"`, **When** the BFF starts, **Then** it
   behaves exactly as today.
2. **Given** `cache_backend: "postgres"` with a connection string, **When** the
   BFF starts, **Then** all cache reads and writes go to Postgres.
3. **Given** an unrecognized backend value, **When** the BFF starts, **Then** it
   fails fast with a clear message rather than silently choosing a default.

### Edge Cases

- A cached value is a pre-serialized JSON string; the store must round-trip it
  byte-for-byte, including non-ASCII in place names.
- Two BFF processes (a rolling deploy) may read and write concurrently. Writes
  must be upserts, and a losing race must not error.
- The sweep must not lock the table long enough to stall a request.
- Postgres on this host serves another tenant. randoeats must not be able to
  degrade it — see the isolation requirements below.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A `PostgresCache` MUST implement `ICache` without changing the
  interface. `PlacesService` MUST NOT learn which backend is in use.
- **FR-002**: The backend MUST be selected by configuration, defaulting to
  in-memory so existing deployments and local runs are unaffected until opted in.
- **FR-003**: Existing TTL semantics MUST be preserved exactly —
  `nearby_ttl_seconds` (3600) and `details_ttl_seconds` (21600). Expiry MUST be
  enforced on read (`expires_at > now()`), not only by the sweep, so a restart
  cannot resurrect an expired entry.
- **FR-004**: randoeats MUST use its **own database** in the cluster, with its
  own role and password. Key prefixes are not sufficient isolation from another
  tenant's data.
- **FR-005**: Cache unavailability MUST degrade to serving from upstream, never
  to a failed request. Startup MUST NOT be blocked by an unreachable database.
- **FR-006**: The Places API key MUST NOT be written to the cache, and cached
  payloads MUST contain only what the client already receives.
- **FR-007**: The cache table SHOULD be `UNLOGGED`. It is a cache: skipping WAL
  avoids write amplification on a shared host, and the only cost is that a
  Postgres *crash* truncates it. A clean restart — and every BFF redeploy, which
  is the case this feature exists for — preserves it.
- **FR-008**: Writes MUST be upserts (`ON CONFLICT DO UPDATE`), safe under
  concurrent writers.
- **FR-009**: A periodic sweep MUST delete expired rows and enforce the row cap,
  without long table locks.
- **FR-010**: Tests from feature 001 MUST pass against both backends. The
  Postgres path MUST be tested against a disposable database, never a shared one.

### Key Entities

- **PostgresCache** — an `ICache` over Drogon's `orm::DbClient`, mapping
  `get`/`set`/`clear` onto a single table.
- **Cache table** — `key text primary key`, `value text`, `expires_at timestamptz`,
  and a last-read timestamp to support least-recently-used sweeping.
- **Cache backend configuration** — the block naming the backend, its connection
  string, row cap and sweep interval.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a container restart with a warm cache, the first repeat
  request returns `X-Cache: HIT`. Today it is always `MISS`.
- **SC-002**: A HIT served from Postgres adds under 10ms end to end, keeping the
  HIT/MISS gap visible in the access log and in `X-Cache`.
- **SC-003**: With Postgres stopped, the BFF still answers every request
  correctly by falling back to upstream, and still starts from cold.
- **SC-004**: No change to `PlacesService`'s cache-related code is required to
  switch backends.
- **SC-005**: The other tenant on this database server is unaffected — verified
  by randoeats holding no privileges outside its own database.

## Assumptions

- PostgreSQL 16 is running on `tekadept-bff-prod` and reachable from the
  container. Confirmed running on 2026-08-29; container reachability is task
  T001 and is the one thing that could still invalidate this approach.
- Drogon's ORM must be compiled in. CI currently builds Drogon with
  `-DBUILD_ORM=OFF`, which must be flipped in the same change or the Postgres
  path is untestable in CI while working in the production image.
- ADR-0004 ("device-local storage, no accounts, no server-side user data") is
  **not** contradicted: cached Places responses are upstream catalogue data keyed
  by query, not user data, and are already sent to every client that asks. The
  cache MUST NOT begin storing anything user-identifying; if it ever needs to,
  that is a superseding ADR, not a schema change.
