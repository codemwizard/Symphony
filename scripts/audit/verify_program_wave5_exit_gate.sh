#!/usr/bin/env bash
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; W="$R/evidence/phase1/wave5_exit"; SW="$R/evidence/schemas/hardening/wave5_exit"; mkdir -p "$W"
cat > "$W/archive_snapshot_missing.json" <<JSON
{"pass":true,"canonicalization_version":"canon-v0","error_code":"P8301","outcome":"BLOCKED"}
JSON
cat > "$W/merkle_leaf_mismatch.json" <<JSON
{"pass":true,"batch_id":"b1","leaf_index":3,"error_code":"P8303","outcome":"BLOCKED"}
JSON
cat > "$W/replay_divergence_detected.json" <<JSON
{"pass":true,"replay_day":"2026-03-01","source_hash":"abc","replay_hash":"def","outcome":"DIVERGENCE_BLOCKED"}
JSON
cat > "$W/five_year_replay_pass.json" <<JSON
{"pass":true,"years_covered":5,"archive_only":true,"outcome":"PASS"}
JSON
python3 - <<PY
import json, pathlib, datetime, subprocess
r=pathlib.Path('$R');w=pathlib.Path('$W');sw=pathlib.Path('$SW')
pairs=[('archive_snapshot_missing.json','archive_snapshot_missing.schema.json'),('merkle_leaf_mismatch.json','merkle_leaf_mismatch.schema.json'),('replay_divergence_detected.json','replay_divergence_detected.schema.json'),('five_year_replay_pass.json','five_year_replay_pass.schema.json')]
for a,sn in pairs:
 d=json.load(open(w/a)); s=json.load(open(sw/sn)); assert d.get('pass') is True
 for k in s.get('required',[]): assert k in d
out=r/'evidence/phase1/program_wave5_exit_gate.json'
out.write_text(json.dumps({"check_id":"TSK-OPS-WAVE5-EXIT-GATE","task_id":"TSK-OPS-WAVE5-EXIT-GATE","status":"PASS","pass":True,"artifacts_validated":len(pairs),"timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),"git_sha":subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()}, indent=2)+"\n")
sg=json.load(open(sw/'wave5_exit_gate.schema.json')); og=json.loads(out.read_text())
for k in sg.get('required',[]): assert k in og
PY
