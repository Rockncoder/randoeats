# Claude Code Prompt: Slot Machine Restaurant Selection

## Context

You are working on **RandoEats**, a Flutter restaurant discovery app with a retro-futuristic "Googie" design aesthetic (think The Jetsons, 1960s space-age, atomic age diners). The app has a campy, fun personality.

**Tech Stack:**
- Flutter with BLoC/Cubit state management
- VGV CLI project structure
- Hive for local storage
- Follow TekAdept architecture standards (see `TEKADEPT_ARCHITECTURE_SPEC.md`)

**Quality Gates (MUST pass before committing):**
- `flutter analyze --fatal-infos --fatal-warnings` - zero warnings
- `flutter test --coverage` - all tests pass, aim for 90%+ coverage

---

## Feature: Slot Machine Restaurant Selection

### Overview

Implement the primary restaurant discovery screen with a slot machine-style random selection animation. This is the core interaction that makes RandoEats fun and memorable.

### Screen Layout

```
┌─────────────────────────────────────┐
│         [Location Header]           │
│         "Near You • Open Now"       │
├─────────────────────────────────────┤
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🍕 Pizza Palace            │   │
│   │  ⭐ 4.5 • 0.3 mi • $$       │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🍔 Burger Barn             │   │
│   │  ⭐ 4.2 • 0.5 mi • $        │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🌮 Taco Town               │   │
│   │  ⭐ 4.7 • 0.4 mi • $$       │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🍜 Noodle Nirvana          │   │
│   │  ⭐ 4.3 • 0.6 mi • $$       │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  🥗 Salad Station           │   │
│   │  ⭐ 4.1 • 0.2 mi • $$       │   │
│   └─────────────────────────────┘   │
│                                     │
│ ~~~ gradient fade ~~~~~~~~~~~~~~~   │
│                                     │
│   ╔═════════════════════════════╗   │
│   ║                             ║   │
│   ║   🎰  RAND-O-EATS!  🎰     ║   │
│   ║                             ║   │
│   ╚═════════════════════════════╝   │
│                                     │
└─────────────────────────────────────┘
```

### Interactions

#### 1. Restaurant List
- Display exactly 5 restaurant cards
- Each card shows: name, cuisine emoji, rating, distance, price level
- Cards are tappable → navigates directly to restaurant detail view
- List scrolls underneath the bottom gradient/button area

#### 2. Rand-o-Eats Button
- Fixed position near bottom of screen (bottom 20%)
- Large touch target (minimum 64px height per TekAdept standards)
- Googie-styled: rounded/pill shape, retro colors, possibly atomic/starburst accents
- On tap → triggers slot machine animation

#### 3. Slot Machine Animation Sequence

**Phase 1: Spin Up (0.3s)**
- List begins scrolling rapidly from bottom to top
- Cards blur slightly during fast motion
- Play a "spinning" sound effect (optional, prepare for it)

**Phase 2: Full Speed (1.5-2s)**
- List cycles through restaurants multiple times
- Maintain consistent high speed
- Cards are a blur, creating anticipation

**Phase 3: Deceleration (1-1.5s)**
- Gradually slow down with easing (cubic-out or similar)
- Cards become distinguishable again
- "Click-click-click" as each card passes (like a wheel of fortune)

**Phase 4: Winner Landing (0.5s)**
- Final card snaps into the top/winner position
- Brief pause for dramatic effect

**Phase 5: Celebration (0.5-1s)**
- Winner card highlights/glows
- Confetti or starburst particle effect around the winning card
- Retro "DING DING DING!" or fanfare visual flash
- Googie-style atomic sparkles or starbursts

**Phase 6: Transition (0.3s)**
- After celebration, auto-navigate to restaurant detail view
- Use a fun transition (zoom into card, or card expands to fill screen)

### Design System: Googie/Retro-Futuristic

**Color Palette:**
```dart
// Primary colors - bold, optimistic, space-age
static const Color atomicOrange = Color(0xFFFF6B35);
static const Color rocketRed = Color(0xFFE63946);
static const Color jetsonsTeal = Color(0xFF2EC4B6);
static const Color spaceAgePurple = Color(0xFF9B5DE5);
static const Color starlightYellow = Color(0xFFFFC300);

// Neutrals
static const Color retroCream = Color(0xFFFFF8E7);
static const Color midCenturyCharcoal = Color(0xFF2D3436);

// Gradients - sunset/sunrise vibes
static const LinearGradient googieGradient = LinearGradient(
  colors: [atomicOrange, rocketRed, spaceAgePurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

**Typography:**
- Headers: Bold, rounded sans-serif (consider Google Fonts: Righteous, Boogaloo, or Fredoka One)
- Body: Clean, readable (Nunito or Quicksand)

**Visual Elements:**
- Rounded corners (generous, 16-24px radius)
- Soft shadows with slight color tint
- Atomic/starburst decorative elements
- Boomerang and kidney shapes as accents
- Slight skeuomorphism (buttons that look pressable)

### File Structure

```
lib/
├── features/
│   └── restaurant_discovery/
│       ├── presentation/
│       │   ├── pages/
│       │   │   └── restaurant_list_page.dart
│       │   ├── widgets/
│       │   │   ├── restaurant_card.dart
│       │   │   ├── rando_eats_button.dart
│       │   │   ├── slot_machine_list.dart
│       │   │   └── winner_celebration.dart
│       │   └── animations/
│       │       ├── slot_machine_controller.dart
│       │       └── confetti_animation.dart
│       ├── cubit/
│       │   ├── restaurant_list_cubit.dart
│       │   └── restaurant_list_state.dart
│       └── domain/
│           └── models/
│               └── restaurant.dart
├── core/
│   └── theme/
│       ├── googie_theme.dart
│       ├── googie_colors.dart
│       └── googie_text_styles.dart
```

### State Management (Cubit)

```dart
// States to handle
enum RestaurantListStatus {
  initial,
  loading,
  loaded,
  spinning,      // Slot machine is animating
  winner,        // Winner selected, showing celebration
  navigating,    // Transitioning to detail view
  error,
}

class RestaurantListState {
  final RestaurantListStatus status;
  final List<Restaurant> restaurants;
  final Restaurant? selectedRestaurant;
  final String? errorMessage;
}
```

### Animation Implementation Notes

1. **Use `AnimationController`** for the slot machine scroll
   - Consider a custom `ScrollPhysics` or manual offset animation
   - The list should appear infinite during spin (loop the 5 items)

2. **Curves:**
   - Spin up: `Curves.easeIn`
   - Deceleration: `Curves.easeOutCubic` or custom curve for "wheel of fortune" feel

3. **Confetti/Celebration:**
   - Consider `confetti` package or custom particle system
   - Keep it performant (limit particle count)
   - Match Googie aesthetic (starbursts, not generic confetti)

4. **Sound Preparation:**
   - Add placeholder methods for sound effects
   - `_playSpinSound()`, `_playTickSound()`, `_playWinnerSound()`
   - Actual audio integration can come later

### Restaurant Model

```dart
class Restaurant {
  final String id;
  final String name;
  final String cuisineEmoji;
  final double rating;
  final double distanceMiles;
  final PriceLevel priceLevel;
  final bool isOpen;
  final String? imageUrl;
  
  // For MVP, we'll use mock data
  // Later: integrate with Google Places API
}

enum PriceLevel {
  budget('\$'),
  moderate('\$\$'),
  upscale('\$\$\$'),
  fineDining('\$\$\$\$');
  
  final String display;
  const PriceLevel(this.display);
}
```

### Mock Data for Development

Create 5+ mock restaurants for testing:

```dart
final mockRestaurants = [
  Restaurant(
    id: '1',
    name: 'Pizza Palace',
    cuisineEmoji: '🍕',
    rating: 4.5,
    distanceMiles: 0.3,
    priceLevel: PriceLevel.moderate,
    isOpen: true,
  ),
  // ... 4 more
];
```

### Testing Requirements

1. **Unit Tests:**
   - `RestaurantListCubit` state transitions
   - Restaurant model serialization
   - Animation timing logic (if extracted to testable class)

2. **Widget Tests:**
   - Restaurant card renders correctly
   - Button tap triggers animation
   - Direct card tap navigates (no animation)

3. **Golden Tests (optional but nice):**
   - Screenshot tests for Googie styling consistency

### Acceptance Criteria

- [ ] Restaurant list displays 5 cards with all required info
- [ ] Cards are tappable and navigate to detail view
- [ ] Rand-o-Eats button is fixed at bottom, large and obvious
- [ ] Slot machine animation plays all phases smoothly
- [ ] Winner celebration is visually delightful and on-brand
- [ ] Auto-navigation to detail view after celebration
- [ ] Gradient fade between list and button area
- [ ] All Googie/retro styling applied consistently
- [ ] Zero analyzer warnings
- [ ] Tests pass with good coverage
- [ ] Smooth 60fps animations on device

### Out of Scope (for this task)

- Google Places API integration (use mock data)
- Actual sound effects (prepare hooks only)
- Location permissions/services
- Restaurant detail page content (just navigate to placeholder)
- Persistent storage of picks

---

## Getting Started

1. Review existing project structure and theme files
2. Create the feature directory structure
3. Implement `Restaurant` model and mock data
4. Build `RestaurantCard` widget with Googie styling
5. Create `RestaurantListPage` with static list
6. Add `RandoEatsButton` with styling
7. Implement `RestaurantListCubit` with states
8. Build slot machine animation controller
9. Add celebration animation
10. Wire up navigation
11. Write tests
12. Run quality gates

**Commit checkpoint before starting, and commit after each major component.**
