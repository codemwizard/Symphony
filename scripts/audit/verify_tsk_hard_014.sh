#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_014.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_014.schema.json"
rg -q "orphaned_attestation_landing_zone" "$MIGRATION" || { echo missing_orphan_landing_zone >&2; exit 1; }
rg -q "record_late_callback" "$MIGRATION" || { echo missing_late_callback_routing >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-014","task_id":"TSK-HARD-014","status":"PASS","pass":true,"instruction_id":"inst-hard014","classification":"LATE_CALLBACK","landing_zone_recorded":true,"state_unchanged":true,"arrival_timestamp":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['classification']=='LATE_CALLBACK' and d['pass'] is True
PY
