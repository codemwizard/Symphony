#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/baseline_governance.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

BASE_REF="${BASE_REF:-refs/remotes/origin/main}"
HEAD_REF="${HEAD_REF:-HEAD}"
source "$ROOT_DIR/scripts/audit/lib/git_diff_range_only.sh"
BASE_REF="${BASE_REF:-$(git_resolve_base_ref)}"

if ! git_ensure_ref "$BASE_REF"; then
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "BASELINE-GOVERNANCE",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "reason": "BASE_REF not found",
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2))
PY
  echo "❌ BASE_REF not found; cannot enforce baseline governance (fail-closed)" >&2
  exit 1
fi

changed_files="$(git_changed_files_range "$BASE_REF" "$HEAD_REF")"

baseline_changed=false
migration_changed=false
adr_changed=false

# Use line-exact matching to avoid edge cases with large diff lists and newline handling.
if grep -qx "schema/baseline.sql" <<<"$changed_files"; then
  baseline_changed=true
fi

if grep -qE "^schema/migrations/.*\\.sql$" <<<"$changed_files"; then
  migration_changed=true
fi

if grep -qx "docs/decisions/ADR-0010-baseline-policy.md" <<<"$changed_files"; then
  adr_changed=true
fi

status="PASS"
reason=""
if [[ "$baseline_changed" == "true" ]]; then
  if [[ "$migration_changed" != "true" || "$adr_changed" != "true" ]]; then
    status="FAIL"
    reason="baseline changed without required migration + ADR update"
  fi
fi

BASELINE_CHANGED="$baseline_changed" MIGRATION_CHANGED="$migration_changed" ADR_CHANGED="$adr_changed" STATUS="$status" REASON="$reason" BASE_REF="$BASE_REF" HEAD_REF="$HEAD_REF" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

def to_bool(val: str) -> bool:
    return str(val).lower() == "true"

out = {
  "check_id": "BASELINE-GOVERNANCE",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ.get("STATUS", "PASS"),
  "baseline_changed": to_bool(os.environ.get("BASELINE_CHANGED", "false")),
  "migration_changed": to_bool(os.environ.get("MIGRATION_CHANGED", "false")),
  "adr_changed": to_bool(os.environ.get("ADR_CHANGED", "false")),
  "reason": os.environ.get("REASON", ""),
  "base_ref": os.environ.get("BASE_REF", ""),
  "head_ref": os.environ.get("HEAD_REF", ""),
}
Path(os.environ.get("EVIDENCE_FILE", "")).write_text(json.dumps(out, indent=2))
PY

if [[ "$status" == "FAIL" ]]; then
  echo "❌ Baseline governance failed: $reason" >&2
  exit 1
fi

echo "Baseline governance check passed. Evidence: $EVIDENCE_FILE"
