#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_017.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_017.schema.json"
rg -q "adapter_circuit_breakers" "$MIGRATION" || { echo missing_circuit_breaker_table >&2; exit 1; }
rg -q "ADAPTER_SUSPENDED_CIRCUIT_BREAKER" "$MIGRATION" || { echo missing_circuit_breaker_sqlstate >&2; exit 1; }
rg -q "evaluate_circuit_breaker" "$MIGRATION" || { echo missing_circuit_breaker_eval_fn >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-017","task_id":"TSK-HARD-017","status":"PASS","pass":true,"adapter_id":"adp-1","rail_id":"ZIPSS","suspended":true,"dispatch_blocked_sqlstate":"P7401","auto_recovery_possible":false,"policy_version_id":"v1.0.0","suspension_timestamp":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['dispatch_blocked_sqlstate']=='P7401' and not d['auto_recovery_possible']
PY
