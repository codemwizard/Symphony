#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_FILE="$ROOT_DIR/docs/governance/ci-gate-spec-v1.md"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/invariants.yml"
PRE_CI_FILE="$ROOT_DIR/scripts/dev/pre_ci.sh"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/invproc_03_ci_gate_spec_parity.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export SPEC_FILE WORKFLOW_FILE PRE_CI_FILE EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
import re
from pathlib import Path

spec_text = Path(os.environ["SPEC_FILE"]).read_text(encoding="utf-8")
workflow_text = Path(os.environ["WORKFLOW_FILE"]).read_text(encoding="utf-8")
pre_ci_text = Path(os.environ["PRE_CI_FILE"]).read_text(encoding="utf-8")
evidence_file = Path(os.environ["EVIDENCE_FILE"])

required_jobs = [
    "mechanical_invariants",
    "security_scan",
    "db_verify_invariants",
    "phase0_evidence_gate",
]
required_pre_ci_refs = [
    "scripts/audit/run_phase0_ordered_checks.sh",
    "scripts/db/verify_invariants.sh",
    "scripts/ci/verify_phase0_contract_evidence_status_parity.sh",
    "scripts/audit/verify_phase1_contract.sh",
    "scripts/audit/verify_phase1_closeout.sh",
]

errors = []
for job in required_jobs:
    if not re.search(rf"(?m)^  {re.escape(job)}:\s*$", workflow_text):
        errors.append(f"missing_workflow_job:{job}")
    if job not in spec_text:
        errors.append(f"missing_spec_job_reference:{job}")

for ref in required_pre_ci_refs:
    if ref not in pre_ci_text:
        errors.append(f"missing_pre_ci_reference:{ref}")

for ref in (
    ".github/workflows/invariants.yml",
    "scripts/dev/pre_ci.sh",
    "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
    "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
):
    if ref not in spec_text:
        errors.append(f"missing_spec_reference:{ref}")

out = {
    "check_id": "INVPROC-03-CI-GATE-SPEC-PARITY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "required_jobs": required_jobs,
    "required_pre_ci_refs": required_pre_ci_refs,
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ CI gate spec parity verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"CI gate spec parity verification passed. Evidence: {evidence_file}")
PY
