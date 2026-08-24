# randoeats — the uniform TekAdept command contract.
#
# Adapted from tekadept-template/stacks/flutter/justfile during the template
# migration. See docs/development-system.adoc in tekadept-template for why each
# tool is chosen, and MIGRATION-NOTES.adoc in this repo for what was changed
# relative to the stock overlay and why.
#
# This project is MIXED (Flutter app + Drogon BFF in bff/). The stock overlay
# is single-stack, so the BFF rings are added here as `bff-*` recipes and
# composed into `check`.
#
# NOTE ON COMMENTS: `just --list` shows the LAST comment line above a recipe
# as its description, so each block below ends with a one-line summary.

BUILD_DIR := "bff/build-just"

default:
    @just --list

# WARNING — this is NOT equivalent to CI. .github/workflows/main.yaml also
# enforces a 60% coverage floor via the very_good_coverage action, and this
# project has no local coverage-gate script to call (unlike shuffle_up, which
# has scripts/coverage.dart). No gate was invented here, because inventing
# tooling is outside the migration's scope. Porting one is a backlog item.
# Until then `just check` passing does not imply CI passing.
#
# Read-only, fail-fast — the single verdict any AI tool or CI relies on.
check: format-check analyze test bff-check

# Auto-fix formatting and lint-fixable issues. Mutates the tree.
format:
    dart fix --apply
    dart format .

# Read-only formatting check.
format-check:
    dart format --output=none --set-exit-if-changed .

# KNOWN RED: `dart run custom_lint` fails on this project — custom_lint is not
# a dependency in pubspec.yaml and the TekAdept layering lint package does not
# exist yet (tekadept-template lists custom_lint rule implementations as out of
# scope). The line is kept because the contract says analyze includes the
# layering check; it is left failing rather than deleted, because a recipe
# quietly weakened to go green corrupts every future agent loop. See
# BACKLOG.adoc. --fatal-warnings matches the gate already used in CI.
#
# Static analysis: analyzer at max strictness, plus the layering lint.
analyze:
    flutter analyze --fatal-infos --fatal-warnings
    dart run custom_lint

# Full automated test suite, with coverage output for inspection.
test:
    flutter test --coverage

# Run a single test file — the fast inner loop for the local agent.
test-one FILE:
    flutter test {{FILE}}

# Nuke all generated/cached state for a clean rebuild.
nuke:
    rm -rf .dart_tool build .flutter-plugins .flutter-plugins-dependencies
    flutter pub get

# ---------------------------------------------------------------------------
# randoeats BFF (bff/) — the second stack in this repo.
#
# KNOWN RED: clang-format and clang-tidy are not installed on the current
# development machine, so bff-format-check and bff-analyze fail with a missing
# binary. `brew install llvm` resolves it. The BFF also has no tests, so there
# is no bff-test ring — that gap is a backlog item, not something to paper over
# with a recipe that trivially succeeds.
#
# Sources live directly under bff/ (main.cc, controllers/, services/) — there
# is no src/ directory, so the stock drogon overlay's paths do not apply.
# ---------------------------------------------------------------------------

# Read-only verdict for the BFF. No test ring: bff/ has no test suite.
bff-check: bff-format-check bff-analyze

# Auto-fix C++ formatting in the BFF. Mutates the tree.
bff-format:
    #!/usr/bin/env bash
    set -euo pipefail
    find bff/controllers bff/services bff/main.cc -type f \
      \( -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 \
      | xargs -0 clang-format -i

# Read-only C++ formatting check.
bff-format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    find bff/controllers bff/services bff/main.cc -type f \
      \( -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 \
      | xargs -0 clang-format --dry-run --Werror

# clang-tidy the BFF against a generated compile_commands.json.
bff-analyze:
    #!/usr/bin/env bash
    set -euo pipefail
    cmake -S bff -B {{BUILD_DIR}} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
    find bff/controllers bff/services bff/main.cc -type f \
      \( -name '*.cc' -o -name '*.cpp' \) -print0 \
      | xargs -0 clang-tidy -p {{BUILD_DIR}}

# Build the BFF binary.
bff-build:
    cmake -S bff -B {{BUILD_DIR}} -DCMAKE_BUILD_TYPE=Debug
    cmake --build {{BUILD_DIR}} -j

# Wipe the BFF build directory.
bff-nuke:
    rm -rf {{BUILD_DIR}}
