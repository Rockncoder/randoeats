# Claude Code Prompt: Slot Machine Restaurant Selection (v2)

## Context

You are working on **RandoEats**, a Flutter restaurant discovery app with a retro-futuristic "Googie" design aesthetic (think The Jetsons, 1960s space-age, atomic age diners). The app has a campy, fun personality.

**Tech Stack:**
- Flutter with BLoC/Cubit state management
- VGV CLI project structure
- Hive for local storage
- Google Places API integration (already connected)
- Follow TekAdept architecture standards (see `TEKADEPT_ARCHITECTURE_SPEC.md`)

**Quality Gates (MUST pass before committing):**
- `flutter analyze --fatal-infos --fatal-warnings` - zero warnings
- `flutter test --coverage` - all tests pass, aim for 90%+ coverage

---

## Task: Refactor App Entry Point & Implement Slot Machine Selection

### Overview

Remove the current entry/splash screen. The app should open directly to the restaurant list with slot machine selection functionality. Add a settings screen for distance units and category filtering.

---

## Screen 1: Restaurant List (NEW APP ENTRY POINT)

### What to Remove
- Delete the current entry screen ("Greetings, Earthling!" with search box and ENGAGE button)
- Remove "Mission Options" header text
- Remove "Mission options identified!" / "Searching for..." subheader
- Remove back chevron navigation

### Layout

```
┌─────────────────────────────────────┐
│                              ⚙️     │  ← Settings gear (top right only)
│                                     │
│   ┌─────────────────────────────┐   │
│   │  [Photo]                    │   │
│   │  Taqueria El Gordito        │   │
│   │  415 N Grand Ave, Santa Ana │   │
│   │  ⭐ 4.1 (719) • $ • Open    │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  [Photo]                    │   │
│   │  Tacos Los Reyes            │   │
│   │  273 S Tustin St, Orange    │   │
│   │  ⭐ 4.5 (1383) • $ • Open   │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  [Photo]                    │   │
│   │  Taqueria HOY!              │   │
│   │  291 N Tustin St, Orange    │   │
│   │  ⭐ 4.3 (892) • $ • Open    │   │
│   └─────────────────────────────┘   │
│                                     │
│   (2 more restaurants...)           │
│                                     │
│ ~~~ gradient fade to cream ~~~~~~   │
│                                     │
│   ╔═════════════════════════════╗   │
│   ║   [rand-o-eats-no-motto]   ║   │  ← Logo image asset
│   ╚═════════════════════════════╝   │
│                                     │
└─────────────────────────────────────┘
```

### Behavior

**On App Launch:**
1. Fetch user location
2. Query Google Places for nearby open restaurants
3. Exclude any categories the user has banned (from settings)
4. Display exactly 5 restaurants
5. Distance shown in miles (default) or kilometers (per user setting)

**Restaurant Cards:**
- Photo from Google Places
- Restaurant name (coral/salmon color as shown in screenshots)
- Full address
- Rating with star icon + review count in parentheses
- Price level ($ / $$ / $$$ / $$$$)
- "Open" badge (teal/green pill)
- Tappable → navigates directly to restaurant detail view

**Rand-o-Eats Button:**
- Fixed at bottom of screen
- Large touch target (minimum 64px height)
- Coral/salmon background matching existing design
- **Use logo image: `assets/images/rand-o-eats-no-motto.png`** (no text, just the logo)
- List scrolls underneath with gradient fade

**Settings Gear:**
- Top right corner
- Teal color matching existing design
- Taps → navigates to Settings screen

---

## Screen 2: Settings

### Layout

```
┌─────────────────────────────────────┐
│  ←  Settings                        │
├─────────────────────────────────────┤
│                                     │
│  DISTANCE UNITS                     │
│  ┌─────────────────────────────┐    │
│  │  ○ Miles          ● Km      │    │  ← Toggle/segmented control
│  └─────────────────────────────┘    │
│                                     │
│  BANNED CATEGORIES                  │
│  Tap to ban, tap again to enable    │
│                                     │
│  ┌───────────┐ ┌───────────┐        │
│  │  Mexican  │ │  Chinese  │        │  ← Active (not banned)
│  └───────────┘ └───────────┘        │
│  ┌───────────┐ ┌───────────┐        │
│  │ ░░Pizza░░ │ │  Burgers  │        │  ← Banned (grayed/struck)
│  └───────────┘ └───────────┘        │
│  ┌───────────┐ ┌───────────┐        │
│  │   Thai    │ │  Indian   │        │
│  └───────────┘ └───────────┘        │
│  ┌───────────┐ ┌───────────┐        │
│  │  Sushi    │ │  Seafood  │        │
│  └───────────┘ └───────────┘        │
│  ...                                │
│                                     │
└─────────────────────────────────────┘
```

### Distance Units Toggle
- **Miles** (default) or **Kilometers**
- Persisted via Hive local storage
- Affects distance display on restaurant cards

### Banned Categories Section
- **Categories pulled from Google Places API types**
- Displayed as chips/tags in a wrap layout
- **Tap = Ban** → chip becomes grayed out / muted / struck through
- **Tap again = Enable** → chip returns to normal active state
- Banned categories persisted via Hive
- Banned categories excluded from restaurant fetch results

### Google Places Category Types
Use relevant Google Places types for food establishments:
```dart
const restaurantCategories = [
  'mexican_restaurant',
  'chinese_restaurant', 
  'italian_restaurant',
  'japanese_restaurant',
  'thai_restaurant',
  'indian_restaurant',
  'vietnamese_restaurant',
  'korean_restaurant',
  'american_restaurant',
  'pizza_restaurant',
  'burger_restaurant',
  'seafood_restaurant',
  'steak_house',
  'sushi_restaurant',
  'mediterranean_restaurant',
  'greek_restaurant',
  'french_restaurant',
  'barbecue_restaurant',
  'cafe',
  'fast_food_restaurant',
  'fine_dining_restaurant',
  'breakfast_restaurant',
  'brunch_restaurant',
  'sandwich_shop',
  'ice_cream_shop',
  'bakery',
  // ... add others as needed
];
```

Display user-friendly names (e.g., `mexican_restaurant` → "Mexican").

---

## Slot Machine Animation

### Trigger
User taps the Rand-o-Eats button.

### Animation Sequence

**Phase 1: Spin Up (0.3s)**
- List begins scrolling rapidly upward
- Cards blur slightly during acceleration

**Phase 2: Full Speed (1.5-2s)**
- List cycles through restaurants multiple times
- Creates anticipation and excitement
- Loop the 5 restaurants seamlessly

**Phase 3: Deceleration (1-1.5s)**
- Gradually slow down with easing curve
- Cards become distinguishable again
- "Click-click-click" feel as cards pass

**Phase 4: Winner Landing (0.5s)**
- **Winner = the restaurant that lands in the TOP position**
- Final card snaps precisely into the top slot
- Brief pause for dramatic effect

**Phase 5: Celebration (0.5-1s)**
- Winner card highlights/glows
- Confetti, starbursts, or particle effect
- Googie-style atomic sparkles
- Visual "WINNER!" feedback

**Phase 6: Auto-Transition (0.3s)**
- After celebration completes
- Navigate to restaurant detail view
- Use fun transition (card expands or zoom effect)

### Key Point
The **top-most displayed restaurant** when the animation stops is the winner. The top position is the "prize line" like a slot machine reel.

---

## Design System

### Colors (from existing screenshots)

```dart
class RandoEatsColors {
  // Background
  static const Color cream = Color(0xFFFFF8E7);        // Main background
  
  // Primary actions
  static const Color coral = Color(0xFFFF6B6B);        // Buttons, CTAs
  static const Color coralLight = Color(0xFFFF8585);   // Hover/pressed
  
  // Accents
  static const Color teal = Color(0xFF2EC4B6);         // Icons, badges, "Open" pill
  static const Color tealLight = Color(0xFFB8F0EA);    // Logo background circle
  
  // Text
  static const Color charcoal = Color(0xFF2D3436);     // Primary text
  static const Color gray = Color(0xFF636E72);         // Secondary text
  
  // Cards
  static const Color white = Color(0xFFFFFFFF);        // Card background
  
  // Status
  static const Color openGreen = Color(0xFF00B894);    // "Open" text
  
  // Banned/disabled
  static const Color mutedGray = Color(0xFFB2BEC3);    // Banned categories
}
```

### Typography
- **Headers:** Bold, rounded (Nunito Bold or similar)
- **Body:** Clean, readable (Nunito Regular)
- **Restaurant names:** Coral/salmon color
- **Addresses:** Charcoal/dark gray
- **Ratings:** Dark with yellow star icon

### Components
- **Cards:** White background, generous rounded corners (16px), soft shadow
- **Buttons:** Coral background, white text, very rounded (pill shape)
- **Chips:** Rounded rectangles, teal border when active, gray when banned
- **Icons:** Teal color for navigation/settings

---

## File Structure

```
lib/
├── app/
│   └── app.dart                      # Update to remove entry screen route
├── features/
│   ├── restaurant_list/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── restaurant_list_page.dart
│   │   │   ├── widgets/
│   │   │   │   ├── restaurant_card.dart
│   │   │   │   ├── rando_eats_button.dart
│   │   │   │   ├── slot_machine_list.dart
│   │   │   │   └── winner_celebration.dart
│   │   │   └── animations/
│   │   │       └── slot_machine_controller.dart
│   │   ├── cubit/
│   │   │   ├── restaurant_list_cubit.dart
│   │   │   └── restaurant_list_state.dart
│   │   └── data/
│   │       └── restaurant_repository.dart
│   └── settings/
│       ├── presentation/
│       │   ├── pages/
│       │   │   └── settings_page.dart
│       │   └── widgets/
│       │       ├── distance_unit_toggle.dart
│       │       └── category_chip.dart
│       ├── cubit/
│       │   ├── settings_cubit.dart
│       │   └── settings_state.dart
│       └── data/
│           └── settings_repository.dart    # Hive persistence
├── core/
│   ├── theme/
│   │   ├── rando_eats_theme.dart
│   │   ├── rando_eats_colors.dart
│   │   └── rando_eats_text_styles.dart
│   └── services/
│       └── google_places_service.dart      # Existing, may need updates
└── models/
    ├── restaurant.dart
    ├── distance_unit.dart
    └── restaurant_category.dart
```

---

## State Management

### RestaurantListCubit

```dart
enum RestaurantListStatus {
  initial,
  loading,
  loaded,
  spinning,        // Slot machine animating
  winner,          // Winner selected, celebration playing
  navigating,      // Transitioning to detail
  error,
}

class RestaurantListState {
  final RestaurantListStatus status;
  final List<Restaurant> restaurants;
  final Restaurant? winningRestaurant;  // The one at top when spin stops
  final String? errorMessage;
}
```

### SettingsCubit

```dart
class SettingsState {
  final DistanceUnit distanceUnit;          // miles or kilometers
  final Set<String> bannedCategories;       // Google Places type strings
}

enum DistanceUnit {
  miles('mi'),
  kilometers('km');
  
  final String abbreviation;
  const DistanceUnit(this.abbreviation);
}
```

---

## Data Models

### Restaurant

```dart
class Restaurant {
  final String placeId;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final PriceLevel priceLevel;
  final bool isOpen;
  final double distanceMeters;    // Always store in meters
  final String? photoReference;
  final List<String> types;       // Google Places types
  
  String formattedDistance(DistanceUnit unit) {
    switch (unit) {
      case DistanceUnit.miles:
        return '${(distanceMeters / 1609.34).toStringAsFixed(1)} mi';
      case DistanceUnit.kilometers:
        return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}

enum PriceLevel {
  free(''),
  inexpensive('\$'),
  moderate('\$\$'),
  expensive('\$\$\$'),
  veryExpensive('\$\$\$\$');
  
  final String display;
  const PriceLevel(this.display);
}
```

### RestaurantCategory

```dart
class RestaurantCategory {
  final String googlePlacesType;    // e.g., 'mexican_restaurant'
  final String displayName;          // e.g., 'Mexican'
  
  static String toDisplayName(String type) {
    return type
        .replaceAll('_restaurant', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
```

---

## Implementation Checklist

### Phase 1: Remove Entry Screen
- [ ] Delete entry screen files/widgets
- [ ] Update app router to start at restaurant list
- [ ] Remove ENGAGE button and search functionality

### Phase 2: Update Restaurant List Screen
- [ ] Remove header text ("Mission Options", etc.)
- [ ] Remove back chevron
- [ ] Add settings gear icon (top right)
- [ ] Ensure distance displays in miles by default
- [ ] Add Rand-o-Eats button at bottom
- [ ] Add gradient fade above button
- [ ] Wire up navigation to settings

### Phase 3: Implement Settings Screen
- [ ] Create settings page with back navigation
- [ ] Implement distance unit toggle (Miles default / Km)
- [ ] Fetch category list from Google Places types
- [ ] Display categories as tappable chips
- [ ] Implement ban/unban toggle on tap
- [ ] Persist settings to Hive
- [ ] Apply banned categories to restaurant fetch

### Phase 4: Slot Machine Animation
- [ ] Create animation controller
- [ ] Implement spin phases (up, full speed, decelerate, land)
- [ ] Ensure winner lands in TOP position
- [ ] Add celebration effects (confetti/starbursts)
- [ ] Auto-navigate to detail after celebration

### Phase 5: Polish & Testing
- [ ] Write unit tests for cubits
- [ ] Write widget tests for key components
- [ ] Verify 60fps animation performance
- [ ] Run `flutter analyze --fatal-infos --fatal-warnings`
- [ ] Ensure test coverage ≥ 90%

---

## Acceptance Criteria

- [ ] App opens directly to restaurant list (no entry screen)
- [ ] No header text or back navigation on list screen
- [ ] Settings gear visible top right, navigates to settings
- [ ] Distance shown in miles by default
- [ ] Settings allows toggling miles ↔ kilometers
- [ ] Settings shows all restaurant categories as chips
- [ ] Tapping category toggles banned state
- [ ] Banned categories excluded from results
- [ ] Settings persist across app restarts
- [ ] Rand-o-Eats button fixed at bottom with gradient fade
- [ ] Slot machine animation plays smoothly
- [ ] **Winner is the TOP-MOST restaurant when animation stops**
- [ ] Celebration plays after winner lands
- [ ] Auto-navigates to detail view after celebration
- [ ] Tapping card directly goes to detail (no animation)
- [ ] Zero analyzer warnings
- [ ] All tests pass

---

## Out of Scope

- Restaurant detail page redesign (just navigate to existing)
- Sound effects (prepare hooks only)
- Location permission handling changes
- Pull-to-refresh
- Infinite scroll / pagination

---

## Getting Started

1. Commit checkpoint: `git commit -m "checkpoint: before entry screen removal and slot machine implementation"`
2. Remove entry screen and update routing
3. Update restaurant list screen layout
4. Implement settings screen with persistence
5. Build slot machine animation
6. Add celebration effects
7. Write tests
8. Run quality gates
9. Commit: `git commit -m "feat: remove entry screen, add slot machine selection and settings"`
