# Flutter Industry-Grade Starter Template

Production-ready Flutter starter with **flavors**, **Riverpod state management**, **GoRouter navigation**, **Firebase integration**, and **CI-quality defaults**.

## What you get

- ✅ Structured feature-first codebase
- ✅ Multi-flavor app setup (`dev`, `staging`, `prod`)
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
cp .env.example .env.staging
cp .env.example .env.prod
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run app by flavor**

```bash
make run-dev
make run-staging
make run-prod
```

## Environment Configuration

Set values in each environment file:

```env
BASE_URL=https://api.example.com/
HIVE_BOX_NAME=FlutterTemplateApp
```

> `.env` files are ignored by git. Never commit real secrets.

## Flavor Commands

### Run

```bash
make run-dev
make run-staging
make run-prod
make run-dev-ios
make run-staging-ios
make run-prod-ios
```

### Build

```bash
make build-apk-dev
make build-apk-staging
make build-apk-prod

make build-appbundle-dev
make build-appbundle-staging
make build-appbundle-prod

make build-ipa-dev
make build-ipa-staging
make build-ipa-prod
```

## Quality Gates (local)

Before opening a PR:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## CI/CD

This template includes:

- `.github/workflows/flutter_ci.yml` for format/analyze/test checks
- `.github/dependabot.yml` for weekly dependency update PRs

## Package Name Change

```bash
make change-pkg name=com.example.newname
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup and quality standards.
