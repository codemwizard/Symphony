#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
source scripts/audit/lib/git_diff_dev.sh

echo "==> Preflight (staged): structural detector + Rule 1 linkage"

MANIFEST="docs/invariants/INVARIANTS_MANIFEST.yml"
DOCS_DIR="docs/invariants"
EXCEPTIONS_DIR="docs/invariants/exceptions"

# Cross-platform temp directory
if [[ -n "${TEMP:-}" ]]; then
  TEMP_DIR="${TEMP}/invariants_preflight"
elif [[ -n "${TMP:-}" ]]; then
  TEMP_DIR="${TMP}/invariants_preflight"
else
  TEMP_DIR="/tmp/invariants_preflight"
fi

mkdir -p "$TEMP_DIR"

# Staged diff (pre-commit)
git_write_unified_diff_staged "$TEMP_DIR/staged.diff" 0

if [[ ! -s "$TEMP_DIR/staged.diff" ]]; then
  echo "No staged changes; skipping."
  exit 0
fi

# Structural detector (same logic as CI, but pointed at staged diff)
python3 scripts/audit/detect_structural_changes.py \
  --diff-file "$TEMP_DIR/staged.diff" \
  --out "$TEMP_DIR/detect.json"

structural="$(python3 -c "import json; d=json.load(open('$TEMP_DIR/detect.json')); print('true' if d.get('structural_change') else 'false')")"
primary="$(python3 -c "import json; d=json.load(open('$TEMP_DIR/detect.json')); print(d.get('primary_reason','other'))")"
types="$(python3 -c "import json; d=json.load(open('$TEMP_DIR/detect.json')); print(','.join(d.get('reason_types',[])))")"

if [[ -z "$types" ]]; then
  types="none"
fi

echo "structural_change=$structural primary_reason=$primary reason_types=$types"

if [[ "$structural" != "true" ]]; then
  echo "✅ No structural change detected."
  exit 0
fi

echo "⚠️ Structural change detected. Checking Rule 1 requirements…"

# Determine staged changed files
changed_files="$(git_changed_files_staged)"

manifest_changed=0
echo "${changed_files}" | grep -qx "${MANIFEST}" && manifest_changed=1 || true

docs_changed=0
inv_token_present=0
if echo "${changed_files}" | grep -q "^${DOCS_DIR}/"; then
  docs_changed=1
  docs_diff_file="$TEMP_DIR/docs.diff"
  git_write_unified_diff_staged_path "${DOCS_DIR}" "$docs_diff_file" 0
  if grep -Eo 'INV-[0-9]{3}' "$docs_diff_file" >/dev/null; then
    inv_token_present=1
  fi
fi

exception_present=0
if echo "${changed_files}" | grep -q "^${EXCEPTIONS_DIR}/"; then
  exception_present=1
fi

# If exception present, validate it (same validator CI uses)
if [[ "${exception_present}" -eq 1 ]]; then
  if [[ -x scripts/audit/verify_exception_template.sh ]]; then
    scripts/audit/verify_exception_template.sh
  fi
fi

# Rule satisfied cases
if [[ "${manifest_changed}" -eq 1 ]]; then
  echo "✅ Rule 1 satisfied: manifest updated (${MANIFEST})."
  exit 0
fi

if [[ "${docs_changed}" -eq 1 && "${inv_token_present}" -eq 1 ]]; then
  echo "✅ Rule 1 satisfied: docs updated with INV-### token(s)."
  exit 0
fi

if [[ "${exception_present}" -eq 1 ]]; then
  echo "⚠️  Rule 1 bypassed via exception file(s) under ${EXCEPTIONS_DIR}."
  exit 0
fi

echo "❌ Rule 1 would fail in CI. Structural change detected without invariants linkage."
echo ""
echo "ACTION REQUIRED: You must manually document the invariants linkage or create a proper exception."
echo "Auto-generation of EXC-* bypass files has been disabled to enforce strict governance."
exit 1
