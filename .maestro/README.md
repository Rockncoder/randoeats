# Maestro integration flows

End-to-end UI flows for rand-o-eats, driven by [Maestro](https://maestro.mobile.dev).
These run against a **debug/staging build on a real device or emulator** — they
are not part of `flutter test`.

## Prerequisites

1. Install Maestro:
   ```bash
   curl -fsSL "https://get.maestro.mobile.dev" | bash
   ```
2. A running Android emulator or iOS simulator (or a connected device).
3. The app installed on that device, built with the API keys wired in:
   ```bash
   flutter run --flavor staging -t lib/main_staging.dart \
     --dart-define=GOOGLE_PLACES_API_KEY=<your_places_key>
   ```
   The Google **Maps** SDK key must also be set in the native config
   (`AndroidManifest.xml`, `AppDelegate.swift`, `web/index.html`) — see the
   `TODO(maps)` markers. Maps and Places keys are separate.

   > `appId` in each flow is `com.tekadept.randoeats` (production). For the
   > staging flavor use `com.tekadept.randoeats.stg`.

## Running

```bash
maestro test .maestro/                 # run every flow
maestro test .maestro/launch_and_spin.yaml   # run one flow
```

## Flows

| Flow | Covers | Automated? |
|------|--------|-----------|
| `launch_and_spin.yaml` | Cold launch → results → spin → winner | ✅ Full |
| `rate_restaurant.yaml` | Spin → detail → thumbs-up → back | ✅ Full |
| `settings_change.yaml` | Open settings → back | ✅ Full |
| `create_region.yaml` | Open draw screen → enter draw mode | ⚠️ Partial |
| `switch_region.yaml` | One-tap scope switching | ⚠️ Needs seeded region |
| `manage_region.yaml` | Long-press → rename/delete | ⚠️ Needs seeded region |

## Known limitation: the freehand lasso

Maestro has no freehand/multi-point gesture, and a single straight `swipe`
collapses to fewer than three vertices, so a polygon can't be formed headlessly.
Therefore:

- `create_region.yaml` verifies the draw screen + draw mode are reachable, but
  the **actual lasso trace, auto-name, and save must be verified manually**.
- `switch_region.yaml` and `manage_region.yaml` assume a region named
  "Orange Circle" already exists. Create one by hand once, then run them with
  `clearState: false`.

The underlying region logic (point-in-polygon, bounding circle, path
simplification, draw-state machine, persistence, discovery filtering) is covered
by fast unit/widget tests under `test/`.
