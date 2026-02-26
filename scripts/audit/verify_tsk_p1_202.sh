#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_SCHEMA="$ROOT_DIR/docs/architecture/evidence_schema.json"
TASK_ID="TSK-P1-202"
EVIDENCE_PATH="evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

happy=false
missing_contract_fail=false
zero_required_fail=false
missing_artifact_fail=false

HAPPY_ARTIFACT="$TMP_DIR/happy.json"
cat > "$HAPPY_ARTIFACT" <<'JSON'
{
  "check_id": "HAPPY-ARTIFACT",
  "timestamp_utc": "2026-02-26T00:00:00Z",
  "git_sha": "0000000000000000000000000000000000000000",
  "status": "PASS"
}
JSON
cat > "$TMP_DIR/happy_contract.yml" <<'YAML'
- invariant_id: "INV-HAPPY"
  status: "implemented"
  required: true
  gate_id: "INT-GX"
  verifier: "scripts/audit/verify_happy.sh"
  evidence_path: "__HAPPY_ARTIFACT__"
YAML
sed -i "s|__HAPPY_ARTIFACT__|$HAPPY_ARTIFACT|g" "$TMP_DIR/happy_contract.yml"
if PHASE1_CONTRACT_SPEC="$TMP_DIR/happy_contract.yml" EVIDENCE_SCHEMA_FILE="$REPO_SCHEMA" OUT_FILE="$TMP_DIR/happy_out.json" bash "$ROOT_DIR/scripts/audit/verify_phase1_closeout.sh" >/dev/null 2>&1; then
  happy=true
fi

if PHASE1_CONTRACT_SPEC="$TMP_DIR/no_contract.yml" OUT_FILE="$TMP_DIR/missing_contract.json" bash "$ROOT_DIR/scripts/audit/verify_phase1_closeout.sh" >/dev/null 2>&1; then
  missing_contract_fail=false
else
  missing_contract_fail=true
fi

cat > "$TMP_DIR/empty.yml" <<'YAML'
- invariant_id: "INV-EMPTY"
  status: "implemented"
  required: false
  gate_id: ""
  verifier: ""
  evidence_path: ""
YAML
if PHASE1_CONTRACT_SPEC="$TMP_DIR/empty.yml" OUT_FILE="$TMP_DIR/empty_out.json" bash "$ROOT_DIR/scripts/audit/verify_phase1_closeout.sh" >/dev/null 2>&1; then
  zero_required_fail=false
else
  zero_required_fail=true
fi

cat > "$TMP_DIR/missing_artifact.yml" <<'YAML'
- invariant_id: "INV-MISS"
  status: "implemented"
  required: true
  gate_id: "INT-GX"
  verifier: "scripts/audit/verify_missing.sh"
  evidence_path: "evidence/phase1/definitely_missing_closeout_artifact.json"
YAML
if PHASE1_CONTRACT_SPEC="$TMP_DIR/missing_artifact.yml" OUT_FILE="$TMP_DIR/missing_artifact_out.json" bash "$ROOT_DIR/scripts/audit/verify_phase1_closeout.sh" >/dev/null 2>&1; then
  missing_artifact_fail=false
else
  missing_artifact_fail=true
fi

status="FAIL"
if [[ "$happy" == "true" && "$missing_contract_fail" == "true" && "$zero_required_fail" == "true" && "$missing_artifact_fail" == "true" ]]; then
  status="PASS"
fi

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"
python3 - <<'PY' "$ROOT_DIR/$EVIDENCE_PATH" "$TASK_ID" "$status" "$happy" "$missing_contract_fail" "$zero_required_fail" "$missing_artifact_fail"
import json, sys
from pathlib import Path
p, task_id, status, happy, missing_contract_fail, zero_required_fail, missing_artifact_fail = sys.argv[1:]
payload = {
  "check_id": "TSK-P1-202-CLOSEOUT-VERIFIER-SCAFFOLD",
  "task_id": task_id,
  "status": status,
  "pass": status == "PASS",
  "happy_path_passed": happy == "true",
  "missing_contract_fail_closed": missing_contract_fail == "true",
  "zero_required_fail_closed": zero_required_fail == "true",
  "missing_artifact_fail_closed": missing_artifact_fail == "true",
}
Path(p).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

if [[ "$status" != "PASS" ]]; then
  echo "TSK-P1-202 verifier failed" >&2
  exit 1
fi

echo "Evidence written: $EVIDENCE_PATH"
