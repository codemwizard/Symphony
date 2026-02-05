#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT_DIR/docs/invariants/INVARIANTS_MANIFEST.yml"
ADR="$ROOT_DIR/docs/architecture/adrs/ADR-0008-proxy-resolution-strategy.md"
SCHEMA_DOC="$ROOT_DIR/docs/architecture/schema/proxy_resolution_schema.md"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/proxy_resolution_invariant.json"

mkdir -p "$EVIDENCE_DIR"

MANIFEST="$MANIFEST" ADR="$ADR" SCHEMA_DOC="$SCHEMA_DOC" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path
import yaml

manifest = Path(os.environ["MANIFEST"]).read_text(encoding="utf-8")
adr = Path(os.environ["ADR"])
schema = Path(os.environ["SCHEMA_DOC"])

status = "pass"
issues = []

# Check manifest entry
try:
    data = yaml.safe_load(manifest)
    inv = None
    for item in data:
        if item.get("id") == "INV-048":
            inv = item
            break
    if not inv:
        issues.append("INV-048 missing in manifest")
    else:
        if inv.get("status") != "roadmap":
            issues.append("INV-048 status is not roadmap")
        if inv.get("verification") != "scripts/audit/verify_proxy_resolution_invariant.sh":
            issues.append("INV-048 verification hook not set to verifier script")
except Exception as e:
    issues.append(f"Manifest parse error: {e}")

# Check ADR + schema docs
if not adr.exists():
    issues.append("ADR missing: ADR-0008-proxy-resolution-strategy.md")
else:
    text = adr.read_text(encoding="utf-8", errors="ignore")
    if "resolve" not in text.lower():
        issues.append("ADR missing resolution decision")

if not schema.exists():
    issues.append("Schema design doc missing: proxy_resolution_schema.md")
else:
    text = schema.read_text(encoding="utf-8", errors="ignore")
    if "proxy_resolutions" not in text:
        issues.append("Schema doc missing proxy_resolutions table")

if issues:
    status = "fail"

out = {
    "status": status,
    "issues": issues,
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2))

if status != "pass":
    print("Proxy resolution invariant verification failed")
    raise SystemExit(1)

print(f"Proxy resolution invariant verification OK. Evidence: {os.environ['EVIDENCE_FILE']}")
PY
