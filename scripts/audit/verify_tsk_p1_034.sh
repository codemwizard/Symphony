#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
TASK_EVIDENCE="$EVIDENCE_DIR/tsk_p1_034_approval_metadata_hardening.json"
SOURCE_EVIDENCE="$EVIDENCE_DIR/approval_metadata.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR TASK_EVIDENCE SOURCE_EVIDENCE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

bash "$ROOT_DIR/scripts/audit/verify_agent_conformance.sh"
RUN_PHASE1_GATES=1 bash "$ROOT_DIR/scripts/audit/verify_phase1_contract.sh"
bash "$ROOT_DIR/scripts/audit/tests/test_approval_metadata_requirements.sh"

python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
task_evidence = Path(os.environ["TASK_EVIDENCE"])
source = Path(os.environ["SOURCE_EVIDENCE"])
errors = []
summary = {}
if not source.exists():
    errors.append(f"missing_evidence:{source}")
else:
    payload = json.loads(source.read_text(encoding="utf-8"))
    try:
        approval = payload["human_approval"]["approval_artifact_ref"]
        regulated = payload["change_scope"]["regulated_surfaces_touched"]
        changed = len(payload["change_scope"]["paths_changed"])
        summary = {
            "regulated_surfaces_touched": regulated,
            "paths_changed_count": changed,
            "approval_artifact_ref": approval,
        }
    except Exception as exc:
        errors.append(f"approval_metadata_shape_invalid:{exc}")
status = "PASS" if not errors else "FAIL"
out = {
    "task_id": "TSK-P1-034",
    "check_id": "TSK-P1-034-APPROVAL-METADATA-HARDENING",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "pass": status == "PASS",
    "source_evidence": str(source.relative_to(root)),
    "summary": summary,
    "errors": errors,
}
task_evidence.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    raise SystemExit(1)
print(f"TSK-P1-034 verification passed. Evidence: {task_evidence}")
PY
