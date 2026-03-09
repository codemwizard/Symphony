#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/cut_001_one_shot_projection_cutover.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"

required=(
  "$ROOT_DIR/tasks/PROJ-001/meta.yml"
  "$ROOT_DIR/tasks/PROJ-002/meta.yml"
  "$ROOT_DIR/tasks/CUT-001/meta.yml"
  "$ROOT_DIR/docs/plans/phase1/CUT-001/PLAN.md"
  "$ROOT_DIR/docs/PHASE1/phase1_contract.yml"
  "$ROOT_DIR/docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml"
)
for f in "${required[@]}"; do
  [[ -f "$f" ]]
done

! rg -n 'schema/v1' \
  "$ROOT_DIR/tasks/PROJ-001/meta.yml" \
  "$ROOT_DIR/tasks/PROJ-002/meta.yml" \
  "$ROOT_DIR/tasks/CUT-001/meta.yml" \
  "$ROOT_DIR/docs/plans/phase1/PROJ-001/PLAN.md" \
  "$ROOT_DIR/docs/plans/phase1/PROJ-002/PLAN.md" \
  "$ROOT_DIR/docs/plans/phase1/CUT-001/PLAN.md" >/dev/null

rg -n 'proj_002_external_query_cutover\.json|verify_no_hot_table_external_reads\.sh' \
  "$ROOT_DIR/tasks/PROJ-002/meta.yml" \
  "$ROOT_DIR/docs/plans/phase1/PROJ-002/PLAN.md" \
  "$ROOT_DIR/docs/PHASE1/phase1_contract.yml" >/dev/null

bash "$ROOT_DIR/scripts/audit/verify_no_hot_table_external_reads.sh" >/dev/null

python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id': 'CUT-001-ONE-SHOT-PROJECTION-CUTOVER',
        'task_id': 'CUT-001',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status': 'PASS',
        'legacy_refs_removed': True,
        'proj_002_prereq_pass': True
    }, fh, indent=2)
    fh.write('\n')
PY
