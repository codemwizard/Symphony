#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/docs/governance/regulator-evidence-pack-template-v1.md"
MANIFEST_FILE="$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/invproc_04_regulator_pack_template.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export ROOT_DIR TEMPLATE_FILE MANIFEST_FILE EVIDENCE_FILE EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
template_text = Path(os.environ["TEMPLATE_FILE"]).read_text(encoding="utf-8")
manifest_text = Path(os.environ["MANIFEST_FILE"]).read_text(encoding="utf-8")
evidence_file = Path(os.environ["EVIDENCE_FILE"])

manifest_ids = set(re.findall(r"(?m)^- id:\s*(INV-\d{3})\s*$", manifest_text))
template_ids = sorted(set(re.findall(r"\bINV-\d{3}\b", template_text)))
evidence_paths = sorted(set(re.findall(r"evidence/phase[01]/[A-Za-z0-9_./-]+\.json", template_text)))

errors = []
for inv in template_ids:
    if inv not in manifest_ids:
        errors.append(f"unknown_invariant_id:{inv}")

for rel in evidence_paths:
    if not (root / rel).is_file():
        errors.append(f"missing_evidence_path:{rel}")

required_phrases = [
    "Only implemented invariants may be presented as active controls",
    "Roadmap invariants must be shown only in a clearly labeled gap/disclosure section",
    "evidence/phase1/approval_metadata.json",
]
for phrase in required_phrases:
    if phrase not in template_text:
        errors.append(f"missing_required_phrase:{phrase}")

out = {
    "check_id": "INVPROC-04-REGULATOR-PACK-TEMPLATE",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if not errors else "FAIL",
    "template_invariants": template_ids,
    "template_evidence_paths": evidence_paths,
    "errors": errors,
}
evidence_file.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
if errors:
    print("❌ Regulator pack template verification failed")
    for err in errors:
        print(f" - {err}")
    raise SystemExit(1)
print(f"Regulator pack template verification passed. Evidence: {evidence_file}")
PY
