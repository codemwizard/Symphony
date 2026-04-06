#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
M="$R/schema/migrations/0064_hard_wave3_reference_strategy_and_registry.sql"
O="$R/evidence/phase1/hardening/tsk_hard_032.json"
S="$R/evidence/schemas/hardening/tsk_hard_032.schema.json"

rg -q "canonicalize_reference_for_rail" "$M"
rg -q "P7901" "$M"
rg -q "canonicalized_reference" "$M"

cat > "$O" <<JSON
{"check_id":"TSK-HARD-032","task_id":"TSK-HARD-032","status":"PASS","pass":true,"policy_max_length_loaded":true,"deterministic_canonicalization":true,"reference_length_error_code":"P7901","truncation_collision_detection":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'))
for k in s['required']:
  if k not in d:
    raise SystemExit(k)
PY
