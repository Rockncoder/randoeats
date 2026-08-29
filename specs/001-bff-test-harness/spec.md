# Feature Specification: BFF test harness and sanitizer build

**Feature Branch**: `001-bff-test-harness`
**Created**: 2026-08-28
**Status**: Draft
**Input**: The Drogon BFF has no tests and no sanitizer build, so the entire C++ side sits outside the harness (`BACKLOG.adoc`). `just bff-check` runs formatting and clang-tidy only — nothing executes the code.

## Why this is first

The other three BFF features (durable cache, cost caps, metrics) all change
behavior that only a test can grade. `docs/agent-loop.adoc` is explicit that an
unambiguous harness verdict is what keeps an agent loop from gaming itself.
Building caps or a Redis cache on top of an ungraded C++ surface would mean
shipping changes whose correctness nothing checks.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cache logic is graded (Priority: P1)

As a maintainer changing `PlacesService`, I want a failing test when I break
cache HIT/MISS or TTL behavior, so that a regression is caught before it
reaches the deployed BFF and starts costing money in extra Google calls.

**Why this priority**: The cache is the only thing standing between the app and
per-request Google Places billing. It is currently unverified by anything.

**Acceptance Scenarios**:

1. **Given** an empty cache, **When** `nearby` is called, **Then** the result is
   a MISS, the upstream client is invoked exactly once, and the response body is
   stored under a key derived from every request input.
2. **Given** a populated cache and an identical request, **When** `nearby` is
   called, **Then** the result is a HIT, the upstream client is **not** invoked,
   and `upstreamMs` is 0.
3. **Given** a cached entry whose TTL has elapsed, **When** the same request is
   made, **Then** the result is a MISS and the upstream client is invoked again.
4. **Given** two requests differing in any single cache-key input, **When** both
   are made, **Then** each is a MISS and produces a distinct cache entry.
5. **Given** an upstream error, **When** `nearby` is called, **Then** nothing is
   written to the cache and the error status is propagated.

### User Story 2 - Memory errors are caught (Priority: P2)

As a maintainer, I want an AddressSanitizer/UndefinedBehaviorSanitizer build of
the test suite, so that use-after-free, buffer overruns and UB in the C++
surface surface as test failures rather than as production crashes.

**Why this priority**: `docs/development-system.adoc` calls the ASan/UBSan test
build the single most valuable feedback signal in a C++ loop. This project has
none of it.

**Acceptance Scenarios**:

1. **Given** the sanitizer build, **When** the test suite runs, **Then** it
   completes with no ASan or UBSan diagnostics and a zero exit code.
2. **Given** deliberately introduced UB, **When** the sanitizer suite runs,
   **Then** it fails with a non-zero exit code naming the fault.

### User Story 3 - The harness enforces it (Priority: P3)

As a maintainer, I want BFF tests to run as part of `just check`, so that "done"
means the same thing on the C++ side as it does on the Dart side.

**Acceptance Scenarios**:

1. **Given** a failing BFF test, **When** `just check` runs, **Then** it exits
   non-zero and names the failing test.
2. **Given** a machine without a C++ toolchain, **When** `just check` runs,
   **Then** the failure is a clear missing-toolchain message, consistent with
   how `bff-format-check` already behaves — not a false green.

### Edge Cases

- The cache is keyed on inputs including coordinates; float formatting must be
  deterministic or keys will differ across platforms for the same request.
- `PlacesService` methods are Drogon coroutines; the harness must be able to
  drive a coroutine to completion synchronously in a test.
- `GooglePlacesClient` performs real network I/O and MUST be replaced by a test
  double. No test may contact Google.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The build MUST expose the BFF's non-`main` sources as a library
  target so tests can link them. `main.cc` MUST NOT be linked into the test
  binary.
- **FR-002**: `GooglePlacesClient` MUST be substitutable in tests. Its call
  surface MUST sit behind an interface owned by the service layer, in the same
  style as the existing `ICache`.
- **FR-003**: A test target MUST cover the acceptance scenarios of User Story 1.
- **FR-004**: `InMemoryCache` MUST have direct tests for get/set/clear, TTL
  expiry, and eviction at `cache_max_entries`.
- **FR-005**: A sanitizer configuration MUST build the same tests with ASan and
  UBSan enabled.
- **FR-006**: `just bff-test` MUST run the suite; `just bff-check` MUST include
  it; `just check` MUST therefore fail when a BFF test fails.
- **FR-007**: No test may perform network I/O or require `config.json` with a
  real Places key.
- **FR-008**: The clang-tidy ratchet (`scripts/tidy-gate.sh --max 112`) MUST NOT
  be raised to accommodate test code. If test sources trip new findings, either
  fix them or exclude test paths from the gate deliberately and say so.

### Key Entities

- **Upstream client interface** — the seam replacing direct
  `GooglePlacesClient` use in `PlacesService`, mirroring `ICache`'s role.
- **Test double** — a scripted upstream returning canned responses, errors and
  latencies, recording call counts so "was Google called?" is assertable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `just bff-test` exits zero on a clean tree and non-zero when any
  cache behavior in User Story 1 is broken.
- **SC-002**: Every branch of the HIT/MISS/TTL/error paths in `PlacesService`
  is exercised by at least one test.
- **SC-003**: The sanitizer build reports zero ASan/UBSan diagnostics.
- **SC-004**: The full suite runs in under 10 seconds locally, so it is cheap
  enough to sit inside `just check` without discouraging use.
- **SC-005**: `just check` fails when a BFF test fails — verified by
  deliberately breaking one.

## Assumptions

- Drogon's bundled test facility (`drogon_test`) is acceptable; if it cannot
  drive coroutines cleanly, a standalone framework may be substituted, recorded
  in the plan.
- CI installs Drogon. **Today it does not** — `bff-analyze` already fails on the
  runner with "Could not find a package configuration file provided by Drogon".
  Making BFF tests part of `just check` will keep CI red until that is fixed;
  that fix is in scope for this feature.
