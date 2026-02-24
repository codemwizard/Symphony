#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-003"
EVIDENCE_PATH="evidence/phase1/tsk_p1_hier_003__distribution_entities_tenant_denorm_ceilings.json"

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

run_bool_query "member_devices_table_exists" "member_devices table exists" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='member_devices');"

for col in tenant_id member_id device_id_hash iccid_hash status created_at; do
  run_bool_query "member_devices_col_${col}" "member_devices.${col} exists" \
    "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='member_devices' AND column_name='${col}');"
done

run_bool_query "status_check_exists" "status check enum-style restriction exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='member_devices' AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%status = ANY%');"

run_bool_query "unique_member_device" "UNIQUE(member_id, device_id_hash) exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype IN ('u','p') AND n.nspname='public' AND t.relname='member_devices' AND pg_get_constraintdef(c.oid) ILIKE '%(member_id, device_id_hash)%');"

run_bool_query "member_fk_exists" "member_devices.member_id FK to members(member_id)" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='public' AND t.relname='member_devices' AND (pg_get_constraintdef(c.oid) ILIKE '%FOREIGN KEY (member_id) REFERENCES members(member_id)%' OR pg_get_constraintdef(c.oid) ILIKE '%FOREIGN KEY (member_id) REFERENCES public.members(member_id)%'));"

run_bool_query "idx_tenant_member" "index (tenant_id, member_id) exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='member_devices' AND indexname='idx_member_devices_tenant_member');"

run_bool_query "idx_active_device" "partial index (tenant_id,device_id_hash) where status=ACTIVE exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='member_devices' AND indexname='idx_member_devices_active_device' AND indexdef ILIKE '%(tenant_id, device_id_hash)%' AND indexdef ILIKE '%WHERE (status = ''ACTIVE''::text)%');"

run_bool_query "idx_active_iccid" "partial index (tenant_id,iccid_hash) where iccid_hash is not null and status=ACTIVE exists" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='member_devices' AND indexname='idx_member_devices_active_iccid' AND indexdef ILIKE '%(tenant_id, iccid_hash)%' AND indexdef ILIKE '%iccid_hash IS NOT NULL%' AND indexdef ILIKE '%status = ''ACTIVE''::text%');"

plan_by_member=$("${PSQL_CMD[@]}" -X -A -t -v ON_ERROR_STOP=1 -c \
  "EXPLAIN (FORMAT JSON) SELECT member_id FROM public.member_devices WHERE tenant_id = '00000000-0000-0000-0000-000000000000'::uuid AND member_id = '00000000-0000-0000-0000-000000000000'::uuid LIMIT 1;" \
  | tr -d '\n')
plan_by_device=$("${PSQL_CMD[@]}" -X -A -t -v ON_ERROR_STOP=1 -c \
  "EXPLAIN (FORMAT JSON) SELECT member_id FROM public.member_devices WHERE tenant_id = '00000000-0000-0000-0000-000000000000'::uuid AND device_id_hash = 'dev' AND status = 'ACTIVE' LIMIT 1;" \
  | tr -d '\n')

status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<PY
import json, pathlib, datetime, os, subprocess
records = [json.loads(line) for line in pathlib.Path("$check_log").read_text().splitlines() if line.strip()]
query_plans = {
  "by_member": """$plan_by_member""",
  "active_by_device": """$plan_by_device""",
}
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
  "checks": records,
  "query_plan_examples": query_plans,
}
path = pathlib.Path("$EVIDENCE_PATH")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("Evidence written:", path)
if "$status" == "FAIL":
  raise SystemExit(1)
PY
