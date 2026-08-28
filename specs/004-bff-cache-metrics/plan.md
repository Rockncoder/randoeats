# Implementation Plan: Cache efficiency and spend reporting

**Branch**: `004-bff-cache-metrics` | **Date**: 2026-08-28 | **Spec**: [spec.md](./spec.md)

## Summary

Aggregate the HIT/MISS classification `ServiceResult` already carries into
per-endpoint, per-window counters; expose them plus an estimated spend as JSON;
give `metrics.jsonl` a retention policy.

## Technical Context

**Depends on**: 001 (tests); shares storage with 003's counter if present
**Already exists**: `MetricsLogger` writing `metrics.jsonl`; `ServiceResult` carrying `"HIT"`/`"MISS"` and `upstreamMs`; Caddy JSON access log with 20mb roll, keep 5, 336h retention
**Missing**: any aggregation, any query surface, any retention on `metrics.jsonl`

## Constitution Check

| Principle | Assessment |
|---|---|
| I. ADRs are binding | **ADR-0004** is the live constraint. A metrics endpoint is the easiest place to accidentally leak user-shaped data — coordinates are a location history. Counters MUST be aggregate only: no coordinates, no place ids, no client addresses, no request parameters. FR-004 states this; the review must verify it rather than trust it. |
| III. `just check` is the verdict | Aggregation logic is pure and must be unit tested via 001's harness. |
| V. Spec Kit specs ≠ ADRs | Adding a public HTTP surface to the BFF is a small architectural change; if the endpoint is exposed publicly through Caddy rather than bound to localhost, that decision deserves an ADR. |

## Project Structure

```
bff/services/
├── MetricsLogger.h/.cc   # MODIFIED: retention/rotation
└── StatsAggregator.h/.cc # NEW: windowed counters, hit rate, estimated spend
bff/controllers/
└── StatsController.h/.cc # NEW: GET /api/v1/stats
bff/config.example.json   # MODIFIED: price table, retention, endpoint exposure
deploy/randoeats.caddy    # MODIFIED only if the endpoint is exposed beyond localhost
```

## Design decisions

1. **Counters in memory, durable snapshot.** Reading an unbounded JSONL per
   query violates SC-002; keep live counters and persist periodically.
2. **Spend is explicitly an estimate.** Report `null` with a reason when prices
   are unconfigured rather than a fabricated figure (spec FR-005) — a wrong
   number here would be trusted and used to set a cap.
3. **Default to localhost-bound.** Least surprising and least risky; exposing it
   publicly is an opt-in with an ADR.

## Complexity Tracking

| Change | Why needed | Simpler alternative rejected because |
|---|---|---|
| In-memory counters + snapshot | Query must be fast with full history present | Scanning `metrics.jsonl` per request fails SC-002 and worsens as the file grows |
| New controller | Operator access without SSH | Parsing JSONL by hand is what this feature exists to replace |
