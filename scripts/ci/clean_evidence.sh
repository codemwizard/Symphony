#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_DIR_PHASE1="$ROOT_DIR/evidence/phase1"

if [[ -z "$EVIDENCE_DIR" || "$EVIDENCE_DIR" == "/" || -z "$EVIDENCE_DIR_PHASE1" || "$EVIDENCE_DIR_PHASE1" == "/" ]]; then
  echo "ERROR: unsafe evidence dir(s): $EVIDENCE_DIR $EVIDENCE_DIR_PHASE1" >&2
  exit 1
fi

mkdir -p "$EVIDENCE_DIR"
mkdir -p "$EVIDENCE_DIR_PHASE1"

echo "🧹 Cleaning evidence directories: $EVIDENCE_DIR $EVIDENCE_DIR_PHASE1"

clean_generated_only() {
  local dir="$1"
  local path rel
  while IFS= read -r -d '' path; do
    rel="${path#"$ROOT_DIR"/}"
    if git -C "$ROOT_DIR" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      continue
    fi
    rm -f "$path"
  done < <(find "$dir" -type f -name '*.json' -print0)
}

clean_generated_only "$EVIDENCE_DIR"
clean_generated_only "$EVIDENCE_DIR_PHASE1"

mkdir -p "$EVIDENCE_DIR" "$EVIDENCE_DIR_PHASE1"
echo "✅ Evidence directory cleaned."
