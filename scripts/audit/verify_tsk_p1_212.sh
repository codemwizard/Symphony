#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_212_npgsql_ingress_store_fix.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-212 npgsql ingress durability lifecycle fix..."

export INGRESS_STORAGE_MODE="db_psql"
export SYMPHONY_RUNTIME_PROFILE="pilot-demo"
export DATABASE_URL="${DATABASE_URL:-postgres://symphony_admin:symphony_pass@localhost:5432/symphony}"

export INGRESS_API_KEY="test-ingress-key"
export ADMIN_API_KEY="test-admin-key"
export SYMPHONY_KNOWN_TENANTS="11111111-1111-1111-1111-111111111111"

# 1. Run the self test to ensure ingress works correctly under db_psql
if ! dotnet run --project "$ROOT/services/ledger-api/dotnet/src/LedgerApi.DemoHost" --no-build -- --self-test >/tmp/ingress_self_test.log 2>&1; then
  errors+=("self_tests_failed_under_db_psql")
fi


# 2. Check that the deployment guide uses db_psql instead of file
GUIDE="$ROOT/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"
if ! grep -q "INGRESS_STORAGE_MODE=db_psql" "$GUIDE" 2>/dev/null; then
  errors+=("deployment_guide_missing_db_psql")
fi
if grep -q "INGRESS_STORAGE_MODE=file" "$GUIDE" 2>/dev/null; then
  errors+=("deployment_guide_still_documents_file_mode")
fi

# 3. Check Program.cs for db_psql default or usage
PROGRAM_CS="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
if ! grep -q "db_psql" "$PROGRAM_CS" 2>/dev/null; then
  errors+=("program_cs_missing_db_psql_default")
fi

# 4. Check pre_ci_demo.sh for INGRESS_STORAGE_MODE verification
PRE_CI="$ROOT/scripts/dev/pre_ci_demo.sh"
if ! grep -q "INGRESS_STORAGE_MODE" "$PRE_CI" 2>/dev/null; then
  errors+=("pre_ci_demo_not_verifying_storage_mode")
fi

if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { [ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ; }
}

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-212",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-212",
    "run_id": run_id,
    "checks": {
        "self_tests_passed": "self_tests_failed_under_db_psql" not in errors,
        "guide_updated": "deployment_guide_missing_db_psql" not in errors and "deployment_guide_still_documents_file_mode" not in errors,
        "code_updated": "program_cs_missing_db_psql_default" not in errors and "pre_ci_demo_not_verifying_storage_mode" not in errors
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

echo "PASS: TSK-P1-212 npgsql ingress durability lifecycle fix verified."
echo "Evidence: $EVIDENCE"
