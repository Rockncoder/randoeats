# Widget Key Convention & Map

Reference for every keyed widget in the app and the naming convention they follow.
Keys drive widget tests (`find.byKey`) and marionette automation, so keep them
stable and consistent.

## Convention

```
ValueKey<String>('<screenPrefix><SemanticName><TypeSuffix><N>')   // camelCase
```

- **screenPrefix** — from the screen widget class name, drop the `Screen`/`Page`
  suffix, camelCase. Exception: the detail screen uses `restaurantDetail`
  (class is `DetailScreen`).
- **SemanticName** — the widget's purpose (e.g. `Navigate`, `Hours`, `SaveSpot`).
- **TypeSuffix** — by widget type:

  | Widget type | Suffix |
  |---|---|
  | Button / IconButton / FloatingActionButton | `Btn` |
  | GestureDetector / InkWell (incl. tappable chips) | `Tap` |
  | TextField / TextFormField | `Input` |
  | DropdownButton / PopupMenuButton | `Menu` |
  | Switch / Checkbox / Radio | `Toggle` |
  | PageView / Swiper | `Carousel` |
  | RefreshIndicator | `Refresh` |
  | Text showing data (name, hours, distance, cuisine) | `Text` |
  | Image / CachedNetworkImage | `Img` |
  | ListView / GridView | `List` |
  | Card | `Card` |
  | GoogleMap | `Map` |
  | BottomSheet | `Sheet` |

- **N** — starts at 1; increments only for repeats of the same
  screen + SemanticName + TypeSuffix (e.g. two photos → `Photo1`, `Photo2`).

**Loop items:** when list items are a named widget class (`_FacetChip`,
`RestaurantCard`, `_ScopeChip`, …) the key keeps the item's dynamic identity as
an interpolated suffix (e.g. `resultsReelCell_${placeId}_$index`) so specific
items stay targetable. Otherwise the `ListView`/`GridView` itself is keyed
(`...List1`) and individual items are not.

**Do NOT key:** layout widgets (Column, Row, Stack, Padding, SizedBox,
Container), decorative widgets, or children already inside a keyed parent
list/carousel.

## Key map

### splash (`SplashScreen`)

| Widget | Old key | New key |
|---|---|---|
| Image (animated logo) | — | `splashLogoImg1` |

### home (`HomeScreen`)

| Widget | Old key | New key |
|---|---|---|
| TextField (mood) | — | `homeMoodInput1` |
| ElevatedButton (engage) | — | `homeEngageBtn1` |
| IconButton (clear input) | — | `homeClearBtn1` |
| IconButton (settings) | — | `homeSettingsBtn1` |
| TextButton (retry) | — | `homeRetryBtn1` |
| Text (wordmark) | — | `homeWordmarkText1` |

### about (`AboutScreen`)

| Widget | Old key | New key |
|---|---|---|
| IconButton (back) | `about_back` | `aboutBackBtn1` |
| Text (version) | `about_version` | `aboutVersionText1` |

### settings (`SettingsScreen`)

| Widget | Old key | New key |
|---|---|---|
| GestureDetector (theme swatch, loop) | `theme_swatch_${appTheme.id}` | `settingsThemeSwatch_${appTheme.id}` |
| GestureDetector (distance unit — miles) | — | `settingsUnitMilesTap1` |
| GestureDetector (distance unit — km) | — | `settingsUnitKilometersTap1` |
| Slider (search radius) | — | `settingsSearchRadiusSlider1` |
| Slider (max results) | — | `settingsMaxResultsSlider1` |
| Slider (hide days) | — | `settingsHideDaysSlider1` |
| Switch (open only) | — | `settingsOpenOnlyToggle1` |
| Switch (calm mode) | `setting_calm_mode` | `settingsCalmModeToggle1` |
| GestureDetector (category chip, loop) | — | `settingsCategoryChip_${category.code}` |
| OutlinedButton (clear visit history) | — | `settingsClearVisitHistoryBtn1` |
| OutlinedButton (clear recent picks) | — | `settingsClearRecentPicksBtn1` |
| OutlinedButton (clear all data) | — | `settingsClearAllDataBtn1` |
| TextButton (visit-history dialog cancel/confirm) | — | `settingsClearVisitHistory{Cancel,Confirm}Btn1` |
| TextButton (recent-picks dialog cancel/confirm) | — | `settingsClearRecentPicks{Cancel,Confirm}Btn1` |
| TextButton (all-data dialog cancel/confirm) | — | `settingsClearAllData{Cancel,Confirm}Btn1` |

> `Slider` uses the suffix `Slider` (an extension of the type table below,
> which has no entry for sliders). Settings widgets built by the shared
> helpers (`_buildUnitOption`, `_buildCategoryChip`, `_buildActionButton`) are
> keyed by threading a `Key?` argument through the helper to each call site.

### regionDraw (`RegionDrawScreen`)

| Widget | Old key | New key |
|---|---|---|
| TextField (name) | `region_name_field` | `regionDrawNameInput1` |
| FilledButton (dialog save confirm) | `region_save_confirm` | `regionDrawSaveConfirmBtn1` |
| TextButton (appBar save) | `region_save_button` | `regionDrawSaveBtn1` |
| FloatingActionButton (draw) | `region_draw_fab` | `regionDrawDrawBtn1` |

### results (`ResultsScreen` + FilterChipBar, RegionChipBar, MultiReelSlotMachine)

| Widget | Old key | New key |
|---|---|---|
| RandoEatsButton (spin) | `spin_button` | `resultsSpinBtn1` |
| Container (count readout) | `result_count` | `resultsResultCountText1` |
| IconButton (quick tune) | `quick_tune_button` | `resultsQuickTuneBtn1` |
| IconButton (about) | `about_button` | `resultsAboutBtn1` |
| IconButton (refresh) | — | `resultsRefreshBtn1` |
| IconButton (settings) | — | `resultsSettingsBtn1` |
| TextButton (notice show-all) | `notice_show_all` | `resultsNoticeShowAllBtn1` |
| IconButton (notice dismiss) | `notice_dismiss` | `resultsNoticeDismissBtn1` |
| ElevatedButton (try again) | — | `resultsTryAgainBtn1` |
| Text (error message) | — | `resultsErrorText1` |
| TextField (save-spot name) | `spot_name_field` | `resultsSpotNameInput1` |
| FilledButton (save-spot confirm) | `spot_save_confirm` | `resultsSpotSaveConfirmBtn1` |
| TextButton (save-spot cancel) | — | `resultsSpotSaveCancelBtn1` |
| TextField (rename-area) | — | `resultsRenameAreaInput1` |
| FilledButton (rename-area save) | — | `resultsRenameAreaSaveBtn1` |
| TextButton (rename-area cancel) | — | `resultsRenameAreaCancelBtn1` |
| ChoiceChip (quick-tune price, loop) | `tune_price_$level` | `resultsTunePriceChip_$level` |
| ChoiceChip (quick-tune beer) | — | `resultsTuneBeerChip1` |
| Switch (quick-tune open-only) | — | `resultsTuneOpenOnlyToggle1` |
| _FacetChip (cuisine, loop) | `filter_cuisine_${c.code}` | `resultsCuisineChip_${c.code}` |
| _FacetChip (price, loop) | `filter_price_$level` | `resultsPriceChip_$level` |
| _FacetChip (beer) | `filter_beer` | `resultsFilterBeerTap1` |
| _FacetChip (wine) | `filter_wine` | `resultsFilterWineTap1` |
| _FacetChip (patio) | `filter_patio` | `resultsFilterPatioTap1` |
| _FacetChip (parking) | `filter_parking` | `resultsFilterParkingTap1` |
| _FacetChip (group) | `filter_group` | `resultsFilterGroupTap1` |
| _FacetChip (open) | `filter_open` | `resultsFilterOpenTap1` |
| _FacetChip (rating) | `filter_rating` | `resultsFilterRatingTap1` |
| ActionChip (clear all) | `filter_clear_all` | `resultsClearAllTap1` |
| ActionChip (save spot) | `filter_save_spot` | `resultsSaveSpotTap1` |
| ListView (reel) | `reel_list` | `resultsReelList1` |
| RestaurantCard (reel cell, loop) | `reel_cell_${placeId}_$index` | `resultsReelCell_${placeId}_$index` |
| _ScopeChip (near me) | `region_chip_near_me` | `resultsRegionNearMeTap1` |
| _ScopeChip (region, loop) | `region_chip_${region.id}` | `resultsRegionChip_${region.id}` |
| _ScopeChip (add area) | `region_chip_add` | `resultsRegionAddTap1` |
| ListTile (menu rename) | `region_menu_rename` | `resultsRegionMenuRenameTap1` |
| ListTile (menu delete) | `region_menu_delete` | `resultsRegionMenuDeleteTap1` |

### restaurantDetail (`DetailScreen` + RestaurantDirectionsSheet)

| Widget | Old key | New key |
|---|---|---|
| IconButton (back) | `detail_back` | `restaurantDetailBackBtn1` |
| Text (name) | — | `restaurantDetailNameText1` |
| Text (address) | — | `restaurantDetailAddressText1` |
| Text (description) | `detail_description` | `restaurantDetailDescriptionText1` |
| Container (rating chip) | — | `restaurantDetailRatingText1` |
| Container (price chip) | — | `restaurantDetailPriceText1` |
| Container (open-status chip) | — | `restaurantDetailOpenStatusText1` |
| _AtmosphereChip (parking) | — | `restaurantDetailParkingText1` |
| _AtmosphereChip (beer) | — | `restaurantDetailBeerText1` |
| _AtmosphereChip (wine) | — | `restaurantDetailWineText1` |
| Container (category chip, loop) | — | `restaurantDetailCategoryText${index+1}` |
| InkWell (phone/call) | `detail_call` | `restaurantDetailCallTap1` |
| InkWell (hours) | `detail_hours` | `restaurantDetailHoursText1` |
| FilledButton (navigate) | `detail_navigate` | `restaurantDetailNavigateBtn1` |
| FilledButton (rate, loop) | `detail_rate_${ratingType.name}` | `restaurantDetailRate${ratingType.name}Btn1` |
| PageView (photo carousel) | `detail_photo_carousel` | `restaurantDetailPhotoCarousel1` |
| Image (photo, loop) | — | `restaurantDetailPhoto${i+1}` |
| SizedBox (directions sheet root) | — | `restaurantDetailDirectionsSheet1` |
| IconButton (directions close) | `directions_close` | `restaurantDetailCloseBtn1` |
| WebViewWidget (directions map) | — | `restaurantDetailDirectionsMap1` |
| TextButton (open external) | `directions_open_external` | `restaurantDetailOpenExternalBtn1` |

## Decisions & deviations

1. **`restaurantDetail` prefix** — the class is `DetailScreen` (mechanical rule
   would give `detail`), but the agreed examples use `restaurantDetail`.
2. **`restaurantDetailHoursText1`** sits on an `InkWell` (type table → `Tap`),
   kept as `Text` to match the given example.
3. **Rating buttons** resolve to `restaurantDetailRatethumbsUpBtn1` /
   `restaurantDetailRatethumbsDownBtn1` (lowercase `thumbs` from the interpolated
   `ratingType.name`); dynamic identity kept so each stays targetable.
4. **`detail_abort`** — no such widget (the back arrow replaced the abort
   button); the corresponding test is a `findsNothing` assertion.

## Known gaps (follow-up)

- **Quick-tune `Slider`** (results quick-tune sheet) — not yet keyed.
- **`restaurant_map_sheet.dart`** (`restaurant_map_close`) — orphaned (the
  directions sheet replaced it), left on its old key; out of screen scope.

_(The settings helper-method coverage gap was resolved — see the settings
table above.)_
