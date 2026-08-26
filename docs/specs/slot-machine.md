# Spec: Responsive multi-reel slot machine + wide-screen hardening

**Status:** Proposed
**Depends on:** merged map-region feature; complements `docs/SPOTS_SPEC.md`
**Branch (when built):** `feature/multi-reel-slot-machine` (off `main`)

---

## Context & goals

Today the pick UX is a **single vertical slot-machine reel** (`lib/widgets/slot_machine_list.dart`)
that spins and lands on one random winner. On an iPad it shows one column of wide cards and
wastes horizontal space.

Evolve it into a **responsive multi-reel slot machine**: 1 reel on a phone, **2 reels in
iPad portrait, 3 in landscape**. All reels spin and **stop one-by-one (left → right)**, then a
**single winning cell** is made unmistakably clear — **highlight → expand → Detail**. Keeps the
playful, on-brand "slot machine" metaphor (rand-o-eats is literally a slot machine) while using
the screen.

### Decisions (confirmed with user)
- **One clear winner.** When scrolling stops, the winning cell is **highlighted**, then
  **expands**, then opens Detail. Clarity of "who won" is the top priority.
- **Duplicates are OK.** If Places returns fewer restaurants than there are cells, cells may
  repeat restaurants to fill the grid. No dedupe needed.
- **Phone unchanged.** A phone is just the 1-reel case → current feel preserved, no regression.

### Defaults (unless changed)
- ~5 rows visible per reel on iPad.
- A **Calm Mode** toggle (reduced motion): skip the spin, reveal the grid + winner directly —
  good for accessibility and for users who don't want the animation.

---

## 1. Responsive layout — measured, not device-based (no blank space)
**Hard requirement: never leave blank horizontal space on any device** (big phones, foldables
folded *and* unfolded, tablets, split-screen/multi-window).

- Use **`LayoutBuilder`** to read the **actual width of the list's slot** (the pane, not the
  screen). This is what makes split-screen, floating windows, and foldables Just Work — we fill
  the pane we're given, never assume the full display, and never branch on device model.
- **Reactive:** `LayoutBuilder` re-runs on rotation, **fold/unfold**, window resize, and
  split-screen enter/exit — columns recompute live with no extra code.
- **Columns from a target width; cells flex to fill** so there is no leftover gutter at any
  width:
  ```
  columns   = (availableWidth / kTargetReelWidth).floor()  // kTargetReelWidth ≈ 340, clamp 1..3
  cellWidth = availableWidth / columns                      // cells STRETCH to fill 100%
  ```
  Between thresholds the cards simply grow wider until there's room for one more column — the
  width is always fully used. (`SliverGridDelegateWithMaxCrossAxisExtent` implements this exact
  math and is a candidate for the non-spinning/grid parts.)
- **Do NOT** hardcode device breakpoints (`if (isTablet)`) — width-measured + flex-to-fill is
  what guarantees no wasted space on hardware we've never seen.
- `rows` = enough to fill the measured viewport **height** (~5 on iPad portrait), same idea on
  the vertical axis.

## 2. Reel mechanics
- The grid is a `Row` of **N reels**; each reel is a vertical strip of restaurant cards reusing
  the existing spin curve (`_SlotMachineCurve`) and card widget.
- **Staggered stop:** reel 0 stops first, reel 1 a beat later, reel 2 last (classic cascade).
  Each reel decelerates and lands on a card.
- **Cell content:** partition the ~20 results across `rows × cols` cells; when results <
  cells, **wrap/repeat** to fill (duplicates allowed, per decision).
- Phone (N=1) collapses to the current single-reel behavior.

## 3. Winner reveal — the key sequence
After **all** reels have stopped:
1. **Pick the winner cell:** random `(column, row)`; the restaurant in that cell is the pick.
2. **Highlight:** dim/scrim the other cells, and emphasize the winner (starburst + glow +
   slight scale-up) so it's unmistakable. Reuse the Googie starburst styling.
3. **Expand:** the winner cell grows/heroes out of the grid (scale + position animation) into
   a full-card state.
4. **Open Detail:** transition (ideally a `Hero`) from the expanded cell into `DetailScreen`.

This replaces the current full-screen `WinnerCelebration` overlay with a grid-anchored
highlight→expand (adapt `lib/widgets/winner_celebration.dart`).

**Calm Mode:** skip steps with motion — reveal the settled grid, apply the highlight to the
winner immediately, then expand on a short fade. Same end state, no spin.

## 4. State & flow
- Extend the discovery/slot state to carry: `columns`, `rows`, the per-cell restaurant
  assignment, and the winning `(col, row)`. The existing `DiscoveryStatus`
  (`spinning`/`winner`/`selected`) and `selectWinner(restaurant)` flow stay; the winner cell
  resolves to a `Restaurant` and drives the existing `selectWinner` → Detail path.
- The big **RAND-O-EATS** button still triggers the spin (now multi-reel).
- Tapping any non-winning cell still navigates to that restaurant's Detail (browse).

## 5. Accessibility & the detail width-hardening (folded in)
- **Announce the winner** via `Semantics(liveRegion: true, label: '<name> won')` so screen
  readers state the result (the winner must be clear to *everyone*).
- **Calm Mode** doubles as the reduced-motion path.
- **Fix the open detail bug** here too: `DetailScreen` throws `BoxConstraints forces an
  infinite width` during the iOS accessibility/semantics pass (seen on the iPad simulator →
  blank body). Harden the layout: drop `crossAxisAlignment: stretch` on the scroll `Column`
  and/or remove `Expanded` from the action/rating `Row`s (use width-robust sizing). Reproduce
  with a semantics-on render test at a scrollable size before/after.

## 6. ValueKeys (per project standard — [[valuekey-on-logic-widgets]])
Every interactive element gets a stable key: each reel cell
(`reel_<col>_<row>` or `cell_<placeId>`), the spin button (`results_spin_button`), the winner
(`slot_winner`), Calm Mode toggle (`settings_calm_mode`). This also makes the whole flow
drivable by marionette/Maestro (which we couldn't do for the spin/settings buttons before).

## 7. Testing
- `responsive layout`: column count = f(width) at phone / iPad-portrait / iPad-landscape sizes.
- `cell assignment`: results partitioned across cells; repeats fill when results < cells.
- `winner`: a valid `(col,row)` chosen; resolves to a real `Restaurant`; `selectWinner` fires.
- `reveal`: after stop, winner highlighted then expanded; Calm Mode skips motion, same winner.
- `detail render` (semantics on, scrollable size): no `infinite width` / overflow — extends the
  new `test/screens/detail_screen_render_test.dart`.
- Run gates: analyze, format, full suite; aim ≥85% on new widget/logic code.

## 8. Out of scope / future
- Places pagination to fill very large grids (still ~20 results today; repeats cover the gap).
- Per-reel category theming.

## 9. Rollout order
1. Detail width-hardening + semantics render test (fixes the open bug; small, ship first).
2. Responsive reel layout (`LayoutBuilder` breakpoints) — phone unchanged.
3. Multi-reel spin with staggered stop.
4. Winner highlight → expand → Hero → Detail; Calm Mode.
5. ValueKeys + Semantics live-region; Maestro flow update; quality gates.
