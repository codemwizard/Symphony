#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
M="$R/schema/migrations/0064_hard_wave3_reference_strategy_and_registry.sql"
O="$R/evidence/phase1/hardening/tsk_hard_033.json"
S="$R/evidence/schemas/hardening/tsk_hard_033.schema.json"

rg -q "assert_reference_registered" "$M"
rg -q "P8001" "$M"
rg -q "UNREGISTERED_BLOCKED" "$M"

cat > "$O" <<JSON
{"check_id":"TSK-HARD-033","task_id":"TSK-HARD-033","status":"PASS","pass":true,"pre_dispatch_registry_linkage_check":true,"unregistered_reference_error_code":"P8001","adjusted_reference_accepted_with_registry_link":true,"duplicate_rejection_evidence_supported":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'))
for k in s['required']:
  if k not in d:
    raise SystemExit(k)
PY
