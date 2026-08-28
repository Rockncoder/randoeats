# Tasks: Cost caps on Google Places spend

**Input**: [spec.md](./spec.md), [plan.md](./plan.md)
**Blocked by**: 001 (to assert "Google was not called"); strongly prefers 002 (durable counter)

## Phase 1: Setup

- [ ] **T001** Add a caps block to `bff/config.example.json`: window length, cap, per-client limit and window. Default to effectively unlimited so today's behavior is preserved. (FR-006, spec Assumptions)

## Phase 2: Foundational

- [ ] **T002** Extend `ICache` so an expired-but-present value is retrievable distinctly from an absent one. Today `get` returns `nullopt` for both, which makes stale-serve impossible. Update `InMemoryCache` and `RedisCache`. (Plan decision 2)
- [ ] **T003** `IBudget` + `BudgetTracker`: consume/peek against a rolling window, persisted so a restart does not reset the budget. (FR-001, FR-005)
- [ ] **T004** `RateLimiter`: per-client counts over a short window. (FR-004)
- [ ] **T005** Extract the forwarded client address in `RestaurantController`, not the socket peer — behind Caddy the peer is always localhost. (Spec edge case)

## Phase 3: User Story 1 — Spend has a ceiling (P1) 🎯 MVP

- [ ] **T006** [US1] Check the budget immediately before any upstream call, in all three paths — `nearby`, `details`, `photo`. (FR-007)
- [ ] **T007** [US1] Ensure HITs never consume budget. (FR-002)
- [ ] **T008** [US1] Implement the degradation order: fresh cache → stale cache marked stale → documented degraded status. (FR-003)
- [ ] **T009** [US1] Test: cap = 0 → zero upstream calls, cached requests still served. (SC-001)
- [ ] **T010** [US1] Test: upstream call count never exceeds the cap under a synthetic flood, asserted on test-double invocations. (SC-003)
- [ ] **T011** [US1] Test: window rollover resumes calls automatically.
- [ ] **T012** [US1] Test: counter survives a restart mid-window. (SC-004)

## Phase 4: User Story 2 — One client cannot exhaust the budget (P2)

- [ ] **T013** [US2] Apply the per-client limiter ahead of the budget check.
- [ ] **T014** [US2] Test: one client floods and is limited; a second client is unaffected. (SC-002)
- [ ] **T015** [US2] Test: a limited client that backs off is served normally afterwards.
- [ ] **T016** [US2] Sanity-check the default limit against real single-user usage so a person picking lunch never trips it. (SC-005) Use 004's data if available; otherwise set it generously and say so.

## Phase 5: User Story 3 — Approaching the cap is visible (P3)

- [ ] **T017** [US3] Expose used/cap/reset-time at runtime. (FR-008)
- [ ] **T018** [US3] Record a distinct warning event when consumption crosses a threshold.

## Phase 6: Polish

- [ ] **T019** Document the degraded response shape and confirm the Dart client handles it without crashing or showing a raw error. (FR-009)
- [ ] **T020** Add the app↔BFF contract entry `docs/conventions.adoc` requires and `BACKLOG.adoc` records as missing — the degraded status is exactly the kind of thing an undocumented contract loses.
- [ ] **T021** Confirm per-client counters are ephemeral and hold nothing user-identifying. (Plan, Constitution Check I)

## Definition of Done

Upstream calls provably cannot exceed the cap, one client cannot starve
another, the counter survives restart, the degraded contract is documented and
handled by the client, and normal usage never trips a limit.
