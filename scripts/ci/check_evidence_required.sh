#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_ROOT="${1:-$ROOT_DIR/evidence/phase0}"
CONTRACT_PATH="$ROOT_DIR/docs/PHASE0/phase0_contract.yml"

if [[ "$EVIDENCE_ROOT" != /* ]]; then
  EVIDENCE_ROOT="$ROOT_DIR/$EVIDENCE_ROOT"
fi

ROOT_DIR="$ROOT_DIR" EVIDENCE_ROOT="$EVIDENCE_ROOT" CONTRACT_PATH="$CONTRACT_PATH" python3 - <<'PY'
import json
import os
import sys
from pathlib import Path
import glob

root = Path(os.environ["ROOT_DIR"])
evidence_root = Path(os.environ["EVIDENCE_ROOT"])
contract_path = Path(os.environ["CONTRACT_PATH"])

ci_only = os.environ.get("CI_ONLY", "0") == "1"

if not contract_path.exists():
    print(f"ERROR: contract not found: {contract_path}")
    sys.exit(1)

try:
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
except Exception as e:
    print(f"ERROR: failed to parse contract: {e}")
    sys.exit(1)

if not isinstance(contract, list):
    print("ERROR: contract must be a list")
    sys.exit(1)

missing = []
checked = []

def matches_for_path(path: str):
    path = path.strip()
    if not path:
        return []
    if path.startswith("./"):
        path = path[2:]

    candidates = []
    if ci_only:
        rel = path
        if rel.startswith("evidence/phase0/"):
            rel = rel[len("evidence/phase0/"):]
        candidates.append(evidence_root / rel)
        candidates.append(evidence_root / "evidence" / "phase0" / rel)
    else:
        candidates.append(root / path)

    matches = []
    for cand in candidates:
        matches.extend(glob.glob(str(cand)))

    if ci_only and not matches:
        # fallback: search basename anywhere under evidence_root
        basename = Path(path).name
        matches = [str(p) for p in evidence_root.rglob(basename)]

    return matches

for row in contract:
    if not isinstance(row, dict):
        continue
    status = str(row.get("status", "")).lower()
    if status != "completed":
        continue
    if row.get("evidence_required") is not True:
        continue

    verification_mode = row.get("verification_mode", "both")
    if ci_only and verification_mode == "local":
        continue
    if (not ci_only) and verification_mode == "ci":
        continue

    task_id = row.get("task_id", "(unknown)")
    evidence_paths = row.get("evidence_paths") or []

    for path in evidence_paths:
        path = str(path)
        if ci_only and path in ("evidence/phase0/local_ci_parity.json", "local_ci_parity.json"):
            # local-only evidence; skip in CI gate
            continue
        matches = matches_for_path(path)
        checked.append((task_id, path, len(matches)))
        if len(matches) == 0:
            missing.append(f"{task_id}: {path}")

if missing:
    print("Missing evidence artifacts:")
    for m in missing:
        print(f" - {m}")
    sys.exit(1)

print("Evidence check passed. Checked:")
for task_id, pattern, count in checked:
    print(f" - {task_id}: {pattern} ({count})")
PY
