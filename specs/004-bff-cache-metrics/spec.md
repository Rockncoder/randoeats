# Feature Specification: Cache efficiency and spend reporting

**Feature Branch**: `004-bff-cache-metrics`
**Created**: 2026-08-28
**Status**: Draft
**Input**: `MetricsLogger` writes `metrics.jsonl` and the Caddy vhost logs access specifically so HIT (~1ms) can be split from MISS (~100-300ms), but nothing turns either into a hit rate, a call count, or an estimated spend. Without those numbers, both TTLs and the caps in 003 can only be guessed at.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hit rate is a number I can read (Priority: P1)

As the operator, I want the cache hit rate over a period, so that I can tell
whether the cache is doing its job and whether a TTL change helped or hurt.

**Why this priority**: Every other tuning decision — TTL length, cache size,
cap value — is unanswerable without it.

**Acceptance Scenarios**:

1. **Given** a mix of HITs and MISSes, **When** I ask for the current period's
   stats, **Then** I get total requests, HITs, MISSes and hit rate per endpoint.
2. **Given** the BFF restarts, **When** I ask again, **Then** history from
   before the restart is not silently lost.
3. **Given** no traffic, **When** I ask, **Then** I get a well-formed zero
   result, not an error or a division by zero.

### User Story 2 - Spend is estimated, not guessed (Priority: P2)

As the operator, I want an estimate of Google Places spend derived from actual
upstream calls, so that I can set a cap in 003 from evidence.

**Acceptance Scenarios**:

1. **Given** a configured price per call per endpoint kind, **When** I ask for
   spend, **Then** I get an estimate for the period broken down by endpoint.
2. **Given** prices are not configured, **When** I ask, **Then** I get call
   counts with spend clearly marked unavailable — never a fabricated number.

### User Story 3 - The numbers are reachable without SSH (Priority: P3)

As the operator, I want to read the stats over HTTP, so that checking cache
health does not require logging into the host and parsing JSONL.

**Acceptance Scenarios**:

1. **Given** the BFF is running, **When** I request the stats endpoint, **Then**
   I receive current counters as JSON.
2. **Given** the endpoint exists, **When** an unauthenticated public client
   requests it, **Then** it does not expose the Places key, request contents, or
   anything identifying a user.

### Edge Cases

- `metrics.jsonl` grows without bound; a period query must not require reading
  an unbounded file, and the file needs a retention story.
- Restart-crossing periods must not double count or drop.
- Estimated spend is an estimate — it must be labeled as one, since Google's
  actual billing includes free tiers and SKU nuances this cannot model.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: HIT and MISS MUST be counted per endpoint. The classification
  already exists in `ServiceResult`; this feature aggregates it.
- **FR-002**: Counters MUST be queryable for a period without reading the entire
  historical log.
- **FR-003**: A stats endpoint MUST return counts, hit rate, and estimated
  spend as JSON.
- **FR-004**: The endpoint MUST NOT expose the Places key, raw request
  parameters, coordinates, or anything user-identifying — consistent with
  ADR-0004.
- **FR-005**: Per-call prices MUST be configuration, never hardcoded, and spend
  MUST be reported as unavailable when unset.
- **FR-006**: `metrics.jsonl` MUST have a documented retention or rotation
  policy, mirroring the Caddy log's existing roll settings.
- **FR-007**: Counters MUST survive restart to the same degree as 003's budget
  counter, and SHOULD share its storage rather than adding a second mechanism.

### Key Entities

- **Period counters** — per endpoint, per window: requests, HITs, MISSes,
  upstream milliseconds.
- **Price table** — configured cost per upstream call per endpoint kind.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Hit rate reported by the endpoint matches hit rate computed
  independently from the Caddy access log for the same window, within 1%.
- **SC-002**: The endpoint answers in under 50ms with a full history present.
- **SC-003**: A reviewer can determine, from the endpoint alone, whether a TTL
  change improved hit rate.
- **SC-004**: Estimated spend for a period is within a documented tolerance of
  the figure Google reports for the same period.
- **SC-005**: No field in the response identifies a user or a location request.

## Assumptions

- Depends on 001 for tests. Sequenced last because 003 is the feature that most
  needs its numbers, but 003 can ship with a conservative default cap before
  this exists.
- This is operator tooling, not a user-facing feature; no Flutter change is in
  scope.
