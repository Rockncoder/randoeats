# Fastlane + Firebase App Distribution Setup for Flutter

Instructions for Claude Code to add Firebase App Distribution deployment to a Flutter app.

## Prerequisites

Before starting, ensure you have:
- Flutter app with iOS and Android targets
- Firebase project created
- Apple Developer account (for iOS)
- GitHub repository for the app

---

## Step 1: Firebase Setup

### 1.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use existing
3. Add iOS app with bundle ID (e.g., `com.company.appname`)
4. Add Android app with package name (same as bundle ID)
5. Download config files:
   - iOS: `GoogleService-Info.plist`
   - Android: `google-services.json`

### 1.2 Enable App Distribution
1. In Firebase Console, go to Release & Monitor > App Distribution
2. Enable for both iOS and Android apps
3. Note the Firebase App IDs:
   - iOS: `1:XXXXXXXXXX:ios:XXXXXXXXXXXX`
   - Android: `1:XXXXXXXXXX:android:XXXXXXXXXXXX`

### 1.3 Create Service Account
1. Go to Project Settings > Service Accounts
2. Click "Generate new private key"
3. Save the JSON file (will be base64 encoded for GitHub secrets)

---

## Step 2: Fastlane Setup

### 2.1 Create Gemfile
```ruby
# Gemfile
source "https://rubygems.org"

gem "fastlane"
gem "fastlane-plugin-firebase_app_distribution"
gem "cocoapods"
```

### 2.2 Create Fastfile
```ruby
# fastlane/Fastfile
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
      git_basic_authorization: Base64.strict_encode64(ENV["MATCH_GIT_BASIC_AUTH"]),
      clone_branch_directly: true
    )

    # Build Flutter app with production flavor
    Dir.chdir("..") do
      sh("flutter build ios --release --flavor production --no-codesign -t lib/main_production.dart")
    end

    # Configure code signing for manual signing
    update_code_signing_settings(
      use_automatic_signing: false,
      path: "ios/Runner.xcodeproj",
      team_id: ENV["APPLE_TEAM_ID"],
      profile_name: "match AdHoc #{ENV['APP_IDENTIFIER']}",
      code_sign_identity: "Apple Distribution",
      targets: ["Runner"]
    )

    # Build and sign IPA
    build_app(
      workspace: "ios/Runner.xcworkspace",
      scheme: "production",
      configuration: "Release-production",
      export_method: "ad-hoc",
      output_directory: "build/ios",
      output_name: "App.ipa",
      export_options: {
        provisioningProfiles: {
          ENV["APP_IDENTIFIER"] => "match AdHoc #{ENV['APP_IDENTIFIER']}"
        }
      }
    )

    # Upload to Firebase App Distribution
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_IOS"],
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
    # Build Flutter app with production flavor
    Dir.chdir("..") do
      sh("flutter build apk --release --flavor production -t lib/main_production.dart")
    end

    # Upload to Firebase App Distribution
    firebase_app_distribution(
      app: ENV["FIREBASE_APP_ID_ANDROID"],
      release_notes: changelog_from_git_commits(commits_count: 5, merge_commit_filtering: "exclude_merges"),
      android_artifact_type: "APK",
      android_artifact_path: "build/app/outputs/flutter-apk/app-production-release.apk",
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

### 2.3 Create Matchfile (iOS code signing)
```ruby
# fastlane/Matchfile
git_url("https://github.com/USERNAME/REPO-certificates.git")
storage_mode("git")
type("adhoc")

app_identifier("com.company.appname")
team_id("XXXXXXXXXX")  # Apple Team ID
```

### 2.4 Create Appfile
```ruby
# fastlane/Appfile
app_identifier(ENV["APP_IDENTIFIER"] || "com.company.appname")
apple_id(ENV["APPLE_ID"])
team_id(ENV["APPLE_TEAM_ID"])
```

---

## Step 3: iOS Code Signing Setup (Match)

### 3.1 Create Certificates Repository
1. Create a **private** GitHub repository for certificates (e.g., `appname-certificates`)
2. Initialize with empty README

### 3.2 Run Match Locally (First Time Only)
```bash
# Install dependencies
bundle install

# Initialize match and create certificates
bundle exec fastlane match adhoc
```

This will:
- Prompt for Match encryption password (save this!)
- Create distribution certificate
- Create ad-hoc provisioning profile
- Store encrypted in your certificates repo

### 3.3 Create GitHub PAT for Match
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Create classic token with `repo` scope
3. Name: `github-ci-access` (or similar)
4. Expiration: 90 days recommended
5. Save the token value

---

## Step 4: Android Signing Setup

### 4.1 Create Keystore
```bash
keytool -genkey -v -keystore android/app/release.keystore \
  -alias appname -keyalg RSA -keysize 2048 -validity 10000
```

### 4.2 Create key.properties Template
```properties
# android/key.properties (DO NOT COMMIT)
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=appname
storeFile=release.keystore
```

### 4.3 Configure build.gradle
```groovy
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## Step 5: GitHub Actions Workflow

### 5.1 Create Workflow File
```yaml
# .github/workflows/distribute.yml
name: Build and Distribute

on:
  push:
    branches: [main]
    paths:
      - 'lib/**'
      - 'pubspec.yaml'
      - 'fastlane/**'
      - '.github/workflows/distribute.yml'
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

env:
  FLUTTER_VERSION: '3.35.0'

jobs:
  # ============================================
  # Android Build
  # ============================================
  android:
    if: github.event.inputs.platform != 'ios'
    runs-on: ubuntu-latest

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
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'
          cache: true

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Create Google Services JSON
        run: echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > android/app/google-services.json

      - name: Create keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=release.keystore
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

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'
          cache: true

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

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
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APP_IDENTIFIER: ${{ secrets.APP_IDENTIFIER }}
        run: bundle exec fastlane ios distribute
```

---

## Step 6: GitHub Secrets Configuration

### Required Secrets

| Secret | Description | How to Get |
|--------|-------------|------------|
| `FIREBASE_APP_ID_IOS` | iOS Firebase App ID | Firebase Console > Project Settings |
| `FIREBASE_APP_ID_ANDROID` | Android Firebase App ID | Firebase Console > Project Settings |
| `FIREBASE_SERVICE_ACCOUNT` | Base64 service account JSON | `base64 -i service-account.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | Base64 iOS config | `base64 -i GoogleService-Info.plist` |
| `GOOGLE_SERVICES_JSON` | Base64 Android config | `base64 -i google-services.json` |
| `MATCH_PASSWORD` | Match encryption password | Set during `fastlane match init` |
| `MATCH_GIT_BASIC_AUTH` | GitHub PAT for cert repo | `username:token` format |
| `APPLE_TEAM_ID` | Apple Developer Team ID | Apple Developer Portal |
| `APP_IDENTIFIER` | Bundle ID | e.g., `com.company.appname` |
| `ANDROID_KEYSTORE_BASE64` | Base64 keystore | `base64 -i release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Set during keystore creation |
| `ANDROID_KEY_PASSWORD` | Key password | Set during keystore creation |
| `ANDROID_KEY_ALIAS` | Key alias | e.g., `appname` |

### Setting Secrets via CLI
```bash
# Base64 encode files
base64 -i path/to/file > file.b64

# Set secret
gh secret set SECRET_NAME < file.b64

# Or set directly
gh secret set SECRET_NAME --body "value"

# For MATCH_GIT_BASIC_AUTH (username:token format)
gh secret set MATCH_GIT_BASIC_AUTH --body "username:ghp_xxxxxxxxxxxxx"
```

---

## Step 7: Verification Checklist

### Files to Create
- [ ] `Gemfile`
- [ ] `fastlane/Fastfile`
- [ ] `fastlane/Matchfile`
- [ ] `fastlane/Appfile`
- [ ] `.github/workflows/distribute.yml`

### Files to Add to .gitignore
```gitignore
# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output

# Signing
*.keystore
*.jks
key.properties
GoogleService-Info.plist
google-services.json
firebase-service-account.json
```

### Local Testing
```bash
# Install dependencies
bundle install

# Test Android build locally
bundle exec fastlane android distribute

# Test iOS build locally (Mac only)
bundle exec fastlane ios distribute
```

---

## Troubleshooting

### Common iOS Issues

1. **"No signing certificate found"**
   - Run `bundle exec fastlane match adhoc` locally to sync certificates

2. **"Provisioning profile doesn't match"**
   - Ensure `APP_IDENTIFIER` secret matches Matchfile

3. **"Branch already exists" in Match**
   - Add `clone_branch_directly: true` to match config

4. **"Pods don't support provisioning profiles"**
   - Use `update_code_signing_settings` with `targets: ["Runner"]`

### Common Android Issues

1. **"Keystore not found"**
   - Verify `ANDROID_KEYSTORE_BASE64` is properly encoded

2. **"Signing config not found"**
   - Check `key.properties` path in `build.gradle`

### Firebase Issues

1. **"Permission denied"**
   - Verify service account has Firebase App Distribution Admin role

2. **"App not found"**
   - Double-check Firebase App IDs match exactly

---

## Adapting for Different Flutter Configurations

### Without Flavors
Change build commands:
```ruby
# iOS
sh("flutter build ios --release --no-codesign")

# Android
sh("flutter build apk --release")
```

And update APK path:
```ruby
android_artifact_path: "build/app/outputs/flutter-apk/app-release.apk"
```

### With Different Flavor Names
Update scheme and configuration in Fastfile:
```ruby
scheme: "your_flavor_name",
configuration: "Release-your_flavor_name",
```

### App Bundle Instead of APK
```ruby
sh("flutter build appbundle --release --flavor production")

firebase_app_distribution(
  android_artifact_type: "AAB",
  android_artifact_path: "build/app/outputs/bundle/productionRelease/app-production-release.aab"
)
```
