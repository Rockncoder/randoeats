# Tasks: Durable cache for the Places proxy

**Input**: [spec.md](./spec.md), [plan.md](./plan.md)
**Blocked by**: 001 (no way to grade either backend without it)

## Phase 1: Setup

- [ ] **T001** Confirm Redis is available on the `tekadept-bff` host, or decide it will be added. If neither, stop and revisit the spec — do not substitute a bespoke on-disk cache.
- [ ] **T002** Add `cache_backend` (`"memory"` | `"redis"`) plus a connection block to `bff/config.example.json`, defaulting to `"memory"`.

## Phase 2: Foundational

- [ ] **T003** `CacheFactory` mapping config → `ICache`, failing fast on an unrecognized backend. (Spec US3 scenario 3)
- [ ] **T004** Move cache construction in `main.cc`/`AppContext` behind the factory.
- [ ] **T005** Namespace all keys as `randoeats:v1:<kind>:<key>`. (FR-004)

## Phase 3: User Story 1 — Survives restart (P1) 🎯 MVP

- [ ] **T006** [US1] Implement `RedisCache : ICache` on `drogon::nosql::RedisClient`; TTL enforced by the store, never by a BFF sweep. (FR-003)
- [ ] **T007** [US1] Round-trip test: non-ASCII place names survive byte-for-byte.
- [ ] **T008** [US1] Restart test: warm cache → restart → still a HIT, no upstream call.
- [ ] **T009** [US1] TTL-across-restart test: expiry is honored, not extended.
- [ ] **T010** [US1] Unreachable-at-startup: BFF starts, serves via in-memory, logs the degradation. (FR-005)
- [ ] **T011** [US1] Unreachable-while-running: requests still served via upstream; no request fails because the cache is down.

## Phase 4: User Story 2 — Capacity (P2)

- [ ] **T012** [US2] Confirm the 2000-entry ceiling no longer applies on the Redis path; capacity governed by store configuration.
- [ ] **T013** [US2] Make eviction observable in logs or metrics.

## Phase 5: User Story 3 — Backend is configurable (P3)

- [ ] **T014** [US3] Run 001's full `PlacesService` suite against both backends.
- [ ] **T015** [US3] Confirm `"memory"` behaves exactly as today (no diff in observable behavior).

## Phase 6: Polish

- [ ] **T016** Confirm the Places key is never written to the cache. (FR-006)
- [ ] **T017** Measure HIT latency from Redis; confirm < 10ms so the access-log HIT/MISS split stays meaningful. (SC-002)
- [ ] **T018** Update `deploy/` if Redis joins the host topology.
- [ ] **T019** **Write an ADR** if Redis is adopted — it changes the operational topology that `deploy/randoeats.caddy` documents. (Plan, Constitution Check V)

## Definition of Done

Both backends pass 001's suite, restart preserves the cache without extending
TTLs, a downed store never fails a request, and the ADR exists if the topology
changed.
