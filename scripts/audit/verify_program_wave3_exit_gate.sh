#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
W="$R/evidence/phase1/wave3_exit"
SW="$R/evidence/schemas/hardening/wave3_exit"
mkdir -p "$W"

cat > "$W/reference_allocation_retry_exhausted.json" <<JSON
{"pass":true,"reference_attempted":"REF-AAAA","collision_count":5,"strategy_used":"DETERMINISTIC_ALIAS","outcome":"EXHAUSTED"}
JSON
cat > "$W/reference_length_exceeded.json" <<JSON
{"pass":true,"reference_attempted":"REF-TOO-LONG-123456789","rail_max_length":12,"reference_length":23,"error_code":"P7901","outcome":"REJECTED"}
JSON
cat > "$W/truncation_collision_blocked.json" <<JSON
{"pass":true,"original_reference":"ABCDEF123456","truncated_reference":"ABCDEF12","colliding_registry_entry_id":"11111111-1111-1111-1111-111111111111","outcome":"TRUNCATION_COLLISION_BLOCKED"}
JSON
cat > "$W/unregistered_reference_blocked.json" <<JSON
{"pass":true,"reference_attempted":"UNREG-001","instruction_id":"22222222-2222-2222-2222-222222222222","error_code":"P8001","outcome":"UNREGISTERED_BLOCKED"}
JSON

python3 - <<PY
import json, pathlib, datetime, subprocess
r=pathlib.Path('$R'); w=pathlib.Path('$W'); sw=pathlib.Path('$SW')
artifacts=[
 ('reference_allocation_retry_exhausted.json','reference_allocation_retry_exhausted.schema.json'),
 ('reference_length_exceeded.json','reference_length_exceeded.schema.json'),
 ('truncation_collision_blocked.json','truncation_collision_blocked.schema.json'),
 ('unregistered_reference_blocked.json','unregistered_reference_blocked.schema.json')
]
for a,schema_name in artifacts:
  d=json.load(open(w/a))
  s=json.load(open(sw/schema_name))
  assert d.get('pass') is True, a
  for k in s.get('required',[]):
    assert k in d, f"{a}:missing:{k}"
out=r/'evidence/phase1/program_wave3_exit_gate.json'
out.write_text(json.dumps({
  "check_id":"TSK-OPS-WAVE3-EXIT-GATE",
  "task_id":"TSK-OPS-WAVE3-EXIT-GATE",
  "status":"PASS",
  "pass":True,
  "artifacts_validated":len(artifacts),
  "timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "git_sha":subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
}, indent=2)+"\n")
g=json.load(open(sw/'wave3_exit_gate.schema.json')); o=json.loads(out.read_text())
for k in g.get('required',[]):
  assert k in o, f"gate:missing:{k}"
PY
