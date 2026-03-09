#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PR_TEMPLATE="$ROOT_DIR/.github/pull_request_template.md"
EXCEPTION_TEMPLATE="$ROOT_DIR/docs/invariants/exceptions/EXCEPTION_TEMPLATE.md"
CHECKLIST="$ROOT_DIR/docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/invproc_05_governance_links.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export PR_TEMPLATE EXCEPTION_TEMPLATE CHECKLIST EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
from pathlib import Path

pr_text = Path(os.environ["PR_TEMPLATE"]).read_text(encoding="utf-8")
ex_text = Path(os.environ["EXCEPTION_TEMPLATE"]).read_text(encoding="utf-8")
checklist_text = Path(os.environ["CHECKLIST"]).read_text(encoding="utf-8")
evidence_file = Path(os.environ["EVIDENCE_FILE"])

errors = []

for needle in (
    "## Canonical Governance",
    "Invariant IDs impacted:",
    "Evidence artifacts added/updated:",
    "Approval metadata artifact:",
    "## DRD Declaration",
    "Severity declaration:",
    "DRD links:",
):
    if needle not in pr_text:
        errors.append(f"missing_pr_section:{needle}")

for needle in (
    "remediation_task:",
    "approved_by:",
    "approval_artifact_ref:",
    "## Compensating Controls",
    "## Verification",
    "## Exit Criteria",
):
    if needle not in ex_text:
        errors.append(f"missing_exception_field_or_section:{needle}")

for needle in (
    "evidence/phase1/approval_metadata.json",
    "evidence/phase1/agent_conformance_architect.json",
    "evidence/phase1/invproc_01_governance_baseline.json",
    "evidence/phase1/invproc_05_governance_links.json",
):
    if needle not in checklist_text:
        errors.append(f"missing_checklist_reference:{needle}")

out = {
    "check_id": "INVPROC-05-GOVERNANCE-LINKS",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Invariant process governance link verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"Invariant process governance link verification passed. Evidence: {evidence_file}")
PY
