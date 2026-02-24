#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-004"
EVIDENCE_PATH="evidence/phase1/tsk_p1_hier_004__person_model_explicit_enrollment.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

PSQL_CMD=(psql)
if [[ -n "${DATABASE_URL:-}" ]]; then
  PSQL_CMD+=("$DATABASE_URL")
elif [[ -n "${PGHOST:-}" ]]; then
  :
fi
PSQL_OPTS=("-X" "-A" "-t" "-v" "ON_ERROR_STOP=1" "-c")
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

check_log="$TMPDIR/checks.ndjson"
errors=0

record_check() {
  local status="$1"
  local check_id="$2"
  local detail="$3"
  printf '{"check_id":"%s","status":"%s","detail":"%s"}' "$check_id" "$status" "$detail" >> "$check_log"
  printf '\n' >> "$check_log"
  if [[ "$status" == "FAIL" ]]; then
    errors=$((errors + 1))
  fi
}

run_bool_query() {
  local check_id="$1"
  local detail="$2"
  local sql="$3"
  local result
  result=$("${PSQL_CMD[@]}" "${PSQL_OPTS[@]}" "$sql")
  result=${result//$'\n'/}
  if [[ "$result" == "t" ]]; then
    record_check PASS "$check_id" "$detail"
  else
    record_check FAIL "$check_id" "$detail"
  fi
}

run_bool_query "events_table_exists" "member_device_events table exists" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='member_device_events');"

for col in tenant_id member_id instruction_id device_id_hash iccid_hash event_type observed_at device_id; do
  run_bool_query "events_col_${col}" "member_device_events.${col} exists" \
    "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='member_device_events' AND column_name='${col}');"
done

run_bool_query "instruction_id_type_text" "member_device_events.instruction_id is TEXT" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='member_device_events' AND column_name='instruction_id' AND data_type='text');"

run_bool_query "ingress_fk_exists" "FK anchors to ingress_attestations with instruction_id" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='public' AND t.relname='member_device_events' AND pg_get_constraintdef(c.oid) ILIKE '%REFERENCES ingress_attestations(tenant_id, instruction_id)%');"

run_bool_query "device_id_check_exists" "CHECK exists for device_id NULL iff unregistered/revoked event types" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='c' AND n.nspname='public' AND t.relname='member_device_events' AND pg_get_constraintdef(c.oid) ILIKE '%device_id IS NULL%' AND pg_get_constraintdef(c.oid) ILIKE '%UNREGISTERED_DEVICE%' AND pg_get_constraintdef(c.oid) ILIKE '%REVOKED_DEVICE_ATTEMPT%');"

run_bool_query "append_only_trigger_exists" "append-only trigger exists on member_device_events" \
  "SELECT EXISTS(SELECT 1 FROM pg_trigger tg JOIN pg_class t ON t.oid=tg.tgrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='member_device_events' AND tg.tgname='trg_deny_member_device_events_mutation' AND NOT tg.tgisinternal);"

status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<PY
import json, pathlib, datetime, os, subprocess
records = [json.loads(line) for line in pathlib.Path("$check_log").read_text().splitlines() if line.strip()]
git_sha = os.environ.get("GIT_SHA")
if not git_sha:
  try:
    git_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
  except Exception:
    git_sha = "UNKNOWN"
result = {
  "check_id": "$TASK_ID",
  "task_id": "$TASK_ID",
  "status": "$status",
  "pass": "$status" == "PASS",
  "git_sha": git_sha,
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP", ""),
  "timestamp_utc": datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
  "errors": $errors,
  "checks": records
}
path = pathlib.Path("$EVIDENCE_PATH")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("Evidence written:", path)
if "$status" == "FAIL":
  raise SystemExit(1)
PY
