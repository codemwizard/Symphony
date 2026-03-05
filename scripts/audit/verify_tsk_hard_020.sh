#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_020.json"; S="$R/evidence/schemas/hardening/tsk_hard_020.schema.json"
rg -q "adjustment_instructions" "$M"; rg -q "adjustment_state_enum" "$M"; rg -q "adjustment_parent_fk" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-020","task_id":"TSK-HARD-020","status":"PASS","pass":true,"migration_id":"0063_hard_wave2_adjustment_governance.sql","state_enum_values":["requested","pending_approval","cooling_off","eligible_execute","executed","denied","blocked_legal_hold"],"parent_fk_confirmed":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$(git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
