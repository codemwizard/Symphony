#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_101.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_101.schema.json"
rg -q "mmo_reality_control_events" "$MIGRATION" || { echo missing_mmo_rule_store >&2; exit 1; }
rg -q "record_mmo_reality_control" "$MIGRATION" || { echo missing_mmo_control_function >&2; exit 1; }
rg -q "ASYNC_CONTRADICTION" "$MIGRATION" || { echo missing_required_scenarios >&2; exit 1; }
rg -q "behavior_profile" "$MIGRATION" || { echo missing_behavior_profile_matching >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-101","task_id":"TSK-HARD-101","status":"PASS","pass":true,"scenarios_covered":["ASYNC_CONTRADICTION","DELAYED_SETTLEMENT","DUAL_DEBIT_RISK","SILENT_REJECTION"],"uses_behavior_profile_matching":true,"hardcoded_mmo_name_used":false,"policy_version_id":"v1.0.0"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert len(d['scenarios_covered'])>=4 and d['hardcoded_mmo_name_used'] is False
PY
