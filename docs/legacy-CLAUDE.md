# CLAUDE.md - rand-o-eats

## Project Overview

**rand-o-eats** is a Flutter app (iOS, Android, Web) that helps users pick a place to eat with a tongue-in-cheek 60s retro-future vibe.

- **Domain:** randoeats.com
- **Stylized Name:** rand-o-eats (always hyphenated in UI)
- **Vibe:** The Jetsons meets Lost in Space — friendly robot butler helping you find dinner

### Documentation

| Document | Purpose |
|----------|---------|
| `CLAUDE.md` | You are here — Claude Code instructions |
| `docs/SPECIFICATION.md` | Full product specification |
| `docs/MVP_PLAN.md` | Development phases |
| `docs/DESIGN_SYSTEM.md` | Googie design language details |

---

## Tech Stack Quick Reference

| Component | Technology | Notes |
|-----------|------------|-------|
| **Framework** | Flutter 3.44.0 via FVM | iOS, Android, Web from single codebase |
| **State Management** | BLoC/Cubit | TekAdept standard |
| **CLI Tools** | VGV CLI | `very_good create flutter_app` |
| **Local Storage** | Hive | Fast, lightweight, no native dependencies |
| **Maps** | google_maps_flutter | Platform maps integration |
| **Places API** | `dio` → RandoEats BFF | Restaurant discovery — not google_places_flutter, not package:http |
| **Location** | geolocator | Cross-platform location |
| **Flavors** | staging, production | Two flavors only (no development) |

**BFF status:** `bff/` is a real, actively-maintained Drogon C++ backend-for-frontend that proxies the Google Places API — not unwired, not dead. It's built and deployed via CI (`.github/workflows/build-push.yml`, `deploy.yml`) to the shared `tekadept-bff` host as the `randoeats-bff` container, with recent feature commits (#72, #74, #76). `lib/services/places_service.dart`'s `_baseUrl` defaults to `https://api.randoeats.com/api/v1/restaurants` (the BFF, overridable via `--dart-define=RANDOEATS_API_URL=...`), and `Restaurant.fromBff` (`lib/models/restaurant.dart:75`) is the live parser for its `/nearby` response, called from `places_service.dart:127` — it is not dead code.

---

## Quality Gates

**All must pass before ANY commit:**

### 1. Zero Warnings

```bash
flutter analyze --fatal-infos --fatal-warnings
dart format --set-exit-if-changed .
```

### 2. All Tests Pass

```bash
flutter test
```

### 3. Coverage ≥ 60% (CI gate)

```bash
flutter test --coverage
# Check coverage
lcov --list coverage/lcov.info
```

**Note:** CI enforces 60% minimum (`min_coverage: 60` in `.github/workflows/main.yaml`). Raised from 40% on 2026-07-26; actual coverage at the time of the raise was 55.8%, so CI on `main` will fail until coverage catches up — that's intentional, not a bug.

### 4. Complexity (DevForge)

Run this on any directory you've changed this session — not the whole repo — and report what it finds:

```bash
devforge metrics analyze <changed dir> \
  --cyclomatic-complexity=10 \
  --maximum-nesting-level=4 \
  --source-lines-of-code=50 \
  --number-of-parameters=5 \
  --number-of-methods=10
```

Thresholds: cyclomatic complexity ≤ 10, nesting depth ≤ 4, function length ≤ 50 source lines, parameters ≤ 5, methods per class ≤ 10. **Cognitive complexity is not enforced** — the installed `metrics` CLI (check with `devforge metrics analyze --help`) has no `--cognitive-complexity` flag; cyclomatic complexity is the only complexity metric it supports.

The pre-existing repo-wide baseline (33 violations across 22 files, measured 2026-07-24) is tracked separately — do not opportunistically fix violations outside the directories you actually changed.

---

## Core Principles

### Dart Enums with External Values

When enums map to external values (JSON, storage), define mapping once:

```dart
// ✅ CORRECT — single source of truth
enum RatingType {
  thumbsUp('thumbs_up'),
  thumbsDown('thumbs_down');

  final String storageValue;
  const RatingType(this.storageValue);

  static RatingType fromStorage(String value) {
    return RatingType.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => throw ArgumentError('Invalid rating: $value'),
    );
  }

  String toStorage() => storageValue;
}

// ❌ WRONG — duplicate switch statements
```

### Dependency Injection

All services receive dependencies via constructor:

```dart
class RestaurantRepository {
  RestaurantRepository({
    required PlacesService placesService,
    required StorageService storageService,
  });
}
```

### BLoC Pattern

Use Cubit for simple state, BLoC for complex event-driven flows:

```dart
// Cubit for settings
class SettingsCubit extends Cubit<SettingsState> { ... }

// BLoC for restaurant discovery (multiple events, complex flow)
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> { ... }
```

---

## Project Structure

```
randoeats/
├── CLAUDE.md                    # This file
├── docs/
│   ├── SPECIFICATION.md         # Full product spec
│   ├── MVP_PLAN.md              # Development phases
│   └── DESIGN_SYSTEM.md         # Googie design details
├── lib/
│   ├── main_staging.dart
│   ├── main_production.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── config/
│   │   ├── theme.dart           # Googie color palette, typography
│   │   └── constants.dart
│   ├── models/
│   │   ├── restaurant.dart
│   │   ├── user_rating.dart
│   │   ├── recent_pick.dart
│   │   └── user_settings.dart
│   ├── repositories/
│   │   ├── restaurant_repository.dart
│   │   ├── rating_repository.dart
│   │   └── settings_repository.dart
│   ├── services/
│   │   ├── places_service.dart
│   │   ├── location_service.dart
│   │   └── storage_service.dart
│   ├── blocs/
│   │   ├── discovery/
│   │   ├── settings/
│   │   └── rating/
│   ├── screens/
│   │   ├── splash/
│   │   ├── home/
│   │   ├── results/
│   │   ├── detail/
│   │   ├── settings/
│   │   └── favorites/
│   └── widgets/
│       ├── restaurant_card.dart
│       ├── mood_input.dart
│       ├── rating_buttons.dart
│       └── googie/              # Retro UI components
│           ├── retro_button.dart
│           ├── starburst.dart
│           ├── neon_text.dart
│           └── atomic_loader.dart
├── test/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   ├── blocs/
│   └── widgets/
├── integration_test/
└── assets/
    ├── images/
    ├── fonts/
    └── audio/
```

---

## Data Models

```dart
class Restaurant {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final String? priceLevel;
  final List<String> types;
  final String? photoReference;
}

class UserRating {
  final String placeId;
  final RatingType rating;  // thumbsUp or thumbsDown
  final DateTime ratedAt;
}

class RecentPick {
  final String placeId;
  final DateTime pickedAt;
}

class UserSettings {
  final int hideDaysAfterPick;  // default 7, range 1-30
}
```

---

## Core Features

### 1. Location-Based Discovery
- Google Places API for nearby restaurants
- Google Maps for visualization
- Graceful location permission handling

### 2. Mood-Based Filtering
- Natural language input: "I want tacos" or "No fast food"
- Filter results based on types, keywords

### 3. The Pick Flow
- Present exactly **5 choices**
- User selects one → recorded with timestamp
- Hidden from suggestions for configurable days

### 4. Local Ratings (👍 / 👎)
- **Thumbs up** — may appear in favorites
- **Thumbs down** — permanently hidden
- All data stored locally (Hive)

---

## Design Language: Googie / 60s Retro-Future

### Inspiration
The Jetsons, Lost in Space (1960s), vintage World's Fair exhibits

### Color Palette
| Name | Hex | Use |
|------|-----|-----|
| Turquoise | `#40E0D0` | Primary accent |
| Coral | `#FF6F61` | Secondary accent, CTAs |
| Mustard | `#FFDB58` | Highlights |
| Cream | `#FFFDD0` | Backgrounds |
| Chrome | `#C0C0C0` | Borders, subtle accents |

### Typography
- **Display:** Retro/atomic fonts (bowling alley signage vibe)
- **Body:** Rounded sans-serif, friendly feel

### UI Elements
- Rounded corners, bubble shapes
- Toggle switches like spaceship controls
- Starburst decorations, atomic motifs
- "Computer readout" styled text where appropriate

### Animation
- Bouncy, playful transitions
- Spinning atoms, blinking lights
- "Computing" sequences with retro flair

### Tone & Copy
- Tongue-in-cheek, campy, self-aware
- Friendly robot butler vibes
- Example phrases:
  - "Greetings, Earthling! What sustenance do you require?"
  - "Scanning nearby quadrants for edible options..."
  - "Danger! Danger! Decision paralysis detected!"
  - Loading: "Consulting the mainframe..."
  - Errors: "Houston, we have a problem"

**Golden Rule:** Would this feel at home in an episode of The Jetsons?

---

## UX Flow

```
┌─────────────────────────────────────────────────────┐
│  LAUNCH — Animated logo, retro fanfare             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  LOCATION — "Pinpointing your coordinates..."      │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  HOME — "Greetings, Earthling!"                    │
│  "What sustenance do you require?"                 │
│  [ Text input for mood ]                           │
│  [ ENGAGE! ] button                                │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  COMPUTING — "Scanning nearby quadrants..."        │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  RESULTS — 5 Restaurant Cards                      │
│  "Mission options identified!"                     │
│  - Tap card to select                              │
│  - Refresh: "These do not please me"               │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  DETAIL — "Destination locked!"                    │
│  - Name, address, map preview                      │
│  - [ NAVIGATE ] → opens Maps                       │
│  - 👍 / 👎 rating buttons                          │
│  - "Abort mission" → pick another                  │
└─────────────────────────────────────────────────────┘
```

---

## Screen Inventory

| Screen | Purpose |
|--------|---------|
| Splash | Animated logo with retro fanfare |
| Home | Mood input + "ENGAGE!" CTA |
| Results | 5 restaurant cards, refresh option |
| Detail | Full info, map, ratings, navigate |
| Settings | Hide duration, clear history, about |
| Favorites | View thumbs-up places (optional) |

---

## Quick Reference

### Setup

```bash
# Install VGV CLI
dart pub global activate very_good_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

# Create project (if starting fresh)
very_good create flutter_app randoeats --desc "Your atomic-age appetite assistant"

# Install dependencies
flutter pub get
```

### Development Commands

```bash
# Analyze (must pass with zero warnings)
flutter analyze --fatal-infos --fatal-warnings

# Format
dart format .

# Run tests
flutter test

# Run with coverage
flutter test --coverage
lcov --list coverage/lcov.info

# Run app (staging)
flutter run --flavor staging -t lib/main_staging.dart

# Run app (production)
flutter run --flavor production -t lib/main_production.dart
```

### Build Commands

```bash
# Android APK
flutter build apk --flavor production -t lib/main_production.dart

# iOS
flutter build ios --flavor production -t lib/main_production.dart

# Web
flutter build web -t lib/main_production.dart
```

---

## Git Workflow

### Git Commits — No AI Attribution

- **NEVER** include "Claude", "Co-Authored-By: Claude", "AI-generated", or any reference to AI tools in commit messages, PR descriptions, code comments, or any file checked into this repository
- Write commit messages as if a human developer wrote them
- This applies to all TekAdept repositories — the company is being built to sell, and the codebase must not reveal its tooling

### Branch Naming

| Type | Pattern |
|------|---------|
| Feature | `feature/mood-input` |
| Fix | `fix/location-permission` |
| Refactor | `refactor/bloc-structure` |

### Commit Types

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `test` | Adding/updating tests |
| `docs` | Documentation |
| `chore` | Config, tooling |
| `checkpoint` | Before starting new work |

### Workflow

```bash
# 1. Create branch
git checkout -b feature/restaurant-cards

# 2. Checkpoint before work
git add -A && git commit -m "checkpoint: before implementing restaurant cards"

# 3. Write code...

# 4. Verify quality gates
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage

# 5. Commit
git add -A && git commit -m "feat: implement restaurant card widget with Googie styling"

# 6. Push for review
git push origin feature/restaurant-cards
```

---

## API Keys & Security

### Google API Setup

1. Create project in Google Cloud Console
2. Enable Places API, Maps SDK for iOS/Android/JavaScript
3. Create API keys restricted by platform
4. **Never commit API keys to version control**

### Key Storage

```bash
# .env files (git-ignored)
GOOGLE_PLACES_API_KEY=your_key_here
GOOGLE_MAPS_API_KEY=your_key_here
```

Use `flutter_dotenv` or `--dart-define` for key injection.

---

## Development Phases

### Phase 1: Foundation (MVP) — Complete
- [x] Project setup with VGV CLI
- [x] Googie theme configuration (Fredoka + Nunito, full color palette)
- [x] Data models (Restaurant, UserRating, RecentPick, UserSettings, VisitedPlace)
- [x] Hive storage setup (multiple boxes for ratings, picks, settings, visits)
- [x] Location service (geolocator with permission handling)
- [x] Basic home screen

### Phase 2: Core Flow — Complete
- [x] Places API integration (Google Places API v1, text search + nearby search)
- [x] Restaurant discovery BLoC (8 events, full state management)
- [x] Results screen with 5 cards (SlotMachineList widget)
- [x] Restaurant detail screen (address, rating, navigation, photos)
- [x] Rating system (👍/👎 with local Hive storage)

### Phase 3: Polish — Partial
- [x] Recent picks filtering (hidesDaysAfterPick setting)
- [x] Settings screen (comprehensive — distance units, search radius, max results, 24 banned categories, data management)
- [ ] Favorites screen (not implemented)
- [x] Googie animations (WinnerCelebration, slot machine widgets)
- [ ] Sound effects (not implemented)

### Phase 4: Platform Release — Not Started
- [ ] Ads integration (google_mobile_ads dependency exists but no implementation)
- [ ] IAP (no in-app purchase implementation)
- [ ] iOS build & testing
- [ ] Android build & testing
- [ ] Web deployment to randoeats.com
- [ ] App Store / Play Store submission

### Code Stats
- **50 Dart files** in lib/, ~5,350 LOC
- **8 test files**, ~650 LOC
- CI/CD configured (main.yaml, deploy-mobile.yml, distribute.yml)
- Version: 1.0.0+39

---

## When in Doubt

1. **Check documentation** — `docs/SPECIFICATION.md` has details
2. **Keep it simple** — Don't over-engineer
3. **Commit a checkpoint** — Before starting anything risky
4. **Run quality gates** — Before every commit
5. **Ask for clarification** — Better to ask than assume
6. **Channel the vibe** — "Would this feel at home in The Jetsons?"

---

## Allowed Operations

Claude Code has permission to:
- Create, modify, and delete files in this project directory
- Run Flutter/Dart commands
- Install pub packages
- Run tests and analyze code
- Create git commits on feature branches
- Access the internet for package downloads

Claude Code should NOT:
- Commit directly to main branch
- Skip quality gates
- Commit API keys or secrets
- Merge PRs without review
