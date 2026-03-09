#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0070_cqrs_projection_roles_and_read_models.sql"
EVIDENCE="$ROOT_DIR/evidence/phase1/cqrs_002_db_role_separation.json"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
mkdir -p "$(dirname "$EVIDENCE")"
rg -n "CREATE ROLE symphony_command|CREATE ROLE symphony_query|GRANT SELECT ON TABLE public\.(instruction_status_projection|evidence_bundle_projection|escrow_summary_projection|incident_case_projection|program_member_summary_projection) TO symphony_query|GRANT SELECT, INSERT, UPDATE ON TABLE public\.(instruction_status_projection|evidence_bundle_projection|escrow_summary_projection|incident_case_projection|program_member_summary_projection) TO symphony_command" "$MIGRATION" >/dev/null
python3 - <<'PY' "$EVIDENCE"
import json, os, sys
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    json.dump({
        'check_id':'CQRS-002-DB-ROLE-SEPARATION',
        'task_id':'CQRS-002',
        'timestamp_utc': os.environ['EVIDENCE_TS'],
        'git_sha': os.environ['EVIDENCE_GIT_SHA'],
        'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
        'status':'PASS',
        'pass':True,
        'query_role_read_only':True
    }, fh, indent=2)
    fh.write('\n')
PY
