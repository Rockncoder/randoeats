#!/usr/bin/env bash
#
# Ratcheting clang-tidy gate for the Drogon BFF.
#
# The BFF carries a backlog of clang-tidy findings that predate its lint
# configuration. Failing the build on all of them would leave `just check`
# permanently red, which makes it useless as a verdict; suppressing them
# wholesale would hide real problems. This gate does neither: it fails only if
# the count goes UP.
#
# Same shape as scripts/coverage.dart --min and scripts/complexity.dart --max:
# the number only ever moves in the improving direction, and lowering it is a
# deliberate commit.
#
# Usage: scripts/tidy-gate.sh --max N [--list]
#
#   --max N   fail if there are more than N distinct findings in bff
#   --list    print every finding, not just the per-check summary
#
# KNOWN LIMITATION: this counts findings. Fixing one and introducing another of
# the same kind nets to zero and passes. The per-check breakdown printed on
# every run is the mitigation — a shifted distribution is visible in the diff
# even when the total is unchanged.

set -euo pipefail

MAX=""
LIST=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max)  MAX="$2"; shift 2 ;;
        --list) LIST=1; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done
if [[ -z "$MAX" ]]; then
    echo "usage: scripts/tidy-gate.sh --max N [--list]" >&2
    exit 2
fi

BUILD_DIR="bff/build-just"

# Homebrew installs LLVM keg-only, so clang-tidy is not on PATH by default.
# Harmless on Linux, where the directory does not exist and CI's own binary is
# already resolvable.
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# CLANG_TIDY lets CI point at a specific binary without rearranging PATH or
# /usr/bin symlinks.
TIDY="${CLANG_TIDY:-clang-tidy}"

if ! command -v "$TIDY" >/dev/null 2>&1; then
    echo "FAIL: $TIDY not found. On macOS: brew install llvm" >&2
    exit 1
fi

# .clang-tidy uses ExcludeHeaderFilterRegex, added in clang-tidy 19. Older
# versions reject the ENTIRE config and then run no checks at all, which
# reports zero findings and reads as clean code. Refuse up front rather than
# rely on the implausibility guard below to catch it.
TIDY_MAJOR="$("$TIDY" --version | grep -oE "version [0-9]+" | head -1 | grep -oE "[0-9]+" || echo 0)"
if (( TIDY_MAJOR < 19 )); then
    echo "FAIL: $TIDY is version $TIDY_MAJOR; this project's .clang-tidy needs 19 or newer."
    echo "      Older versions reject ExcludeHeaderFilterRegex, discard the whole"
    echo "      config, and then report zero findings — which looks like success."
    exit 1
fi

# Homebrew's clang-tidy cannot find the macOS SDK's libc++ headers unaided: it
# fails with "'string' file not found" inside trantor and then analyses only a
# SUBSET of the translation units, which silently understates the count. On
# Linux xcrun is absent and no sysroot is needed.
EXTRA=()
if SDK="$(xcrun --show-sdk-path 2>/dev/null)" && [[ -n "$SDK" ]]; then
    EXTRA=(--extra-arg=-isysroot --extra-arg="$SDK")
fi

cmake -S bff -B "$BUILD_DIR" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DCMAKE_BUILD_TYPE=Debug >/dev/null

RAW="$(mktemp)"
trap 'rm -f "$RAW"' EXIT

# clang-tidy exits non-zero when it reports anything, which is the normal case
# here — the gate decides pass/fail, not clang-tidy's exit code.
find bff/controllers bff/services bff/main.cc -type f \( -name '*.cc' -o -name '*.cpp' \) -print0 \
  | xargs -0 "$TIDY" -p "$BUILD_DIR" "${EXTRA[@]}" > "$RAW" 2>&1 || true

# A header included by several .cpp files reports its findings once per
# translation unit; dedupe so the number reflects distinct problems.
FINDINGS="$(grep -E "^/.*(warning|error):" "$RAW" \
            | grep "/bff/" \
            | sed 's|.*/bff/||' \
            | sort -u || true)"

COUNT=0
[[ -n "$FINDINGS" ]] && COUNT="$(printf '%s\n' "$FINDINGS" | wc -l | tr -d ' ')"

FILES="$(find bff/controllers bff/services bff/main.cc -type f \( -name '*.cc' -o -name '*.cpp' \) | wc -l | tr -d ' ')"
echo "clang-tidy: $("$TIDY" --version | head -1 | sed 's/^ *//')"
echo "analysed $FILES translation unit(s) in bff"

# A ratchet is only as trustworthy as the run behind it. Three ways a run can
# be wrong while still exiting cleanly, each of which would report a LOW count
# and look like progress:

# 1. A compiler error means clang-tidy gave up partway through a translation
#    unit. This is how the missing macOS SDK sysroot went unnoticed: it
#    reported a subset for several passes before anyone checked.
if grep -q "Found compiler error(s)" "$RAW"; then
    echo
    echo "FAIL: clang-tidy hit a compiler error, so the analysis is incomplete."
    grep -B3 "Found compiler error" "$RAW" | head -8
    exit 1
fi

# 2. A bad configuration file means no checks ran at all.
if grep -qiE "Error reading configuration|Unknown check|invalid configuration" "$RAW"; then
    echo
    echo "FAIL: clang-tidy could not read its configuration, so no checks ran."
    grep -iE "Error reading configuration|Unknown check|invalid configuration" "$RAW" | head -4
    exit 1
fi

# 3. Zero findings against a non-zero ratchet. A lint run that suddenly finds
#    NOTHING in code that had dozens of findings is far more likely to be
#    broken — wrong config, no compile_commands.json, an empty file list —
#    than genuinely fixed. Refuse to treat it as an improvement.
if (( COUNT == 0 && MAX > 0 )); then
    echo
    echo "FAIL: 0 findings against a ratchet of $MAX. That is implausible, so"
    echo "      this is being treated as a broken analysis rather than a clean"
    echo "      one. Check that clang-tidy found .clang-tidy, that"
    echo "      $BUILD_DIR/compile_commands.json exists and is current, and"
    echo "      that the source list is not empty."
    echo
    echo "      If the relay genuinely has zero findings, lower the ratchet to"
    echo "      0 in the justfile in the same commit that earned it."
    tail -5 "$RAW" | sed 's/^/      /'
    exit 1
fi

echo
echo "$COUNT distinct finding(s) (ratchet: $MAX)"
if [[ -n "$FINDINGS" ]]; then
    echo
    printf '%s\n' "$FINDINGS" | grep -oE "\[[a-z0-9,.-]+\]$" | sed 's/,-warnings-as-errors//' \
      | sort | uniq -c | sort -rn | sed 's/^/  /' || true
fi

if [[ "$LIST" -eq 1 ]]; then
    echo
    printf '%s\n' "$FINDINGS" | sed 's/^/  /'
fi
echo

if (( COUNT > MAX )); then
    echo "FAIL: $COUNT findings exceeds the ratchet of $MAX."
    echo "      Fix the new finding, or if it is genuinely not actionable,"
    echo "      suppress it at the call site with a NOLINT naming the check"
    echo "      and the reason. Do not raise the ratchet."
    exit 1
fi

if (( COUNT < MAX )); then
    echo "PASS: $COUNT findings, below the ratchet of $MAX."
    echo "      Lower the ratchet to $COUNT in the justfile so the improvement sticks."
    exit 0
fi

echo "PASS: $COUNT findings matches the ratchet of $MAX."
