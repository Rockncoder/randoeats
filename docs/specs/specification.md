# rand-o-eats Product Specification

**Version:** 1.0
**Last Updated:** January 2026

---

## Overview

**rand-o-eats** is a mobile and web application that helps users decide where to eat using a playful 60s retro-future aesthetic.

- **Domain:** randoeats.com
- **Stylized Name:** rand-o-eats (always hyphenated in UI)
- **Platforms:** iOS, Android, Web (Flutter)

---

## Core Features

### 1. Location-Based Discovery

- Uses Google Places API to find nearby restaurants
- Google Maps for visualization
- Graceful location permission handling
- Configurable search radius

### 2. Mood-Based Filtering

- Natural language input: "I want tacos" or "No fast food"
- Filter results based on types, keywords
- Exclusion patterns (no X, avoid Y)

### 3. The Pick Flow

- Present exactly **5 choices** to the user
- User selects one → recorded with timestamp
- Selected restaurant hidden from suggestions for configurable days (default: 7)
- "These do not please me" refresh option

### 4. Local Ratings

- **Thumbs up (👍)** — May appear in favorites
- **Thumbs down (👎)** — Permanently hidden from suggestions
- All data stored locally (Hive) — no account required

---

## Data Models

### Restaurant

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
```

### UserRating

```dart
class UserRating {
  final String placeId;
  final RatingType rating;  // thumbsUp or thumbsDown
  final DateTime ratedAt;
}
```

### RecentPick

```dart
class RecentPick {
  final String placeId;
  final DateTime pickedAt;
}
```

### UserSettings

```dart
class UserSettings {
  final int hideDaysAfterPick;  // default 7, range 1-30
}
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
| Favorites | View thumbs-up places |

---

## UX Flow

```
LAUNCH → LOCATION → HOME → COMPUTING → RESULTS → DETAIL
                      ↑                    │
                      └────────────────────┘
                         (Abort/Refresh)
```

---

## API Dependencies

| API | Purpose |
|-----|---------|
| Google Places API | Restaurant discovery |
| Google Maps SDK | Map visualization |
| Geolocator | Device location |

---

## Non-Goals (v1)

- User accounts / authentication
- Social features / sharing
- Restaurant reviews / comments
- Reservations / ordering
- Backend server (all local storage)
