#!/usr/bin/env bash
#
# Route-registration smoke test, run by CTest against the BUILT EXECUTABLE.
#
# The unit suite cannot catch what this catches. Drogon controllers register
# themselves through static initialisers in their translation unit; when the
# controller sources were built into a STATIC library, the linker dropped the
# object file (main.cc references no symbol from it) and every controller route
# vanished while /api/v1/health -- registered directly in main.cc -- kept
# answering. `just check` was green, the image built, it deployed, and the app
# 404'd in production on 2026-08-29.
#
# The unit tests link the same objects, so registration always works there.
# Only the real binary can prove the routes survived the link.
#
# Usage: smoke_routes.sh <path-to-randoeats_bff>

set -uo pipefail

BIN="${1:?usage: smoke_routes.sh <path-to-randoeats_bff>}"
PORT=$(( 20000 + RANDOM % 20000 ))
TMP="$(mktemp -d)"
trap 'kill "${PID:-0}" 2>/dev/null; rm -rf "$TMP"' EXIT

cat > "$TMP/config.json" <<CFG
{
  "places_api_key": "SMOKE-TEST-NOT-A-REAL-KEY",
  "port": $PORT,
  "threads": 1,
  "cache_max_entries": 10,
  "nearby_ttl_seconds": 60,
  "details_ttl_seconds": 60,
  "metrics_log_path": "$TMP/metrics.jsonl",
  "allowed_origins": ["http://localhost"]
}
CFG

"$BIN" "$TMP/config.json" >"$TMP/server.log" 2>&1 &
PID=$!

for _ in $(seq 1 50); do
    if curl -fsS -m 1 "http://127.0.0.1:$PORT/api/v1/health" >/dev/null 2>&1; then break; fi
    kill -0 "$PID" 2>/dev/null || { echo "FAIL: server exited during startup"; cat "$TMP/server.log"; exit 1; }
    sleep 0.2
done

fail=0

# A registered route must NOT answer 404. It may answer 502 (the fake key makes
# the upstream call fail) -- that is a pass: it proves the request reached our
# controller instead of Drogon's default handler.
check_route() {
    local path="$1" name="$2"
    local code
    code=$(curl -s -o /dev/null -m 20 -w '%{http_code}' "http://127.0.0.1:$PORT$path")
    if [ "$code" = "404" ]; then
        echo "FAIL: $name is not registered ($path returned 404 -- Drogon's default handler)"
        fail=1
    else
        echo "ok: $name registered ($path -> $code)"
    fi
}

# The cache decision must be visible on the wire, not just in the metrics log.
check_cache_header() {
    local path="$1"
    local hdr
    hdr=$(curl -s -o /dev/null -m 20 -D - "http://127.0.0.1:$PORT$path" \
          | tr -d '\r' | grep -i '^x-cache:' | head -1)
    if [ -z "$hdr" ]; then
        echo "FAIL: no X-Cache header on $path"
        fail=1
    else
        echo "ok: cache decision exposed ($hdr)"
    fi
}

check_route "/api/v1/health" "health"
check_route "/api/v1/restaurants/nearby?lat=33.7&lng=-117.8&radius=1000&max_results=1" "nearby"
check_route "/api/v1/restaurants/smoke-test-place-id" "details"
check_cache_header "/api/v1/restaurants/nearby?lat=33.7&lng=-117.8&radius=1000&max_results=1"

exit "$fail"
