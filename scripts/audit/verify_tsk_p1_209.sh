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
UI="$ROOT/src/supervisory-dashboard/index.html"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_209_ui_traceability_cleanup.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"

errors=()

[[ -f "$UI" ]] || errors+=("index_html_missing")

echo "==> Verifying supervisory UI compatibility alias traceability..."

if [[ -f "$UI" ]]; then
  # 1. Control inventory block exists
  if ! grep -q 'SYMPHONY_UI_CONTROL_INVENTORY' "$UI"; then
    errors+=("control_inventory_missing")
  fi

  # 2. All controls are classified (no UNCLASSIFIED)
  if grep -q 'UNCLASSIFIED' "$UI"; then
    errors+=("unclassified_controls_found")
  fi

  # 3. Classification types are present
  if ! grep -q 'WIRED_ACTION' "$UI"; then
    errors+=("wired_action_classification_missing")
  fi
  if ! grep -q 'COMPATIBILITY_ALIAS' "$UI"; then
    errors+=("compatibility_alias_classification_missing")
  fi

  # 4. Alias buttons exist
  if ! grep -q 'export-trigger' "$UI"; then
    errors+=("export_trigger_alias_missing")
  fi
  if ! grep -q 'raw-artifact-drilldown' "$UI"; then
    errors+=("raw_artifact_drilldown_alias_missing")
  fi

  # 5. Alias wiring code exists (click listeners)
  if ! grep -q "addEventListener.*click.*triggerExport" "$UI"; then
    errors+=("export_trigger_not_wired")
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
    "task_id": "TSK-P1-209",
    "run_id": run_id,
    "status": status,
    "checks": {
        "control_inventory_present": "control_inventory_missing" not in errors,
        "no_unclassified_controls": "unclassified_controls_found" not in errors,
        "classifications_present": all(e not in errors for e in [
            "wired_action_classification_missing",
            "compatibility_alias_classification_missing"
        ]),
        "alias_buttons_exist": all(e not in errors for e in [
            "export_trigger_alias_missing",
            "raw_artifact_drilldown_alias_missing"
        ]),
        "alias_wiring_active": "export_trigger_not_wired" not in errors
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

echo "PASS: UI compatibility alias traceability verified."
echo "Evidence: $EVIDENCE"
