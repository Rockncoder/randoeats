# Claude Code Prompt: Reduce Restaurant Card Size

## Context

RandoEats currently displays only 3 restaurant cards on screen, which feels too few. We need to reduce card sizes and spacing to fit 4-5 cards comfortably.

## Files to Modify

1. `lib/features/restaurant_list/presentation/widgets/restaurant_card.dart`
2. `lib/features/restaurant_list/presentation/pages/restaurant_list_page.dart`

## Changes Required

### 1. Restaurant Card Widget (`restaurant_card.dart`)

**Reduce internal padding:**
- Card content padding: 16px → 12px

**Reduce image/photo container:**
- Image container height: ~80px → ~60px
- Image container width: proportionally smaller

**Reduce typography:**
- Restaurant name font size: reduce by 2pt (e.g., 18 → 16)
- Keep other text sizes readable but review for any that can shrink slightly

**Reduce card margins:**
- Any external margins on the card itself should be minimal

### 2. Restaurant List Page (`restaurant_list_page.dart`)

**Reduce ListView padding:**
- Top padding: reduce to 8px
- Bottom padding: reduce to 8px (or enough to clear the Rand-o-Eats button)
- Keep horizontal padding at 16px

**Reduce spacing between cards:**
- Gap/SizedBox between cards: reduce to 8px
- If using `ListView.separated`, set separator height to 8px
- If using `ListView.builder` with manual spacing, reduce SizedBox height

### 3. General Guidelines

- Maintain the Googie aesthetic and visual hierarchy
- Ensure touch targets remain accessible (cards should still be easy to tap)
- Test that 4-5 cards are visible on a standard phone screen
- Keep the gradient fade at the bottom working correctly with the new spacing

## Quality Gates

After making changes:
```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

All tests must pass with zero warnings.

## Visual Target

Before: 3 cards visible on screen
After: 4-5 cards visible on screen

The cards should feel more compact but still readable and tappable.
