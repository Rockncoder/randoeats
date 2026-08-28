# Implementation Plan: BFF test harness and sanitizer build

**Branch**: `001-bff-test-harness` | **Date**: 2026-08-28 | **Spec**: [spec.md](./spec.md)

## Summary

Split the BFF's sources into a library target plus a thin `main`, put an
interface in front of `GooglePlacesClient` the way `ICache` already sits in
front of the cache, and add a test binary that drives `PlacesService` with a
scripted upstream. Add a sanitizer build of the same tests, and wire both into
`just`.

## Technical Context

**Language/Version**: C++20 (`CMAKE_CXX_STANDARD 20`, extensions off)
**Framework**: Drogon (brings trantor + jsoncpp, enables coroutines)
**Build**: CMake >= 3.16, out-of-tree; `just bff-build` uses `-DCMAKE_BUILD_TYPE=Debug`
**Testing**: `drogon_test` preferred (already available via the Drogon dependency); a standalone framework only if coroutine driving proves unworkable
**Lint gate**: `scripts/tidy-gate.sh --max 112` — a ratchet, must not be raised
**Target**: shared `tekadept-bff` host, behind Caddy at `api.randoeats.com`

Existing shape:

- `bff/CMakeLists.txt` builds one executable from `main.cc` + 5 sources
- `PlacesService` takes `std::shared_ptr<ICache>` plus TTLs — already injectable
- `PlacesService` takes `GooglePlacesClient` concretely — **not** injectable; this is the seam to open
- `ServiceResult{status, body, "HIT"|"MISS", upstreamMs, ttl}` is already the observable outcome a test asserts on

## Constitution Check

| Principle | Assessment |
|---|---|
| I. ADRs are binding | **ADR-0003** (BFF proxies Places, key never client-side) is *reinforced*: tests must never contact Google or require a real key. No ADR is contradicted, so no superseding ADR is needed. |
| II. Conventions | C++ conventions come from the TekAdept clang-format/clang-tidy config adopted in `4d4f459`. Test sources follow them. |
| III. `just check` is the verdict | This feature *extends* the verdict to the C++ side. It must not weaken any existing recipe, and must not raise the tidy ratchet. |
| IV. Tests not editable to pass | This feature *creates* the tests that principle protects. |
| V. Spec Kit specs ≠ ADRs | No architectural decision is being made here beyond introducing a test seam, which is a structural consequence of testing, not a new direction. |

**Note on CI**: `bff-analyze` already fails on the runner ("Could not find a
package configuration file provided by Drogon"). Adding tests to `just check`
does not create that failure but does deepen it. Installing Drogon in CI is
part of this feature, not a follow-up — otherwise the verdict this feature
exists to provide is unavailable exactly where it matters most.

## Project Structure

### Documentation (this feature)

```
specs/001-bff-test-harness/
├── spec.md
├── plan.md      # this file
└── tasks.md
```

### Source Code (repository root)

```
bff/
├── CMakeLists.txt          # MODIFIED: library target + test target + sanitizer option
├── main.cc                 # unchanged; links the library
├── controllers/
├── services/
│   ├── IPlacesUpstream.h   # NEW: the seam, mirroring ICache
│   ├── GooglePlacesClient.h/.cc  # MODIFIED: implements IPlacesUpstream
│   └── PlacesService.h/.cc # MODIFIED: depends on IPlacesUpstream
└── tests/                  # NEW
    ├── FakePlacesUpstream.h    # scripted double: canned responses, call counts
    ├── PlacesServiceTest.cc    # HIT/MISS/TTL/key-distinctness/error
    └── InMemoryCacheTest.cc    # get/set/clear, expiry, eviction at capacity

justfile                    # MODIFIED: bff-test, bff-test-asan; bff-check gains bff-test
.github/workflows/main.yaml # MODIFIED: install Drogon so the C++ ring can run
```

## Design decisions

1. **Library target, not object reuse.** `add_library(randoeats_bff_lib ...)`
   with `main.cc` left in the executable. Tests link the library. This is the
   smallest change that makes the code testable and does not alter the shipped
   binary's contents.

2. **`IPlacesUpstream` mirrors `ICache`.** The codebase already establishes the
   pattern — an interface owned by the service layer so the service never
   depends on a concrete client. Following it keeps the reviewer's expectations
   intact rather than introducing a second style of seam.

3. **Time is injectable for TTL tests.** Expiry cannot be tested by sleeping for
   an hour. `InMemoryCache` needs a clock source that a test can advance. This
   is the one place the production code changes shape purely for testability,
   and it is justified: without it, FR-004's expiry scenario is untestable.

4. **Sanitizers as a CMake option, not a separate tree.** `-DENABLE_SANITIZERS=ON`
   adding `-fsanitize=address,undefined` to the test target, so the same
   sources are graded twice rather than diverging.

## Complexity Tracking

| Change | Why needed | Simpler alternative rejected because |
|---|---|---|
| Library/executable split | Tests cannot link a binary containing `main` | Compiling sources twice into the test binary duplicates build time and can drift from what ships |
| `IPlacesUpstream` | Tests must assert Google was not called, and must never call it | Conditional compilation or a network stub is less honest and untestable in the shipped path |
| Injectable clock | TTL expiry is otherwise untestable without real waiting | Sleeping makes the suite slow, violating SC-004's 10-second budget |
