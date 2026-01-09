# Claude Code Prompt: Reduce Excess Space on Restaurant List Screen

## Problem

The restaurant list screen has too much wasted vertical space:

1. **Top area**: Large gap between the header (refresh/settings icons) and the first restaurant card
2. **Bottom area**: Excessive gradient fade area between the last card and the Rand-o-Eats button

This wastes screen real estate and limits how many restaurant cards are visible.

## Files to Modify

- `lib/features/restaurant_list/presentation/pages/restaurant_list_page.dart`

## Changes Required

### 1. Reduce Top Padding

Find the ListView or Column containing the restaurant cards and reduce the top padding:

```dart
// BEFORE: Something like EdgeInsets.only(top: 24) or padding at top of ~20-30px
// AFTER: EdgeInsets.only(top: 8) or minimal top padding

// Also check for any SizedBox or spacing widgets above the ListView
```

### 2. Reduce Bottom Gradient/Button Area

The gradient fade and button area at the bottom is taking too much space:

```dart
// BEFORE: Gradient container height might be ~200px or more
// AFTER: Reduce to ~140-150px - just enough for the button and a subtle fade

// BEFORE: Bottom padding below button might be excessive
// AFTER: Reduce bottom safe area padding, keep just enough for gesture bar
```

### 3. Adjust ListView Bottom Padding

The ListView needs bottom padding so the last card scrolls above the button, but it may be too much:

```dart
// BEFORE: ListView bottom padding might be ~200px+ to clear button area
// AFTER: Reduce to match the new smaller button area height (~140-150px)
```

### 4. Check for Unnecessary Spacing Widgets

Look for any `SizedBox` or `Padding` widgets that add vertical space:
- Between the app bar/header and the list
- Above or below the gradient overlay
- Around the Rand-o-Eats button

## Target Layout

```
┌─────────────────────────────────┐
│  ↻                          ⚙  │  ← Header row (compact)
├─────────────────────────────────┤
│  [Card 1]                       │  ← Cards start immediately
│  [Card 2]                       │
│  [Card 3]                       │
│  [Card 4]                       │
│  [Card 5]                       │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ← Short gradient fade
│       [RAND-O-EATS BUTTON]      │  ← Button with minimal padding
└─────────────────────────────────┘
```

## Quality Gates

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

## Visual Target

- Header to first card: ~8px gap
- Gradient fade height: ~100px (just enough for visual effect)
- Button bottom padding: just safe area inset + 8px
- Result: 4-5 full cards visible without scrolling
