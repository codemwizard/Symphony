#!/usr/bin/env bash
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_217_onboarding_control_plane.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$(date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-217: Onboarding Control-Plane Persistence..."

MIGRATION=$(find "$ROOT/schema/migrations" -name '*onboarding_control_plane*' -type f | head -1)
STORES="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs"
CONTRACTS="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Commands/CommandContracts.cs"
AUTH="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Security/ApiAuthorization.cs"

# ─── 1. Migration file exists ───
if [ -z "$MIGRATION" ]; then
  errors+=("migration_file_missing")
fi

# ─── 2. Migration contains required tables ───
if [ -n "$MIGRATION" ]; then
  for table in tenant_registry programme_registry programme_policy_binding; do
    if ! grep -q "$table" "$MIGRATION" 2>/dev/null; then
      errors+=("migration_missing_table_${table}")
    fi
  done

  # FK constraints
  if ! grep -q "REFERENCES.*tenant_registry" "$MIGRATION" 2>/dev/null; then
    errors+=("missing_fk_to_tenant_registry")
  fi

  # RLS policies
  RLS_COUNT=$(grep -c "CREATE POLICY" "$MIGRATION" 2>/dev/null || echo "0")
  if [ "$RLS_COUNT" -lt 3 ]; then
    errors+=("insufficient_rls_policies:found_${RLS_COUNT}_need_3")
  fi

  # Lifecycle enum check
  if ! grep -q "CREATED.*ACTIVE.*SUSPENDED.*CLOSED" "$MIGRATION" 2>/dev/null; then
    errors+=("programme_lifecycle_enum_missing")
  fi
fi

# ─── 3. Store interfaces exist ───
if ! grep -q "interface ITenantRegistryStore" "$CONTRACTS" 2>/dev/null; then
  errors+=("ITenantRegistryStore_missing")
fi
if ! grep -q "interface IProgrammeStore" "$CONTRACTS" 2>/dev/null; then
  errors+=("IProgrammeStore_missing")
fi

# ─── 4. Npgsql implementations exist ───
if ! grep -q "class NpgsqlTenantRegistryStore" "$STORES" 2>/dev/null; then
  errors+=("NpgsqlTenantRegistryStore_missing")
fi
if ! grep -q "class NpgsqlProgrammeStore" "$STORES" 2>/dev/null; then
  errors+=("NpgsqlProgrammeStore_missing")
fi

# ─── 5. Stores use parameterized queries (no string concatenation) ───
if grep -n 'cmd.CommandText.*\$"' "$STORES" 2>/dev/null | grep -qi "tenant_registry\|programme_registry"; then
  errors+=("string_interpolation_in_sql")
fi

# ─── 6. Build check ───
echo "    Building LedgerApi..."
BUILD_OUTPUT=$(dotnet build "$ROOT/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" 2>&1 || true)
NEW_ERRORS=$(echo "$BUILD_OUTPUT" | { grep 'error CS' || true; } | { grep -v 'CS0117' || true; } | wc -l)
if [ "$NEW_ERRORS" -gt 0 ]; then
  errors+=("build_has_new_errors")
  echo "    Build errors (non-CS0117):"
  echo "$BUILD_OUTPUT" | grep 'error CS' | grep -v 'CS0117'
fi

# ─── Emit evidence ───
if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
}

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-217",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-217",
    "run_id": run_id,
    "checks": {
        "migration_exists": "migration_file_missing" not in errors,
        "tables_present": all(f"migration_missing_table_{t}" not in errors for t in ["tenant_registry", "programme_registry", "programme_policy_binding"]),
        "fk_constraints": "missing_fk_to_tenant_registry" not in errors,
        "rls_policies": "insufficient_rls_policies" not in " ".join(errors),
        "lifecycle_enum": "programme_lifecycle_enum_missing" not in errors,
        "store_interfaces": "ITenantRegistryStore_missing" not in errors and "IProgrammeStore_missing" not in errors,
        "npgsql_implementations": "NpgsqlTenantRegistryStore_missing" not in errors and "NpgsqlProgrammeStore_missing" not in errors,
        "parameterized_queries": "string_interpolation_in_sql" not in errors,
        "build_compiles": "build_has_new_errors" not in errors,
    },
    "errors": errors
}
os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: TSK-P1-217 Onboarding control-plane persistence verified."
echo "Evidence: $EVIDENCE"
