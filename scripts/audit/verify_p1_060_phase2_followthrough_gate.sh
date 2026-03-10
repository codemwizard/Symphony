#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-060"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/p1_060_phase2_followthrough_gate.json}"

source "$ROOT_DIR/scripts/lib/evidence.sh"
ts="$(evidence_now_utc)"
git_sha_val="$(git_sha)"
schema_fp="$(schema_fingerprint)"
mkdir -p "$(dirname "$EVIDENCE_PATH")"

python3 - <<'PY' "$ROOT_DIR" "$TASK_ID" "$EVIDENCE_PATH" "$ts" "$git_sha_val" "$schema_fp"
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
task_id = sys.argv[2]
evidence_path = Path(sys.argv[3])
ts = sys.argv[4]
git_sha = sys.argv[5]
schema_fp = sys.argv[6]

errors = []
details = {}

try:
    import yaml
except Exception:
    errors.append("missing_pyyaml")
    yaml = None

if yaml is not None:
    dep_meta = root / "tasks/TSK-P1-059/meta.yml"
    if not dep_meta.exists():
        errors.append("missing_dependency_meta:TSK-P1-059")
    else:
        dep = yaml.safe_load(dep_meta.read_text(encoding="utf-8")) or {}
        dep_status = str(dep.get("status", "")).lower()
        details["dependency_status_TSK-P1-059"] = dep_status
        if dep_status != "completed":
            errors.append(f"dependency_not_completed:TSK-P1-059:{dep_status}")

adr = root / "docs/architecture/adrs/ADR-0001-service-boundaries-dotnet.md"
roadmap = root / "docs/architecture/ROADMAP.md"

if not adr.exists():
    errors.append("missing_doc:docs/architecture/adrs/ADR-0001-service-boundaries-dotnet.md")
else:
    adr_text = adr.read_text(encoding="utf-8")
    must_markers = [
        "Boundary Conformance Checks",
        "No-cross-boundary direct writes",
        "Forward-only domain-schema migration sequencing",
    ]
    for m in must_markers:
        if m not in adr_text:
            errors.append(f"missing_adr_marker:{m}")
    details["adr_marker_count"] = sum(1 for m in must_markers if m in adr_text)

if not roadmap.exists():
    errors.append("missing_doc:docs/architecture/ROADMAP.md")
else:
    roadmap_text = roadmap.read_text(encoding="utf-8")
    must_markers = [
        "Phase-2 Followthrough Program (Post Phase-1 Closeout)",
        "boundary conformance verifier",
        "forward-only domain schema charter",
        "no implementation claims before verifier/evidence wiring",
    ]
    for m in must_markers:
        if re.search(re.escape(m), roadmap_text, flags=re.IGNORECASE) is None:
            errors.append(f"missing_roadmap_marker:{m}")
    details["roadmap_marker_count"] = sum(
        1
        for m in must_markers
        if re.search(re.escape(m), roadmap_text, flags=re.IGNORECASE) is not None
    )

out = {
    "check_id": "TSK-P1-060-PHASE2-FOLLOWTHROUGH-GATE",
    "task_id": task_id,
    "timestamp_utc": ts,
    "git_sha": git_sha,
    "schema_fingerprint": schema_fp,
    "status": "PASS" if not errors else "FAIL",
    "pass": not errors,
    "details": details,
    "errors": errors,
}
evidence_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(f"TSK-P1-060 verifier status: {out['status']}")
print(f"Evidence: {evidence_path}")
raise SystemExit(0 if out["pass"] else 1)
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$TASK_ID" --evidence "$EVIDENCE_PATH"
