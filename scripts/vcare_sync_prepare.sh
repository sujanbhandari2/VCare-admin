#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VCAREAPP_ROOT="$(cd "${FLUTTER_ROOT}/../vcareapp" && pwd)"

SYNC_DIR="${FLUTTER_ROOT}/docs/sync"
PROMPTS_DIR="${FLUTTER_ROOT}/docs/prompts"
TRACKER_FILE="${SYNC_DIR}/vcare_last_synced_commit.txt"

CHANGED_FILES_FILE="${SYNC_DIR}/last_sync_changed_files.txt"
COMMIT_LOG_FILE="${SYNC_DIR}/last_sync_commit_log.txt"
WEB_DIFF_FILE="${SYNC_DIR}/last_sync_web.diff"
READY_PROMPT_FILE="${SYNC_DIR}/last_sync_prompt.md"
META_FILE="${SYNC_DIR}/last_sync_meta.env"

usage() {
  cat <<'EOF'
Prepare sync artifacts from vcareapp commit range.

Usage:
  bash scripts/vcare_sync_prepare.sh --to <commit> [--from <commit>] [--feature <home|all>]

Options:
  --to       Target commit in vcareapp (required)
  --from     Start commit in vcareapp (optional)
  --feature  Scope filter: home (default), find-care, home-full, or all
  --help     Show this help

Examples:
  bash scripts/vcare_sync_prepare.sh --to a1b2c3d --feature home
  bash scripts/vcare_sync_prepare.sh --from 123abcd --to a1b2c3d --feature all
EOF
}

info() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

die() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

read_tracker_commit() {
  if [[ ! -f "$1" ]]; then
    return 1
  fi
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { print $1; exit }
  ' "$1"
}

TO_COMMIT=""
FROM_COMMIT=""
FEATURE_SCOPE="home"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      TO_COMMIT="${2:-}"
      shift 2
      ;;
    --from)
      FROM_COMMIT="${2:-}"
      shift 2
      ;;
    --feature)
      FEATURE_SCOPE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ -n "${TO_COMMIT}" ]] || die "--to is required"
[[ "${FEATURE_SCOPE}" == "home" || "${FEATURE_SCOPE}" == "find-care" || "${FEATURE_SCOPE}" == "home-full" || "${FEATURE_SCOPE}" == "all" ]] \
  || die "--feature must be 'home', 'find-care', 'home-full', or 'all'"

[[ -d "${VCAREAPP_ROOT}" ]] || die "vcareapp path not found: ${VCAREAPP_ROOT}"
git -C "${VCAREAPP_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not a git repo: ${VCAREAPP_ROOT}"

git -C "${VCAREAPP_ROOT}" rev-parse --verify "${TO_COMMIT}^{commit}" >/dev/null 2>&1 \
  || die "Invalid --to commit: ${TO_COMMIT}"
TO_COMMIT="$(git -C "${VCAREAPP_ROOT}" rev-parse --short=12 "${TO_COMMIT}^{commit}")"

if [[ -z "${FROM_COMMIT}" ]]; then
  TRACKED_COMMIT="$(read_tracker_commit "${TRACKER_FILE}" || true)"
  if [[ -n "${TRACKED_COMMIT}" ]]; then
    FROM_COMMIT="${TRACKED_COMMIT}"
    info "Using tracker commit as --from: ${FROM_COMMIT}"
  else
    FROM_COMMIT="$(git -C "${VCAREAPP_ROOT}" rev-parse --short=12 "${TO_COMMIT}^")"
    warn "No tracker commit found. Falling back to parent commit: ${FROM_COMMIT}"
  fi
fi

git -C "${VCAREAPP_ROOT}" rev-parse --verify "${FROM_COMMIT}^{commit}" >/dev/null 2>&1 \
  || die "Invalid --from commit: ${FROM_COMMIT}"
FROM_COMMIT="$(git -C "${VCAREAPP_ROOT}" rev-parse --short=12 "${FROM_COMMIT}^{commit}")"

mkdir -p "${SYNC_DIR}" "${PROMPTS_DIR}"

if [[ "${FEATURE_SCOPE}" == "home" ]]; then
  # Keep this list explicit so sync stays focused and predictable.
  PATHSPEC=(
    "src/pages/Home.tsx"
    "src/features/home"
  )
elif [[ "${FEATURE_SCOPE}" == "find-care" ]]; then
  PATHSPEC=(
    "src/pages/ProviderDetail.tsx"
    "src/pages/MedicareProviderDetail.tsx"
    "src/pages/SavedProviders.tsx"
    "src/features/find-care"
  )
elif [[ "${FEATURE_SCOPE}" == "home-full" ]]; then
  PATHSPEC=(
    "src/pages/Home.tsx"
    "src/features/home"
    "src/components/PageHeader.tsx"
    "src/components/LocationBar.tsx"
    "src/components/TransactionReceiptDialog.tsx"
  )
else
  PATHSPEC=()
fi

info "Preparing sync artifacts"
info "vcareapp: ${VCAREAPP_ROOT}"
info "flutter:  ${FLUTTER_ROOT}"
info "range:    ${FROM_COMMIT}..${TO_COMMIT}"
info "scope:    ${FEATURE_SCOPE}"

if [[ ${#PATHSPEC[@]} -gt 0 ]]; then
  git -C "${VCAREAPP_ROOT}" diff --name-status "${FROM_COMMIT}..${TO_COMMIT}" -- "${PATHSPEC[@]}" > "${CHANGED_FILES_FILE}"
  git -C "${VCAREAPP_ROOT}" diff "${FROM_COMMIT}..${TO_COMMIT}" -- "${PATHSPEC[@]}" > "${WEB_DIFF_FILE}"
  git -C "${VCAREAPP_ROOT}" log --oneline "${FROM_COMMIT}..${TO_COMMIT}" -- "${PATHSPEC[@]}" > "${COMMIT_LOG_FILE}"
else
  git -C "${VCAREAPP_ROOT}" diff --name-status "${FROM_COMMIT}..${TO_COMMIT}" > "${CHANGED_FILES_FILE}"
  git -C "${VCAREAPP_ROOT}" diff "${FROM_COMMIT}..${TO_COMMIT}" > "${WEB_DIFF_FILE}"
  git -C "${VCAREAPP_ROOT}" log --oneline "${FROM_COMMIT}..${TO_COMMIT}" > "${COMMIT_LOG_FILE}"
fi

cat > "${META_FILE}" <<EOF
FROM_COMMIT=${FROM_COMMIT}
TO_COMMIT=${TO_COMMIT}
FEATURE_SCOPE=${FEATURE_SCOPE}
VCAREAPP_ROOT=${VCAREAPP_ROOT}
FLUTTER_ROOT=${FLUTTER_ROOT}
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

cat > "${READY_PROMPT_FILE}" <<EOF
Sync Flutter with vcareapp updates.

Source repo: ${VCAREAPP_ROOT}
Target repo: ${FLUTTER_ROOT}
Commit range: ${FROM_COMMIT}..${TO_COMMIT}
Feature scope: ${FEATURE_SCOPE}

Use these generated artifacts:
- ${CHANGED_FILES_FILE}
- ${COMMIT_LOG_FILE}
- ${WEB_DIFF_FILE}

Tasks:
1) Analyze web changes in this commit range.
2) Map each web change to Flutter equivalent files.
3) Implement only relevant parity updates in Flutter.
4) Follow architecture + naming conventions from \`Agents.md\`.
5) Run format/lint for modified Flutter files.
6) Summarize: synced items, intentionally skipped items, and manual follow-ups.
7) Do not change unrelated features.
EOF

if [[ ! -s "${CHANGED_FILES_FILE}" ]]; then
  warn "No scoped file changes found for ${FROM_COMMIT}..${TO_COMMIT}."
fi

info "Artifacts written:"
info "  ${CHANGED_FILES_FILE}"
info "  ${COMMIT_LOG_FILE}"
info "  ${WEB_DIFF_FILE}"
info "  ${READY_PROMPT_FILE}"
info "  ${META_FILE}"
info ""
info "Next:"
info "  1) Open ${READY_PROMPT_FILE}"
info "  2) Run it in Cursor to apply Flutter parity updates"
info "  3) After validation, update ${TRACKER_FILE} to: ${TO_COMMIT}"
