#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if flavor argument is provided
if [ -z "$1" ]; then
    print_error "Usage: ./scripts/setup_firebase_config.sh <flavor>"
    print_info "Example: ./scripts/setup_firebase_config.sh dev"
    exit 1
fi

FLAVOR=$1
GOOGLE_SERVICES_SOURCE="android/app/google-services-${FLAVOR}.json"
GOOGLE_SERVICES_DEST="android/app/src/${FLAVOR}/google-services.json"
FIREBASE_OPTIONS_FILE="lib/firebase_options.dart"

print_info "Updating Firebase configuration for flavor: ${FLAVOR}"

# Check if google-services file exists
if [ ! -f "$GOOGLE_SERVICES_SOURCE" ]; then
    print_error "File not found: $GOOGLE_SERVICES_SOURCE"
    exit 1
fi

# Copy flavor-specific google-services.json into the matching Android source set
print_info "Copying ${GOOGLE_SERVICES_SOURCE} to ${GOOGLE_SERVICES_DEST}"
mkdir -p "$(dirname "$GOOGLE_SERVICES_DEST")"
cp "$GOOGLE_SERVICES_SOURCE" "$GOOGLE_SERVICES_DEST"
if [ $? -eq 0 ]; then
    print_info "✅ Successfully copied google-services.json"
else
    print_error "Failed to copy google-services.json"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed. Please install it first:"
    print_info "  macOS: brew install jq"
    print_info "  Ubuntu/Debian: sudo apt-get install jq"
    exit 1
fi

print_info "Reading configuration from: $GOOGLE_SERVICES_SOURCE"

# Extract values from google-services.json
PROJECT_ID=$(jq -r '.project_info.project_id' "$GOOGLE_SERVICES_SOURCE")
PROJECT_NUMBER=$(jq -r '.project_info.project_number' "$GOOGLE_SERVICES_SOURCE")
STORAGE_BUCKET=$(jq -r '.project_info.storage_bucket' "$GOOGLE_SERVICES_SOURCE")

# Map flavor to expected Android package name
case "$FLAVOR" in
    dev)  EXPECTED_PACKAGE="com.vcare.admin.dev" ;;
    qa)   EXPECTED_PACKAGE="com.vcare.admin.qa" ;;
    uat)  EXPECTED_PACKAGE="com.vcare.admin.uat" ;;
    prod) EXPECTED_PACKAGE="com.vcare.admin" ;;
    *)    EXPECTED_PACKAGE="" ;;
esac

# Select Android client matching the flavor package name
ANDROID_CLIENT_INDEX=$(jq -r --arg pkg "$EXPECTED_PACKAGE" '
  .client | to_entries[] | select(.value.client_info.android_client_info.package_name == $pkg) | .key
' "$GOOGLE_SERVICES_SOURCE" | head -n 1)

if [ -z "$ANDROID_CLIENT_INDEX" ] || [ "$ANDROID_CLIENT_INDEX" = "null" ]; then
    print_warning "No Android client found for package: $EXPECTED_PACKAGE"
    print_warning "Falling back to first client in google-services.json"
    ANDROID_CLIENT_INDEX=0
fi

ANDROID_CLIENT_ID=$(jq -r ".client[$ANDROID_CLIENT_INDEX].client_info.mobilesdk_app_id" "$GOOGLE_SERVICES_SOURCE")
ANDROID_API_KEY=$(jq -r ".client[$ANDROID_CLIENT_INDEX].api_key[0].current_key" "$GOOGLE_SERVICES_SOURCE")
ANDROID_APP_ID=$(jq -r ".client[$ANDROID_CLIENT_INDEX].client_info.mobilesdk_app_id" "$GOOGLE_SERVICES_SOURCE")
ANDROID_PACKAGE_NAME=$(jq -r ".client[$ANDROID_CLIENT_INDEX].client_info.android_client_info.package_name" "$GOOGLE_SERVICES_SOURCE")

print_info "Extracted Android configuration:"
print_info "  Project ID: $PROJECT_ID"
print_info "  Package Name: $ANDROID_PACKAGE_NAME"
print_info "  App ID: $ANDROID_APP_ID"

# For iOS, we need to read from GoogleService-Info.plist
IOS_PLIST_SOURCE="ios/Runner/GoogleService-Info-${FLAVOR}.plist"
IOS_PLIST_DEST="ios/Runner/GoogleService-Info.plist"
IOS_APP_ID=""
IOS_CLIENT_ID=""
IOS_API_KEY=""
IOS_BUNDLE_ID=""
IOS_PROJECT_ID=""
IOS_STORAGE_BUCKET=""
IOS_GCM_SENDER_ID=""

if [ -f "$IOS_PLIST_SOURCE" ]; then
    print_info "Copying ${IOS_PLIST_SOURCE} to ${IOS_PLIST_DEST}"
    cp "$IOS_PLIST_SOURCE" "$IOS_PLIST_DEST"
    if [ $? -eq 0 ]; then
        print_info "✅ Successfully copied GoogleService-Info.plist"
    else
        print_warning "Failed to copy GoogleService-Info.plist"
    fi
    
    print_info "Reading iOS configuration from: $IOS_PLIST_SOURCE"
    
    # Check if plutil is available (macOS) or use a Python fallback
    if command -v plutil &> /dev/null; then
        # Convert plist to JSON temporarily
        TEMP_JSON=$(mktemp)
        plutil -convert json "$IOS_PLIST_SOURCE" -o "$TEMP_JSON"
        
        IOS_APP_ID=$(jq -r '.GOOGLE_APP_ID' "$TEMP_JSON")
        IOS_CLIENT_ID=$(jq -r '.CLIENT_ID // empty' "$TEMP_JSON")
        IOS_API_KEY=$(jq -r '.API_KEY' "$TEMP_JSON")
        IOS_BUNDLE_ID=$(jq -r '.BUNDLE_ID' "$TEMP_JSON")
        IOS_PROJECT_ID=$(jq -r '.PROJECT_ID // empty' "$TEMP_JSON")
        IOS_STORAGE_BUCKET=$(jq -r '.STORAGE_BUCKET // empty' "$TEMP_JSON")
        IOS_GCM_SENDER_ID=$(jq -r '.GCM_SENDER_ID // empty' "$TEMP_JSON")
        
        rm "$TEMP_JSON"
    else
        print_warning "plutil not found. Using Python to parse plist..."
        
        IOS_APP_ID=$(python3 -c "import plistlib; print(plistlib.load(open('$IOS_PLIST_SOURCE', 'rb'))['GOOGLE_APP_ID'])" 2>/dev/null || echo "")
        IOS_CLIENT_ID=$(python3 -c "import plistlib; print(plistlib.load(open('$IOS_PLIST_SOURCE', 'rb'))['CLIENT_ID'])" 2>/dev/null || echo "")
        IOS_API_KEY=$(python3 -c "import plistlib; print(plistlib.load(open('$IOS_PLIST_SOURCE', 'rb'))['API_KEY'])" 2>/dev/null || echo "")
        IOS_BUNDLE_ID=$(python3 -c "import plistlib; print(plistlib.load(open('$IOS_PLIST_SOURCE', 'rb'))['BUNDLE_ID'])" 2>/dev/null || echo "")
    fi
    
    print_info "Extracted iOS configuration:"
    print_info "  Bundle ID: $IOS_BUNDLE_ID"
    print_info "  App ID: $IOS_APP_ID"
else
    print_warning "iOS plist file not found: $IOS_PLIST_SOURCE"
    print_warning "iOS configuration will use default values"
fi

# Generate firebase_options.dart
print_info "Generating $FIREBASE_OPTIONS_FILE..."

cat > "$FIREBASE_OPTIONS_FILE" << EOF
// File generated by update_firebase_config.sh - DO NOT EDIT MANUALLY
// Generated for flavor: ${FLAVOR}
// Generated at: $(date)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// \`\`\`dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// \`\`\`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${ANDROID_API_KEY}',
    appId: '${ANDROID_APP_ID}',
    messagingSenderId: '${PROJECT_NUMBER}',
    projectId: '${PROJECT_ID}',
    storageBucket: '${STORAGE_BUCKET}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${IOS_API_KEY:-${ANDROID_API_KEY}}',
    appId: '${IOS_APP_ID:-${ANDROID_APP_ID}}',
    messagingSenderId: '${IOS_GCM_SENDER_ID:-${PROJECT_NUMBER}}',
    projectId: '${IOS_PROJECT_ID:-${PROJECT_ID}}',
    storageBucket: '${IOS_STORAGE_BUCKET:-${STORAGE_BUCKET}}',
    iosBundleId: '${IOS_BUNDLE_ID:-${EXPECTED_PACKAGE}}',
  );
}
EOF

print_info "${GREEN}✅ Successfully generated $FIREBASE_OPTIONS_FILE${NC}"
print_info "Firebase configuration updated for flavor: ${FLAVOR}"
