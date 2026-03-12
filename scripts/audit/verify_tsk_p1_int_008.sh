#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-008"
PLAN="docs/plans/phase1/TSK-P1-INT-008/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-008/EXEC_LOG.md"
META="tasks/TSK-P1-INT-008/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_008_offline_verification.json"
VERIFY_PY="scripts/dr/verify_tsk_p1_int_008_offline.py"

for f in "$PLAN" "$EXEC_LOG" "$META" "$VERIFY_PY"; do
  if [[ ! -f "$f" ]]; then
    echo "missing_required_file:$f" >&2
    exit 1
  fi
done

required_sections=("objective" "scope" "implementation_steps" "acceptance_criteria" "remediation_trace")
missing=()
for s in "${required_sections[@]}"; do
  if ! rg -n "^## ${s}$" "$PLAN" >/dev/null 2>&1; then
    missing+=("$s")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "$TASK_ID verification failed: missing plan sections (${missing[*]})" >&2
  exit 1
fi

python3 "$VERIFY_PY"

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
