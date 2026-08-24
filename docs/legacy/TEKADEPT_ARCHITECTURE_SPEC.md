# TekAdept LLC - Standard Architecture Specification

**Version:** 1.0  
**Date:** January 2026  
**Purpose:** Standard technology stack, patterns, and preferences for all TekAdept projects

---

## Table of Contents

1. [Philosophy](#philosophy)
2. [Technology Stack](#technology-stack)
3. [Infrastructure](#infrastructure)
4. [Quality Gates](#quality-gates)
5. [Testing Strategy](#testing-strategy)
6. [Code Patterns](#code-patterns)
7. [Flutter Development](#flutter-development)
8. [Git Workflow](#git-workflow)
9. [Performance Requirements](#performance-requirements)
10. [Audio & Media Assets](#audio--media-assets)
11. [Documentation Standards](#documentation-standards)

---

## Philosophy

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Self-hosted > Vendor lock-in** | Predictable costs, full control, no surprise pricing |
| **Open source preferred** | Podman over Docker, avoid proprietary dependencies |
| **Speed is a feature** | Sub-100ms response times, stopwatch timing on critical paths |
| **Quality gates are non-negotiable** | Zero warnings, 90%+ coverage, all tests pass |
| **Tests verify code, not accommodate frameworks** | Low coverage = poorly written code |
| **Price signals quality** | Don't compete on cost—cheap pricing suggests inferior products |
| **Build for acquisition** | Clean docs, automated deployment, minimal owner dependency |

### AI-Assisted Development

- **Claude Code** is the default execution tool for all development work
- All work creates **CLAUDE.md** instructions for Claude Code execution
- Use AI as a force multiplier to accomplish ambitious development goals

---

## Technology Stack

### Backend

| Component | Technology | Notes |
|-----------|------------|-------|
| **Language** | C++ | High performance, 10x+ performance per dollar vs Node/Dart |
| **Framework** | Drogon | Built-in WebSocket, PostgreSQL ORM, async/non-blocking |
| **Build System** | CMake | Standard C++ build system |
| **Database** | PostgreSQL | Horizontal scaling ready, Linode Managed option |
| **Containers** | Podman | Open source, no Docker dependency |

#### Why Drogon

| Feature | Drogon Support |
|---------|----------------|
| HTTP/HTTPS | ✅ Built-in |
| WebSockets | ✅ Built-in |
| PostgreSQL | ✅ Built-in async ORM |
| JSON | ✅ Built-in |
| Connection pooling | ✅ Built-in |
| Async/non-blocking | ✅ Core design |

### Frontend

| Component | Technology | Notes |
|-----------|------------|-------|
| **Mobile** | Flutter | iOS + Android from single codebase |
| **Web** | Flutter Web | Customer-facing and admin dashboards |
| **State Management** | BLoC/Cubit | Preferred pattern |
| **CLI Tools** | Very Good Ventures (VGV) CLI | `very_good create` for new apps |

### Infrastructure

| Component | Technology | Notes |
|-----------|------------|-------|
| **Hosting** | Linode VPS | Predictable pricing, simple |
| **DNS/CDN** | Cloudflare Free | DDoS protection, free tier sufficient |
| **Reverse Proxy** | Caddy | Auto HTTPS via Let's Encrypt |
| **Domain Registrar** | Namecheap | Domains only—skip SSL upsells |
| **IaC** | Pulumi (TypeScript) | Real programming language, not HCL |
| **Configuration** | Ansible | Server setup and deployment |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Payments** | Stripe | Direct integration |

### Why These Choices

| Choice | Rationale |
|--------|-----------|
| C++/Drogon over Dart/Node | 10x+ performance per dollar, lower hosting costs at scale |
| PostgreSQL over SQLite | Horizontal scaling ready, managed option available |
| Podman over Docker | Open source, no proprietary lock-in |
| Linode over AWS/GCP | Predictable pricing, simpler, sufficient for needs |
| Pulumi over Terraform | Real programming language, less convoluted than HCL |
| Cloudflare over custom DNS | Free tier covers needs, DDoS protection included |
| Caddy over nginx | Auto HTTPS, simpler configuration |
| Namecheap for domains | Don't need SSL from registrar—Caddy handles it |

---

## Infrastructure

### Scalability Path

**Phase 1 - Single VPS:** One Linode running backend + PostgreSQL (~$12/month)

**Phase 2 - Separate DB:** Backend on VPS, Linode Managed PostgreSQL (~$27/month)

**Phase 3 - Horizontal:** Load balancer + multiple backend instances + Redis for WebSocket pub/sub

```
Phase 1:
┌─────────────────────────────────────────┐
│  Linode VPS ($12/mo)                    │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │   Drogon    │  │   PostgreSQL    │   │
│  │   Backend   │  │                 │   │
│  └─────────────┘  └─────────────────┘   │
│  ┌─────────────────────────────────┐    │
│  │   Caddy (reverse proxy)         │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘

Phase 3:
                ┌─────────────────┐
                │  Cloudflare     │
                └────────┬────────┘
                         │
                ┌────────▼────────┐
                │  NodeBalancer   │
                └────────┬────────┘
                         │
     ┌───────────────────┼───────────────────┐
     │                   │                   │
     ▼                   ▼                   ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Backend 1  │   │  Backend 2  │   │  Backend 3  │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                ┌────────▼────────┐
                │   PostgreSQL    │
                └────────┬────────┘
                         │
                ┌────────▼────────┐
                │     Redis       │ (WebSocket pub/sub)
                └─────────────────┘
```

### DNS Configuration

**Namecheap DNS Setup:**

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | `<server-ip>` | Automatic |
| A | api | `<server-ip>` | Automatic |
| A | www | `<server-ip>` | Automatic |

**Optional: Cloudflare (Recommended for DDoS protection)**

1. Add domain to Cloudflare
2. Update Namecheap nameservers to Cloudflare's
3. Add A records in Cloudflare (Proxied - orange cloud)

### Deployment Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────────────┐
│  example.com    │────▶│                 │────▶│ :3000 Web Dashboard         │
│                 │     │                 │     │       (Flutter Web)         │
├─────────────────┤     │     Caddy       │     ├─────────────────────────────┤
│  api.example.com│────▶│  (Auto HTTPS)   │────▶│ :8080 Backend API           │
│                 │     │                 │     │       (C++/Drogon)          │
├─────────────────┤     │                 │     ├─────────────────────────────┤
│  short.domain   │────▶│                 │────▶│ :8081 Customer Web          │
│                 │     │                 │     │       (Flutter Web)         │
└─────────────────┘     └─────────────────┘     └─────────────────────────────┘
```

---

## Quality Gates

**All of these must pass before ANY commit:**

### 1. Zero Errors, Zero Warnings

```bash
# C++ must compile cleanly with strict flags
cmake -DCMAKE_CXX_FLAGS="-Wall -Wextra -Werror" ..
make

# Flutter must analyze cleanly
flutter analyze --fatal-infos --fatal-warnings
```

**No exceptions.** Fix all errors and warnings before committing.

### 2. All Tests Pass

```bash
# Backend (Catch2)
cd backend/build && ctest --output-on-failure

# Flutter
flutter test
```

**No exceptions.** All tests must pass before committing.

### 3. Code Coverage ≥ 90%

```bash
# Backend (gcovr)
cd backend/build
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_CXX_FLAGS="--coverage -Wall -Wextra -Werror" ..
make
ctest --output-on-failure
gcovr --root .. --exclude '.*/tests/.*' --fail-under-line 90

# HTML report (optional)
gcovr --root .. --exclude '.*/tests/.*' --html --html-details -o coverage.html

# Flutter
flutter test --coverage
lcov --list coverage/lcov.info
```

**Coverage below 90% means the code isn't well written.** Either:
- Tests are missing — write them
- Code is untestable — refactor it
- Dead code exists — remove it

The `--fail-under-line 90` flag will fail the build if coverage drops below 90%.

---

## Testing Strategy

### Unit Testing

| Language | Framework | Installation |
|----------|-----------|--------------|
| **C++** | Catch2 | FetchContent in CMake |
| **Dart/Flutter** | flutter_test | Built-in |

#### Why Catch2 over Google Test

- Header-only (single file via FetchContent)
- Cleaner syntax with `TEST_CASE`, `REQUIRE`, `CHECK`
- Built-in BDD style with `SECTION`, `SCENARIO`, `GIVEN/WHEN/THEN`
- Better output when tests fail
- SECTIONs reduce test boilerplate

```cmake
# CMake setup for Catch2
Include(FetchContent)
FetchContent_Declare(Catch2 
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git 
  GIT_TAG v3.4.0)
FetchContent_MakeAvailable(Catch2)
```

### Integration Testing

| Platform | Framework | Purpose |
|----------|-----------|---------|
| **Mobile (iOS/Android)** | Maestro | E2E UI testing |
| **Web** | Flutter integration_test | Browser-based testing |

### Coverage Tools

| Language | Tool | Command |
|----------|------|---------|
| **C++** | gcovr | `gcovr --root .. --exclude '.*/tests/.*' --fail-under-line 90` |
| **Flutter** | lcov | `flutter test --coverage && lcov --list coverage/lcov.info` |

---

## Code Patterns

### 1. Tests for Code, Not Code for Tests

Write clean production code first. Then write tests that verify behavior. **Never:**
- Add methods/parameters just to make testing easier
- Expose internals for test access
- Let test structure dictate production architecture

### 2. Dependency Injection

Use constructor injection for all dependencies. This creates decoupled code.

```cpp
// Good: Dependencies injected
class OrderService {
public:
    OrderService(
        std::shared_ptr<IOrderRepository> orderRepo,
        std::shared_ptr<INotificationService> notifier,
        std::shared_ptr<IClock> clock
    );
};
```

### 3. Dart Enums with External Values

When an enum maps to external values (JSON, database, API), define the mapping once with the enum value. Never use separate switch statements with string literals.

**Wrong — duplicate mappings, easy to mismatch:**
```dart
enum OrderStatus {
  preparing,
  ready,
  pickedUp;

  static OrderStatus fromJson(String json) {
    switch (json) {
      case 'preparing': return OrderStatus.preparing;
      case 'ready': return OrderStatus.ready;
      case 'picked_up': return OrderStatus.pickedUp;
      default: throw ArgumentError('Invalid: $json');
    }
  }

  String toJson() {
    switch (this) {
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.pickedUp: return 'picked_up';
    }
  }
}
```

**Right — single source of truth:**
```dart
enum OrderStatus {
  preparing('preparing'),
  ready('ready'),
  pickedUp('picked_up');

  final String jsonValue;
  const OrderStatus(this.jsonValue);

  static OrderStatus fromJson(String json) {
    return OrderStatus.values.firstWhere(
      (e) => e.jsonValue == json,
      orElse: () => throw ArgumentError('Invalid order status: $json'),
    );
  }

  String toJson() => jsonValue;
}
```

**Apply this pattern to ALL enums that serialize to/from external values.**

### 4. Database Race Conditions

Use proper UPSERT queries to prevent race conditions:

```sql
-- Good: Atomic upsert
INSERT INTO orders (id, vendor_id, order_number)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET
    order_number = EXCLUDED.order_number;
```

---

## Flutter Development

### Setup

```bash
# Required tools
flutter --version  # Requires 3.24+ with Dart 3.5+
dart pub global activate very_good_cli
very_good --version  # Requires 0.21+

# Add to PATH
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Project Structure

**Two Flavors Only:** Staging and Production. Remove the default `development` flavor from VGV apps.

```
project/
├── apps/
│   ├── vendor_app/           # Flutter iOS/Android
│   ├── customer_web/         # Flutter Web
│   └── admin/                # Flutter Web
├── packages/
│   └── shared/               # Shared Dart models
├── backend/
├── database/
├── infrastructure/
└── docs/
```

### Skip Melos — Use Simple Scripts

Melos adds complexity. Use a bash script instead:

```bash
# scripts/flutter_all.sh
#!/bin/bash
set -e

APPS="apps/vendor_app apps/customer_web apps/admin packages/shared"

case "$1" in
  bootstrap)
    for dir in $APPS; do
      echo "Installing $dir..."
      (cd "$dir" && flutter pub get)
    done
    ;;
  analyze)
    for dir in $APPS; do
      echo "Analyzing $dir..."
      (cd "$dir" && flutter analyze --fatal-infos --fatal-warnings)
    done
    ;;
  test)
    for dir in $APPS; do
      echo "Testing $dir..."
      (cd "$dir" && flutter test --coverage)
    done
    ;;
  format)
    for dir in $APPS; do
      echo "Formatting $dir..."
      (cd "$dir" && dart format --set-exit-if-changed .)
    done
    ;;
esac
```

### Flutter Commands

```bash
# Individual app
cd apps/vendor_app
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
flutter run --flavor staging -t lib/main_staging.dart

# Build
flutter build apk --flavor production -t lib/main_production.dart
flutter build ios --flavor production -t lib/main_production.dart
flutter build web -t lib/main_production.dart
```

### UI Principles

1. **One-hand operation** — All primary buttons in bottom 60% of screen
2. **Large touch targets** — Minimum 64px height buttons
3. **Visible from distance** — Large order numbers readable across counter
4. **Minimal text input** — Number picker, not keyboard
5. **2 taps maximum** — For core flows

---

## Git Workflow

### Branch Strategy

| Type | Branch Name |
|------|-------------|
| Feature | `feature/[short-description]` |
| Fix | `fix/[short-description]` |
| Refactor | `refactor/[short-description]` |

### Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes nor adds |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build, config, tooling changes |
| `checkpoint` | Before starting new work |

### Complete Workflow

```bash
# 1. Create feature branch
git checkout -b feature/order-service

# 2. Before starting work
git add -A
git commit -m "checkpoint: before implementing OrderService"

# 3. Write the code...

# 4. Build application AND tests
cd backend/build
cmake -DCMAKE_CXX_FLAGS="-Wall -Wextra -Werror" -DBUILD_TESTS=ON ..
make -j$(nproc)  # Builds BOTH app and tests

# 5. Run tests
ctest --output-on-failure

# 6. Check coverage
gcovr --root .. --exclude '.*/tests/.*' --fail-under-line 90

# 7. All gates pass → commit
git add -A
git commit -m "feat: implement OrderService with create and markReady"

# 8. Push feature branch for review
git push origin feature/order-service

# 9. Create pull request (wait for review approval)
# DO NOT merge to main — wait for review
```

### Rules

1. **Never commit directly to main** — Always use feature branches
2. **Zero warnings** — Fix all warnings before committing
3. **All tests pass** — No broken tests, ever
4. **Coverage ≥ 90%** — Low coverage = poorly written code
5. **Push feature branch when complete** — Creates PR for review
6. **Wait for review** — Do not merge your own PRs
7. **Checkpoints stay on branch** — Squash or keep, reviewer decides

---

## Performance Requirements

### Response Time Targets

| Operation | Target |
|-----------|--------|
| Mark order ready | <30ms |
| Create order | <50ms |
| WebSocket push | <20ms |
| Notification delivery | <100ms total |

### Implementation

Add stopwatch timing to all critical paths:

```cpp
#include "infrastructure/Stopwatch.h"

void OrderService::markReady(const std::string& id) {
    Stopwatch sw;
    sw.start();
    
    // ... do work ...
    
    auto elapsed = sw.elapsedMicroseconds();
    if (elapsed > 30000) { // > 30ms
        LOG_WARN << "markReady slow: " << elapsed << "μs";
    }
}
```

---

## Audio & Media Assets

### Preferred Sources

| Source | License | Notes |
|--------|---------|-------|
| [OpenGameArt](https://opengameart.org) | CC0/CC-BY | Games, fanfares, UI sounds |
| [Pixabay](https://pixabay.com/sound-effects) | CC0 | No attribution required |
| [Freesound](https://freesound.org) | CC0/CC-BY | Filter by license |
| [Mixkit](https://mixkit.co/free-sound-effects) | Free commercial | Notification sounds |

### Format Guidelines

| Format | Use Case | Notes |
|--------|----------|-------|
| **MP3** | Web/mobile audio | Small file size, universal support |
| **WAV** | Source files only | Keep originals, serve MP3 |
| **OGG** | Fallback option | No Safari/iOS support |

### Attribution Template

For CC-BY licensed assets:
```
[Asset Name] by [Author Name]
[Author URL]
Licensed under CC-BY [version]
```

---

## Documentation Standards

### Required Documents

| Document | Purpose |
|----------|---------|
| `CLAUDE.md` | Instructions for Claude Code (main entry point) |
| `docs/SPECIFICATION.md` | Full product specification |
| `docs/MVP_PLAN.md` | Development phases and scope |
| `docs/PERFORMANCE.md` | Performance requirements |
| `docs/FLUTTER_SETUP.md` | Flutter-specific setup |
| `database/schema.sql` | Database schema |

### CLAUDE.md Structure

```markdown
# CLAUDE.md - Instructions for Claude Code

## Project Overview
Brief description, documentation links

## Tech Stack Quick Reference
Table of components and technologies

## Quality Gates
Commands and thresholds

## Core Principles
Code patterns to follow

## Quick Reference
Common commands

## When in Doubt
1. Check documentation
2. Keep it simple
3. Commit a checkpoint
4. Ask for clarification
```

---

## Quick Reference

### Install Dependencies

```bash
# C++ coverage tool
pip install gcovr

# Flutter tools
dart pub global activate very_good_cli

# Add to PATH
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### Build Commands

```bash
# Backend
cd backend && mkdir -p build && cd build
cmake -DCMAKE_CXX_FLAGS="-Wall -Wextra -Werror" -DBUILD_TESTS=ON ..
make -j$(nproc)
ctest --output-on-failure

# Flutter
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
```

### Infrastructure Commands

```bash
# Pulumi
cd infrastructure/pulumi
pulumi login
pulumi stack select prod
pulumi up

# DNS verification
dig api.example.com +short
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial specification |
