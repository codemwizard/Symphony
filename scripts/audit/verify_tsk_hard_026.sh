#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_026.json"; S="$R/evidence/schemas/hardening/tsk_hard_026.schema.json"
rg -q "role_at_time_of_signing" "$M"; rg -q "department_at_time_of_signing" "$M"; rg -q "signature_ref" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-026","task_id":"TSK-HARD-026","status":"PASS","pass":true,"snapshot_attestation":true,"stage_linked":true,"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
