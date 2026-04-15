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
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_219_operator_onboarding_console.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-219: Operator Onboarding Console..."

DASHBOARD="$ROOT/src/supervisory-dashboard/index.html"

# ─── 1. Onboarding tab exists ───
if ! grep -q "switchTab('onboarding'" "$DASHBOARD" 2>/dev/null; then
  errors+=("onboarding_tab_missing")
fi

# ─── 2. Onboarding screen exists ───
if ! grep -q 'id="screen-onboarding"' "$DASHBOARD" 2>/dev/null; then
  errors+=("onboarding_screen_missing")
fi

# ─── 3. loadOnboardingState function exists ───
if ! grep -q 'function loadOnboardingState' "$DASHBOARD" 2>/dev/null; then
  errors+=("loadOnboardingState_missing")
fi

# ─── 4. Calls /api/admin/onboarding/status ───
if ! grep -q '/api/admin/onboarding/status' "$DASHBOARD" 2>/dev/null; then
  errors+=("status_api_call_missing")
fi

# ─── 5. No x-admin-api-key in dashboard ───
if grep -qi 'x-admin-api-key' "$DASHBOARD" 2>/dev/null; then
  errors+=("admin_key_in_browser")
fi

# ─── 6. No ADMIN_API_KEY in dashboard ───
if grep -q 'ADMIN_API_KEY' "$DASHBOARD" 2>/dev/null; then
  errors+=("admin_api_key_in_browser")
fi

# ─── 7. Uses credentials:include (session boundary) ───
if ! grep -q "credentials.*include" "$DASHBOARD" 2>/dev/null; then
  errors+=("no_session_credentials")
fi

# ─── 8. Tab bar has 5 tabs ───
TAB_COUNT=$(grep -c "onclick=\"switchTab" "$DASHBOARD" 2>/dev/null || echo "0")
if [ "$TAB_COUNT" -lt 5 ]; then
  errors+=("insufficient_tabs:found_${TAB_COUNT}_need_5")
fi

# ─── 9. Worker tokens tab exists ───
if ! grep -q "switchTab('worker-tokens'" "$DASHBOARD" 2>/dev/null; then
  errors+=("worker_tokens_tab_missing")
fi

# ─── 10. Worker tokens screen exists ───
if ! grep -q 'id="screen-worker-tokens"' "$DASHBOARD" 2>/dev/null; then
  errors+=("worker_tokens_screen_missing")
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
    "check_id": "TSK-P1-219",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-219",
    "run_id": run_id,
    "checks": {
        "onboarding_tab": "onboarding_tab_missing" not in errors,
        "onboarding_screen": "onboarding_screen_missing" not in errors,
        "load_function": "loadOnboardingState_missing" not in errors,
        "status_api_call": "status_api_call_missing" not in errors,
        "no_admin_key_in_browser": "admin_key_in_browser" not in errors and "admin_api_key_in_browser" not in errors,
        "session_credentials": "no_session_credentials" not in errors,
        "five_tabs": "insufficient_tabs" not in " ".join(errors),
        "worker_tokens_tab": "worker_tokens_tab_missing" not in errors,
        "worker_tokens_screen": "worker_tokens_screen_missing" not in errors,
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

echo "PASS: TSK-P1-219 Operator onboarding console verified."
echo "Evidence: $EVIDENCE"
