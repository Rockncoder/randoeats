# Tasks: Cache efficiency and spend reporting

**Input**: [spec.md](./spec.md), [plan.md](./plan.md)
**Blocked by**: 001. Shares storage with 003's counter where present.

## Phase 1: Setup

- [ ] **T001** Add to `bff/config.example.json`: price table per endpoint kind, `metrics.jsonl` retention, and whether the stats endpoint is exposed beyond localhost (default: not).

## Phase 2: Foundational

- [ ] **T002** `StatsAggregator`: per-endpoint, per-window counters for requests, HITs, MISSes and upstream milliseconds, fed from the `"HIT"`/`"MISS"` classification `ServiceResult` already carries. (FR-001)
- [ ] **T003** Periodic durable snapshot so a restart does not lose history and a query never scans the full log. (FR-002, FR-007, SC-002)
- [ ] **T004** Retention/rotation for `metrics.jsonl`, mirroring the Caddy log's roll settings. (FR-006)

## Phase 3: User Story 1 — Hit rate is a number I can read (P1) 🎯 MVP

- [ ] **T005** [US1] `GET /api/v1/stats` returning counts and hit rate per endpoint as JSON. (FR-003)
- [ ] **T006** [US1] Test: zero traffic yields a well-formed zero result, not an error or a divide-by-zero. (Spec scenario 3)
- [ ] **T007** [US1] Test: history survives a restart.
- [ ] **T008** [US1] Validate reported hit rate against the Caddy access log for the same window, within 1%. (SC-001)

## Phase 4: User Story 2 — Spend is estimated, not guessed (P2)

- [ ] **T009** [US2] Estimated spend per endpoint from the configured price table.
- [ ] **T010** [US2] With prices unset, report counts and mark spend explicitly unavailable — never a fabricated number. (FR-005)
- [ ] **T011** [US2] Label the figure an estimate wherever it appears; Google's billing includes free tiers this cannot model.

## Phase 5: User Story 3 — Reachable without SSH (P3)

- [ ] **T012** [US3] Bind to localhost by default; expose via `deploy/randoeats.caddy` only as a deliberate opt-in.
- [ ] **T013** [US3] **Write an ADR** if the endpoint is exposed publicly. (Plan, Constitution Check V)

## Phase 6: Polish

- [ ] **T014** Audit every response field against ADR-0004: no coordinates, place ids, client addresses or request parameters. Aggregate counts only. Verify by reading the response, not by trusting the code. (FR-004, SC-005)
- [ ] **T015** Confirm the endpoint answers in under 50ms with full history present. (SC-002)
- [ ] **T016** Feed the observed numbers back into 003's cap and the TTL values.

## Definition of Done

Hit rate and call counts are readable over HTTP and agree with the access log,
spend is estimated or honestly absent, nothing user-identifying is exposed, and
003 has real data to set a cap from.
