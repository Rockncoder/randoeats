# Tasks: BFF test harness and sanitizer build

**Input**: [spec.md](./spec.md), [plan.md](./plan.md)
**Format**: `[ID] [P?] [Story] Description` — `[P]` = parallelizable (different files, no dependency)

## Phase 1: Setup

- [x] **T001** Add `add_library(randoeats_bff_lib STATIC ...)` to `bff/CMakeLists.txt` with the five non-`main` sources; make `randoeats_bff` an executable of `main.cc` linking the library. Verify `just bff-build` still produces a working binary.
- [x] **T002** Add `enable_testing()` and an `option(ENABLE_SANITIZERS "..." OFF)` to `bff/CMakeLists.txt`; when ON, add `-fsanitize=address,undefined -fno-omit-frame-pointer` to the test target only.
- [x] **T003** Create `bff/tests/` and a `randoeats_bff_tests` executable linking `randoeats_bff_lib` and Drogon's test facility; register it with CTest.

## Phase 2: Foundational (blocking prerequisites)

- [x] **T004** Extract `IPlacesUpstream` (`bff/services/IPlacesUpstream.h`) covering the calls `PlacesService` makes on `GooglePlacesClient`. Mirror `ICache.h`'s doc-comment style: state why the interface exists.
- [x] **T005** Make `GooglePlacesClient` implement `IPlacesUpstream`; no behavior change.
- [x] **T006** Change `PlacesService` to hold `std::shared_ptr<IPlacesUpstream>` instead of the concrete client; update `AppContext`/`main.cc` construction.
- [x] **T007** Add an injectable clock to `InMemoryCache` (default: steady clock) so TTL expiry is testable without sleeping. Production behavior must be unchanged.
- [x] **T008** [P] Write `bff/tests/FakePlacesUpstream.h`: canned responses, injectable errors, configurable latency, and a call counter so "Google was not called" is assertable.

## Phase 3: User Story 1 — Cache logic is graded (P1) 🎯 MVP

- [x] **T009** [US1] `PlacesServiceTest.cc`: empty cache → MISS, upstream called exactly once, value stored. (Scenario 1)
- [x] **T010** [US1] Populated cache + identical request → HIT, upstream **not** called, `upstreamMs == 0`. (Scenario 2)
- [x] **T011** [US1] Advance the clock past TTL → MISS, upstream called again. (Scenario 3)
- [x] **T012** [US1] Vary each cache-key input in turn → each is a distinct MISS. Covers the coordinate-formatting edge case. (Scenario 4)
- [x] **T013** [US1] Upstream error → nothing cached, error status propagated. (Scenario 5)
- [x] **T014** [US1] Same five scenarios for the `details` path with `details_ttl_seconds`.
- [x] **T015** [P] [US1] `InMemoryCacheTest.cc`: get/set/clear, expiry via the injected clock, eviction at `cache_max_entries`. (FR-004)

## Phase 4: User Story 2 — Memory errors are caught (P2)

- [x] **T016** [US2] `just bff-test-asan` recipe: configure with `-DENABLE_SANITIZERS=ON`, build, run; fail on any diagnostic.
- [x] **T017** [US2] Verify the sanitizer actually fires: temporarily introduce UB, confirm non-zero exit naming the fault, then revert. Record the result in the PR — an unverified sanitizer is indistinguishable from one that is silently disabled.

## Phase 5: User Story 3 — The harness enforces it (P3)

- [x] **T018** [US3] `just bff-test` recipe: configure, build, run via CTest.
- [x] **T019** [US3] Add `bff-test` to `bff-check` so `just check` covers it.
- [x] **T020** [US3] Verify `just check` fails when a BFF test fails — break one deliberately, confirm, revert. (SC-005)
- [x] **T021** [US3] Install Drogon in `.github/workflows/main.yaml` so the C++ ring can run in CI. Today it fails with "Could not find a package configuration file provided by Drogon", which would make this feature's verdict unavailable exactly where it matters most.

## Phase 6: Polish

- [x] **T022** Confirm `scripts/tidy-gate.sh --max 112` still passes. Do **not** raise the ratchet; if test sources trip findings, fix them or exclude test paths deliberately and document why. (FR-008)
- [x] **T023** Run `just bff-format` and confirm `bff-format-check` is clean.
- [x] **T024** Confirm the suite runs in under 10 seconds. (SC-004)
- [x] **T025** Document in `bff/README.md` how to run tests and the sanitizer build.

## Dependencies & Execution Order

- Phase 1 → Phase 2 → Phase 3. T004-T006 are one refactor and must land together; the build is broken between them.
- T008 is parallel with T004-T007 (new file, no dependency).
- T015 is parallel with T009-T014 (different file, different unit).
- Phases 4 and 5 both depend on Phase 3 existing but are independent of each other.
- T021 can start any time and is required before the feature is truly done.

## Definition of Done

`just check` green (accounting for the two known-red rings in `BACKLOG.adoc`),
every acceptance scenario in spec.md covered by a named test, the sanitizer
verified to actually fire, and the tidy ratchet unchanged.
