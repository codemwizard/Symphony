#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/remediation_workflow_doc.json"
DOC="$ROOT_DIR/docs/operations/REMEDIATION_TRACE_WORKFLOW.md"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

DOC="$DOC" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

doc = Path(os.environ["DOC"])
evidence_out = Path(os.environ["EVIDENCE_FILE"])

check_id = "REMEDIATION-WORKFLOW-DOC"

required = [
    "production-affecting surfaces",
    "remediation casefile",
    "failure_signature",
    "origin_task_id",
    "repro_command",
    "verification_commands_run",
    "final_status",
]

errors: list[str] = []

if not doc.exists():
    errors.append("missing_doc:docs/operations/REMEDIATION_TRACE_WORKFLOW.md")
    text = ""
else:
    text = doc.read_text(encoding="utf-8", errors="ignore").lower()
    for r in required:
        if r not in text:
            errors.append(f"missing_required_token:{r}")

out = {
    "check_id": check_id,
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "doc_path": "docs/operations/REMEDIATION_TRACE_WORKFLOW.md",
    "errors": errors,
}

evidence_out.parent.mkdir(parents=True, exist_ok=True)
evidence_out.write_text(json.dumps(out, indent=2) + "\n")

if errors:
    print("Remediation workflow doc verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)

print("Remediation workflow doc verification passed")
PY

echo "Remediation workflow doc evidence: $EVIDENCE_FILE"

