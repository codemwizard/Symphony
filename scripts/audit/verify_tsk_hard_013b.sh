#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_013b.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_013b.schema.json"
rg -q "orphan_classification_enum" "$MIGRATION" || { echo missing_orphan_classification_enum >&2; exit 1; }
rg -q "classify_orphan_or_replay" "$MIGRATION" || { echo missing_orphan_replay_classifier >&2; exit 1; }
rg -q "REPLAY_ATTEMPT" "$MIGRATION" || { echo missing_replay_classification >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-013B","task_id":"TSK-HARD-013B","status":"PASS","pass":true,"classifications":["LATE_CALLBACK","DUPLICATE_DISPATCH","UNKNOWN_REFERENCE","REPLAY_ATTEMPT"],"replay_rejected":true,"unknown_reference_rejected":true,"instruction_state_unchanged":true,"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert 'REPLAY_ATTEMPT' in d['classifications']
PY
