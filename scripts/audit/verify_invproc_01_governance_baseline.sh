#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/invproc_01_governance_baseline.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
docs = {
    "invariant_register": root / "docs/governance/invariant-register-v1.md",
    "ci_gate_spec": root / "docs/governance/ci-gate-spec-v1.md",
    "regulator_pack_template": root / "docs/governance/regulator-evidence-pack-template-v1.md",
    "policy_precedence": root / "docs/operations/POLICY_PRECEDENCE.md",
    "enforcement_matrix": root / "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
}

required_refs = {
    "invariant_register": [
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        "docs/operations/POLICY_PRECEDENCE.md",
        "docs/invariants/INVARIANTS_MANIFEST.yml",
        "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
        ".github/workflows/invariants.yml",
        "scripts/dev/pre_ci.sh",
    ],
    "ci_gate_spec": [
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        ".github/workflows/invariants.yml",
        "scripts/dev/pre_ci.sh",
        "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
    ],
    "regulator_pack_template": [
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        "docs/invariants/INVARIANTS_MANIFEST.yml",
        "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
        "docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md",
    ],
}

errors = []
checked = {}
for key, path in docs.items():
    if not path.exists():
        errors.append(f"missing_file:{path.relative_to(root)}")
        checked[key] = []
        continue
    text = path.read_text(encoding="utf-8")
    found = []
    for ref in required_refs.get(key, []):
        if ref in text:
            found.append(ref)
        else:
            errors.append(f"missing_reference:{path.relative_to(root)}:{ref}")
    checked[key] = found

precedence_text = docs["policy_precedence"].read_text(encoding="utf-8")
for needle in (
    "Domain-Canonical Rule",
    "docs/invariants/INVARIANTS_MANIFEST.yml",
    "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
    ".github/workflows/invariants.yml",
    "scripts/dev/pre_ci.sh",
):
    if needle not in precedence_text:
        errors.append(f"missing_policy_precedence_guard:{needle}")

matrix_text = docs["enforcement_matrix"].read_text(encoding="utf-8")
if "domain-canonical source for exact verifier commands and evidence paths" not in matrix_text:
    errors.append("missing_matrix_domain_canonical_note")

out = {
    "check_id": "INVPROC-01-GOVERNANCE-BASELINE",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "checked_references": checked,
    "errors": errors,
}

evidence_file = Path(os.environ["EVIDENCE_FILE"])
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Governance baseline verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"Governance baseline verification passed. Evidence: {evidence_file}")
PY
