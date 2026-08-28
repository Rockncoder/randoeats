# Feature Specification: Cost caps on Google Places spend

**Feature Branch**: `003-bff-cost-caps`
**Created**: 2026-08-28
**Status**: Draft
**Input**: Nothing bounds Google Places spend. A grep for quota, budget, rate-limit or throttle across `bff/` returns nothing. The cache reduces calls opportunistically but sets no ceiling: a cold cache under load, a crawler, or a client retry loop hits Google as hard as traffic demands, and the first signal would be the bill.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Spend has a ceiling (Priority: P1)

As the operator, I want a hard daily ceiling on upstream Google calls, so that
no traffic pattern — legitimate, buggy or hostile — can produce an unbounded
bill while I am not watching.

**Why this priority**: This is the only gap in the BFF with money directly
attached, and the app is a hobby-scale project on a shared host where a runaway
bill matters more than a brief loss of freshness.

**Acceptance Scenarios**:

1. **Given** a daily cap of N upstream calls, **When** the Nth call has been
   made, **Then** further MISSes do not call Google.
2. **Given** the cap is reached, **When** a request arrives that can be served
   from cache, **Then** it is still served normally — the cap MUST throttle
   upstream calls, never cached reads.
3. **Given** the cap is reached and nothing is cached for the request, **When**
   it arrives, **Then** the client receives a clear, documented degraded
   response rather than a generic failure.
4. **Given** the cap was reached yesterday, **When** the counting window rolls
   over, **Then** upstream calls resume automatically with no intervention.

### User Story 2 - One client cannot exhaust the budget (Priority: P2)

As the operator, I want per-client rate limiting, so that a single misbehaving
app instance or scraper cannot consume the whole day's budget in minutes.

**Acceptance Scenarios**:

1. **Given** a per-client limit, **When** one client exceeds it, **Then** that
   client is limited while others are unaffected.
2. **Given** a limited client, **When** it backs off and returns later, **Then**
   it is served normally.
3. **Given** normal app usage — a person picking somewhere to eat — **When**
   they use the app, **Then** they never encounter the limit. The limit must be
   set from observed usage, not guessed.

### User Story 3 - Approaching the cap is visible (Priority: P3)

As the operator, I want to see consumption against the cap, so that I can raise
it deliberately rather than discovering it by outage.

**Acceptance Scenarios**:

1. **Given** the BFF is running, **When** I query its status, **Then** I can see
   upstream calls used, the cap, and time until the window resets.
2. **Given** consumption crosses a warning threshold, **When** it happens,
   **Then** it is recorded distinctly enough to alert on.

### Edge Cases

- Only MISSes cost money. HITs MUST NOT count against the cap.
- The counter must survive a restart, or a crash loop silently resets the
  budget — this makes the feature depend on 002, or on its own durable counter.
- Client identity behind Caddy is the forwarded address, not the socket peer;
  getting this wrong limits everyone as one client or nobody at all.
- Photo requests proxy upstream too and MUST be counted.
- A cap that hard-fails the app is worse than a slightly stale answer: prefer
  serving expired-but-present cache over refusing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Upstream calls MUST be counted per rolling window, configurable,
  and the count MUST be checked before any upstream call.
- **FR-002**: Cache HITs MUST NOT consume budget.
- **FR-003**: At the cap, behavior MUST follow a documented order: serve fresh
  cache; else serve expired cache if present, marked as stale; else return a
  documented degraded status the client can handle.
- **FR-004**: Per-client rate limiting MUST key on the forwarded client address
  supplied by the reverse proxy, with a configurable limit and window.
- **FR-005**: The cap counter MUST survive process restart.
- **FR-006**: Limits MUST be configurable without a rebuild, and MUST default to
  values that do not change today's behavior for normal usage.
- **FR-007**: All three endpoints — `nearby`, `details`, `photo` — MUST be
  covered.
- **FR-008**: Cap state MUST be observable at runtime.
- **FR-009**: The Dart client MUST handle the degraded response without
  crashing or presenting a raw error. This spec covers the BFF contract; the
  client change is in scope only insofar as the contract must be honored.

### Key Entities

- **Budget window** — calls used, cap, window start, reset time.
- **Client limiter** — per-identity request counts over a short window.
- **Degraded response** — the documented shape returned when the cap is hit
  with nothing cached, distinguishable by the client from a server error.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With the cap set to zero, no request produces an upstream call,
  and cached requests are still served.
- **SC-002**: A synthetic flood from one client is limited without affecting a
  second client.
- **SC-003**: Upstream calls in any window never exceed the configured cap —
  verified by counting test-double invocations, not by inspection.
- **SC-004**: The counter is intact across a restart mid-window.
- **SC-005**: Normal single-user app usage never trips either limit.

## Assumptions

- Depends on 001 for a test harness capable of asserting "Google was not
  called", and is far more robust with 002's durable store backing the counter.
  Building it before 001 would mean shipping money-affecting logic that nothing
  grades.
- The cap's numeric value is an operator decision, not a spec decision. The
  plan must not invent a number and present it as a requirement; it should ship
  a default that preserves current behavior and document how to set a real one
  once 004 supplies usage data.
