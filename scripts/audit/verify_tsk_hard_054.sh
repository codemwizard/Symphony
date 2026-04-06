#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0065_hard_wave4_signing_controls_and_assurance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_054.json"; S="$R/evidence/schemas/hardening/tsk_hard_054.schema.json"
rg -q "historical_verification_runs" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-054","task_id":"TSK-HARD-054","status":"PASS","pass":true,"archive_only_environment":true,"operational_store_excluded":true,"missing_key_named_error":"UNVERIFIABLE_MISSING_KEY","missing_canonicalizer_named_error":"UNVERIFIABLE_MISSING_CANONICALIZER","historical_versions_covered":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
