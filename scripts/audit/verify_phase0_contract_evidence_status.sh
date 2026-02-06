#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_PATH="$ROOT_DIR/docs/PHASE0/phase0_contract.yml"
CONTROL_PLANES_PATH="$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/phase0_contract_evidence_status.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
export CONTRACT_PATH CONTROL_PLANES_PATH EVIDENCE_FILE

python3 - <<'PY'
import json
import os
from pathlib import Path

contract_path = Path(os.environ["CONTRACT_PATH"])
cp_path = Path(os.environ["CONTROL_PLANES_PATH"])
evidence_out = Path(os.environ["EVIDENCE_FILE"])
repo_root = Path(os.environ.get("ROOT_DIR") or Path.cwd())
evidence_root_env = os.environ.get("EVIDENCE_ROOT")
evidence_root = None
if evidence_root_env:
    p = Path(evidence_root_env)
    evidence_root = p if p.is_absolute() else (repo_root / p)

ci_only = os.environ.get("CI_ONLY") == "1" or os.environ.get("GITHUB_ACTIONS") == "true"

try:
    import yaml  # type: ignore
except Exception as e:
    out = {
        "check_id": "PHASE0-CONTRACT-EVIDENCE-STATUS",
        "timestamp_utc": os.environ.get("EVIDENCE_TS"),
        "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
        "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
        "status": "FAIL",
        "errors": ["pyyaml_missing", str(e)],
    }
    evidence_out.write_text(json.dumps(out, indent=2) + "\n")
    raise SystemExit(1)

errors = []
checked = []

if not contract_path.exists():
    errors.append("contract_missing")
    contract = []
else:
    contract = json.loads(contract_path.read_text(encoding="utf-8"))

if not cp_path.exists():
    errors.append("control_planes_missing")
    cp = {}
else:
    cp = yaml.safe_load(cp_path.read_text(encoding="utf-8")) or {}

gate_map = {}
for plane in (cp.get("control_planes") or {}).values():
    for gate in plane.get("required_gates") or []:
        gid = gate.get("gate_id")
        ev = gate.get("evidence")
        if gid and ev:
            gate_map[str(gid)] = str(ev)

def load_status(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data.get("status")
    except Exception:
        return None

for row in contract:
    if not isinstance(row, dict):
        continue
    task_id = row.get("task_id", "(unknown)")
    status = str(row.get("status", "")).lower()
    verification_mode = str(row.get("verification_mode", "both")).lower()
    gate_ids = row.get("gate_ids") or []

    if ci_only and verification_mode == "local":
        continue
    if (not ci_only) and verification_mode == "ci":
        continue

    if not gate_ids:
        # Gate-scoped check only applies where gate_ids are defined
        continue

    for gid in gate_ids:
        ev_rel = gate_map.get(str(gid))
        if not ev_rel:
            errors.append(f"{task_id}:gate_not_declared:{gid}")
            continue

        # Skip self-evidence regardless of file presence to avoid recursion.
        expected_rel = os.path.relpath(evidence_out, repo_root)
        if str(ev_rel) == expected_rel:
            continue
        ev_path = Path(ev_rel)
        if not ev_path.is_absolute():
            base = evidence_root or repo_root
            ev_path = base / ev_path

        # If artifacts were downloaded into evidence/phase0, we may end up with:
        #   evidence/phase0/evidence/phase0/<file>.json
        # Support a fallback to the basename when the contract path is prefixed.
        candidates = [ev_path]
        if str(ev_rel).startswith("evidence/phase0/"):
            candidates.append((evidence_root or repo_root) / Path(ev_rel).name)

        ev_path = None
        for c in candidates:
            if c.exists():
                ev_path = c
                break

        # As a last resort, search for the basename anywhere under evidence_root.
        if ev_path is None and evidence_root is not None:
            basename = Path(ev_rel).name
            matches = [p for p in evidence_root.rglob(basename)]
            if len(matches) == 1:
                ev_path = matches[0]
            elif len(matches) > 1:
                errors.append(f"{task_id}:multiple_evidence_matches:{gid}:{basename}")
                continue

        if ev_path and ev_path.resolve() == evidence_out.resolve():
            # Skip self-evidence to avoid recursion
            continue

        if ev_path is None or not ev_path.exists():
            errors.append(f"{task_id}:missing_evidence:{gid}:{ev_rel}")
            continue

        ev_status = load_status(ev_path)
        checked.append({"task_id": task_id, "gate_id": gid, "evidence": ev_rel, "status": ev_status})

        if ev_status not in ("PASS", "FAIL", "SKIPPED"):
            errors.append(f"{task_id}:invalid_evidence_status:{gid}:{ev_status}")
            continue

        if status == "completed":
            if ev_status != "PASS":
                errors.append(f"{task_id}:completed_requires_pass:{gid}:{ev_status}")
        else:
            if ev_status not in ("PASS", "SKIPPED"):
                errors.append(f"{task_id}:noncompleted_requires_pass_or_skipped:{gid}:{ev_status}")

out = {
    "check_id": "PHASE0-CONTRACT-EVIDENCE-STATUS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "errors": errors,
    "checked": checked,
}

evidence_out.write_text(json.dumps(out, indent=2) + "\n")

if errors:
    print("❌ Phase-0 contract evidence status check failed")
    for e in errors:
        print(f" - {e}")
    raise SystemExit(1)

print(f"Phase-0 contract evidence status check passed. Evidence: {evidence_out}")
PY
export ROOT_DIR
