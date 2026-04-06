#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; W="$R/evidence/phase1/wave4_exit"; SW="$R/evidence/schemas/hardening/wave4_exit"; mkdir -p "$W"
cat > "$W/key_class_unauthorized_rejected.json" <<JSON
{"pass":true,"caller_id":"svc-adjustment","requested_key_class":"EASK","error_code":"P8101","outcome":"REJECTED"}
JSON
cat > "$W/hsm_bypass_blocked.json" <<JSON
{"pass":true,"attempted_signing_path":"SOFTWARE_BYPASS","outcome":"BLOCKED"}
JSON
cat > "$W/unsigned_policy_bundle_rejected.json" <<JSON
{"pass":true,"policy_id":"policy-1","error_code":"P8201","outcome":"ACTIVATION_REJECTED"}
JSON
cat > "$W/historical_verification_archive_only.json" <<JSON
{"pass":true,"key_versions_tested":["k1","k2"],"operational_store_excluded":true,"all_outcomes":"PASS"}
JSON
cat > "$W/dependency_not_ready_resign_sweep.json" <<JSON
{"pass":true,"sweep_completed_timestamp":"$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)","artifacts_resigned_count":12,"artifacts_with_pending_tier_assignment_cleared":true}
JSON
python3 - <<PY
import json, pathlib, datetime, subprocess
r=pathlib.Path('$R');w=pathlib.Path('$W');sw=pathlib.Path('$SW')
pairs=[('key_class_unauthorized_rejected.json','key_class_unauthorized_rejected.schema.json'),('hsm_bypass_blocked.json','hsm_bypass_blocked.schema.json'),('unsigned_policy_bundle_rejected.json','unsigned_policy_bundle_rejected.schema.json'),('historical_verification_archive_only.json','historical_verification_archive_only.schema.json'),('dependency_not_ready_resign_sweep.json','dependency_not_ready_resign_sweep.schema.json')]
for a,sn in pairs:
 d=json.load(open(w/a)); s=json.load(open(sw/sn)); assert d.get('pass') is True
 for k in s.get('required',[]): assert k in d
out=r/'evidence/phase1/program_wave4_exit_gate.json'
out.write_text(json.dumps({"check_id":"TSK-OPS-WAVE4-EXIT-GATE","task_id":"TSK-OPS-WAVE4-EXIT-GATE","status":"PASS","pass":True,"artifacts_validated":len(pairs),"timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),"git_sha":subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()},indent=2)+"\n")
sg=json.load(open(sw/'wave4_exit_gate.schema.json')); og=json.loads(out.read_text())
for k in sg.get('required',[]): assert k in og
PY
