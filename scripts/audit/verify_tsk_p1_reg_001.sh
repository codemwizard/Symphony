#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-REG-001"
EVIDENCE_PATH="evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json"
QUERIES_FILE="scripts/audit/sql/boz_reconstruction_queries.sql"
MIGRATION_FILE="schema/migrations/0025_boz_observability_role.sql"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$QUERIES_FILE" ]] || { echo "missing:$QUERIES_FILE" >&2; exit 1; }
[[ -f "$MIGRATION_FILE" ]] || { echo "missing:$MIGRATION_FILE" >&2; exit 1; }

role_declared=false
if rg -n "CREATE ROLE boz_auditor|CREATE ROLE symphony_auditor_boz|GRANT .* TO boz_auditor|GRANT .* TO symphony_auditor_boz" "$MIGRATION_FILE" >/dev/null; then
  role_declared=true
fi

read_only_markers=false
if rg -n "REVOKE|GRANT SELECT|NOLOGIN" "$MIGRATION_FILE" >/dev/null; then
  read_only_markers=true
fi

reconstruction_queries_present=false
if rg -n "ingress_attestations|payment_outbox_attempts|instruction_settlement_finality|instruction_id|correlation_id" "$QUERIES_FILE" >/dev/null; then
  reconstruction_queries_present=true
fi

runtime_dml_denied="not_run"
runtime_reconstruction_ok="not_run"
if [[ -n "${DATABASE_URL:-}" ]]; then
  set +e
  dml_probe=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -t -A <<'SQL' 2>&1
DO $$
BEGIN
  BEGIN
    EXECUTE 'SET ROLE boz_auditor';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'SET_ROLE_FAILED';
  END;
  BEGIN
    EXECUTE 'INSERT INTO public.external_proofs(proof_type, proof_ref, payload_hash) VALUES (''probe'',''probe'',''probe'')';
    RAISE NOTICE 'UNEXPECTED_DML_ALLOWED';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'DML_DENIED';
  END;
  RESET ROLE;
END $$;
SQL
)
  rc=$?
  set -e
  if [[ $rc -eq 0 && "$dml_probe" == *"DML_DENIED"* ]]; then
    runtime_dml_denied="true"
  else
    runtime_dml_denied="false"
  fi

  set +e
  recon_probe=$(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -t -A -c "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('ingress_attestations','payment_outbox_attempts','instruction_settlement_finality') LIMIT 1;" 2>&1)
  rc=$?
  set -e
  if [[ $rc -eq 0 && "$recon_probe" == *"1"* ]]; then
    runtime_reconstruction_ok="true"
  else
    runtime_reconstruction_ok="false"
  fi
fi

status="PASS"
if [[ "$role_declared" != "true" || "$read_only_markers" != "true" || "$reconstruction_queries_present" != "true" ]]; then
  status="FAIL"
fi
if [[ "$runtime_dml_denied" == "false" || "$runtime_reconstruction_ok" == "false" ]]; then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$status" "$role_declared" "$read_only_markers" "$reconstruction_queries_present" "$runtime_dml_denied" "$runtime_reconstruction_ok"
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

task_id, evidence_path, status, role_declared, read_only_markers, reconstruction_queries_present, runtime_dml_denied, runtime_reconstruction_ok = sys.argv[1:]

def git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

payload = {
    "check_id": "REG-001-BOZ-OBSERVABILITY-READONLY",
    "task_id": task_id,
    "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "git_sha": git_sha(),
    "status": status,
    "pass": status == "PASS",
    "details": {
      "role_declared": role_declared == "true",
      "read_only_markers": read_only_markers == "true",
      "reconstruction_queries_present": reconstruction_queries_present == "true",
      "runtime_dml_denied": runtime_dml_denied,
      "runtime_reconstruction_ok": runtime_reconstruction_ok,
      "reconstruction_queries_file": "scripts/audit/sql/boz_reconstruction_queries.sql"
    }
}

Path(evidence_path).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"Evidence written: {evidence_path}")
PY
