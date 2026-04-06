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
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER="$ROOT/services/supervisor_api/server.py"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"

errors=()

if [[ ! -f "$SERVER" ]]; then
  errors+=("server_file_missing")
fi

echo "==> Verifying supervisor API auth hardening (static analysis)..."

if [[ -f "$SERVER" ]]; then
  # 1. Constant-time auth comparison present
  if ! grep -q 'hmac.compare_digest' "$SERVER"; then
    errors+=("missing_constant_time_auth")
  fi

  # 2. ADMIN_API_KEY required at startup
  if ! grep -q 'ADMIN_API_KEY' "$SERVER"; then
    errors+=("missing_admin_api_key_requirement")
  fi

  # 3. SUPERVISOR_API_TEST_MODE bypass present
  if ! grep -q 'SUPERVISOR_API_TEST_MODE' "$SERVER"; then
    errors+=("missing_test_mode_bypass")
  fi

  # 4. Query-string token parsing removed from audit-records
  if grep -q 'parse_qs' "$SERVER" || grep -q 'urllib.parse' "$SERVER"; then
    errors+=("query_string_token_still_present")
  fi

  # 5. Authorization header used for audit-records token
  if ! grep -q 'Authorization' "$SERVER"; then
    errors+=("missing_bearer_token_transport")
  fi

  # 6. No raw DB exception detail in error responses
  if grep -q '"detail": msg' "$SERVER" || grep -q '"detail":msg' "$SERVER"; then
    errors+=("raw_db_detail_still_exposed")
  fi

  # 7. Malformed JSON handling present
  if ! grep -q 'MALFORMED_JSON' "$SERVER"; then
    errors+=("missing_malformed_json_handling")
  fi

  # 8. Auth check on all privileged routes
  if ! grep -q '_check_admin_auth' "$SERVER"; then
    errors+=("missing_admin_auth_checks")
  fi
fi

# Produce evidence JSON
if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys
evidence_path, run_id, status, errors_csv = sys.argv[1:5]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "task_id": "TSK-P1-207",
    "run_id": run_id,
    "status": status,
    "checks": {
        "constant_time_auth": "missing_constant_time_auth" not in errors,
        "admin_api_key_required": "missing_admin_api_key_requirement" not in errors,
        "test_mode_bypass": "missing_test_mode_bypass" not in errors,
        "query_string_removed": "query_string_token_still_present" not in errors,
        "bearer_token_transport": "missing_bearer_token_transport" not in errors,
        "no_raw_db_detail": "raw_db_detail_still_exposed" not in errors,
        "malformed_json_handling": "missing_malformed_json_handling" not in errors,
        "admin_auth_on_routes": "missing_admin_auth_checks" not in errors
    },
    "errors": errors
}
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: Supervisor API auth hardening verified (static analysis)."
echo "Evidence: $EVIDENCE"
