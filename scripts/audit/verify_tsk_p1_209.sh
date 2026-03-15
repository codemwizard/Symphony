#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UI="$ROOT/src/supervisory-dashboard/index.html"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_209_ui_traceability_cleanup.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$(date -u +%Y%m%dT%H%M%SZ)}"

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
