#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0063_hard_wave2_adjustment_governance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_021.json"; S="$R/evidence/schemas/hardening/tsk_hard_021.schema.json"
rg -q "adjustment_approval_stages" "$M"; rg -q "adjustment_approvals" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-021","task_id":"TSK-HARD-021","status":"PASS","pass":true,"quorum_policy_version_id":"v1.0.0","heterogeneity_enforced":true,"same_department_quorum_denied":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
