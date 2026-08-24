# Spec: Spots — one-tap saved places + filters

**Status:** Proposed (follow-up to PR #30, the map-region-selection feature)
**Author:** TekAdept
**Depends on:** the saved-region / region-draw work in `feature/map-region-selection`

---

## Context & goals

PR #30 added **regions** (draw an area on a map, save it, scope discovery to it via
one-tap chips). This spec extends that into **Spots**: a saved favorite that bundles
**where** (the region) **+ what** (filters like beer, patio, rating) **+ a name**, so the
user can recall an entire "I want lunch near the Orange Circle with a patio and a beer"
in a **single tap, with no typing and no chat/LLM**.

Motivating user need: a handful of recurring SoCal spots — *Long Beach 2nd Street*,
*Costa Mesa near Triangle Square*, *Orange near the Circle* — each with a usual vibe.
Save once, recall instantly.

### Design principles (carried over from the project)
- **Minimum taps, no typing.** Filters are tappable chips, never a text box. The existing
  "mood" text input is **replaced** by cuisine chips.
- **No conversation, no LLM.** The Atlas-style natural-language goals decompose into
  filters over an area — expressible as taps. No model, no inference cost.
- **Free except servers.** Reuse the free on-device geocoder for naming; only the existing
  (already-paid) Places API is used, with a cost-controlled field mask (see §5).
- **Friction-free / fun.** Auto-suggested names, remembered last-used Spot, Googie styling.

---

## 1. Concept: a Spot

A **Spot** = a saved bundle of:

| Half | Source | Already built? |
|---|---|---|
| **Where** — a polygon (or "Near Me" GPS) | the region from PR #30 | ✅ |
| **What** — a set of filters | new (this spec) | ❌ |
| **Name** — auto-suggested, editable | the region auto-namer from PR #30 | ✅ (tune in §4) |

The results screen's chip bar becomes **"My Spots"**:

```
[ Near Me ]  [ 2nd Street ]  [ Triangle Square ]  [ The Circle ]  [ + ]
```

- Tap a Spot → restores its **area + filters** and runs the pick. One tap.
- `+` → draw area → set filters → **Save** (name pre-filled). Long-press → rename / delete
  (reuses the existing menu).
- Last-used Spot is remembered (persisted) → a repeat visit is **zero taps**.

This **unifies** "saved regions" and "filter presets" into a single concept. There is no
separate preset list — a Spot *is* the preset, with an area attached.

---

## 2. Data model

### 2a. New: `SpotFilters` (Hive typeId 8)
`lib/models/spot_filters.dart` (+ hand-written `.g.dart`, following the existing adapter
pattern). Immutable, `Equatable`, `copyWith`. All fields default to "no filter" so an empty
`SpotFilters` reproduces today's behavior.

```dart
@HiveType(typeId: 8)
class SpotFilters extends Equatable {
  @HiveField(0) final Set<String> cuisines;     // Places type keywords: {'mexican','hamburger'}
  @HiveField(1) final bool servesBeer;           // atmosphere
  @HiveField(2) final bool outdoorSeating;       // "patio" — atmosphere
  @HiveField(3) final bool goodForGroups;        // "lots of seats" — atmosphere
  @HiveField(4) final bool hasParking;           // atmosphere
  @HiveField(5) final bool openNow;
  @HiveField(6) final double? minRating;         // e.g. 4.0; null = any ("above average")
  @HiveField(7) final Set<int> priceLevels;      // {1,2,3,4}; empty = any
  // bool get isEmpty / int get activeCount  (drives the "save" affordance + chip badges)
  // bool get usesAtmosphere => servesBeer || outdoorSeating || goodForGroups || hasParking;
}
```

### 2b. Evolve: `SavedRegion` → carries filters (it becomes a "Spot")
Add one field. Hive reads a missing field as `null` on old records, so this is
**backward-compatible** — no migration needed for dev data already written by PR #30.

```dart
@HiveField(4) final SpotFilters? filters;   // null ⇒ no filters (area-only spot)
```

Keep the class name `SavedRegion` for now to minimize PR churn (rename to `Spot`
optional, later). UI strings use **"Spot."** `getAllRegions()` etc. stay; add nothing new
to storage beyond registering the `SpotFiltersAdapter`.

### 2c. Extend: `Restaurant` with atmosphere attributes
So client-side filtering (§5) can enforce beer/patio/etc. Add nullable fields + parse them
in `Restaurant.fromPlacesApiNew` (only present when the atmosphere field mask is requested):

```dart
@HiveField(11) final bool? servesBeer;
@HiveField(12) final bool? outdoorSeating;
@HiveField(13) final bool? goodForGroups;
@HiveField(14) final bool? hasParking;   // derived: any true in Places `parkingOptions`
```

---

## 3. State & flow (Riverpod)

- Keep `activeRegionProvider` (the area; `null` = GPS / "Near Me").
- **New** `activeFiltersProvider` (`Notifier<SpotFilters>`) — the *current* filter set,
  independent of whether a Spot is saved. The filter chips toggle this.
- **Selecting a saved Spot** sets *both*: `activeRegionProvider.select(spot)` **and**
  `activeFiltersProvider.set(spot.filters ?? empty)`.
- **Tapping "Near Me"** clears the region; filters persist (user can tweak then save).
- `DiscoveryNotifier._discover()` reads both providers and passes the filters into Places
  (§5). Re-run on change is already wired for region; add the same `ref.listen` for filters
  (debounced ~300ms so rapid multi-toggle = one fetch).

---

## 4. Auto-namer (tuned)

Reuse `_suggestRegionName` from the region-draw screen, but tune field preference and share
it as `lib/services/place_namer.dart` so Spots and regions use one implementation.

**Preference order (free, on-device `geocoding` plugin):**
`subLocality` (neighborhood, e.g. "Old Towne", "Belmont Shore") → nearest `thoroughfare`
(street, e.g. "2nd St") → `locality` (city, e.g. "Costa Mesa") → fallback `"New Spot"`.

**Honest limitation (document in code + UI hint):** the free geocoder returns
neighborhood / street / city — **not** POI/landmark names. So it will suggest
*"Old Towne Orange," "Belmont Shore," "Costa Mesa"* — **not** *"Triangle Square"* or
*"The Circle."* Those are points-of-interest that only a **paid** Places lookup knows. The
user types those once (then saved forever). A future paid "nearest prominent POI" lookup is
out of scope (§9).

---

## 5. Places integration + cost control

Filters split into two tiers. **Apply all filters client-side in `DiscoveryNotifier`** (the
reliable path — `searchNearby` doesn't support most server-side filters), and *additionally*
pass the cheap ones to `searchText` to improve the relevance of the ~20 results Places
returns.

| Filter | Server-side (Text Search only) | Client-side (always) | Field-mask cost |
|---|---|---|---|
| Cuisine | `textQuery` / `includedType` | type/keyword match | cheap |
| Open now | `openNow: true` | `isOpen == true` (already done) | cheap |
| Min rating | `minRating` | `rating >= min` | cheap |
| Price | `priceLevels` | `priceLevel ∈ set` | cheap |
| **Beer** | — | `servesBeer == true` | **Atmosphere SKU** |
| **Patio** | — | `outdoorSeating == true` | **Atmosphere SKU** |
| **Group** | — | `goodForGroups == true` | **Atmosphere SKU** |
| **Parking** | — | `hasParking == true` | **Atmosphere SKU** |

**Cost knob:** the atmosphere fields (`servesBeer`, `outdoorSeating`, `goodForGroups`,
`parkingOptions`) push the request into Google's pricier **"Atmosphere" SKU**. So
`PlacesService` builds the **field mask dynamically**: append atmosphere fields **only when
`filters.usesAtmosphere`**. A search with just cuisine/open/rating/price stays on the cheap
field mask.

`PlacesService.getNearbyRestaurants(... , SpotFilters? filters)` gains a `filters` param;
it (a) builds the field mask, (b) adds `openNow`/`minRating`/`priceLevels`/cuisine to the
Text Search body when present, (c) returns the parsed restaurants. The polygon + atmosphere
+ residual filters are enforced in `DiscoveryNotifier._applyFilters` (extend the existing
stage). Region polygon filtering from PR #30 stays.

---

## 6. UI

### 6a. Filter chip bar — `lib/widgets/filter_chip_bar.dart`
A second horizontally-scrollable chip row under the Spots row on the results screen.
Multi-select toggles, Googie-styled like `RegionChipBar`:

```
🌮 Tacos  🍔 Burgers  🍣 Sushi  ☕ Coffee  🍕 Pizza | 🍺 Beer  ☀️ Patio  🅿️ Parking  👥 Group | 🕐 Open  ⭐ 4.0+  $  $$  $$$
```

- Reads/writes `activeFiltersProvider`. Toggling re-runs discovery (debounced).
- Keep it scannable: cuisine chips first, then vibe toggles, then rating/price. If it gets
  too long, the rating/price group can collapse behind a single "More" chip → small sheet.
  (Start with everything inline; only add the sheet if it feels cluttered.)
- Add stable `ValueKey`/`Semantics` ids per chip (for Maestro + widget tests).

### 6b. Spots row — evolve `RegionChipBar` → `SpotChipBar`
- Same widget, now showing Spots (region + filters). Active highlight reads
  `activeRegionProvider`. `+` opens the draw screen; long-press → rename / delete (built).
- **Save affordance:** when the current area+filters differ from the active Spot (or there's
  no active Spot and at least one filter/region is set), show a **⭐ Save** action (a chip or
  an app-bar button). Tapping it opens the existing name dialog with the **auto-suggested
  name pre-filled**, writes a `SavedRegion` with `filters: activeFilters`, and selects it.
- Renaming/saving reuses the region dialog and auto-namer.

### 6c. Replace the mood text box
Remove the free-text "mood" input from the home/results flow; cuisine chips replace it. The
`PlacesService` keyword path stays (driven by the selected cuisine chips instead of typed
text), so no Places logic is lost.

---

## 7. Discovery changes (`DiscoveryNotifier`)
- `_discover()` reads `activeFiltersProvider` and threads `filters` into
  `getNearbyRestaurants`.
- `_applyFilters(list, settings, filters)` extends the existing open-only/banned stage with:
  cuisine, minRating, priceLevels, and the four atmosphere booleans (treat `null` attribute
  as "unknown" → excluded when that filter is on, since we can't confirm it).
- Empty-after-filter message: *"No spots match those filters here — try removing one."*
- Region polygon filter + visit-count sort from PR #30 unchanged.

---

## 8. Testing (target ≥ 85% on new logic, per project standard)
- `spot_filters_test.dart` — adapter round-trip, `copyWith`, `isEmpty`/`activeCount`,
  `usesAtmosphere`, value equality.
- `saved_region_test.dart` — extend: round-trips with and without `filters`.
- `place_namer_test.dart` — preference order (subLocality → thoroughfare → locality →
  fallback); given fake `Placemark`s.
- `places_service_test.dart` — field mask includes atmosphere fields **iff** `usesAtmosphere`;
  cheap filters added to the Text Search body; mock Dio.
- `discovery_notifier_test.dart` — extend: each filter narrows results; atmosphere `null`
  excluded when filter on; filters + region compose.
- `filter_chip_bar_test.dart` — toggles update `activeFiltersProvider`; active highlight.
- `spot_chip_bar_test.dart` — selecting a Spot sets region **and** filters; Save writes
  `filters`.
- The GoogleMap-hosting draw screen remains the only low-coverage file (platform view).

---

## 9. Migration / compat & out-of-scope
- **Compat:** adding `SpotFilters?` to `SavedRegion` and atmosphere fields to `Restaurant`
  are additive Hive fields → old records read fine (null). Register `SpotFiltersAdapter`
  (typeId 8) in `StorageService.initialize()`.
- **Out of scope (future):** landmark/POI auto-naming via a paid Places lookup
  ("Triangle Square"); multi-cuisine OR queries beyond what Text Search supports cheaply; a
  ranked list view (we keep the slot-machine random pick); cross-device sync of Spots.

---

## 10. Rollout relative to PR #30
Ship **after** PR #30 merges, as its own branch `feature/spots-and-filters`. Order of work:
1. `SpotFilters` model + adapter + tests.
2. `Restaurant` atmosphere fields + parsing + tests.
3. `PlacesService` dynamic field mask + filter params + tests.
4. `DiscoveryNotifier` filter stage + `activeFiltersProvider` + tests.
5. `FilterChipBar` widget + results-screen wiring + tests.
6. Evolve `RegionChipBar` → `SpotChipBar` (filters on save) + shared `place_namer`.
7. Remove the mood text box; cuisine chips drive the keyword path.
8. Quality gates (analyze, format, coverage), Maestro flow updates.

**Net UX:** your SoCal spots become a row of one-tap chips, each remembering the area *and*
the vibe, each with a sensible free name you can override — the entire Atlas conversation,
reduced to a tap.
```
