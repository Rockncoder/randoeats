# AGENTS.md — randoeats

Conventions for coding agents (OpenCode's `devforge` agent, or any other)
working in this repo. Verified against the actual codebase, not copied from
`CLAUDE.md` — see the note at the bottom.

## State management: Riverpod

This app uses `flutter_riverpod` (`^3.3.2`). `flutter_bloc` is **not** a
dependency. Each feature lives under `lib/blocs/<feature>/` (legacy directory
name) with three files:

- `<feature>_notifier.dart` — `class FooNotifier extends Notifier<FooState>`
  plus `final fooProvider = NotifierProvider<FooNotifier, FooState>(FooNotifier.new)`
- `<feature>_state.dart` — an `Equatable` state class, typically with a
  `Status` enum (initial/loading/success/failure/...)
- `<feature>.dart` — barrel export of the above two

Reference implementation: `lib/blocs/discovery/`. Other feature: `lib/blocs/iap/`.

## Where tests live

`test/` mirrors `lib/` path-for-path: `lib/blocs/discovery/discovery_notifier.dart`
→ `test/blocs/discovery/discovery_notifier_test.dart`. Same for
`test/screens/`, `test/services/`, `test/models/`, `test/providers/`,
`test/widgets/`, `test/config/`, `test/app/`.

## How to run things

Flutter is pinned via FVM (`.fvmrc` → `3.44.0`); `flutter` on `$PATH` already
resolves to the FVM-pinned binary on this machine (`~/fvm/default` symlink),
so plain `flutter ...` commands are correct here — no `fvm flutter` prefix
needed.

```bash
flutter analyze                          # must be clean before any commit
flutter test path/to/some_test.dart       # run one file while iterating
flutter test                              # full suite
flutter test --coverage                   # CI enforces 60% minimum (see CLAUDE.md)
dart format --set-exit-if-changed .       # formatting gate
```

## Plans

Plan docs live directly in `docs/` (`docs/MVP_PLAN.md`,
`docs/BACKEND_PROXY_PLAN.md`) — there is no `docs/plans/` directory.

## BFF

`bff/` is a real, actively-maintained Drogon C++ backend-for-frontend (see
`CLAUDE.md` for its status and API surface) — build it with CMake from
`bff/`, standard out-of-tree `build/` dir.

---

**Note on `CLAUDE.md`:** this repo's `CLAUDE.md` has a documented history of
drifting from reality. Its "Tech Stack Quick Reference" table currently says
state management is "BLoC/Cubit" — that is stale/wrong as of this writing;
the code is Riverpod throughout (confirmed via `pubspec.yaml` and every file
under `lib/blocs/`). Trust this file and the actual code over `CLAUDE.md`
where they disagree; if you fix `CLAUDE.md`'s claim, update this note too.
