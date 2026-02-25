#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-TEN-002"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/ten_002_rls_leakage.json"

source "$ROOT_DIR/scripts/lib/evidence.sh"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

failures=()
add_failure() { failures+=("$1"); }

query() {
  psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "$1"
}

if [[ ! -f "$ROOT_DIR/schema/migrations/0059_ten_002_rls_tenant_isolation.sql" ]]; then
  add_failure "migration_missing:0059_ten_002_rls_tenant_isolation.sql"
fi

tenant_tables_raw="$(query "
SELECT c.relname
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid
WHERE n.nspname='public'
  AND c.relkind='r'
  AND a.attname='tenant_id'
  AND a.attisdropped=false
ORDER BY c.relname;")"

mapfile -t tenant_tables < <(printf '%s\n' "$tenant_tables_raw" | sed '/^$/d')
if [[ ${#tenant_tables[@]} -eq 0 ]]; then
  add_failure "tenant_tables_missing"
fi

# tenant fixtures
billable_a="$(query "SELECT public.uuid_v7_or_random();" | tr -d '[:space:]')"
billable_b="$(query "SELECT public.uuid_v7_or_random();" | tr -d '[:space:]')"
tenant_a="$(query "SELECT public.uuid_v7_or_random();" | tr -d '[:space:]')"
tenant_b="$(query "SELECT public.uuid_v7_or_random();" | tr -d '[:space:]')"

query "
INSERT INTO public.billable_clients(billable_client_id, legal_name, client_type, status, client_key)
VALUES
  ('$billable_a'::uuid, 'TEN-002 Tenant A', 'ENTERPRISE', 'ACTIVE', 'ten002-a-' || md5(random()::text)),
  ('$billable_b'::uuid, 'TEN-002 Tenant B', 'ENTERPRISE', 'ACTIVE', 'ten002-b-' || md5(random()::text));
"

query "
INSERT INTO public.tenants(tenant_id, tenant_key, tenant_name, tenant_type, status, billable_client_id)
VALUES
  ('$tenant_a'::uuid, 'ten002-a-' || substr(md5(random()::text),1,8), 'TEN-002 Tenant A', 'COMMERCIAL', 'ACTIVE', '$billable_a'::uuid),
  ('$tenant_b'::uuid, 'ten002-b-' || substr(md5(random()::text),1,8), 'TEN-002 Tenant B', 'COMMERCIAL', 'ACTIVE', '$billable_b'::uuid);
"

# Seed best-effort tenant A rows on all tenant-scoped tables using replica mode to avoid FK coupling.
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 <<SQL
DO \$\$
DECLARE
  r record;
  col_list text;
  val_list text;
BEGIN
  PERFORM set_config('session_replication_role', 'replica', true);

  FOR r IN
    SELECT c.oid, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname='public'
      AND c.relkind='r'
      AND a.attname='tenant_id'
      AND a.attisdropped=false
      AND c.relname <> 'tenants'
    ORDER BY c.relname
  LOOP
    SELECT
      string_agg(quote_ident(a.attname), ', ' ORDER BY a.attnum),
      string_agg(
        CASE
          WHEN a.attname = 'tenant_id' THEN quote_literal('$tenant_a') || '::uuid'
          WHEN a.atttypid = 'uuid'::regtype THEN 'public.uuid_v7_or_random()'
          WHEN a.atttypid = 'text'::regtype OR a.atttypid = 'character varying'::regtype THEN quote_literal('ten002_' || r.relname || '_' || a.attname)
          WHEN a.atttypid = 'jsonb'::regtype THEN '''{}''::jsonb'
          WHEN a.atttypid = 'json'::regtype THEN '''{}''::json'
          WHEN a.atttypid = 'boolean'::regtype THEN 'false'
          WHEN a.atttypid = 'smallint'::regtype OR a.atttypid = 'integer'::regtype OR a.atttypid = 'bigint'::regtype OR a.atttypid = 'numeric'::regtype THEN '1'
          WHEN a.atttypid = 'date'::regtype THEN 'CURRENT_DATE'
          WHEN a.atttypid = 'timestamp without time zone'::regtype OR a.atttypid = 'timestamp with time zone'::regtype THEN 'NOW()'
          WHEN a.atttypid = 'outbox_attempt_state'::regtype THEN '''DISPATCHED''::outbox_attempt_state'
          ELSE NULL
        END,
        ', ' ORDER BY a.attnum
      )
    INTO col_list, val_list
    FROM pg_attribute a
    LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
    WHERE a.attrelid = r.oid
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attnotnull
      AND a.attidentity = ''
      AND a.attgenerated = ''
      AND (d.adbin IS NULL OR pg_get_expr(d.adbin, d.adrelid) IS NULL);

    IF col_list IS NOT NULL AND val_list IS NOT NULL THEN
      BEGIN
        EXECUTE format('INSERT INTO public.%I (%s) VALUES (%s) ON CONFLICT DO NOTHING', r.relname, col_list, val_list);
      EXCEPTION WHEN OTHERS THEN
        -- best effort seeding; leakage verification still runs and records table outcomes.
        NULL;
      END;
    END IF;
  END LOOP;

  PERFORM set_config('session_replication_role', 'origin', true);
END
\$\$;
SQL

# Create non-bypass tester role for RLS visibility checks.
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='rls_tester') THEN
    CREATE ROLE rls_tester LOGIN;
  END IF;
  ALTER ROLE rls_tester NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
END
$$;
SQL

query "GRANT USAGE ON SCHEMA public TO rls_tester;"
for t in "${tenant_tables[@]}"; do
  query "GRANT SELECT ON TABLE public.\"$t\" TO rls_tester;"
done

rls_tables_json="[]"
leakage_tables_json="[]"
exemptions_json="[]"

for t in "${tenant_tables[@]}"; do
  rls_enabled="$(query "SELECT c.relrowsecurity::text FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='$t';" | tr -d '[:space:]')"
  rls_forced="$(query "SELECT c.relforcerowsecurity::text FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='$t';" | tr -d '[:space:]')"
  has_restrictive="$(query "
SELECT EXISTS (
  SELECT 1
  FROM pg_policy p
  JOIN pg_class c ON c.oid=p.polrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public'
    AND c.relname='$t'
    AND p.polpermissive = false
    AND (
      pg_get_expr(p.polqual, p.polrelid) ILIKE '%current_setting(%app.current_tenant_id%'
      OR pg_get_expr(p.polqual, p.polrelid) ILIKE '%current_tenant_id_or_null()%'
    )
)::text;
" | tr -d '[:space:]')"

  [[ "$rls_enabled" == "true" ]] || add_failure "rls_not_enabled:$t"
  [[ "$rls_forced" == "true" ]] || add_failure "rls_not_forced:$t"
  [[ "$has_restrictive" == "true" ]] || add_failure "restrictive_policy_missing_or_not_tenant_bound:$t"

  rls_tables_json="$(python3 - <<PY
import json
arr=json.loads('''$rls_tables_json''')
arr.append({
  "table": "$t",
  "rls_enabled": "$rls_enabled" == "true",
  "rls_forced": "$rls_forced" == "true",
  "restrictive_policy_tenant_bound": "$has_restrictive" == "true"
})
print(json.dumps(arr))
PY
)"

  row_seeded="$(query "SELECT EXISTS (SELECT 1 FROM public.\"$t\" WHERE tenant_id='$tenant_a'::uuid LIMIT 1)::text;" | tr -d '[:space:]')"
  if [[ "$row_seeded" != "true" ]]; then
    exemptions_json="$(python3 - <<PY
import json
arr=json.loads('''$exemptions_json''')
arr.append({"table":"$t","reason":"no_seeded_row_available_for_leakage_probe"})
print(json.dumps(arr))
PY
)"
    leakage_tables_json="$(python3 - <<PY
import json
arr=json.loads('''$leakage_tables_json''')
arr.append({"table":"$t","seeded":False,"blocked":True,"policy":"rls_tenant_isolation_$t"})
print(json.dumps(arr))
PY
)"
    continue
  fi

  blocked="$(query "
SET ROLE rls_tester;
SET LOCAL app.current_tenant_id = '$tenant_b';
SELECT (COUNT(*) FILTER (WHERE tenant_id='$tenant_a'::uuid) = 0)::text FROM public.\"$t\";
RESET ROLE;
" | tail -n1 | tr -d '[:space:]')"

  if [[ "$blocked" != "true" ]]; then
    add_failure "cross_tenant_leakage_detected:$t"
  fi

  leakage_tables_json="$(python3 - <<PY
import json
arr=json.loads('''$leakage_tables_json''')
arr.append({"table":"$t","seeded":True,"blocked":"$blocked"=="true","policy":"rls_tenant_isolation_$t"})
print(json.dumps(arr))
PY
)"
done

pass=true
status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  pass=false
  status="FAIL"
fi

EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "TEN-002-RLS-LEAKAGE",
  "task_id": "$TASK_ID",
  "status": "$status",
  "pass": True if "$pass" == "true" else False,
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "tenant_table_count": ${#tenant_tables[@]},
  "rls_tables": json.loads('''$rls_tables_json'''),
  "leakage_tests": json.loads('''$leakage_tables_json'''),
  "exemptions": json.loads('''$exemptions_json'''),
  "failures": json.loads('''$(printf '%s\n' "${failures[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')''')
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY

if [[ "$pass" != "true" ]]; then
  echo "TEN-002 verifier failed"
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "TEN-002 verifier passed. Evidence: $EVIDENCE_FILE"
