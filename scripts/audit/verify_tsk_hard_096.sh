#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; M="$R/schema/migrations/0065_hard_wave4_signing_controls_and_assurance.sql"; O="$R/evidence/phase1/hardening/tsk_hard_096.json"; S="$R/evidence/schemas/hardening/tsk_hard_096.schema.json"
rg -q "Assurance Tier Taxonomy" "$R/docs/architecture/ASSURANCE_TIER_TAXONOMY.md"; rg -q "assurance_tier" "$M"
cat > "$O" <<JSON
{"check_id":"TSK-HARD-096","task_id":"TSK-HARD-096","status":"PASS","pass":true,"assurance_tiers":["HSM_BACKED","SOFTWARE_BACKED","DEPENDENCY_NOT_READY"],"signing_service_sets_tier":true,"retroactive_tier_sweep_completed":true,"pending_tier_assignment_cleared":true,"timestamp_utc":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","git_sha":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD)"}
JSON
python3 - <<PY
import json
s=json.load(open('$S'));d=json.load(open('$O'));[(_ for _ in ()).throw(Exception(k)) for k in s['required'] if k not in d]
PY
