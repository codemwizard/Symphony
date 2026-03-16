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

if [ ${#missing[@]} -gt 0 ]; then
  {
    echo "{"
    echo "  \"task_id\": \"TSK-P1-DEMO-017\","
    echo "  \"status\": \"FAIL\","
    echo "  \"runbook\": \"$RUNBOOK\","
    echo "  \"missing_sections\": ["
    for i in "${!missing[@]}"; do
      sep=","
      if [ "$i" -eq "$((${#missing[@]} - 1))" ]; then sep=""; fi
      echo "    \"${missing[$i]}\"$sep"
    done
    echo "  ]"
    echo "}"
  } > "$EVIDENCE"
  echo "TSK-P1-DEMO-017 verification failed. Missing sections: ${missing[*]}"
  exit 1
fi

cat > "$EVIDENCE" <<JSON
{
  "task_id": "TSK-P1-DEMO-017",
  "status": "PASS",
  "runbook": "$RUNBOOK",
  "checks": [
    "purpose_present",
    "provisioning_procedure_present",
    "required_inputs_present",
    "isolation_verification_present",
    "completion_checklist_present"
  ]
}
JSON

echo "TSK-P1-DEMO-017 verification passed. Evidence: $EVIDENCE"
