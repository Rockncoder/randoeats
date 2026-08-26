# rand-o-eats Design System

**Version:** 1.0
**Last Updated:** January 2026

---

## Design Language: Googie / 60s Retro-Future

### Inspiration Sources

- **The Jetsons** (1962-1963) — Optimistic future living
- **Lost in Space** (1965-1968) — Friendly robot companions
- **World's Fair exhibits** (1962-1964) — Space age architecture
- **Bowling alley signage** — Atomic-age typography
- **Googie architecture** — Starbursts, boomerangs, atomic motifs

### The Golden Rule

> "Would this feel at home in an episode of The Jetsons?"

---

## Color Palette

| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| **Turquoise** | `#40E0D0` | 64, 224, 208 | Primary accent, headers |
| **Coral** | `#FF6F61` | 255, 111, 97 | Secondary accent, CTAs |
| **Mustard** | `#FFDB58` | 255, 219, 88 | Highlights, stars |
| **Cream** | `#FFFDD0` | 255, 253, 208 | Backgrounds |
| **Chrome** | `#C0C0C0` | 192, 192, 192 | Borders, subtle accents |
| **Space Black** | `#1A1A2E` | 26, 26, 46 | Text, dark mode bg |

### Color Usage

- **Primary actions:** Coral buttons
- **Secondary actions:** Turquoise outlines
- **Success states:** Turquoise fill
- **Warning states:** Mustard fill
- **Backgrounds:** Cream (light) / Space Black (dark)

---

## Typography

### Display Font

- **Style:** Retro/atomic (bowling alley signage vibe)
- **Use:** Headlines, screen titles, "ENGAGE!" button
- **Candidates:** Atomic Age, Googie, Futura Display

### Body Font

- **Style:** Rounded sans-serif, friendly feel
- **Use:** Body text, labels, descriptions
- **Candidates:** Nunito, Quicksand, Comfortaa

### Monospace (Computer Readout)

- **Style:** Terminal/computer display
- **Use:** "Computing..." text, coordinates, status
- **Candidates:** Space Mono, VT323, IBM Plex Mono

---

## UI Components

### Buttons

```
┌──────────────────────────────┐
│                              │
│         ENGAGE!              │  ← Coral fill, rounded corners
│                              │
└──────────────────────────────┘
     ↑ Minimum 64px height
```

- Large touch targets (minimum 64px height)
- Rounded corners (16-24px radius)
- Slight shadow for depth
- Bouncy press animation

### Cards

```
┌─────────────────────────────────┐
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │      Restaurant Image     │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Restaurant Name                │
│  ★★★★☆  •  $$  •  0.3 mi       │
│                                 │
└─────────────────────────────────┘
```

- Rounded corners
- Subtle chrome border
- Cream background
- Shadow on elevation

### Toggle Switches

```
┌─────────────────────────────┐
│  ○─────────────────────●    │  ← Spaceship control style
└─────────────────────────────┘
```

- Styled like spaceship controls
- Satisfying click feedback
- Turquoise when active

### Rating Buttons

```
┌─────────┐     ┌─────────┐
│   👍    │     │   👎    │
│ Stellar │     │  Avoid  │
└─────────┘     └─────────┘
```

- Large, easy to tap
- Clear visual feedback on selection

---

## Decorative Elements

### Starbursts

```
      \  |  /
    ─── ★ ───
      /  |  \
```

- Used sparingly for emphasis
- Mustard or turquoise color
- Animate on interaction

### Atomic Motifs

```
    ○
   /|\
  ○─●─○
   \|/
    ○
```

- Background decorations
- Loading spinner inspiration
- Corner accents

### Boomerang Shapes

```
  ╭───────╮
 ╱         ╲
╱           ╲
```

- Dividers
- Background patterns
- Card accents

---

## Animation Guidelines

### Principles

- **Bouncy:** Spring physics, slight overshoot
- **Playful:** Nothing too serious
- **Quick:** 200-400ms for most transitions
- **Purposeful:** Animation serves function

### Specific Animations

| Element | Animation |
|---------|-----------|
| Button press | Scale down slightly, bounce back |
| Card appear | Fade in + slide up with spring |
| Loading | Spinning atom / orbiting dots |
| Screen transition | Slide with slight bounce |
| Starburst | Rotate slowly, pulse glow |
| Success | Starburst burst animation |

### Loading Sequence

```
Frame 1:  ○       Frame 2:  ○      Frame 3:    ○
         /               |               \
        ●                ●                ●
         \               |               /
          ○              ○              ○

"Consulting the mainframe..."
```

---

## Tone & Copy

### Voice Characteristics

- **Campy:** Self-aware retro fun
- **Friendly:** Helpful robot butler
- **Enthusiastic:** Excited to help
- **Never condescending:** User is the captain

### Standard Phrases

| Context | Copy |
|---------|------|
| Welcome | "Greetings, Earthling!" |
| Prompt | "What sustenance do you require?" |
| Searching | "Scanning nearby quadrants..." |
| Loading | "Consulting the mainframe..." |
| Results | "Mission options identified!" |
| Selection | "Destination locked!" |
| Navigation | "Initiating guidance protocol!" |
| Error | "Houston, we have a problem" |
| Empty | "No life forms detected in this sector" |
| Refresh | "These do not please me" |
| Decision paralysis | "Danger! Danger! Decision paralysis detected!" |

### Button Labels

| Action | Label |
|--------|-------|
| Search | "ENGAGE!" |
| Navigate | "LAUNCH NAVIGATION" |
| Refresh | "SCAN AGAIN" |
| Back | "ABORT MISSION" |
| Thumbs up | "STELLAR!" |
| Thumbs down | "AVOID SECTOR" |

---

## Responsive Considerations

### Mobile (Primary)

- Full-screen cards
- Bottom navigation
- Large touch targets
- One-hand operation (buttons in bottom 60%)

### Tablet

- Side-by-side layout possible
- Larger cards with more detail
- Map alongside list

### Web

- Centered content area (max 600px)
- Keyboard navigation support
- Hover states for cards

---

## Dark Mode

| Element | Light | Dark |
|---------|-------|------|
| Background | Cream `#FFFDD0` | Space Black `#1A1A2E` |
| Card bg | White | `#2D2D44` |
| Text | Space Black | Cream |
| Accents | Same | Same (Turquoise, Coral, Mustard) |

---

## Assets Checklist

### Required

- [ ] App icon (all sizes)
- [ ] Splash screen
- [ ] Logo (with/without tagline)
- [ ] Loading animation
- [ ] Empty state illustrations
- [ ] Error state illustrations

### Optional (Nice to Have)

- [ ] Sound effects (beeps, whooshes)
- [ ] Custom font files
- [ ] Background patterns
- [ ] Starburst SVGs
