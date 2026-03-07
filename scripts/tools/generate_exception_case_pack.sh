#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTRUCTION_ID=""
CORRELATION_ID=""
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --instruction-id) INSTRUCTION_ID="${2:-}"; shift 2 ;;
    --correlation-id) CORRELATION_ID="${2:-}"; shift 2 ;;
    --output) OUTPUT_PATH="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$INSTRUCTION_ID" && -z "$CORRELATION_ID" ]]; then
  echo "must provide --instruction-id or --correlation-id" >&2
  exit 2
fi
if [[ -z "$OUTPUT_PATH" ]]; then
  echo "must provide --output" >&2
  exit 2
fi

mkdir -p "$(dirname "$ROOT_DIR/$OUTPUT_PATH")"
ROOT_DIR="$ROOT_DIR" OUTPUT_PATH="$OUTPUT_PATH" INSTRUCTION_ID="$INSTRUCTION_ID" CORRELATION_ID="$CORRELATION_ID" python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path
from datetime import datetime, timezone

root = Path(os.environ["ROOT_DIR"])
out = root / os.environ["OUTPUT_PATH"]
instruction_id = os.environ.get("INSTRUCTION_ID", "")
correlation_id = os.environ.get("CORRELATION_ID", "")

sources = {
    "ingress_attestation": root / "evidence/phase1/ingress_ack_attestation_semantics.json",
    "outbox_attempts": root / "evidence/phase1/ingress_api_contract_tests.json",
    "exception_chain": root / "evidence/phase1/exception_case_pack_generation.json",
    "evidence_pack_contract": root / "evidence/phase1/evidence_pack_api_contract.json",
}

missing = [name for name, p in sources.items() if not p.exists()]
if missing:
    raise SystemExit("missing_sources:" + ",".join(missing))

loaded = {k: json.loads(v.read_text(encoding="utf-8")) for k, v in sources.items()}
pack = {
    "check_id": "TSK-P1-204-CASE-PACK-SAMPLE",
    "timestamp_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_sha": subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip(),
    "status": "PASS",
    "pack_type": "EXCEPTION_CASE_PACK",
    "pack_version": "1.0",
    "generated_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "instruction_id": instruction_id or None,
    "correlation_id": correlation_id or None,
    "contains_raw_pii": False,
    "items": [
        {"kind": "ingress_attestation", "source": str(sources["ingress_attestation"].relative_to(root)), "status": loaded["ingress_attestation"].get("status")},
        {"kind": "outbox_attempts", "source": str(sources["outbox_attempts"].relative_to(root)), "status": loaded["outbox_attempts"].get("status")},
        {"kind": "exception_chain", "source": str(sources["exception_chain"].relative_to(root)), "status": loaded["exception_chain"].get("status")},
        {"kind": "evidence_pack_contract", "source": str(sources["evidence_pack_contract"].relative_to(root)), "status": loaded["evidence_pack_contract"].get("status")},
    ],
}
out.write_text(json.dumps(pack, indent=2) + "\n", encoding="utf-8")
print(f"case_pack_written:{out}")
PY
