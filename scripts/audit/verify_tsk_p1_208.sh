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
PROGRAM="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
UI="$ROOT/src/supervisory-dashboard/index.html"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"

errors=()

[[ -f "$PROGRAM" ]] || errors+=("program_cs_missing")
[[ -f "$UI" ]] || errors+=("index_html_missing")

echo "==> Verifying pilot-demo generate auth boundary..."

if [[ -f "$PROGRAM" ]]; then
  # Extract the pilot-demo generate route segment
  segment=$(python3 - <<'PY' "$PROGRAM"
from pathlib import Path
import sys
text = Path(sys.argv[1]).read_text(encoding='utf-8')
start = text.find('app.MapPost("/pilot-demo/api/instruction-files/generate"')
if start < 0:
    print("ROUTE_MISSING")
    raise SystemExit(0)
end = text.find('app.Map', start + 10)
segment = text[start:end if end > start else None]
print(segment)
PY
  )

  if [[ "$segment" == "ROUTE_MISSING" ]]; then
    errors+=("generate_route_missing")
  else
    # 1. Must use AuthorizeAdminTenantOnboarding
    if ! echo "$segment" | grep -q 'AuthorizeAdminTenantOnboarding'; then
      errors+=("generate_route_not_admin_guarded")
    fi

    # 2. Must NOT use AuthorizeEvidenceRead
    if echo "$segment" | grep -q 'AuthorizeEvidenceRead'; then
      errors+=("generate_route_uses_evidence_read")
    fi

    # 3. Must still have operator cookie defence-in-depth
    if ! echo "$segment" | grep -q 'TryValidatePilotDemoOperatorCookie'; then
      errors+=("operator_cookie_layer_removed")
    fi
  fi
fi

if [[ -f "$UI" ]]; then
  # 4. No admin secret in browser source
  if grep -Fq 'ctx.adminApiKey' "$UI" || grep -Fq 'x-admin-api-key' "$UI"; then
    errors+=("admin_secret_in_browser")
  fi
fi

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
    "task_id": "TSK-P1-208",
    "run_id": run_id,
    "status": status,
    "checks": {
        "admin_auth_on_generate_route": "generate_route_not_admin_guarded" not in errors,
        "evidence_read_removed": "generate_route_uses_evidence_read" not in errors,
        "operator_cookie_preserved": "operator_cookie_layer_removed" not in errors,
        "no_admin_secret_in_browser": "admin_secret_in_browser" not in errors
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

echo "PASS: Pilot-demo generate route admin auth boundary verified."
echo "Evidence: $EVIDENCE"
