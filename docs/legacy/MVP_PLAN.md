# rand-o-eats MVP Development Plan

**Version:** 1.0
**Last Updated:** January 2026

---

## Phase 1: Foundation

### Goals
Establish project structure, theme, and core data layer.

### Tasks

- [x] Project setup with VGV CLI
- [x] Remove development flavor (staging + production only)
- [ ] Googie theme configuration (colors, typography)
- [ ] Data models (Restaurant, UserRating, RecentPick, UserSettings)
- [ ] Hive storage service setup
- [ ] Location service with permission handling
- [ ] Basic home screen shell

### Deliverables
- App launches with themed splash screen
- Location permissions work correctly
- Local storage initialized

---

## Phase 2: Core Flow

### Goals
Implement the main user journey from mood input to restaurant selection.

### Tasks

- [ ] Google Places API service
- [ ] Restaurant repository
- [ ] Discovery BLoC (fetch, filter, present 5)
- [ ] Home screen with mood input
- [ ] Results screen with 5 restaurant cards
- [ ] Restaurant detail screen
- [ ] Rating system (👍/👎) with Hive persistence
- [ ] Recent picks tracking and filtering

### Deliverables
- Complete pick flow works end-to-end
- Ratings persist between sessions
- Recent picks hidden for configured days

---

## Phase 3: Polish

### Goals
Refine UX, add animations, and complete all screens.

### Tasks

- [ ] Settings screen (hide duration, clear history)
- [ ] Favorites screen (thumbs-up places)
- [ ] Googie animations (atomic loader, starburst)
- [ ] Sound effects (optional retro beeps)
- [ ] Error states with themed messaging
- [ ] Empty states
- [ ] Loading states with "Computing..." animations

### Deliverables
- All screens complete
- Consistent retro-future aesthetic
- Delightful micro-interactions

---

## Phase 4: Platform Release

### Goals
Build, test, and deploy to all platforms.

### Tasks

- [ ] iOS build configuration and testing
- [ ] Android build configuration and testing
- [ ] Web deployment to randoeats.com
- [ ] App icons and splash screens (all sizes)
- [ ] App Store assets and submission
- [ ] Play Store assets and submission

### Deliverables
- Live on iOS App Store
- Live on Google Play Store
- Live on randoeats.com

---

## Quality Gates (All Phases)

Every commit must pass:

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
# Coverage must be ≥ 90%
```

---

## Dependencies

| Package | Purpose |
|---------|---------|
| flutter_bloc | State management |
| hive / hive_flutter | Local storage |
| geolocator | Location services |
| google_maps_flutter | Map display |
| http | Places API calls |
| equatable | Value equality |
