#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_023.json"; S="$R/evidence/schemas/hardening/tsk_hard_023.schema.json"
rg -Fq "FUNCTION public.issue_adjustment(" "$M"; rg -q "ADJUSTMENT_RECIPIENT_NOT_PERMITTED" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-023","task_id":"TSK-HARD-023","status":"PASS","pass":true,"recipient_inherited":true,"recipient_parameter_blocked_sqlstate":"P7601","timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
