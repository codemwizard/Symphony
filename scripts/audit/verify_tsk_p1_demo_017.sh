#!/usr/bin/env bash
set -euo pipefail

RUNBOOK="docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md"
EVIDENCE="evidence/phase1/tsk_p1_demo_017_provisioning_runbook.json"

required_patterns=(
  "Purpose"
  "Provisioning Procedure"
  "Required Inputs"
  "isolation verification before go-live"
  "Completion Checklist"
)

missing=()
for p in "${required_patterns[@]}"; do
  if ! rg -n "$p" "$RUNBOOK" >/dev/null 2>&1; then
    missing+=("$p")
  fi
done

mkdir -p "$(dirname "$EVIDENCE")"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -f "$ROOT_DIR/scripts/lib/evidence.sh" ]; then
  source "$ROOT_DIR/scripts/lib/evidence.sh"
else
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { [ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ; }
fi

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

STATUS="PASS"
if [ ${#missing[@]} -gt 0 ]; then
  STATUS="FAIL"
fi

python3 - <<PY
import json
import os

missing_str = "$*"
missing = missing_str.split() if missing_str else []

payload = {
  "check_id": "TSK-P1-DEMO-017",
  "timestamp_utc": "$TS_UTC",
  "git_sha": "$GIT_SHA",
  "schema_fingerprint": "$SCHEMA_FP",
  "status": "$STATUS",
  "runbook": "$RUNBOOK",
  "missing_sections": [
$(for i in "${!missing[@]}"; do echo "    \"${missing[$i]}\","; done)
  ],
  "checks": [
    "purpose_present",
    "provisioning_procedure_present",
    "required_inputs_present",
    "isolation_verification_present",
    "completion_checklist_present"
  ]
}

with open("$ROOT_DIR/$EVIDENCE", "w") as f:
  json.dump(payload, f, indent=2)
PY

if [ "$STATUS" == "FAIL" ]; then
  echo "TSK-P1-DEMO-017 verification failed. Missing sections: ${missing[*]}"
  exit 1
fi

echo "TSK-P1-DEMO-017 verification passed. Evidence: $EVIDENCE"
