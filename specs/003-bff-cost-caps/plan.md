# Implementation Plan: Cost caps on Google Places spend

**Branch**: `003-bff-cost-caps` | **Date**: 2026-08-28 | **Spec**: [spec.md](./spec.md)

## Summary

Count upstream calls against a configurable rolling window, check the budget
before every upstream call, rate-limit per forwarded client address, and degrade
in a documented order — fresh cache, then stale cache, then an explicit degraded
status — rather than failing or overspending.

## Technical Context

**Depends on**: 001 (to assert "Google was not called"); strongly prefers 002 (durable counter)
**Interception point**: `PlacesService`, immediately before the upstream call — the same place the cache MISS path already sits
**Client identity**: Caddy `reverse_proxy` sets `X-Forwarded-For`; the socket peer is always localhost and is useless as an identity
**Endpoints in scope**: `nearby`, `details`, `photo` — all three reach Google

## Constitution Check

| Principle | Assessment |
|---|---|
| I. ADRs are binding | **ADR-0003** reinforced — this strengthens the BFF's role as the single controlled path to Google. **ADR-0004**: per-client counters MUST be ephemeral, keyed on a coarse identity, and never persisted as a user record. A per-client counter that outlives its window starts to look like server-side user data; keep the window short and the storage transient. |
| III. `just check` is the verdict | Cap logic must be covered by 001's harness; SC-003 requires asserting on test-double call counts, not inspection. |
| V. Spec Kit specs ≠ ADRs | The *degraded response contract* is a client-visible API decision. If the Dart client must learn a new status, that is an interface change worth an ADR or at minimum an entry in the app↔BFF contract `docs/conventions.adoc` already asks for and `BACKLOG.adoc` records as missing. |

## Project Structure

```
bff/services/
├── IBudget.h              # NEW: consume/peek against the window
├── BudgetTracker.h/.cc    # NEW: rolling window, backed by ICache or memory
├── RateLimiter.h/.cc      # NEW: per-client short-window limiter
└── PlacesService.cc       # MODIFIED: budget check before upstream; stale-serve path
bff/controllers/
└── RestaurantController.cc # MODIFIED: forwarded-address extraction; degraded status
bff/config.example.json     # MODIFIED: caps block
```

## Design decisions

1. **Count MISSes only.** HITs are free; charging them would throttle the very
   behavior the cache exists to encourage (spec FR-002).
2. **Stale-serve before refusal.** A slightly old restaurant list is a better
   product than an error (spec FR-003). This requires the cache to distinguish
   "expired but present" from "absent" — which `ICache` currently cannot express,
   since `get` returns `nullopt` for both. **This interface gains a method**, and
   that ripples into 002. Sequencing 002 first is what makes this cheap.
3. **Default cap preserves today's behavior.** Ship effectively unlimited and
   document how to set a real number once 004 provides usage data. The plan must
   not invent a number (spec Assumptions).

## Complexity Tracking

| Change | Why needed | Simpler alternative rejected because |
|---|---|---|
| `ICache` gains expired-value access | Stale-serve is impossible without it | Returning stale from `get` silently would break TTL semantics everywhere else |
| Separate budget and rate limiter | They answer different questions (total spend vs. one abuser) | One combined counter cannot express "this client is limited but the budget is fine" |
