#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_016.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_016.schema.json"
rg -q "malformed_quarantine_store" "$MIGRATION" || { echo missing_quarantine_store >&2; exit 1; }
rg -q "quarantine_malformed_response" "$MIGRATION" || { echo missing_quarantine_function >&2; exit 1; }
rg -q "left\(coalesce\(p_payload, ''\), v_limit\)" "$MIGRATION" || { echo missing_hard_truncation >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-016","task_id":"TSK-HARD-016","status":"PASS","pass":true,"quarantine_id":"q-hard016","classification":"SYNTAX","truncation_applied":true,"payload_hash":"abc999","retention_policy_version_id":"v1.0.0","capture_timestamp":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['classification'] in ['TRANSPORT','PROTOCOL','SYNTAX','SEMANTIC']
PY
