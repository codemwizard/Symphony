#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_REPO="$(mktemp -d)"
FIRST_DIR="$(mktemp -d)"
SECOND_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO" "$FIRST_DIR" "$SECOND_DIR"' EXIT

cp -a "$ROOT/." "$TMP_REPO/"

run_suite() {
  local out_dir="$1"
  (
    cd "$TMP_REPO"
    mkdir -p .tmp_tsk_p1_253/phase0 "$out_dir/phase0"
    SYMPHONY_ENV=development SYMPHONY_EVIDENCE_DETERMINISTIC=1 REPORT_FILE=".tmp_tsk_p1_253/phase0/evidence_validation.json" bash scripts/audit/validate_evidence_schema.sh >/dev/null
    SYMPHONY_ENV=development SYMPHONY_EVIDENCE_DETERMINISTIC=1 OUT_FILE=".tmp_tsk_p1_253/phase0/evidence_schema_validation.json" bash scripts/audit/validate_evidence_json.sh >/dev/null
    SYMPHONY_ENV=development SYMPHONY_EVIDENCE_DETERMINISTIC=1 EVIDENCE_OUT=".tmp_tsk_p1_253/phase0/sqlstate_map_drift.json" bash scripts/audit/check_sqlstate_map_drift.sh >/dev/null
    cp .tmp_tsk_p1_253/phase0/evidence_validation.json "$out_dir/phase0/evidence_validation.json"
    cp .tmp_tsk_p1_253/phase0/evidence_schema_validation.json "$out_dir/phase0/evidence_schema_validation.json"
    cp .tmp_tsk_p1_253/phase0/sqlstate_map_drift.json "$out_dir/phase0/sqlstate_map_drift.json"
  )
}

run_suite "$FIRST_DIR"

(
  cd "$TMP_REPO"
  git config user.name "Codex"
  git config user.email "codex@example.invalid"
  mkdir -p docs/operations
  printf '%s\n' 'adjacent validation noise' > docs/operations/tsk_p1_253_adjacent_note.md
  git add docs/operations/tsk_p1_253_adjacent_note.md
  git -c core.hooksPath=/dev/null commit -m "test: adjacent doc change for TSK-P1-253" >/dev/null
)

run_suite "$SECOND_DIR"

cmp -s "$FIRST_DIR/phase0/evidence_validation.json" "$SECOND_DIR/phase0/evidence_validation.json"
cmp -s "$FIRST_DIR/phase0/evidence_schema_validation.json" "$SECOND_DIR/phase0/evidence_schema_validation.json"
cmp -s "$FIRST_DIR/phase0/sqlstate_map_drift.json" "$SECOND_DIR/phase0/sqlstate_map_drift.json"

python3 - <<'PY' "$FIRST_DIR/phase0/evidence_validation.json" "$FIRST_DIR/phase0/evidence_schema_validation.json" "$FIRST_DIR/phase0/sqlstate_map_drift.json"
import json
import sys

validation = json.load(open(sys.argv[1], encoding="utf-8"))
schema = json.load(open(sys.argv[2], encoding="utf-8"))
sqlstate = json.load(open(sys.argv[3], encoding="utf-8"))

if validation.get("status") != "PASS":
    raise SystemExit("validation status mismatch")
if schema.get("status") != "PASS":
    raise SystemExit("schema status mismatch")
if sqlstate.get("status") != "PASS":
    raise SystemExit("sqlstate status mismatch")

if validation.get("inputs", {}).get("phase0_dir", "").startswith("/"):
    raise SystemExit("validation phase0_dir still absolute")
if validation.get("outputs", {}).get("report_path", "").startswith("/"):
    raise SystemExit("validation report_path still absolute")
for checked_dir in schema.get("checked_dirs", []):
    if str(checked_dir).startswith("/"):
        raise SystemExit("schema checked_dirs still absolute")
print("ok")
PY

echo "test_evidence_validation_stability.sh passed"
