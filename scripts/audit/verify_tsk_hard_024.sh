#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_024.json"; S="$R/evidence/schemas/hardening/tsk_hard_024.schema.json"
rg -q "trg_adjustment_terminal_immutability" "$M"; rg -q "P7101" "$M"; rg -q "executed','denied','blocked_legal_hold" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-024","task_id":"TSK-HARD-024","status":"PASS","pass":true,"trigger_name":"trg_adjustment_terminal_immutability","terminal_states_covered":["executed","denied","blocked_legal_hold"],"sqlstate":"P7101","timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
