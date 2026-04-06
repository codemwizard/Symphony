#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT_DIR/docs/programs/symphony-hardening/TRUST_INVARIANTS.md"
TRACE="$ROOT_DIR/docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md"
EVIDENCE="$ROOT_DIR/evidence/phase1/hardening/tsk_hard_001.json"

[[ -s "$DOC" ]] || { echo "missing_trust_invariants_doc" >&2; exit 1; }

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
doc = (root / "docs/programs/symphony-hardening/TRUST_INVARIANTS.md").read_text(encoding="utf-8")
trace = (root / "docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md").read_text(encoding="utf-8")

blocks = re.findall(r"## INV-HARD-\d{2}[\s\S]*?(?=\n## INV-HARD-|\Z)", doc)
required_keys = [
    "- invariant_id:",
    "- plain_language_statement:",
    "- enforcement_layer:",
    "- violation_impact_description:",
    "- test_mapping:",
]

if len(blocks) != 12:
    raise SystemExit(f"expected_12_invariants_found_{len(blocks)}")

for i, block in enumerate(blocks, 1):
    for key in required_keys:
        if key not in block:
            raise SystemExit(f"missing_field:{key}:block_{i}")
    for line in block.splitlines():
        if any(line.startswith(k) for k in required_keys):
            parts = line.split(":", 1)
            if len(parts) != 2 or not parts[1].strip():
                raise SystemExit(f"empty_field:{line}")

if "TRUST_INVARIANTS.md" not in trace:
    raise SystemExit("traceability_link_missing")

payload = {
    "check_id": "TSK-HARD-001",
    "task_id": "TSK-HARD-001",
    "status": "PASS",
    "pass": True,
    "timestamp_utc": os.popen("[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ).read().strip(),
    "git_sha": os.popen("[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD").read().strip(),
    "details": {
        "invariant_count": len(blocks),
        "all_required_fields_present": True,
        "traceability_linked": True,
    },
}
(root / "evidence/phase1/hardening").mkdir(parents=True, exist_ok=True)
(root / "evidence/phase1/hardening/tsk_hard_001.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print("TSK-HARD-001 verifier: PASS")
print(f"Evidence: {root / 'evidence/phase1/hardening/tsk_hard_001.json'}")
PY
