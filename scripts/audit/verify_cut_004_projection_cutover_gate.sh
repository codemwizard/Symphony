#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT_DIR/evidence/phase1/cut_004_projection_cutover_gate.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"

bash "$ROOT_DIR/scripts/db/verify_projection_freshness_and_scope.sh" >/dev/null
bash "$ROOT_DIR/scripts/audit/verify_no_hot_table_external_reads.sh" >/dev/null
bash "$ROOT_DIR/scripts/audit/verify_cut_001_one_shot_projection_cutover.sh" >/dev/null
bash "$ROOT_DIR/scripts/audit/verify_cut_002_query_surface_boundary.sh" >/dev/null
bash "$ROOT_DIR/scripts/audit/verify_cut_003_projection_cutover_runbook.sh" >/dev/null

for path in \
  "$ROOT_DIR/evidence/phase1/proj_001_initial_projection_set.json" \
  "$ROOT_DIR/evidence/phase1/proj_002_external_query_cutover.json" \
  "$ROOT_DIR/evidence/phase1/cut_001_one_shot_projection_cutover.json" \
  "$ROOT_DIR/evidence/phase1/cut_002_query_surface_boundary.json" \
  "$ROOT_DIR/evidence/phase1/cut_003_projection_cutover_runbook.json"; do
  [[ -f "$path" ]]
done

python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id': 'CUT-004-PROJECTION-CUTOVER-GATE',
        'task_id': 'CUT-004',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status': 'PASS',
        'validated_prerequisites': ['PROJ-001', 'PROJ-002', 'CUT-001', 'CUT-002', 'CUT-003']
    }, fh, indent=2)
    fh.write('\n')
PY
