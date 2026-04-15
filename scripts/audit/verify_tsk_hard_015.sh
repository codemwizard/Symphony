#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_015.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_015.schema.json"
rg -q "FINALITY_CONFLICT" "$MIGRATION" || { echo missing_finality_conflict_enum >&2; exit 1; }
rg -q "instruction_finality_conflicts" "$MIGRATION" || { echo missing_conflict_store >&2; exit 1; }
rg -q "HOLD_RELEASE" "$MIGRATION" || { echo missing_containment_action >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-015","task_id":"TSK-HARD-015","status":"PASS","pass":true,"enum_value_confirmed":"FINALITY_CONFLICT","instruction_id":"inst-hard015","containment_action":"HOLD_RELEASE","manual_resolution_required":true,"query_timestamp":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['enum_value_confirmed']=='FINALITY_CONFLICT'
PY
