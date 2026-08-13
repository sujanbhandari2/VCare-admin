# Flutter Industry-Grade Starter Template

Production-ready Flutter starter with **flavors**, **Riverpod state management**, **GoRouter navigation**, **Firebase integration**, and **CI-quality defaults**.

## What you get

- ✅ Structured feature-first codebase
- ✅ Multi-flavor app setup (`dev`, `qa`, `uat`, `prod`)
- ✅ Firebase config switching script support
- ✅ Localization scaffold (`en`, `bn`, `ne`)
- ✅ Built-in networking, storage, connectivity, and location services
- ✅ Makefile commands for common run/build workflows
- ✅ CI workflow for formatting, analysis, and tests
- ✅ Dependabot automation for dependency hygiene

## Project Structure (high level)

```text
lib/
  app/               # app wiring (bootstrap, router, app widget)
  core/              # config, styles, services, database
  shared/            # reusable UI + utilities
  features/          # feature modules (auth, onboarding, profile, etc.)
  l10n/              # generated localization files and ARB resources
```

### Feature Anatomy

Each feature is organized by layers to keep business logic isolated:

```text
lib/features/<feature>/
  data/              # DTO/models, mappers, repositories impl
  domain/            # entities, enums, repository contracts
  presentation/      # UI + state (Riverpod)
```

**Rule of thumb:** presentation depends on domain, data depends on domain, and domain depends on nothing.

## Prerequisites

- Flutter stable SDK (see `pubspec.yaml` constraints)
- Xcode + CocoaPods (for iOS)
- Android Studio / Android SDK (for Android)

Verify your toolchain:

```bash
flutter doctor
```

## Quick Start

1. **Create environment files**

```bash
cp .env.example .env.dev
cp .env.example .env.qa
cp .env.example .env.uat
cp .env.example .env.prod
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run app by flavor**

```bash
make run-dev
make run-qa
make run-uat
make run-prod
```

## Environment Configuration

Set values in each environment file:

```env
# Host root only — the app appends api/v1/ for all flavors.
BASE_URL=https://dev-api-v4.vitafyhealth.com/
HIVE_BOX_NAME=FlutterTemplateApp
```

> `.env` files are ignored by git. Never commit real secrets.

## IDE Setup

### Cursor / VS Code

1. Open the **project root** (`vcare2.0-admin`).
2. Install the **Flutter** and **Dart** extensions.
3. First-time setup: run `make setup-env` and edit `.env.dev`, `.env.qa`, `.env.uat`, `.env.prod`.
4. Select a device/emulator from the status bar (Android or iOS).
5. Open **Run and Debug** (`⇧⌘D`) and pick a flavor config:
   - `dev`, `qa`, `uat`, `prod` (debug)
   - `dev (profile)`, `qa (profile)`, … for profile mode
   - `dev (release)`, `qa (release)`, … for release mode
6. Press **F5** (or the green play button). Each config runs `./scripts/configure_flavor.sh` first to sync `.env` and Firebase files.

Configs live in `.vscode/launch.json` and `.vscode/tasks.json`.

### Android Studio

1. Open the **project root** (`vcare2.0-admin`), not the `android/` subfolder.
2. First-time setup: run `make setup-env` and edit `.env.dev`, `.env.qa`, `.env.uat`, `.env.prod`.
3. Select a shared run configuration from `.run/`:
   - `dev (Android)`, `qa (Android)`, `uat (Android)`, `prod (Android)`
4. Each config runs `./scripts/configure_flavor.sh` before launch to sync `.env` and Firebase files.
5. For Android builds, match **Build Variants** to the selected flavor (for example `devDebug` when running `dev (Android)`).

All four flavors can be installed side-by-side on one device because each flavor uses a distinct application ID.

### Xcode

1. Open `ios/Runner.xcworkspace` (not `Runner.xcodeproj`).
2. Select the scheme: `dev`, `qa`, `uat`, or `prod`.
3. Run or Archive. Each scheme pre-runs `./scripts/configure_flavor.sh` for the matching flavor.
4. Profile builds use the flavor-specific `Profile-{flavor}` configuration.

### Flavor reference

| Flavor | Android app ID | iOS bundle ID | CLI run |
|--------|----------------|---------------|---------|
| dev | `com.vcare.admin.dev` | `com.vcare.admin.dev` | `make run-dev` |
| qa | `com.vcare.admin.qa` | `com.vcare.admin.qa` | `make run-qa` |
| uat | `com.vcare.admin.uat` | `com.vcare.admin.uat` | `make run-uat` |
| prod | `com.vcare.admin` | `com.vcare.admin` | `make run-prod` |

See [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) for Firebase file setup per flavor.

## Flavor Commands

### Run

```bash
make run-dev
make run-qa
make run-uat
make run-prod
make run-dev-ios
make run-qa-ios
make run-uat-ios
make run-prod-ios
```

### Build

```bash
make build-apk-dev
make build-apk-qa
make build-apk-uat
make build-apk-prod

make build-appbundle-dev
make build-appbundle-qa
make build-appbundle-uat
make build-appbundle-prod

make build-ipa-dev
make build-ipa-qa
make build-ipa-uat
make build-ipa-prod
```

## Quality Gates (local)

Before opening a PR:

```bash
make format-check
flutter analyze
flutter test
```

## CI/CD

This template includes:

- `.github/workflows/flutter_ci.yml` for format/analyze/test checks
  - Pull requests: runs `dart format`, auto-commits fixes, then analyze/test
  - Pushes to `main`: enforces formatting with `dart format --set-exit-if-changed`
- `.github/dependabot.yml` for weekly dependency update PRs

## Package Name Change

```bash
make change-pkg name=com.example.newname
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup and quality standards.
