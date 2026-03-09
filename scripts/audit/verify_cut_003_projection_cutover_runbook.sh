#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNBOOK="$ROOT_DIR/docs/operations/PHASE1_PROJECTION_CUTOVER_RUNBOOK.md"
EVIDENCE="$ROOT_DIR/evidence/phase1/cut_003_projection_cutover_runbook.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"

for section in '## Preconditions' '## Freeze Point' '## Cutover Sequence' '## Stop Conditions' '## Rollback' '## Evidence Outputs'; do
  rg -n "^${section}$" "$RUNBOOK" >/dev/null
done
! rg -n 'dual-write|compatibility shim' "$RUNBOOK" >/dev/null
rg -n 'verify_cut_004_projection_cutover_gate\.sh' "$RUNBOOK" >/dev/null

python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id': 'CUT-003-PROJECTION-CUTOVER-RUNBOOK',
        'task_id': 'CUT-003',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status': 'PASS',
        'runbook_complete': True,
        'rollback_defined': True
    }, fh, indent=2)
    fh.write('\n')
PY
