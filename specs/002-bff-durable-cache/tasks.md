# Tasks: Durable cache for the Places proxy

**Input**: [spec.md](./spec.md), [plan.md](./plan.md)
**Blocked by**: 001 (no way to grade either backend without it)
**Revised**: 2026-08-29 — retargeted from Redis to the host's PostgreSQL

## Phase 1: Setup

- [ ] **T001** Confirm the BFF **container** can reach PostgreSQL on the host. The container publishes a host port rather than joining a shared network, so it needs `host.containers.internal:5432` or an equivalent. **This is the one thing that could still invalidate the approach — do it first.**
- [ ] **T002** Verify Drogon's ORM is compiled into `drogonframework/drogon:latest` (the runtime image). If it is not, the image needs a source build with `-DBUILD_ORM=ON -DBUILD_POSTGRESQL=ON`.
- [ ] **T003** Enable the ORM in CI: `.github/workflows/check.yml` currently builds Drogon with `-DBUILD_ORM=OFF -DBUILD_POSTGRESQL=OFF`. Without this the Postgres path is untestable in CI while working in production — the worst of both.
- [ ] **T004** Add `cache_backend` (`"memory"` | `"postgres"`), connection string, row cap and sweep interval to `bff/config.example.json`, defaulting to `"memory"`.

## Phase 2: Foundational

- [ ] **T005** Provision `randoeats_prod` and a role with privileges on that database only. Record it in `deploy/`; do not grant anything on the other tenant's database. (FR-004, SC-005)
- [ ] **T006** Create the schema from the plan: `UNLOGGED` table, primary key on `key`, indexes on `expires_at` and `last_read`. Idempotent (`IF NOT EXISTS`) so startup can apply it. (FR-007)
- [ ] **T007** `CacheFactory` mapping config → `ICache`, failing fast on an unrecognized backend. (Spec US3 scenario 3)
- [ ] **T008** Move cache construction in `main.cc` / `AppContext` behind the factory.

## Phase 3: User Story 1 — Survives restart (P1) 🎯 MVP

- [ ] **T009** [US1] Implement `PostgresCache : ICache` on `orm::DbClient`. `get` filters `expires_at > now()` so expiry never depends on the sweep; `set` upserts. (FR-001, FR-003, FR-008)
- [ ] **T010** [US1] Round-trip test: non-ASCII place names survive byte-for-byte.
- [ ] **T011** [US1] Restart test: warm cache → restart the process → still a HIT, no upstream call. (SC-001)
- [ ] **T012** [US1] TTL-across-restart test: an entry expired during downtime is not served. (Spec scenario 2)
- [ ] **T013** [US1] Unreachable-at-startup: the BFF starts, serves via in-memory, logs the degradation. (FR-005)
- [ ] **T014** [US1] Unreachable-while-running: requests still served via upstream; no request fails because the cache is down. (SC-003)
- [ ] **T015** [US1] Concurrent-writer test: two writers upserting the same key, neither errors. (FR-008)

## Phase 4: User Story 2 — Capacity is governed (P2)

- [ ] **T016** [US2] Sweep: delete expired rows, then trim to the row cap by oldest `last_read`. No long table locks. (FR-009)
- [ ] **T017** [US2] Update `last_read` on hit, cheaply enough not to cost more than the read itself.
- [ ] **T018** [US2] Test: a read of an expired row is a miss even when the sweep has never run. (Spec US2 scenario 3)
- [ ] **T019** [US2] Test: exceeding the row cap evicts expired rows before live ones.

## Phase 5: User Story 3 — Backend is configurable (P3)

- [ ] **T020** [US3] Run 001's full `PlacesService` suite against both backends, using a disposable database for the Postgres path — never a shared one. (FR-010)
- [ ] **T021** [US3] Confirm `"memory"` behaves exactly as today; the smoke test still passes.

## Phase 6: Polish

- [ ] **T022** Confirm the Places key is never written to the cache. (FR-006)
- [ ] **T023** Measure HIT latency through Postgres; confirm under 10ms so the `X-Cache` / access-log gap stays meaningful. (SC-002)
- [ ] **T024** Confirm the other tenant is unaffected: randoeats' role has no privileges outside its own database. (SC-005)
- [ ] **T025** **Write an ADR** for depending on a shared database server. It changes the operational topology and the dependency graph the platform README describes. (Plan, Constitution Check V)

## Dependencies & Execution Order

- **T001 gates everything.** If the container cannot reach Postgres, revisit the spec rather than working around it.
- T003 should land early: without the ORM in CI, none of Phase 3 can be graded.
- Phase 3 is the MVP. Phases 4 and 5 depend on it and are independent of each other.

## Definition of Done

`just check` green with both backends, a container restart preserves the cache
without extending TTLs, a stopped database never fails a request, randoeats holds
no privileges outside its own database, and the ADR exists.
