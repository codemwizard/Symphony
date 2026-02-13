#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_FILE="$ROOT_DIR/docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md"
META_SCHEMA="$ROOT_DIR/docs/operations/approval_metadata.schema.json"
SIDECAR_SCHEMA="$ROOT_DIR/docs/operations/approval_sidecar.schema.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/verify_agent_conformance_spec.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

SPEC_FILE="$SPEC_FILE" META_SCHEMA="$META_SCHEMA" SIDECAR_SCHEMA="$SIDECAR_SCHEMA" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

spec_file = Path(os.environ["SPEC_FILE"])
meta_schema = Path(os.environ["META_SCHEMA"])
sidecar_schema = Path(os.environ["SIDECAR_SCHEMA"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])

required_headers = [
    "## Purpose",
    "## Canonical Inputs",
    "## Regulated Surface Definition",
    "## Verification Rules",
    "## Failure Codes",
    "## Output Contract",
]
errors = []
found_headers = []

if not spec_file.exists():
    errors.append(f"missing_spec:{spec_file}")
    text = ""
else:
    text = spec_file.read_text(encoding="utf-8", errors="ignore")
    for h in required_headers:
        if h in text:
            found_headers.append(h)
        else:
            errors.append(f"missing_header:{h}")
    for required_ref in (
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        "docs/operations/approval_metadata.schema.json",
        "docs/operations/approval_sidecar.schema.json",
    ):
        if required_ref not in text:
            errors.append(f"missing_reference:{required_ref}")

if not meta_schema.exists():
    errors.append(f"missing_file:{meta_schema}")
if not sidecar_schema.exists():
    errors.append(f"missing_file:{sidecar_schema}")

out = {
    "check_id": "AGENT-CONFORMANCE-SPEC",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "spec_file": str(spec_file),
    "required_headers": required_headers,
    "found_headers": found_headers,
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Agent conformance spec verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"Agent conformance spec verification passed. Evidence: {evidence_file}")
PY
