#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-HIER-002"
EVIDENCE_PATH="evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json"

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

run_bool_query "persons_table_exists" "persons table exists" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='persons');"
run_bool_query "members_table_exists" "members table exists" \
  "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='members');"

# columns
for col in tenant_id person_id person_ref_hash status created_at updated_at; do
  run_bool_query "person_column_${col}" "persons.${col} present" \
    "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='persons' AND column_name='${col}');"
done
for col in tenant_id member_id tenant_member_id person_id entity_id member_ref_hash kyc_status enrolled_at status ceiling_amount_minor ceiling_currency metadata; do
  run_bool_query "member_column_${col}" "members.${col} present" \
    "SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='members' AND column_name='${col}');"
done

# check constraints existence
run_bool_query "person_status_check" "persons.status CHECK constraint" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='persons' AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%status = ANY (%');"
run_bool_query "member_status_check" "members.status CHECK constraint" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='members' AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%status = ANY (%');"
run_bool_query "member_kyc_status_check" "members.kyc_status CHECK constraint" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='public' AND t.relname='members' AND c.contype='c' AND pg_get_constraintdef(c.oid) LIKE '%kyc_status = ANY (%');"

run_bool_query "person_unique_idx" "persons unique tenant+person index" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='persons' AND indexname='idx_persons_tenant_ref');"
run_bool_query "member_unique_idx" "members unique tenant/member_ref index" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='members' AND indexname='idx_members_tenant_member_ref');"
run_bool_query "member_entity_index" "members entity/status active index" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='members' AND indexname='idx_members_entity_active');"
run_bool_query "member_entity_ref_index" "members entity/member_ref active index" \
  "SELECT EXISTS(SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='members' AND indexname='idx_members_entity_member_ref_active');"

# foreign keys
run_bool_query "members_person_fk" "members.person_id FK to persons" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='public' AND t.relname='members' AND pg_get_constraintdef(c.oid) ILIKE '%FOREIGN KEY (person_id) REFERENCES %persons(person_id)%');"
run_bool_query "members_tenant_member_fk" "members.tenant_member_id FK" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='public' AND t.relname='members' AND pg_get_constraintdef(c.oid) ILIKE '%FOREIGN KEY (tenant_member_id) REFERENCES %tenant_members(member_id)%');"
run_bool_query "members_program_fk" "members.entity_id FK to programs" \
  "SELECT EXISTS(SELECT 1 FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f' AND n.nspname='public' AND t.relname='members' AND pg_get_constraintdef(c.oid) ILIKE '%FOREIGN KEY (entity_id) REFERENCES %programs(program_id)%');"

# concluded
status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

if [[ ! -d "$(dirname "$EVIDENCE_PATH")" ]]; then
  mkdir -p "$(dirname "$EVIDENCE_PATH")"
fi

python3 - <<PY
import json, pathlib, datetime, os
import subprocess
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
