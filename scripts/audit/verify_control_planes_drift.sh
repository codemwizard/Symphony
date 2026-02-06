#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CP_FILE="$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/control_planes_drift.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$CP_FILE" ]]; then
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "CONTROL-PLANES-DRIFT",
  "timestamp_utc": "$EVIDENCE_TS",
  "git_sha": "$EVIDENCE_GIT_SHA",
  "schema_fingerprint": "$EVIDENCE_SCHEMA_FP",
  "status": "FAIL",
  "errors": ["missing_control_planes_file"],
}
Path("$EVIDENCE_FILE").write_text(json.dumps(out, indent=2) + "\n")
PY
  echo "❌ Missing control planes file: $CP_FILE" >&2
  exit 1
fi

RUNNERS=(
  "$ROOT_DIR/scripts/audit/run_invariants_fast_checks.sh"
  "$ROOT_DIR/scripts/audit/run_security_fast_checks.sh"
  "$ROOT_DIR/scripts/audit/run_governance_fast_checks.sh"
  "$ROOT_DIR/scripts/audit/run_phase0_ordered_checks.sh"
  "$ROOT_DIR/scripts/dev/pre_ci.sh"
  "$ROOT_DIR/.github/workflows/invariants.yml"
)

CP_FILE="$CP_FILE" EVIDENCE_FILE="$EVIDENCE_FILE" ROOT_DIR="$ROOT_DIR" RUNNERS="${RUNNERS[*]}" python3 - <<'PY'
import json
import os
from pathlib import Path

cp_path = Path(os.environ["CP_FILE"])
root = Path(os.environ["ROOT_DIR"])
runners = [Path(p) for p in os.environ.get("RUNNERS", "").split() if p]

try:
    import yaml  # type: ignore
except Exception as e:
    out = {
        "check_id": "CONTROL-PLANES-DRIFT",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": ["pyyaml_missing"],
        "details": [str(e)],
    }
    Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

cp = yaml.safe_load(cp_path.read_text(encoding="utf-8")) or {}
planes = cp.get("control_planes") or {}

errors = []
warnings = []

if not isinstance(planes, dict) or not planes:
    errors.append("control_planes_missing_or_empty")

# Load runner contents
runner_text = {}
for r in runners:
    if r.exists():
        runner_text[str(r)] = r.read_text(encoding="utf-8", errors="ignore")
    else:
        warnings.append(f"runner_missing:{r}")

all_gate_ids = set()
all_evidence = set()

for plane_name, plane in (planes or {}).items():
    gates = plane.get("required_gates") or []
    if not isinstance(gates, list):
        errors.append(f"{plane_name}:required_gates_not_list")
        continue
    for g in gates:
        gate_id = (g or {}).get("gate_id")
        script = (g or {}).get("script")
        evidence = (g or {}).get("evidence")

        if not gate_id:
            errors.append(f"{plane_name}:missing_gate_id")
            continue
        if gate_id in all_gate_ids:
            errors.append(f"duplicate_gate_id:{gate_id}")
        all_gate_ids.add(gate_id)

        if not script:
            errors.append(f"{gate_id}:missing_script")
        else:
            script_path = root / script
            if not script_path.exists():
                errors.append(f"{gate_id}:script_missing:{script}")
            else:
                # ensure script is referenced in at least one runner
                found = any(script in txt for txt in runner_text.values())
                if not found:
                    errors.append(f"{gate_id}:script_not_wired:{script}")

        if not evidence:
            errors.append(f"{gate_id}:missing_evidence")
        else:
            if not str(evidence).startswith("evidence/phase0/"):
                errors.append(f"{gate_id}:evidence_path_not_phase0:{evidence}")
            if evidence in all_evidence:
                errors.append(f"duplicate_evidence_path:{evidence}")
            all_evidence.add(evidence)

status = "PASS" if not errors else "FAIL"

out = {
    "check_id": "CONTROL-PLANES-DRIFT",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "errors": errors,
    "warnings": warnings,
    "gate_count": len(all_gate_ids),
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")

if status != "PASS":
    print("❌ Control planes drift check failed")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)

print(f"Control planes drift check passed. Evidence: {os.environ['EVIDENCE_FILE']}")
PY
