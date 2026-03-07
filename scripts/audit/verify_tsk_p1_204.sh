#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_PATH="evidence/phase1/tsk_p1_204__exception_case_pack_generator_script_tool.json"
SAMPLE_PACK="evidence/phase1/exception_case_pack_sample.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence) EVIDENCE_PATH="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$(dirname "$ROOT_DIR/$EVIDENCE_PATH")" "$(dirname "$ROOT_DIR/$SAMPLE_PACK")"

"$ROOT_DIR/scripts/tools/generate_exception_case_pack.sh" \
  --instruction-id "P1-DEMO-INSTR-001" \
  --correlation-id "P1-DEMO-CORR-001" \
  --output "$SAMPLE_PACK"

ROOT_DIR="$ROOT_DIR" SAMPLE_PACK="$SAMPLE_PACK" EVIDENCE_PATH="$EVIDENCE_PATH" python3 - <<'PY'
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
sample = root / os.environ["SAMPLE_PACK"]
evidence = root / os.environ["EVIDENCE_PATH"]

errors = []
if not sample.exists():
    errors.append("sample_pack_missing")
    pack = {}
else:
    pack = json.loads(sample.read_text(encoding="utf-8"))

if pack.get("pack_type") != "EXCEPTION_CASE_PACK":
    errors.append("invalid_pack_type")
if not isinstance(pack.get("items"), list) or len(pack.get("items", [])) < 4:
    errors.append("pack_items_incomplete")
if pack.get("contains_raw_pii") is not False:
    errors.append("contains_raw_pii_not_false")

required_kinds = {"ingress_attestation", "outbox_attempts", "exception_chain", "evidence_pack_contract"}
kinds = {item.get("kind") for item in pack.get("items", []) if isinstance(item, dict)}
missing_kinds = sorted(required_kinds - kinds)
if missing_kinds:
    errors.append("missing_required_kinds:" + ",".join(missing_kinds))

payload = {
    "check_id": "TSK-P1-204-VERIFY",
    "timestamp_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip(),
    "task_id": "TSK-P1-204",
    "status": "PASS" if not errors else "FAIL",
    "pass": len(errors) == 0,
    "sample_pack_path": str(sample.relative_to(root)),
    "errors": errors,
}
evidence.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"evidence_written:{evidence}")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task TSK-P1-204 --evidence "$ROOT_DIR/$EVIDENCE_PATH"
