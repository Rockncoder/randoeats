# Claude Code Instructions: Fastlane + Firebase App Distribution Setup

## Overview

Set up fastlane with GitHub Actions to build and deploy RandoEats Flutter app to Firebase App Distribution for both iOS and Android.

---

## Prerequisites - User Must Provide These Values

Before starting, collect these values from the user:

```
# Firebase (from Firebase Console → Project Settings)
FIREBASE_PROJECT_ID: _______________
FIREBASE_APP_ID_IOS: _______________
FIREBASE_APP_ID_ANDROID: _______________

# Apple Developer (from developer.apple.com)
APPLE_TEAM_ID: _______________
APP_BUNDLE_ID: _______________ (e.g., com.tekadept.randoeats)
APPLE_ID_EMAIL: _______________

# GitHub
GITHUB_ORG_OR_USER: _______________ (for certificates repo)
RANDOEATS_REPO_NAME: _______________ (existing repo name)

# App Info
APP_NAME: RandoEats
```

---

## Task 1: Create Private Certificates Repository

Create a private GitHub repo to store Match certificates.

```bash
# Using GitHub CLI
gh repo create [GITHUB_ORG_OR_USER]/randoeats-certificates --private --description "Fastlane Match certificates for RandoEats"
```

---

## Task 2: Generate Android Release Keystore

```bash
# Navigate to android app directory
cd [PROJECT_ROOT]/apps/randoeats_app/android

# Generate keystore (will prompt for passwords)
keytool -genkey -v \
  -keystore randoeats-release.keystore \
  -alias randoeats \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=RandoEats, OU=Mobile, O=TekAdept LLC, L=City, ST=State, C=US"

# IMPORTANT: Record the passwords used - user will need them for GitHub Secrets
# Store keystore in a secure location outside git
mv randoeats-release.keystore ~/randoeats-release.keystore

echo "Keystore created at ~/randoeats-release.keystore"
echo "Add to .gitignore: *.keystore"
```

---

## Task 3: Create Fastlane Directory Structure

```bash
cd [PROJECT_ROOT]/apps/randoeats_app

# Create fastlane directory
mkdir -p fastlane
```

---

## Task 4: Create Appfile

Create `[PROJECT_ROOT]/apps/randoeats_app/fastlane/Appfile`:

```ruby
# iOS
app_identifier("[APP_BUNDLE_ID]")
apple_id("[APPLE_ID_EMAIL]")
team_id("[APPLE_TEAM_ID]")

# Android
json_key_file(ENV["GOOGLE_SERVICE_ACCOUNT_KEY_PATH"])
package_name("[APP_BUNDLE_ID]")
```

---

## Task 5: Create Matchfile

Create `[PROJECT_ROOT]/apps/randoeats_app/fastlane/Matchfile`:

```ruby
git_url("git@github.com:[GITHUB_ORG_OR_USER]/randoeats-certificates.git")
storage_mode("git")
type("adhoc") # Use "adhoc" for Firebase App Distribution

app_identifier("[APP_BUNDLE_ID]")
team_id("[APPLE_TEAM_ID]")

# For CI
readonly(is_ci)
```

---

## Task 6: Create Fastfile

Create `[PROJECT_ROOT]/apps/randoeats_app/fastlane/Fastfile`:

```ruby
default_platform(:ios)

# ============================================
# iOS
# ============================================
platform :ios do
  desc "Build and upload iOS to Firebase App Distribution"
  lane :distribute do
    # Setup CI environment
    setup_ci if is_ci

    # Fetch certificates using Match
    match(
      type: "adhoc",
      readonly: is_ci,
      git_basic_authorization: Base64.strict_encode64(ENV["MATCH_GIT_BASIC_AUTH"]) 
    )

    # Build Flutter app
    Dir.chdir("..") do
      sh("flutter build ios --release --no-codesign")
    end

    # Build and sign IPA
    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      export_method: "ad-hoc",
      output_directory: "build/ios",
      output_name: "RandoEats.ipa",
      export_options: {
        provisioningProfiles: {
          "[APP_BUNDLE_ID]" => "match AdHoc [APP_BUNDLE_ID]"
        }
      }
    )

    # Upload to Firebase App Distribution
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_IOS"],
      groups: "internal-testers",
      release_notes: changelog_from_git_commits(commits_count: 5, merge_commit_filtering: "exclude_merges"),
      service_credentials_file: ENV["GOOGLE_SERVICE_ACCOUNT_KEY_PATH"]
    )
  end

  desc "Sync certificates (run locally first time)"
  lane :sync_certs do
    match(type: "adhoc")
  end
end

# ============================================
# Android
# ============================================
platform :android do
  desc "Build and upload Android to Firebase App Distribution"
  lane :distribute do
    # Build Flutter app
    Dir.chdir("..") do
      sh("flutter build apk --release")
    end

    # Upload to Firebase App Distribution
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_ANDROID"],
      groups: "internal-testers",
      release_notes: changelog_from_git_commits(commits_count: 5, merge_commit_filtering: "exclude_merges"),
      android_artifact_type: "APK",
      android_artifact_path: "build/app/outputs/flutter-apk/app-release.apk",
      service_credentials_file: ENV["GOOGLE_SERVICE_ACCOUNT_KEY_PATH"]
    )
  end
end

# ============================================
# Both Platforms
# ============================================
desc "Build and distribute both platforms"
lane :distribute_all do
  Fastlane::LaneManager.cruise_lane("ios", "distribute")
  Fastlane::LaneManager.cruise_lane("android", "distribute")
end
```

---

## Task 7: Create Gemfile

Create `[PROJECT_ROOT]/apps/randoeats_app/Gemfile`:

```ruby
source "https://rubygems.org"

gem "fastlane"
gem "fastlane-plugin-firebase_app_distribution"
```

---

## Task 8: Create GitHub Actions Workflow

Create `[PROJECT_ROOT]/.github/workflows/distribute.yml`:

```yaml
name: Build and Distribute

on:
  push:
    branches: [main]
    paths:
      - 'apps/randoeats_app/**'
  workflow_dispatch:
    inputs:
      platform:
        description: 'Platform to build'
        required: true
        default: 'both'
        type: choice
        options:
          - ios
          - android
          - both

jobs:
  # ============================================
  # Android Build
  # ============================================
  android:
    if: github.event.inputs.platform != 'ios'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: apps/randoeats_app

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: apps/randoeats_app

      - name: Install dependencies
        run: flutter pub get

      - name: Create Google Services JSON
        run: echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > android/app/google-services.json

      - name: Create keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/randoeats-release.keystore

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=randoeats
          storeFile=randoeats-release.keystore
          EOF

      - name: Create service account file
        run: |
          echo "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" | base64 -d > firebase-service-account.json

      - name: Build and distribute
        env:
          FIREBASE_APP_ID_ANDROID: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
          GOOGLE_SERVICE_ACCOUNT_KEY_PATH: firebase-service-account.json
        run: bundle exec fastlane android distribute

  # ============================================
  # iOS Build
  # ============================================
  ios:
    if: github.event.inputs.platform != 'android'
    runs-on: macos-14
    defaults:
      run:
        working-directory: apps/randoeats_app

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: apps/randoeats_app

      - name: Install dependencies
        run: flutter pub get

      - name: Create GoogleService-Info.plist
        run: echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 -d > ios/Runner/GoogleService-Info.plist

      - name: Create service account file
        run: |
          echo "${{ secrets.FIREBASE_SERVICE_ACCOUNT }}" | base64 -d > firebase-service-account.json

      - name: Build and distribute
        env:
          FIREBASE_APP_ID_IOS: ${{ secrets.FIREBASE_APP_ID_IOS }}
          GOOGLE_SERVICE_ACCOUNT_KEY_PATH: firebase-service-account.json
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_BASIC_AUTH: ${{ secrets.MATCH_GIT_BASIC_AUTH }}
        run: bundle exec fastlane ios distribute
```

---

## Task 9: Update Android Build Configuration for Signing

Update `[PROJECT_ROOT]/apps/randoeats_app/android/app/build.gradle`:

Add signing config section (after `android {`):

```gradle
android {
    // ... existing config ...

    def keystorePropertiesFile = rootProject.file("key.properties")
    def keystoreProperties = new Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... existing release config ...
        }
    }
}
```

---

## Task 10: Update .gitignore

Append to `[PROJECT_ROOT]/apps/randoeats_app/.gitignore`:

```gitignore
# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output
fastlane/README.md

# Signing
*.keystore
*.jks
key.properties
firebase-service-account.json

# Google Services (if storing as secrets)
# Uncomment if not committing these files:
# ios/Runner/GoogleService-Info.plist
# android/app/google-services.json
```

---

## Task 11: Create Local Environment Template

Create `[PROJECT_ROOT]/apps/randoeats_app/.env.example`:

```bash
# Firebase
FIREBASE_APP_ID_IOS=1:123456789:ios:abcdef
FIREBASE_APP_ID_ANDROID=1:123456789:android:abcdef
GOOGLE_SERVICE_ACCOUNT_KEY_PATH=./firebase-service-account.json

# Match (iOS code signing)
MATCH_PASSWORD=your-match-passphrase
MATCH_GIT_BASIC_AUTH=your-github-username:your-github-pat
```

---

## GitHub Secrets Reference

User must add these secrets in GitHub repo → Settings → Secrets and variables → Actions:

| Secret Name | How to Get |
|-------------|-----------|
| `FIREBASE_APP_ID_IOS` | Firebase Console → Project Settings → Your apps |
| `FIREBASE_APP_ID_ANDROID` | Firebase Console → Project Settings → Your apps |
| `FIREBASE_SERVICE_ACCOUNT` | Base64 of service account JSON |
| `GOOGLE_SERVICES_JSON` | Base64 of `google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | Base64 of `GoogleService-Info.plist` |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/randoeats-release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Password used when creating keystore |
| `ANDROID_KEY_PASSWORD` | Key password (often same as keystore) |
| `MATCH_PASSWORD` | Passphrase for Match encryption |
| `MATCH_GIT_BASIC_AUTH` | `username:github_pat_token` |

---

## Post-Setup: Initialize Match (Run Once Locally)

After Claude Code creates the files, user must run locally:

```bash
cd apps/randoeats_app

# Install gems
bundle install

# Initialize Match - this will prompt for Apple credentials
# and create certificates in the private repo
bundle exec fastlane ios sync_certs
```

This requires Apple Developer authentication and will:
1. Create App ID in Apple Developer Portal (if needed)
2. Create AdHoc provisioning profile
3. Encrypt and store in the certificates repo

---

## Verification Steps

After setup, verify:

1. **Files created:**
   - [ ] `fastlane/Appfile`
   - [ ] `fastlane/Matchfile`
   - [ ] `fastlane/Fastfile`
   - [ ] `Gemfile`
   - [ ] `.github/workflows/distribute.yml`
   - [ ] `.env.example`
   - [ ] Updated `.gitignore`
   - [ ] Updated `android/app/build.gradle`

2. **Certificates repo created:**
   - [ ] Private repo exists at `[GITHUB_ORG_OR_USER]/randoeats-certificates`

3. **Local test (Android only, no signing):**
   ```bash
   cd apps/randoeats_app
   bundle install
   flutter build apk --debug
   ```

4. **Match initialized:**
   - [ ] Run `bundle exec fastlane ios sync_certs` locally

---

## GitHub Secrets Summary

Add these secrets in GitHub repo → Settings → Secrets and variables → Actions:

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `FIREBASE_APP_ID_IOS` | iOS app identifier | Firebase Console → Project Settings → Your apps |
| `FIREBASE_APP_ID_ANDROID` | Android app identifier | Firebase Console → Project Settings → Your apps |
| `FIREBASE_SERVICE_ACCOUNT` | Service account for uploads | Base64 encode: `base64 -i firebase-sa.json \| tr -d '\n'` |
| `GOOGLE_SERVICES_JSON` | Android Firebase config | Base64 encode: `base64 -i android/app/google-services.json \| tr -d '\n'` |
| `GOOGLE_SERVICE_INFO_PLIST` | iOS Firebase config | Base64 encode: `base64 -i ios/Runner/GoogleService-Info.plist \| tr -d '\n'` |
| `ANDROID_KEYSTORE_BASE64` | Release signing keystore | Base64 encode: `base64 -i ~/randoeats-release.keystore \| tr -d '\n'` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Password used during `keytool` generation |
| `ANDROID_KEY_PASSWORD` | Key password | Key password (often same as keystore password) |
| `MATCH_PASSWORD` | Encrypts certs in git | Choose a strong passphrase |
| `MATCH_GIT_BASIC_AUTH` | Auth for certificates repo | Format: `github_username:github_pat_token`|

### Creating the GitHub PAT for Match

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Combine with username: `myusername:ghp_xxxxxxxxxxxx`
