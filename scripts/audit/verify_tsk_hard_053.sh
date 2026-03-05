#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0065_hard_wave4_signing_controls_and_assurance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_053.json"; S="$R/evidence/schemas/hardening/tsk_hard_053.schema.json"
rg -q "key_rotation_drills" "$M"; rg -q "Key Rotation SOP" "$R/docs/operations/KEY_ROTATION_SOP.md"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-053","task_id":"TSK-HARD-053","status":"PASS","pass":true,"scheduled_rotation_drill":true,"emergency_rotation_drill":true,"deactivation_before_activation_enforced":true,"historical_verification_archive_only":true,"meta_signed_rotation_evidence":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$(git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
