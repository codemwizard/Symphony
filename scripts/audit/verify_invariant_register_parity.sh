#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTER_FILE="$ROOT_DIR/docs/governance/invariant-register-v1.md"
MANIFEST_FILE="$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml"
MATRIX_FILE="$ROOT_DIR/docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/invproc_02_register_parity.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export REGISTER_FILE MANIFEST_FILE MATRIX_FILE EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
import re
from pathlib import Path

register_file = Path(os.environ["REGISTER_FILE"])
manifest_file = Path(os.environ["MANIFEST_FILE"])
matrix_file = Path(os.environ["MATRIX_FILE"])
evidence_file = Path(os.environ["EVIDENCE_FILE"])

register_text = register_file.read_text(encoding="utf-8")
manifest_text = manifest_file.read_text(encoding="utf-8")
matrix_text = matrix_file.read_text(encoding="utf-8")

manifest_ids = set(re.findall(r"(?m)^- id:\s*(INV-\d{3})\s*$", manifest_text))
status_pairs = dict(re.findall(r"(?ms)^- id:\s*(INV-\d{3})\s*.*?^\s*status:\s*([a-z_]+)\s*$", manifest_text))
register_ids = sorted(set(re.findall(r"\bINV-\d{3}\b", register_text)))

errors = []
for inv in register_ids:
    if inv not in manifest_ids:
        errors.append(f"unknown_invariant_id:{inv}")

for ref in (
    "docs/invariants/INVARIANTS_MANIFEST.yml",
    "docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md",
    ".github/workflows/invariants.yml",
    "scripts/dev/pre_ci.sh",
):
    if ref not in register_text:
        errors.append(f"missing_canonical_reference:{ref}")

for inv in ("INV-009", "INV-039"):
    if inv in register_text and status_pairs.get(inv) != "roadmap":
        errors.append(f"non_promotable_invariant_not_roadmap:{inv}:{status_pairs.get(inv)}")

if "INV-009" not in matrix_text or "INV-039" not in matrix_text:
    errors.append("matrix_missing_gap_disclosure")

out = {
    "check_id": "INVPROC-02-INVARIANT-REGISTER-PARITY",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "register_invariants": register_ids,
    "manifest_invariant_count": len(manifest_ids),
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Invariant register parity verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"Invariant register parity verification passed. Evidence: {evidence_file}")
PY
