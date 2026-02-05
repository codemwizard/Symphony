#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ALLOWLIST="$ROOT_DIR/docs/security/ddl_allowlist.json"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/ddl_allowlist_governance.json"

mkdir -p "$EVIDENCE_DIR"

if [[ ! -f "$ALLOWLIST" ]]; then
  python3 - <<PY
import json
from pathlib import Path
Path("$EVIDENCE_FILE").write_text(json.dumps({"status":"fail","reason":"missing allowlist"}, indent=2))
PY
  echo "❌ Missing allowlist: $ALLOWLIST" >&2
  exit 1
fi

ALLOWLIST="$ALLOWLIST" EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path
from datetime import datetime, timezone

allowlist_path = Path(os.environ['ALLOWLIST']) if 'ALLOWLIST' in os.environ else None
if allowlist_path is None:
    raise SystemExit("ALLOWLIST env not set")

data = json.loads(allowlist_path.read_text(encoding='utf-8'))
entries = data.get('entries', [])
issues = []
expired = []

required = [
    'id',
    'migration',
    'statement_fingerprint',
    'reason',
    'expires_on',
    'reviewed_by',
    'approved_at'
]

now = datetime.now(timezone.utc).date()

for e in entries:
    for k in required:
        if k not in e or not str(e.get(k)).strip():
            issues.append(f"{e.get('id','<unknown>')}: missing {k}")
    exp = e.get('expires_on')
    if exp:
        try:
            exp_date = datetime.strptime(exp, "%Y-%m-%d").date()
            if exp_date < now:
                expired.append(e.get('id', '<unknown>'))
        except ValueError:
            issues.append(f"{e.get('id','<unknown>')}: invalid expires_on format")

status = 'pass' if not issues and not expired else 'fail'

out = {
    'status': status,
    'entry_count': len(entries),
    'expired': expired,
    'issues': issues,
}

Path(os.environ['EVIDENCE_FILE']).write_text(json.dumps(out, indent=2))

if status != 'pass':
    print("DDL allowlist governance failed")
    raise SystemExit(1)

print(f"DDL allowlist governance OK. Evidence: {os.environ['EVIDENCE_FILE']}")
PY
