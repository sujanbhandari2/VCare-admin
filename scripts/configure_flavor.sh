#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

if [ -z "${1:-}" ]; then
  print_error "Usage: ./scripts/configure_flavor.sh <flavor>"
  print_info "Valid flavors: dev, qa, uat, prod"
  exit 1
fi

FLAVOR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

case "${FLAVOR}" in
  dev|qa|uat|prod) ;;
  *)
    print_error "Invalid flavor: ${FLAVOR}"
    print_info "Valid flavors: dev, qa, uat, prod"
    exit 1
    ;;
esac

cd "${PROJECT_ROOT}"

ENV_SOURCE=".env.${FLAVOR}"
ENV_DEST=".env"

if [ ! -f "${ENV_SOURCE}" ]; then
  print_error "Missing ${ENV_SOURCE}"
  print_info "Run: make setup-env"
  print_info "Then update values in ${ENV_SOURCE}"
  exit 1
fi

print_info "Configuring flavor: ${FLAVOR}"
cp "${ENV_SOURCE}" "${ENV_DEST}"
print_info "Copied ${ENV_SOURCE} -> ${ENV_DEST}"

FIREBASE_SCRIPT="${PROJECT_ROOT}/scripts/setup_firebase_config.sh"
if [ ! -x "${FIREBASE_SCRIPT}" ]; then
  chmod +x "${FIREBASE_SCRIPT}"
fi

"${FIREBASE_SCRIPT}" "${FLAVOR}"

if command -v flutter >/dev/null 2>&1; then
  print_info "Running flutter pub get..."
  flutter pub get
else
  print_warning "flutter not found in PATH; skipped flutter pub get"
fi

print_info "Flavor ${FLAVOR} configured successfully"
