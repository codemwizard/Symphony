#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="evidence/phase1/hardening/tsk_hard_000.json"

source "$ROOT_DIR/scripts/lib/evidence.sh"

required=(
  "docs/programs/symphony-hardening/CHARTER.md"
  "docs/programs/symphony-hardening/SCOPE.md"
  "docs/programs/symphony-hardening/DECISION_LOG.md"
  "docs/programs/symphony-hardening/MASTER_PLAN.md"
  "docs/programs/symphony-hardening/WAVE_PLAN.md"
  "docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"
)

for f in "${required[@]}"; do
  [[ -s "$ROOT_DIR/$f" ]] || { echo "missing_or_empty:$f" >&2; exit 1; }
done

if ! rg -q "Program Owner:" "$ROOT_DIR/docs/programs/symphony-hardening/CHARTER.md"; then
  echo "missing_program_owner" >&2
  exit 1
fi
if ! rg -q "Approval Authority:" "$ROOT_DIR/docs/programs/symphony-hardening/CHARTER.md"; then
  echo "missing_approval_authority" >&2
  exit 1
fi

hard_invariant_count=$(rg -c '^- INV-HARD-' "$ROOT_DIR/docs/programs/symphony-hardening/CHARTER.md" || true)
if [[ "$hard_invariant_count" -lt 12 ]]; then
  echo "insufficient_hard_invariants:$hard_invariant_count" >&2
  exit 1
fi

expected_order=(
  "TSK-HARD-000" "TSK-HARD-001" "TSK-HARD-002" "TSK-HARD-010" "TSK-HARD-011"
  "TSK-HARD-011A" "TSK-HARD-012" "TSK-HARD-013" "TSK-HARD-014" "TSK-HARD-015"
  "TSK-HARD-016" "TSK-HARD-017" "TSK-HARD-094" "TSK-HARD-101" "TSK-HARD-013B"
  "TSK-OPS-A1-STABILITY-GATE" "TSK-OPS-WAVE1-EXIT-GATE"
)

mapfile -t actual_order < <(awk '/^## Wave 1 Canonical Order/{flag=1;next}/^## /{flag=0}flag && /^- TSK-/{sub(/^- /,""); print}' "$ROOT_DIR/docs/programs/symphony-hardening/WAVE_PLAN.md")

if [[ "${#actual_order[@]}" -ne "${#expected_order[@]}" ]]; then
  echo "wave1_order_count_mismatch" >&2
  exit 1
fi
for i in "${!expected_order[@]}"; do
  [[ "${expected_order[$i]}" == "${actual_order[$i]}" ]] || { echo "wave1_order_mismatch_at:$i" >&2; exit 1; }
done

if ! rg -q '^\| TSK-HARD-013B \|' "$ROOT_DIR/docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"; then
  echo "missing_013b_row" >&2
  exit 1
fi
if rg -q '^\| TSK-HARD-013 \|.*(orphan|replay)' "$ROOT_DIR/docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"; then
  echo "invalid_013_orphan_replay_mapping" >&2
  exit 1
fi
if ! rg -q 'Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md' "$ROOT_DIR/tasks/TSK-HARD-000/EXEC_LOG.md"; then
  echo "missing_exec_log_canonical_reference" >&2
  exit 1
fi

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")"
python3 - <<'PY' "$ROOT_DIR/$EVIDENCE_PATH" "$hard_invariant_count" "$(evidence_now_utc)" "$(git_sha)"
import json
import sys
from pathlib import Path
p, inv_count, ts, sha = sys.argv[1:]
payload = {
  "check_id": "TSK-HARD-000",
  "task_id": "TSK-HARD-000",
  "status": "PASS",
  "pass": True,
  "timestamp_utc": ts,
  "git_sha": sha,
  "details": {
    "charter_exists": True,
    "scope_exists": True,
    "decision_log_exists": True,
    "master_plan_exists": True,
    "wave_plan_order_ok": True,
    "traceability_matrix_exists": True,
    "hard_invariant_count": int(inv_count),
    "contains_013b_row": True
  }
}
Path(p).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
PY

echo "TSK-HARD-000 verifier: PASS"
echo "Evidence: $ROOT_DIR/$EVIDENCE_PATH"
