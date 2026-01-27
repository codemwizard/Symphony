#!/usr/bin/env bash
set -euo pipefail

# enforce_invariant_promotion.sh
#
# Enforces:
# - implemented invariants in manifest must have owners + verification (not empty, not TODO)
# - manifest implemented IDs must appear in INVARIANTS_IMPLEMENTED.md
# - implemented IDs must NOT still appear in INVARIANTS_ROADMAP.md
#
# This gate is intentionally text-based and conservative.

MANIFEST="docs/invariants/INVARIANTS_MANIFEST.yml"
IMPL_DOC="docs/invariants/INVARIANTS_IMPLEMENTED.md"
ROAD_DOC="docs/invariants/INVARIANTS_ROADMAP.md"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "Manifest not found: ${MANIFEST}"
  exit 1
fi

python3 - <<'PY'
import re, sys, pathlib

MANIFEST = pathlib.Path("docs/invariants/INVARIANTS_MANIFEST.yml")
IMPL = pathlib.Path("docs/invariants/INVARIANTS_IMPLEMENTED.md")
ROAD = pathlib.Path("docs/invariants/INVARIANTS_ROADMAP.md")

text = MANIFEST.read_text(encoding="utf-8", errors="ignore")

# Minimal YAML list-of-maps parser for entries like:
# - id: INV-001
#   title: ...
#   status: implemented
# We only extract id/status/owners/verification.
entries=[]
cur={}
for line in text.splitlines():
    if re.match(r'^\s*-\s+id:\s*', line):
        if cur:
            entries.append(cur)
        cur={"id": line.split("id:",1)[1].strip().strip('"').strip("'")}
    else:
        m=re.match(r'^\s+(\w+):\s*(.*)$', line)
        if m and cur is not None:
            k=m.group(1)
            v=m.group(2).strip()
            cur[k]=v
if cur:
    entries.append(cur)

implemented=[e for e in entries if e.get("status","").strip().lower()=="implemented"]

errs=[]

# check owners/verification
for e in implemented:
    iid=e.get("id","")
    owners=e.get("owners","").strip()
    ver=e.get("verification","").strip()
    if not owners or owners in ("[]","null","None"):
        errs.append(f"{iid}: implemented but owners missing/empty")
    if (not ver) or ("TODO" in ver.upper()):
        errs.append(f"{iid}: implemented but verification missing/empty/TODO")

impl_text = IMPL.read_text(encoding="utf-8", errors="ignore") if IMPL.exists() else ""
road_text = ROAD.read_text(encoding="utf-8", errors="ignore") if ROAD.exists() else ""

impl_ids=set(re.findall(r'INV-\d{3}', impl_text))
road_ids=set(re.findall(r'INV-\d{3}', road_text))

for e in implemented:
    iid=e.get("id","")
    if iid not in impl_ids:
        errs.append(f"{iid}: manifest=implemented but not found in INVARIANTS_IMPLEMENTED.md")
    if iid in road_ids:
        errs.append(f"{iid}: manifest=implemented but still present in INVARIANTS_ROADMAP.md")

if errs:
    print("❌ Promotion gate failed:")
    for x in errs:
        print(" -", x)
    sys.exit(2)

print("✅ Promotion gate passed.")
PY
