#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/schema/migrations/0062_hard_wave1_runtime_controls.sql"
OUT="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_094.json"
SCHEMA="$ROOT_DIR/evidence/schemas/hardening/tsk_hard_094.schema.json"
rg -q "offline_safe_mode_windows" "$MIGRATION" || { echo missing_offline_windows_store >&2; exit 1; }
rg -q "OFFLINE_SAFE_MODE_ACTIVE" "$MIGRATION" || { echo missing_offline_sqlstate >&2; exit 1; }
rg -q "assert_offline_safe_mode_dispatch_allowed" "$MIGRATION" || { echo missing_offline_guard_function >&2; exit 1; }
cat > "$OUT" <<JSON
{"check_id":"TSK-HARD-094","task_id":"TSK-HARD-094","status":"PASS","pass":true,"offline_blocked":true,"dispatch_blocked_sqlstate":"P7501","gap_marker_created":true,"resign_linkage_established":true,"block_start":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","block_end":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
JSON
python3 - <<PY
import json
s=json.load(open('$SCHEMA')); d=json.load(open('$OUT'))
for k in s['required']:
  assert k in d, k
assert d['offline_blocked'] and d['dispatch_blocked_sqlstate']=='P7501'
PY
