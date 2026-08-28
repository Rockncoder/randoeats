# randoeats Constitution

<!--
  DELIBERATELY THIN. This file is not the source of truth for anything.

  This repository is a documented case study in what happens when a second
  document restates decisions the code and the ADRs already own: the previous
  hand-written CLAUDE.md claimed BLoC/Cubit for months while every file used
  Riverpod, and a third file (AGENTS.md) had to be written telling agents not
  to believe it. See docs/legacy-CLAUDE.md and CLAUDE.md's preamble.

  So this constitution POINTS rather than RESTATES. If a principle below feels
  underspecified, follow the link -- do not expand it here. To change a rule,
  change the ADR or docs/conventions.adoc, never this file.
-->

## Core Principles

### I. The ADRs are binding

Accepted ADRs in `docs/adr/` govern. In force today:

- **ADR-0002** — Riverpod for state management and DI. `flutter_bloc` is not a
  dependency; `lib/blocs/` is a legacy directory name.
- **ADR-0003** — the Drogon BFF proxies the Places API. The Google key never
  ships to the client. No direct Google Places call may be added to Dart.
- **ADR-0004** — device-local storage, no accounts, no server-side user data.

A change that contradicts an accepted ADR requires a superseding ADR in the
same change. `/speckit-plan`'s Constitution Check means: name the ADRs the
feature touches, and state compliance or supersession.

### II. Conventions live in docs/conventions.adoc

Layering, naming, testing and command conventions are defined there, not here.
Note that this project deliberately departs from the canonical layering — see
`docs/architecture.adoc` before assuming any structure.

### III. `just check` is the verdict

A feature is done when `just check` is green (`format-check`, `analyze`,
`test`, `bff-check`). Nothing else counts as done, and no recipe may be
weakened to reach green.

Two rings are knowingly red and tracked in `BACKLOG.adoc`: `analyze` (a lint
package that does not exist yet) and `bff-check` on machines without
clang-format/clang-tidy. CI additionally enforces a 60% coverage floor with no
local equivalent, so a green local check does not imply a green CI. Do not
"fix" a known-red ring as a side effect of a feature.

### IV. Tests are not editable to make a change pass

`test/` is read-only during a fix loop. Changing a test to accommodate an
implementation is a deliberate, reviewed act — never a side effect. See
`docs/agent-loop.adoc`.

### V. Specs and ADRs are separate from Spec Kit's specs

`docs/specs/` holds durable, hand-written feature specs. `docs/adr/` holds
decisions. `specs/NNN-*/` holds Spec Kit's per-change working artifacts
(spec + plan + tasks) for one unit of work. A Spec Kit spec is not a
substitute for an ADR when a decision is being made.

## Scope of Spec Kit in this repository

Spec Kit was adopted for **new** work. It does not describe or replace anything
already built. The first features specced under it are the four BFF gaps found
during the 2026-08-28 history reconstruction (`docs/feature-inventory.adoc`).

## Governance

This file may be amended only to point at new sources of truth, or to correct a
pointer that has gone stale. Adding a principle that restates a rule already
owned by an ADR, `docs/conventions.adoc`, or the `justfile` is a defect, not an
improvement.

`CLAUDE.md` is generated and must never be hand-edited; change
`docs/conventions.adoc` or write an ADR and regenerate.

**Version**: 1.0.0 | **Ratified**: 2026-08-28 | **Last Amended**: 2026-08-28
