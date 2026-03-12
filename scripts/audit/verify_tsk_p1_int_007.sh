#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INT-007"
PLAN="docs/plans/phase1/TSK-P1-INT-007/PLAN.md"
EXEC_LOG="docs/plans/phase1/TSK-P1-INT-007/EXEC_LOG.md"
META="tasks/TSK-P1-INT-007/meta.yml"
EVIDENCE="evidence/phase1/tsk_p1_int_007_dr_bundle_generator.json"
GENERATOR="scripts/dr/generate_tsk_p1_int_007_bundle.sh"
VERIFY_PY="scripts/dr/verify_tsk_p1_int_007_bundle.py"

for f in "$PLAN" "$EXEC_LOG" "$META" "$GENERATOR" "$VERIFY_PY"; do
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

"$GENERATOR" "$EVIDENCE"
python3 "$VERIFY_PY"

echo "$TASK_ID verification passed. Evidence: $EVIDENCE"
