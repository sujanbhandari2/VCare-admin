# Flutter Multi-Flavor Makefile with Firebase Support
# Supports: dev, qa, uat, prod flavors
# Platform: iOS, Android

.PHONY: help setup setup-env setup-firebase gen-code gen-l10n format format-check change-pkg change-package-name sync-home sync-all run-dev run-qa run-uat run-prod run-dev-ios run-qa-ios run-uat-ios run-prod-ios build-apk-dev build-apk-qa build-apk-uat build-apk-prod build-appbundle-dev build-appbundle-qa build-appbundle-uat build-appbundle-prod build-ios-dev build-ios-qa build-ios-uat build-ios-prod build-ipa-dev build-ipa-qa build-ipa-uat build-ipa-prod configure-dev configure-qa configure-uat configure-prod

# Configuration
APP_NAME = vcare_admin
# Support multiple possible script locations
FIREBASE_SCRIPT_PATHS = ./scripts/update_firebase_config.sh ./scripts/setup_firebase_config.sh ./update_firebase_config.sh ./setup_firebase_config.sh
FIREBASE_SCRIPT = $(firstword $(wildcard $(FIREBASE_SCRIPT_PATHS)))

# Default target
help:
	@echo "Flutter Multi-Flavor Build System - $(APP_NAME)"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup                - First-time setup (env files, deps, code gen)"
	@echo "  make setup-env            - Create .env files from .env.example"
	@echo "  make setup-firebase       - Make Firebase script executable"
	@echo "  make gen-code             - Run Dart code generation with build_runner"
	@echo "  make gen-l10n             - Generate localization files"
	@echo "  make format               - Apply dart format to the project"
	@echo "  make format-check         - Fail if any Dart file needs formatting (CI check)"
	@echo "  make change-pkg name=com.example.app - Change Android/iOS package name"
	@echo "  make sync-home to=<sha> [from=<sha>] - Build home sync artifacts from vcareapp"
	@echo "  make sync-all to=<sha> [from=<sha>]  - Build full-project sync artifacts"
	@echo ""
	@echo "Flavor Configuration Commands:"
	@echo "  make configure-dev              - Configure dev flavor"
	@echo "  make configure-qa          - Configure qa flavor
	@echo "  make configure-uat          - Configure uat flavor"
	@echo "  make configure-prod             - Configure prod flavor"
	@echo ""
	@echo "Run Commands:"
	@echo "  make run-dev              - Run dev flavor (Android)"
	@echo "  make run-qa          - Run qa flavor (Android)
	@echo "  make run-uat          - Run uat flavor (Android)"
	@echo "  make run-prod             - Run prod flavor (Android)"
	@echo "  make run-dev-ios          - Run dev flavor (iOS)"
	@echo "  make run-qa-ios      - Run qa flavor (iOS)
	@echo "  make run-uat-ios      - Run uat flavor (iOS)"
	@echo "  make run-prod-ios         - Run prod flavor (iOS)"
	@echo ""
	@echo "Android Build Commands:"
	@echo "  make build-apk-dev        - Build dev APK"
	@echo "  make build-apk-qa    - Build qa APK
	@echo "  make build-apk-uat    - Build uat APK"
	@echo "  make build-apk-prod       - Build prod APK"
	@echo "  make build-appbundle-dev  - Build dev App Bundle"
	@echo "  make build-appbundle-qa - Build qa App Bundle
	@echo "  make build-appbundle-uat - Build uat App Bundle"
	@echo "  make build-appbundle-prod - Build prod App Bundle"
	@echo ""
	@echo "iOS Build Commands:"
	@echo "  make build-ios-dev        - Build dev iOS (no codesign)"
	@echo "  make build-ios-qa    - Build qa iOS (no codesign)
	@echo "  make build-ios-uat    - Build uat iOS (no codesign)"
	@echo "  make build-ios-prod       - Build prod iOS (no codesign)"
	@echo "  make build-ipa-dev        - Build dev IPA"
	@echo "  make build-ipa-qa    - Build qa IPA
	@echo "  make build-ipa-uat    - Build uat IPA"
	@echo "  make build-ipa-prod       - Build prod IPA"

# ============================================
# SETUP
# ============================================

setup: setup-env setup-firebase
	@echo "📦 Installing dependencies..."
	flutter pub get
	@$(MAKE) gen-code
	@$(MAKE) configure-dev
	@echo "✅ Project setup complete. Run: make run-dev"

setup-env:
	@echo "📝 Creating environment files from .env.example..."
	@cp -n .env.example .env.dev 2>/dev/null || true
	@cp -n .env.example .env.qa 2>/dev/null || true
	@cp -n .env.example .env.uat 2>/dev/null || true
	@cp -n .env.example .env.prod 2>/dev/null || true
	@cp -n .env.example .env 2>/dev/null || true
	@echo "✅ Environment files ready (.env, .env.dev, .env.qa, .env.uat, .env.prod)"

setup-firebase:
	@echo "🔧 Setting up Firebase configuration script..."
	@mkdir -p scripts
	@if [ -z "$(FIREBASE_SCRIPT)" ]; then \
		echo "❌ Error: Firebase configuration script not found!"; \
		echo ""; \
		echo "Expected locations (checked in order):"; \
		echo "  - ./scripts/update_firebase_config.sh"; \
		echo "  - ./scripts/setup_firebase_config.sh"; \
		echo "  - ./update_firebase_config.sh"; \
		echo "  - ./setup_firebase_config.sh"; \
		echo ""; \
		echo "Please place the script in one of these locations."; \
		exit 1; \
	fi
	@echo "Found script at: $(FIREBASE_SCRIPT)"
	@chmod +x $(FIREBASE_SCRIPT)
	@echo "✅ Firebase script is now executable"
	@echo ""
	@echo "📋 Prerequisites:"
	@echo "  - jq: brew install jq (macOS) or sudo apt-get install jq (Linux)"
	@echo "  - Python 3 (for iOS plist parsing)"
	@echo ""
	@echo "📁 Required file structure:"
	@echo "  scripts/update_firebase_config.sh (or setup_firebase_config.sh)"
	@echo "  android/app/google-services-dev.json"
	@echo "  android/app/google-services-qa.json
	@echo "  android/app/google-services-uat.json"
	@echo "  android/app/google-services-prod.json"
	@echo "  ios/Runner/GoogleService-Info-dev.plist (optional)"
	@echo "  ios/Runner/GoogleService-Info-qa.plist (optional)
	@echo "  ios/Runner/GoogleService-Info-uat.plist (optional)"
	@echo "  ios/Runner/GoogleService-Info-prod.plist (optional)"

# ============================================
# CODE GENERATION
# ============================================

gen-code:
	@echo "🛠️ Running code generation..."
	dart run build_runner build
	@echo "✅ Code generation complete"

gen-l10n:
	@echo "🌐 Generating localization files..."
	flutter gen-l10n
	@echo "✅ Localization generation complete"

format:
	@echo "✨ Applying dart format..."
	dart format .
	@echo "✅ Formatting complete"

format-check:
	@echo "🔍 Checking Dart formatting..."
	dart format --output=none --set-exit-if-changed .
	@echo "✅ Formatting check passed"

change-pkg:
	@if [ -z "$(name)" ]; then \
		echo "❌ Error: name is required"; \
		echo "Usage: make change-pkg name=com.example.app"; \
		exit 1; \
	fi
	@echo "📦 Changing package name to $(name)..."
	flutter pub run change_app_package_name:main $(name)
	@echo "✅ Package name updated to $(name)"

sync-home:
	@if [ -z "$(to)" ]; then \
		echo "❌ Error: to is required"; \
		echo "Usage: make sync-home to=<vcareapp_sha> [from=<vcareapp_sha>]"; \
		exit 1; \
	fi
	@if [ -n "$(from)" ]; then \
		bash scripts/vcare_sync_prepare.sh --from $(from) --to $(to) --feature home; \
	else \
		bash scripts/vcare_sync_prepare.sh --to $(to) --feature home; \
	fi

sync-all:
	@if [ -z "$(to)" ]; then \
		echo "❌ Error: to is required"; \
		echo "Usage: make sync-all to=<vcareapp_sha> [from=<vcareapp_sha>]"; \
		exit 1; \
	fi
	@if [ -n "$(from)" ]; then \
		bash scripts/vcare_sync_prepare.sh --from $(from) --to $(to) --feature all; \
	else \
		bash scripts/vcare_sync_prepare.sh --to $(to) --feature all; \
	fi

# ============================================
# CONFIGURATION SETUP COMMANDS - FLAVOR
# ============================================

configure-dev:
	@echo "⚙️ Configuring DEV flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	@echo "✅ Environment for dev flavor configured"

configure-qa:
configure-uat:
	@echo "⚙️ Configuring STAGING flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	@echo "✅ Environment for uat flavor configured"

configure-prod:
	@echo "⚙️ Configuring PROD flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	@echo "✅ Environment for production flavor configured"

# ============================================
# RUN COMMANDS - ANDROID
# ============================================

run-dev: setup-env
	@echo "🚀 Running DEV flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter run --flavor dev

run-qa: setup-env
run-uat: setup-env
	@echo "🚀 Running STAGING flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter run --flavor uat

run-prod: setup-env
	@echo "🚀 Running PROD flavor..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter run --flavor prod

# ============================================
# RUN COMMANDS - iOS
# ============================================

run-dev-ios: setup-env
	@echo "🚀 Running DEV flavor (iOS)..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	cd ios && pod install && cd ..
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter run --flavor dev

run-qa-ios: setup-env
run-uat-ios: setup-env
	@echo "🚀 Running STAGING flavor (iOS)..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	cd ios && pod install && cd ..
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter run --flavor uat

run-prod-ios: setup-env
	@echo "🚀 Running PROD flavor (iOS)..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	@$(MAKE) gen-code
	cd ios && pod install && cd ..
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter run --flavor prod

# ============================================
# ANDROID APK BUILDS
# ============================================

build-apk-dev:
	@echo "🤖 Building Android APK for DEV..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter build apk --flavor dev --release
	@echo "✅ APK: build/app/outputs/flutter-apk/app-dev-release.apk"

build-apk-qa:
build-apk-uat:
	@echo "🤖 Building Android APK for STAGING..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter build apk --flavor uat --release
	@echo "✅ APK: build/app/outputs/flutter-apk/app-uat-release.apk"

build-apk-prod:
	@echo "🤖 Building Android APK for PROD..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter build apk --flavor prod --release
	@echo "✅ APK: build/app/outputs/flutter-apk/app-prod-release.apk"

# ============================================
# ANDROID APP BUNDLE BUILDS
# ============================================

build-appbundle-dev:
	@echo "🤖 Building App Bundle for DEV..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter build appbundle --flavor dev --release
	@echo "✅ AAB: build/app/outputs/bundle/devRelease/app-dev-release.aab"

build-appbundle-qa:
build-appbundle-uat:
	@echo "🤖 Building App Bundle for STAGING..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter build appbundle --flavor uat --release
	@echo "✅ AAB: build/app/outputs/bundle/uatRelease/app-uat-release.aab"

build-appbundle-prod:
	@echo "🤖 Building App Bundle for PROD..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter build appbundle --flavor prod --release
	@echo "✅ AAB: build/app/outputs/bundle/prodRelease/app-prod-release.aab"

# ============================================
# iOS BUILDS
# ============================================

build-ios-dev:
	@echo "🍎 Building iOS for DEV..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter build ios --flavor dev --release --no-codesign
	@echo "✅ iOS build complete"

build-ios-qa:
build-ios-uat:
	@echo "🍎 Building iOS for STAGING..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter build ios --flavor uat --release --no-codesign
	@echo "✅ iOS build complete"

build-ios-prod:
	@echo "🍎 Building iOS for PROD..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter build ios --flavor prod --release --no-codesign
	@echo "✅ iOS build complete"

# ============================================
# iOS IPA BUILDS
# ============================================

build-ipa-dev:
	@echo "🍎 Building IPA for DEV..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) dev
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.dev ]; then cp .env.dev .env; fi
	flutter build ipa --flavor dev --release
	@echo "✅ IPA: build/ios/ipa"

build-ipa-qa:
build-ipa-uat:
	@echo "🍎 Building IPA for STAGING..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) uat
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.uat ]; then cp .env.uat .env; fi
	flutter build ipa --flavor uat --release
	@echo "✅ IPA: build/ios/ipa"

build-ipa-prod:
	@echo "🍎 Building IPA for PROD..."
	@chmod +x $(FIREBASE_SCRIPT) 2>/dev/null || true
	@$(FIREBASE_SCRIPT) prod
	flutter clean
	flutter pub get
	cd ios && pod install && cd ..
	@if [ -f .env.prod ]; then cp .env.prod .env; fi
	flutter build ipa --flavor prod --release
	@echo "✅ IPA: build/ios/ipa"
