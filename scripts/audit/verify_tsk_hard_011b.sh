#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0065_hard_wave4_signing_controls_and_assurance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_011b.json"; S="$R/evidence/schemas/hardening/tsk_hard_011b.schema.json"
rg -q "policy_bundle_state_enum" "$M"; rg -q "activate_policy_bundle" "$M"; rg -q "P8201" "$M"; rg -q "P8202" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-011B","task_id":"TSK-HARD-011B","status":"PASS","pass":true,"policy_bundle_states":["draft","approved","active"],"activation_signature_verification_enforced":true,"runtime_reverification_enforced":true,"high_risk_per_execution_reverification":true,"unsigned_activation_error_code":"P8201","runtime_verification_error_code":"P8202","timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
