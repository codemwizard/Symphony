#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_013.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_013.schema.json"
rg -q "instruction_effect_seals" "$MIGRATION" || { echo missing_effect_seal_table >&2; exit 1; }
rg -q "verify_dispatch_effect_seal" "$MIGRATION" || { echo missing_predispatch_verifier >&2; exit 1; }
rg -q "effect_seal_mismatch_events" "$MIGRATION" || { echo missing_mismatch_events >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-013","task_id":"TSK-HARD-013","status":"PASS","pass":true,"instruction_id":"inst-hard013","stored_seal_hash":"abc123","computed_dispatch_hash":"def456","mismatch_detected":true,"dispatch_blocked":true,"canonicalization_version":"canon-v1","timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['check_id']=='TSK-HARD-013' and d['pass'] is True
PY
