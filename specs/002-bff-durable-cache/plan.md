# Implementation Plan: Durable cache for the Places proxy

**Branch**: `002-bff-durable-cache` | **Date**: 2026-08-29 | **Spec**: [spec.md](./spec.md)

## Summary

Add a `PostgresCache` implementing the existing `ICache`, backed by the
PostgreSQL already running on the host, selected by config, falling back to
in-memory whenever the database is unavailable. No change to `PlacesService`.

## Technical Context

**Depends on**: 001 (tests to grade both backends)
**Client**: Drogon's `orm::DbClient` — no new dependency, but requires the ORM to be compiled in
**Database**: PostgreSQL 16, already running on `tekadept-bff-prod` (systemd, not a container), port 5432
**Existing TTLs**: nearby 3600s, details 21600s; `cache_max_entries` currently 2000
**Config**: `bff/config.json` (untracked; `config.example.json` is the tracked template), delivered by `deploy.yml` from the `RANDOEATS_CONFIG_JSON` secret

### Schema

```sql
CREATE UNLOGGED TABLE IF NOT EXISTS places_cache (
  key         text PRIMARY KEY,
  value       text        NOT NULL,
  expires_at  timestamptz NOT NULL,
  last_read   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS places_cache_expires_at ON places_cache (expires_at);
CREATE INDEX IF NOT EXISTS places_cache_last_read  ON places_cache (last_read);
```

`get` is `SELECT value FROM places_cache WHERE key = $1 AND expires_at > now()`
— expiry enforced on read, so a stale row is never served even if the sweep has
not run. `set` is an upsert. The sweep deletes expired rows, then trims to the
row cap by oldest `last_read`.

## Constitution Check

| Principle | Assessment |
|---|---|
| I. ADRs are binding | **ADR-0004** needs an explicit statement, and it holds: cached Places responses are upstream catalogue data keyed by query — not user data, not tied to an identity, and already sent to every client that asks. The cache must not begin storing anything user-identifying. **ADR-0003** unaffected: the API key stays server-side and is never cached. |
| II. Conventions | `PostgresCache` follows the existing `ICache` implementation style. |
| III. `just check` is the verdict | Both backends must pass 001's suite; the smoke test must still pass. |
| V. Spec Kit specs ≠ ADRs | **Write an ADR.** Making randoeats depend on a database server shared with another tenant changes the operational topology and the dependency graph that `deploy/randoeats.caddy` and the platform README describe. That is an architectural decision, not a config change. |

## Project Structure

```
bff/services/
├── ICache.h              # unchanged — the seam already exists
├── PostgresCache.h/.cc   # NEW
├── InMemoryCache.h/.cc   # unchanged (fallback, and the local/test default)
└── CacheFactory.h/.cc    # NEW: config -> ICache, with fallback on failure
bff/config.example.json   # MODIFIED: cache_backend + connection + sweep settings
bff/CMakeLists.txt        # MODIFIED if the ORM needs linking explicitly
.github/workflows/check.yml  # MODIFIED: build Drogon with the ORM enabled
deploy/                   # MODIFIED: database and role provisioning
docs/adr/0006-*.adoc      # NEW: depending on a shared database server
```

## Design decisions

1. **Its own database and role, not a shared one.** Key prefixes are not
   isolation. randoeats gets `randoeats_prod` and a role with rights to nothing
   else, so it cannot read or damage the other tenant's data even if compromised.

2. **`UNLOGGED` table.** This is a cache; skipping WAL avoids write
   amplification on a box shared with another tenant's real data. The cost is
   that a Postgres *crash* truncates it — acceptable, because the case this
   feature exists for is a **BFF redeploy**, which does not touch Postgres at all.

3. **Expiry enforced on read, sweep is only housekeeping.** If expiry depended
   on the sweep, a missed sweep would serve stale data. The sweep exists to
   reclaim space, not to enforce correctness.

4. **Factory, not conditional construction in `main`.** Backend choice stays in
   one testable place and `main.cc` stays thin.

5. **Fallback is silent to callers, loud in logs.** A request must never fail
   because the cache is down (FR-005), but the degradation must be visible.

6. **Do not reach for Drogon's ORM model layer.** One table, three statements —
   `DbClient` with parameterised SQL is simpler than generated models and keeps
   the dependency surface small.

## Complexity Tracking

| Change | Why needed | Simpler alternative rejected because |
|---|---|---|
| Postgres dependency for the BFF | The cache must outlive the process | Redis would mean a second datastore to install, secure, cap and monitor, for a latency difference no user can perceive at this traffic |
| Hand-written TTL + sweep | Postgres has no native key expiry | This is the real cost of not using Redis, and it is ~20 lines of SQL plus a timer |
| `CacheFactory` | Backend choice must be configurable and testable | Branching in `main.cc` is untestable and grows with each backend |
| Separate database + role | Another tenant shares the server | A shared database with prefixed keys is not an isolation boundary |
