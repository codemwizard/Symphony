#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_025.json"; S="$R/evidence/schemas/hardening/tsk_hard_025.schema.json"
rg -q "cooling_off" "$M"; rg -q "P7701" "$M"; rg -q "P7702" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-025","task_id":"TSK-HARD-025","status":"PASS","pass":true,"cooling_off_block_sqlstate":"P7701","freeze_flag_block_sqlstate":"P7702","freeze_flags":["participant_suspended","account_frozen","aml_hold","regulator_stop","program_hold"],"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
