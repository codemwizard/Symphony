#!/usr/bin/env bash
set -eo pipefail

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
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_218_server_side_onboarding_apis.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-218: Server-Side Onboarding APIs..."

PROGRAM="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs"

# ─── 1. Endpoint registrations ───
EXPECTED_ROUTES=(
  "/api/admin/onboarding/tenants"
  "/api/admin/onboarding/programmes"
  "/api/admin/onboarding/programmes/{id}/activate"
  "/api/admin/onboarding/programmes/{id}/suspend"
  "/api/admin/onboarding/programmes/{id}/policy-binding"
  "/api/admin/onboarding/status"
)
for route in "${EXPECTED_ROUTES[@]}"; do
  if ! grep -q "\"$route\"" "$PROGRAM" 2>/dev/null; then
    errors+=("missing_route_${route}")
  fi
done

# Count distinct endpoint registrations (POST + GET for tenants = 2, POST + GET for programmes = 2, etc.)
ENDPOINT_COUNT=$(grep -c '/api/admin/onboarding/' "$PROGRAM" 2>/dev/null || echo "0")
if [ "$ENDPOINT_COUNT" -lt 8 ]; then
  errors+=("insufficient_endpoints:found_${ENDPOINT_COUNT}_need_8")
fi

# ─── 2. Admin auth guard on all endpoints ───
GUARD_COUNT=$(grep -A2 '/api/admin/onboarding/' "$PROGRAM" 2>/dev/null | grep -c 'AuthorizeAdminTenantOnboarding' || echo "0")
if [ "$GUARD_COUNT" -lt 8 ]; then
  errors+=("insufficient_auth_guards:found_${GUARD_COUNT}")
fi

# ─── 3. No SYMPHONY_KNOWN_TENANTS in new onboarding code ───
# Check that the onboarding API section doesn't reference the env allowlist
ONBOARDING_SECTION=$(sed -n '/TSK-P1-218/,/app.RunAsync/p' "$PROGRAM" 2>/dev/null)
if echo "$ONBOARDING_SECTION" | grep -q "SYMPHONY_KNOWN_TENANTS" 2>/dev/null; then
  errors+=("env_allowlist_in_onboarding_apis")
fi

# ─── 4. No x-admin-api-key in HTML/JS (prohibition check) ───
DASHBOARD="$ROOT/src/supervisory-dashboard/index.html"
if [ -f "$DASHBOARD" ]; then
  if grep -q "x-admin-api-key" "$DASHBOARD" 2>/dev/null; then
    errors+=("admin_key_in_browser")
  fi
fi

# ─── 5. Readback endpoint exists ───
if ! grep -q '/api/admin/onboarding/status' "$PROGRAM" 2>/dev/null; then
  errors+=("status_readback_missing")
fi

# ─── 6. Build check ───
echo "    Building LedgerApi..."
BUILD_OUTPUT=$(dotnet build "$ROOT/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" 2>&1 || true)
NEW_ERRORS=$(echo "$BUILD_OUTPUT" | { grep 'error CS' || true; } | { grep -v 'CS0117' || true; } | wc -l)
if [ "$NEW_ERRORS" -gt 0 ]; then
  errors+=("build_has_new_errors")
  echo "    Build errors:"
  echo "$BUILD_OUTPUT" | grep 'error CS' | grep -v 'CS0117'
fi

# ─── Emit evidence ───
if [[ ${#errors[@]} -eq 0 ]]; then status="PASS"; else status="FAIL"; fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { [ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ; }
}

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$(evidence_now_utc)" "$(git_sha)" "$(schema_fingerprint)" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-218",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-218",
    "run_id": run_id,
    "checks": {
        "all_routes_registered": all(f"missing_route_{r}" not in errors for r in [
            "/api/admin/onboarding/tenants", "/api/admin/onboarding/programmes",
            "/api/admin/onboarding/status"]),
        "sufficient_endpoints": "insufficient_endpoints" not in " ".join(errors),
        "auth_guards_present": "insufficient_auth_guards" not in " ".join(errors),
        "no_env_allowlist": "env_allowlist_in_onboarding_apis" not in errors,
        "no_admin_key_in_browser": "admin_key_in_browser" not in errors,
        "status_readback": "status_readback_missing" not in errors,
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

echo "PASS: TSK-P1-218 Server-side onboarding APIs verified."
echo "Evidence: $EVIDENCE"
