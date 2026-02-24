#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="${1:-$ROOT_DIR/evidence/phase0/evidence_schema_validation.json}"

source "$ROOT_DIR/scripts/lib/evidence.sh"
ensure_evidence_write_allowed "$EVIDENCE_FILE"

python3 - "$ROOT_DIR" "$EVIDENCE_FILE" <<'PY'
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
out = Path(sys.argv[2])
required = {"check_id", "timestamp_utc", "git_sha", "status"}
invalid = []
valid_count = 0
files = []

for phase in ("phase0", "phase1"):
    p = root / "evidence" / phase
    if p.exists():
        files.extend(sorted(p.glob("*.json")))

for f in files:
    try:
        data = json.loads(f.read_text(encoding="utf-8"))
    except Exception as exc:
        invalid.append({"file": str(f.relative_to(root)), "error": f"invalid_json:{exc}"})
        continue

    missing = sorted(k for k in required if k not in data)
    if missing:
        invalid.append({"file": str(f.relative_to(root)), "error": f"missing_required:{','.join(missing)}"})
        continue
    valid_count += 1

status = "PASS" if not invalid else "FAIL"
payload = {
    "check_id": "EVIDENCE-JSON-VALIDATION",
    "task_id": "TSK-P0-103",
    "timestamp_utc": "TBD",
    "git_sha": "TBD",
    "status": status,
    "count_valid": valid_count,
    "count_invalid": len(invalid),
    "invalid_files": invalid,
    "schema_version": "1.0"
}

from subprocess import check_output
payload["timestamp_utc"] = check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]).decode().strip()
payload["git_sha"] = check_output(["git", "-C", str(root), "rev-parse", "HEAD"]).decode().strip()

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

print(status)
if status != "PASS":
    raise SystemExit(1)
PY

