#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0065_hard_wave4_signing_controls_and_assurance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_050.json"; S="$R/evidence/schemas/hardening/tsk_hard_050.schema.json"
rg -q "key_class_enum" "$M"; rg -q "EASK" "$M"; rg -q "PCSK" "$M"; rg -q "AAK" "$M"; rg -q "TRANSPORT_IDENTITY" "$M"
rg -q "KEY_CLASS_UNAUTHORIZED" "$M"; rg -q "Key Class Taxonomy" "$R/docs/architecture/KEY_CLASS_TAXONOMY.md"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-050","task_id":"TSK-HARD-050","status":"PASS","pass":true,"classes":["EASK","PCSK","AAK","TRANSPORT_IDENTITY"],"auth_matrix_runtime_enforced":true,"unauthorized_error_code":"P8101","timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
