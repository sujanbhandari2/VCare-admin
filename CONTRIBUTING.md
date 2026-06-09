# Contributing Guide

Thanks for contributing to this Flutter starter template.

## Development Setup

1. Install Flutter (stable channel) and verify tooling:
   ```bash
   flutter doctor
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Create environment files from the example:
   ```bash
   cp .env.example .env.dev
   cp .env.example .env.qa
   cp .env.example .env.uat
   cp .env.example .env.prod
   ```
4. Run the app with a flavor:
   ```bash
   make run-dev
   ```

## Code Quality Gates

Before opening a PR, run:

```bash
make format-check
flutter analyze
flutter test
```

On pull requests, CI also runs `dart format` and commits any fixes automatically.
Run `make format` locally if you want to apply formatting before pushing.

## Commit and PR Standards

- Keep commits focused and atomic.
- Use clear commit messages in imperative mood.
- Include testing notes in PR descriptions.
- Update docs when behavior or setup changes.

## Architecture Expectations

- Keep feature modules under `lib/ui/features/<feature>`.
- Keep shared UI in `lib/ui/common`.
- Keep app-wide services under `lib/core/services`.
- Keep repositories isolated from widget code.

## Security and Secrets

- Never commit real `.env` files.
- Never commit production secrets or signing files.
- Use environment-specific Firebase configs and CI secrets.
