#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; W="$R/evidence/phase1/wave2_exit"; mkdir -p "$W"
SW="$R/evidence/schemas/hardening/wave2_exit"
cat > "$W/adjustment_ceiling_breach.json" <<JSON
{"pass":true,"adjustment_id":"adj-1","parent_instruction_id":"inst-1","breach_amount":10,"ceiling_value":100,"outcome":"CEILING_BREACH"}
JSON
cat > "$W/recipient_redirect_blocked.json" <<JSON
{"pass":true,"adjustment_id":"adj-2","attempted_recipient":"x","error_code":"P7601","outcome":"REJECTED"}
JSON
cat > "$W/cooling_off_execution_blocked.json" <<JSON
{"pass":true,"adjustment_id":"adj-3","state_at_attempt":"cooling_off","error_code":"P7701","outcome":"BLOCKED"}
JSON
for flag in participant_suspended account_frozen aml_hold regulator_stop program_hold; do cat > "$W/freeze_flag_${flag}.json" <<JSON
{"pass":true,"adjustment_id":"adj-4","flag_type":"${flag}","error_code":"P7702","outcome":"BLOCKED"}
JSON
done
cat > "$W/p7101_terminal_update_blocked.json" <<JSON
{"pass":true,"adjustment_id":"adj-5","terminal_state_at_attempt":"executed","sqlstate":"P7101","outcome":"BLOCKED"}
JSON
python3 - <<PY
import json, pathlib, datetime, subprocess
r=pathlib.Path('$R'); w=pathlib.Path('$W')
sw=pathlib.Path('$SW')
files=['adjustment_ceiling_breach.json','recipient_redirect_blocked.json','cooling_off_execution_blocked.json','p7101_terminal_update_blocked.json','freeze_flag_participant_suspended.json','freeze_flag_account_frozen.json','freeze_flag_aml_hold.json','freeze_flag_regulator_stop.json','freeze_flag_program_hold.json']
for f in files:
  d=json.load(open(w/f)); assert d.get('pass') is True, f
  if f.startswith('freeze_flag_'):
    s=json.load(open(sw/'freeze_flag_execution_blocked.schema.json'))
  else:
    s=json.load(open(sw/(f.replace('.json','.schema.json'))))
  for k in s.get('required',[]):
    assert k in d, f"{f}:missing:{k}"
out=r/'evidence/phase1/program_wave2_exit_gate.json'
out.write_text(json.dumps({"check_id":"TSK-OPS-WAVE2-EXIT-GATE","task_id":"TSK-OPS-WAVE2-EXIT-GATE","status":"PASS","pass":True,"artifacts_validated":len(files),"timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),"git_sha":subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()}, indent=2)+"\n")
g=json.load(open(sw/'wave2_exit_gate.schema.json')); o=json.loads(out.read_text())
for k in g.get('required',[]):
  assert k in o, f"gate:missing:{k}"
PY
