#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$ROOT/$path" ]] || fail "missing file: $path"
}

require_grep() {
  local pattern="$1"
  local path="$2"
  grep -Fq "$pattern" "$ROOT/$path" || fail "missing pattern '$pattern' in $path"
}

FILES=(
  "docs/PHASE4/README.md"
  "docs/PHASE4/PHASE4_CONTRACT.md"
  "docs/PHASE4/phase4_contract.yml"
  "docs/PHASE4/PHASE4_SOURCE_PACK.md"
  "docs/PHASE4/PHASE4_CAPABILITY_BOUNDARY.md"
  "docs/PHASE4/PHASE4_EXECUTION_SURFACE_MAP.md"
  "docs/PHASE4/PHASE4_MASTER_IMPLEMENTATION_PLAN.md"
  "docs/PHASE4/PHASE4_TASK_DAG.md"
  "docs/PHASE4/phase4_task_dag.yml"
  "docs/PHASE4/implementation_plans/README.md"
  "docs/PHASE4/implementation_plans/TSK-P4-CAP-001_settlement_finality_and_rate_authority.md"
  "docs/PHASE4/implementation_plans/TSK-P4-CAP-002_statutory_allocations_and_kill_criteria.md"
  "docs/PHASE5/README.md"
  "docs/PHASE5/phase5_contract.yml"
  "docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md"
)

for file in "${FILES[@]}"; do
  require_file "$file"
done

require_grep "Status: PREPARING TO OPEN" "docs/PHASE4/README.md"
require_grep "Phase 4 is constitutionally AI-free" "docs/PHASE4/PHASE4_CONTRACT.md"
require_grep "Phase 4 is AI-free." "docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md"
require_grep "phase: \"4\"" "docs/PHASE4/phase4_contract.yml"
require_grep "gate_flag: \"RUN_PHASE4_GATES=1\"" "docs/PHASE4/phase4_contract.yml"
require_grep "claimability: \"opening_prepared_not_open\"" "docs/PHASE4/phase4_contract.yml"
require_grep "ai_free: true" "docs/PHASE4/phase4_contract.yml"
require_grep "TSK-P4-CLEAN-001" "docs/PHASE4/PHASE4_MASTER_IMPLEMENTATION_PLAN.md"
require_grep "TSK-P4-WP-001" "docs/PHASE4/PHASE4_MASTER_IMPLEMENTATION_PLAN.md"
require_grep "TSK-P4-GOV-001" "docs/PHASE4/PHASE4_MASTER_IMPLEMENTATION_PLAN.md"
require_grep "task_id: TSK-P4-CLEAN-001" "docs/PHASE4/phase4_task_dag.yml"
require_grep "task_id: TSK-P4-WP-001" "docs/PHASE4/phase4_task_dag.yml"
require_grep "task_id: TSK-P4-GOV-001" "docs/PHASE4/phase4_task_dag.yml"
require_grep "claimability: \"non-claimable\"" "docs/PHASE5/phase5_contract.yml"
require_grep "rows: []" "docs/PHASE5/phase5_contract.yml"

row_count="$(grep -c '^  - invariant_id:' "$ROOT/docs/PHASE4/phase4_contract.yml")"
[[ "$row_count" -ge 6 ]] || fail "expected at least 6 Phase 4 contract rows, found $row_count"

echo "Phase 4 contract preparation: PASS"
