#!/usr/bin/env bash
# Generates web diff artifacts for UI sync audits.
# Usage: ./scripts/sync_audit.sh [FROM_COMMIT] [TO_COMMIT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="${WEB_ROOT:-$(cd "$FLUTTER_ROOT/../vcareAdmin-web/vcare-agent-app-2.0" && pwd)}"
SYNC_DIR="$FLUTTER_ROOT/docs/sync"

FROM_COMMIT="${1:-$(cat "$SYNC_DIR/vcare_last_synced_commit.txt" 2>/dev/null || echo 'HEAD~20')}"
TO_COMMIT="${2:-HEAD}"

mkdir -p "$SYNC_DIR"

if [[ ! -d "$WEB_ROOT" ]]; then
  echo "Web root not found: $WEB_ROOT" >&2
  exit 1
fi

cd "$WEB_ROOT"

git log --oneline "${FROM_COMMIT}..${TO_COMMIT}" \
  > "$SYNC_DIR/last_sync_commit_log.txt" 2>/dev/null || true

git diff --name-only "${FROM_COMMIT}..${TO_COMMIT}" \
  -- src/index.css src/components src/features src/pages \
  > "$SYNC_DIR/last_sync_changed_files.txt" 2>/dev/null || true

git diff "${FROM_COMMIT}..${TO_COMMIT}" \
  -- src/index.css src/components src/features src/pages \
  > "$SYNC_DIR/last_sync_web.diff" 2>/dev/null || true

cat > "$SYNC_DIR/last_sync_meta.env" <<EOF
FROM_COMMIT=${FROM_COMMIT}
TO_COMMIT=${TO_COMMIT}
FEATURE_SCOPE=ui,theme,auth,referral
WEB_ROOT=${WEB_ROOT}
FLUTTER_ROOT=${FLUTTER_ROOT}
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "Sync audit written to $SYNC_DIR"
echo "  FROM: $FROM_COMMIT"
echo "  TO:   $TO_COMMIT"
echo "  Changed files: $(wc -l < "$SYNC_DIR/last_sync_changed_files.txt" | tr -d ' ')"
