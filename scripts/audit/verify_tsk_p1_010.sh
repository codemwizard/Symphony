#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-010"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_010_phase1_closeout_verification.json}"

source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"
mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<'PY' "$ROOT_DIR" "$TASK_ID" "$EVIDENCE_PATH" "$ts" "$git_sha_val" "$schema_fp"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
task_id = sys.argv[2]
evidence_path = Path(sys.argv[3])
ts = sys.argv[4]
git_sha = sys.argv[5]
schema_fp = sys.argv[6]

task_meta = root / "tasks/TSK-P1-010/meta.yml"
phase1_closeout = root / "evidence/phase1/phase1_closeout.json"
reg_demo = root / "evidence/phase1/regulator_demo_pack.json"
tier1_demo = root / "evidence/phase1/tier1_pilot_demo_pack.json"

errors = []
details = {}

if not task_meta.exists():
    errors.append("missing_task_meta:tasks/TSK-P1-010/meta.yml")
else:
    import yaml
    meta = yaml.safe_load(task_meta.read_text(encoding="utf-8")) or {}
    deps = meta.get("depends_on", []) or []
    dep_status = {}
    for dep in deps:
        dep_meta_path = root / "tasks" / dep / "meta.yml"
        if not dep_meta_path.exists():
            dep_status[dep] = "missing_meta"
            errors.append(f"missing_dependency_meta:{dep}")
            continue
        dep_meta = yaml.safe_load(dep_meta_path.read_text(encoding="utf-8")) or {}
        st = str(dep_meta.get("status", "")).lower()
        dep_status[dep] = st
        if st != "completed":
            errors.append(f"dependency_not_completed:{dep}:{st}")
    details["dependency_status"] = dep_status

for label, path in [
    ("phase1_closeout", phase1_closeout),
    ("regulator_demo_pack", reg_demo),
    ("tier1_pilot_demo_pack", tier1_demo),
]:
    if not path.exists():
        errors.append(f"missing_evidence:{path.relative_to(root)}")
        details[label] = {"exists": False}
        continue
    payload = json.loads(path.read_text(encoding="utf-8"))
    status = str(payload.get("status", "")).upper()
    details[label] = {"exists": True, "status": status}
    if status != "PASS":
        errors.append(f"evidence_not_pass:{path.relative_to(root)}:{status}")

out = {
    "check_id": "TSK-P1-010-CLOSEOUT",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": git_sha,
    "schema_fingerprint": schema_fp,
    "status": "PASS" if not errors else "FAIL",
    "pass": not errors,
    "details": details,
    "errors": errors,
}
evidence_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P1-010 verifier status: {out['status']}")
print(f"Evidence: {evidence_path}")
raise SystemExit(0 if out["pass"] else 1)
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
