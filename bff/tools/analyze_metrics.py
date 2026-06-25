#!/usr/bin/env python3
"""Summarize the RandoEats BFF metrics log (JSON Lines).

Computes latency percentiles (p50/p95/p99) and cache hit rates, overall and per
upstream endpoint. Run it before enabling caching (Phase 0 baseline) and after
to measure the real improvement.

Usage:
    python3 analyze_metrics.py /var/log/randoeats/metrics.jsonl
    python3 analyze_metrics.py            # defaults to ./metrics.jsonl

Stdlib only — no third-party dependencies.
"""

import json
import sys
from collections import defaultdict


def percentile(values, pct):
    """Nearest-rank percentile of a list of numbers."""
    if not values:
        return 0
    ordered = sorted(values)
    k = max(0, min(len(ordered) - 1, round((pct / 100) * len(ordered) + 0.5) - 1))
    return ordered[k]


def summarize(label, rows):
    total = [r["total_ms"] for r in rows if "total_ms" in r]
    upstream = [r["upstream_ms"] for r in rows if r.get("upstream_ms")]
    caches = [r.get("cache", "NONE") for r in rows]
    hits = caches.count("HIT")
    cacheable = hits + caches.count("MISS")
    hit_rate = (100 * hits / cacheable) if cacheable else 0.0

    print(f"\n{label}  (n={len(rows)})")
    print(f"  total_ms    p50={percentile(total, 50):>5}  "
          f"p95={percentile(total, 95):>5}  p99={percentile(total, 99):>5}")
    print(f"  upstream_ms p50={percentile(upstream, 50):>5}  "
          f"p95={percentile(upstream, 95):>5}  p99={percentile(upstream, 99):>5}")
    print(f"  cache       HIT={hits}  MISS={caches.count('MISS')}  "
          f"NONE={caches.count('NONE')}  hit_rate={hit_rate:.1f}%")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "metrics.jsonl"
    rows = []
    try:
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if line:
                    rows.append(json.loads(line))
    except FileNotFoundError:
        print(f"No metrics file at {path}", file=sys.stderr)
        return 1

    if not rows:
        print("No metrics records found.")
        return 0

    summarize("ALL", rows)

    by_endpoint = defaultdict(list)
    for r in rows:
        by_endpoint[r.get("upstream_endpoint") or "(none)"].append(r)
    for endpoint in sorted(by_endpoint):
        summarize(f"endpoint: {endpoint}", by_endpoint[endpoint])
    return 0


if __name__ == "__main__":
    sys.exit(main())
