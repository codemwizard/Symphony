#!/usr/bin/env bash
set -euo pipefail

# new_invariant.sh
#
# Allocate a new INV-### id and append a stub entry to:
# - docs/invariants/INVARIANTS_MANIFEST.yml
# - docs/invariants/INVARIANTS_ROADMAP.md
#
# Usage:
#   scripts/audit/new_invariant.sh "Title here" P1 "team-db"
#
TITLE="${1:-}"
SEVERITY="${2:-P1}"
OWNER="${3:-team-unknown}"

if [[ -z "${TITLE}" ]]; then
  echo "Usage: $0 \"Invariant title\" [P0|P1|P2] [owner]"
  exit 2
fi

MANIFEST="docs/invariants/INVARIANTS_MANIFEST.yml"
ROAD="docs/invariants/INVARIANTS_ROADMAP.md"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "Manifest not found: ${MANIFEST}"
  exit 1
fi

next="$(python3 - <<'PY'
import re
text=open("docs/invariants/INVARIANTS_MANIFEST.yml","r",encoding="utf-8").read()
ids=[int(m.group(1)) for m in re.finditer(r'INV-(\d{3})', text)]
print(f"INV-{(max(ids) if ids else 0)+1:03d}")
PY
)"

cat >> "${MANIFEST}" <<EOF

- id: ${next}
  title: "${TITLE}"
  status: roadmap
  severity: ${SEVERITY}
  owners: ["${OWNER}"]
  sla_days: 14
  verification: "TODO: add verification hook"
EOF

if [[ -f "${ROAD}" ]]; then
  cat >> "${ROAD}" <<EOF

## ${next}: ${TITLE}

- Severity: ${SEVERITY}
- Owner(s): ${OWNER}
- Verification: TODO
- Notes: Add enforcement + verification, then promote to Implemented.
EOF
fi

echo "✅ Created ${next}"
