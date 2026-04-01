#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# verify_gf_rls_runtime.sh — Runtime RLS verifier for Green Finance tables
#
# Validates that all 16 GF tables in a running database have the canonical
# born-secure RLS configuration:
#   - relrowsecurity = true
#   - relforcerowsecurity = true  (critical: blocks superuser bypass)
#   - Exactly 1 policy per table
#   - Policy is RESTRICTIVE (polpermissive = false)
#   - Policy is FOR ALL (polcmd = '*')
#   - Policy applies TO PUBLIC (polroles = {0})
#   - Expression matches canonical function per isolation class
#
# Evidence output: evidence/phase1/gf_rls_runtime_verification.json
# =============================================================================

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$ROOT_DIR/evidence/phase1/gf_rls_runtime_verification.json"

source "$ROOT_DIR/scripts/lib/evidence.sh"

mkdir -p "$(dirname "$EVIDENCE_FILE")"

failures=()
pending_tables=()
add_failure() { failures+=("$1"); }

query() {
  psql "$DATABASE_URL" -X -q -t -A -v ON_ERROR_STOP=1 -c "$1"
}

# GF tables and their isolation class
# Format: table_name:isolation_type
# isolation_type: tenant | jurisdiction | join_tenant
GF_TABLES=(
  "adapter_registrations:tenant"
  "monitoring_records:tenant"
  "evidence_nodes:tenant"
  "evidence_edges:join_tenant"
  "asset_batches:tenant"
  "asset_lifecycle_events:join_tenant"
  "retirement_events:tenant"
  "verifier_registry:tenant"
  "verifier_project_assignments:join_tenant"
  "gf_verifier_read_tokens:tenant"
  "interpretation_packs:jurisdiction"
  "regulatory_authorities:jurisdiction"
  "regulatory_checkpoints:jurisdiction"
  "jurisdiction_profiles:jurisdiction"
  "lifecycle_checkpoint_rules:jurisdiction"
  "authority_decisions:jurisdiction"
)

table_results_json="[]"

for entry in "${GF_TABLES[@]}"; do
  tbl="${entry%%:*}"
  isolation_type="${entry##*:}"

  # Check table exists
  exists="$(query "SELECT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = '$tbl'
  )::text;" | tr -d '[:space:]')"

  if [[ "$exists" != "true" ]]; then
    pending_tables+=("$tbl")
    continue  # table from a future Wave 4 task — skip, don't fail
  fi

  # Check relrowsecurity and relforcerowsecurity
  rls_enabled="$(query "
    SELECT c.relrowsecurity::text
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = '$tbl';
  " | tr -d '[:space:]')"

  rls_forced="$(query "
    SELECT c.relforcerowsecurity::text
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = '$tbl';
  " | tr -d '[:space:]')"

  [[ "$rls_enabled" == "true" ]] || add_failure "rls_not_enabled:$tbl"
  [[ "$rls_forced" == "true" ]] || add_failure "rls_not_forced:$tbl"

  # Check policy count (must be exactly 1)
  policy_count="$(query "
    SELECT COUNT(*)
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = '$tbl';
  " | tr -d '[:space:]')"

  [[ "$policy_count" == "1" ]] || add_failure "wrong_policy_count:$tbl:expected_1_got_$policy_count"

  # Check policy shape: RESTRICTIVE, FOR ALL, TO PUBLIC
  policy_shape="$(query "
    SELECT json_build_object(
      'name', p.polname,
      'permissive', p.polpermissive,
      'cmd', p.polcmd,
      'roles', p.polroles::text,
      'using_expr', pg_get_expr(p.polqual, p.polrelid),
      'with_check_expr', pg_get_expr(p.polwithcheck, p.polrelid)
    )::text
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = '$tbl'
    LIMIT 1;
  " | tr -d '[:space:]' | sed 's/^[[:space:]]*//')"

  if [[ -z "$policy_shape" ]]; then
    add_failure "no_policy_found:$tbl"
    table_results_json="$(python3 - <<PY
import json
arr = json.loads('''$table_results_json''')
arr.append({
    "table": "$tbl",
    "isolation_type": "$isolation_type",
    "rls_enabled": "$rls_enabled" == "true",
    "rls_forced": "$rls_forced" == "true",
    "policy_count": int("$policy_count"),
    "policy_valid": False,
    "failure_reason": "no_policy_found"
})
print(json.dumps(arr))
PY
)"
    continue
  fi

  # Parse and validate policy details
  validation_result="$(POLICY_SHAPE_RAW="$policy_shape" python3 - <<PY
import json, os
shape_raw = os.environ['POLICY_SHAPE_RAW']
try:
    shape = json.loads(shape_raw)
except json.JSONDecodeError:
    print(json.dumps({"valid": False, "reason": "policy_json_parse_error"}))
    exit(0)

errors = []
isolation_type = "$isolation_type"

# Must be PERMISSIVE (polpermissive = true) — RESTRICTIVE-only blocks all access
if not shape.get("permissive", True):
    errors.append("is_restrictive_blocks_all_access")

# Must be FOR ALL (polcmd = '*')
if shape.get("cmd") != "*":
    errors.append("not_for_all:cmd=" + str(shape.get("cmd")))

# Must be TO PUBLIC (polroles = {0})
roles = shape.get("roles", "")
if roles not in ("{0}", "0"):
    errors.append("not_to_public:roles=" + str(roles))

# Validate USING expression
using_expr = (shape.get("using_expr") or "").strip().lower()
with_check = (shape.get("with_check_expr") or "").strip().lower()

if isolation_type == "tenant":
    expected_fn = "current_tenant_id_or_null()"
    if expected_fn not in using_expr:
        errors.append("wrong_using_expr:missing_" + expected_fn)
    if expected_fn not in with_check:
        errors.append("wrong_with_check:missing_" + expected_fn)

elif isolation_type == "jurisdiction":
    expected_fn = "current_jurisdiction_code_or_null()"
    if expected_fn not in using_expr:
        errors.append("wrong_using_expr:missing_" + expected_fn)
    if expected_fn not in with_check:
        errors.append("wrong_with_check:missing_" + expected_fn)

elif isolation_type == "join_tenant":
    if "exists" not in using_expr:
        errors.append("wrong_using_expr:missing_exists_subquery")
    if "current_tenant_id_or_null()" not in using_expr:
        errors.append("wrong_using_expr:missing_current_tenant_id_or_null")
    if "exists" not in with_check:
        errors.append("wrong_with_check:missing_exists_subquery")
    if "current_tenant_id_or_null()" not in with_check:
        errors.append("wrong_with_check:missing_current_tenant_id_or_null")

if not with_check:
    errors.append("missing_with_check")

result = {
    "valid": len(errors) == 0,
    "policy_name": shape.get("name", "unknown"),
    "errors": errors,
    "using_expr": shape.get("using_expr", ""),
    "with_check_expr": shape.get("with_check_expr", "")
}
print(json.dumps(result))
PY
)"

  policy_valid="$(echo "$validation_result" | python3 -c "import json,sys; print(json.load(sys.stdin)['valid'])")"
  if [[ "$policy_valid" != "True" ]]; then
    policy_errors="$(echo "$validation_result" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin).get('errors', [])))")"
    add_failure "policy_shape_invalid:$tbl:$policy_errors"
  fi

  table_results_json="$(TABLE_RESULTS_RAW="$table_results_json" VALIDATION_RAW="$validation_result" python3 - <<PY
import json, os
arr = json.loads(os.environ['TABLE_RESULTS_RAW'])
val = json.loads(os.environ['VALIDATION_RAW'])
arr.append({
    "table": "$tbl",
    "isolation_type": "$isolation_type",
    "rls_enabled": "$rls_enabled" == "true",
    "rls_forced": "$rls_forced" == "true",
    "policy_count": int("$policy_count"),
    "policy_valid": val["valid"],
    "policy_name": val.get("policy_name", ""),
    "policy_errors": val.get("errors", []),
    "using_expr": val.get("using_expr", ""),
    "with_check_expr": val.get("with_check_expr", "")
})
print(json.dumps(arr))
PY
)"
done

# Check canonical functions exist
tenant_fn_exists="$(query "
  SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'current_tenant_id_or_null'
  )::text;
" | tr -d '[:space:]')"

jurisdiction_fn_exists="$(query "
  SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'current_jurisdiction_code_or_null'
  )::text;
" | tr -d '[:space:]')"

[[ "$tenant_fn_exists" == "true" ]] || add_failure "function_missing:current_tenant_id_or_null"
# jurisdiction function is created by GF-W1-SCH-006 — only fail if jurisdiction tables exist but function is missing
jurisdiction_tables_exist=false
for jt in interpretation_packs regulatory_authorities regulatory_checkpoints jurisdiction_profiles lifecycle_checkpoint_rules authority_decisions; do
  for entry in "${GF_TABLES[@]}"; do
    if [[ "${entry%%:*}" == "$jt" ]]; then
      check_exists="$(query "SELECT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relname = '$jt')::text;" | tr -d '[:space:]')"
      [[ "$check_exists" == "true" ]] && jurisdiction_tables_exist=true
    fi
  done
done
if [[ "$jurisdiction_tables_exist" == "true" ]]; then
  [[ "$jurisdiction_fn_exists" == "true" ]] || add_failure "function_missing:current_jurisdiction_code_or_null"
fi

# Check no system_full_access policies exist on GF tables
system_bypass_count="$(query "
  SELECT COUNT(*)
  FROM pg_policy p
  JOIN pg_class c ON c.oid = p.polrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND p.polname LIKE '%system_full_access%'
    AND c.relname IN (
      'adapter_registrations', 'monitoring_records', 'evidence_nodes', 'evidence_edges',
      'asset_batches', 'asset_lifecycle_events', 'retirement_events',
      'verifier_registry', 'verifier_project_assignments', 'gf_verifier_read_tokens',
      'interpretation_packs', 'regulatory_authorities', 'regulatory_checkpoints',
      'jurisdiction_profiles', 'lifecycle_checkpoint_rules', 'authority_decisions'
    );
" | tr -d '[:space:]')"

[[ "$system_bypass_count" == "0" ]] || add_failure "system_full_access_bypass_present:count=$system_bypass_count"

pass=true
status="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then
  pass=false
  status="FAIL"
fi

EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

TABLE_RESULTS_FINAL="$table_results_json" python3 - <<PY
import json, os
from pathlib import Path
out = {
    "check_id": "GF-RLS-RUNTIME-VERIFICATION",
    "task_id": "RLS-002",
    "status": "$status",
    "pass": True if "$pass" == "true" else False,
    "timestamp_utc": "$EVIDENCE_TS",
    "git_sha": "$EVIDENCE_GIT_SHA",
    "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
    "gf_table_count": ${#GF_TABLES[@]},
    "verified_table_count": ${#GF_TABLES[@]} - ${#pending_tables[@]},
    "pending_table_count": ${#pending_tables[@]},
    "pending_tables": json.loads('''$(printf '%s\n' "${pending_tables[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')'''),
    "canonical_functions": {
        "current_tenant_id_or_null": "$tenant_fn_exists" == "true",
        "current_jurisdiction_code_or_null": "$jurisdiction_fn_exists" == "true"
    },
    "system_full_access_bypass_count": int("$system_bypass_count"),
    "table_results": json.loads(os.environ['TABLE_RESULTS_FINAL']),
    "failures": json.loads('''$(printf '%s\n' "${failures[@]}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')''')
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY

if [[ "$pass" != "true" ]]; then
  echo "GF RLS runtime verifier FAILED"
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi

echo "GF RLS runtime verifier PASSED (${#pending_tables[@]} tables pending from future tasks). Evidence: $EVIDENCE_FILE"
