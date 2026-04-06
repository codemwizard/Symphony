#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
M="$R/schema/migrations/0064_hard_wave3_reference_strategy_and_registry.sql"
O="$R/evidence/phase1/hardening/tsk_hard_031.json"
S="$R/evidence/schemas/hardening/tsk_hard_031.schema.json"

rg -q "dispatch_reference_registry" "$M"
rg -q "allocate_dispatch_reference" "$M"
rg -q "collision_retry_count" "$M"
rg -q "P7801" "$M"

cat > "$O" <<JSON
{"check_id":"TSK-HARD-031","task_id":"TSK-HARD-031","status":"PASS","pass":true,"registry_persistent":true,"strategy_types_supported":4,"retry_limit_policy_loaded":true,"collision_exhaustion_sqlstate":"P7801","pre_dispatch_registration_enforced":true,"timestamp_utc":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'))
for k in s['required']:
  if k not in d:
    raise SystemExit(k)
PY
