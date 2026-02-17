#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase0"
OUT="$EVIDENCE_DIR/outbox_mvcc_posture.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

EXPECTED_FILLFACTOR="80"

relopts="$(psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "SELECT reloptions FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='payment_outbox_pending';")"

ff=""
if [[ -n "$relopts" && "$relopts" != "" ]]; then
  ff="$(echo "$relopts" | tr '{,}' '\n' | grep -Eo "fillfactor=[0-9]+" | head -n 1 | cut -d '=' -f 2 || true)"
fi

ok=1
if [[ "$ff" != "$EXPECTED_FILLFACTOR" ]]; then
  ok=0
fi

OK="$ok" EXPECTED_FILLFACTOR="$EXPECTED_FILLFACTOR" RELOPTIONS="$relopts" OUT="$OUT" \
python3 - <<'PY'
import json
import os
from pathlib import Path

out = {
    "check_id": "DB-OUTBOX-MVCC",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if os.environ.get("OK") == "1" else "FAIL",
    "ok": os.environ.get("OK") == "1",
    "expected_fillfactor": os.environ.get("EXPECTED_FILLFACTOR"),
    "reloptions": os.environ.get("RELOPTIONS") or "",
}

Path(os.environ["OUT"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if [[ "$ok" -ne 1 ]]; then
  echo "Outbox MVCC posture verification failed. See $OUT" >&2
  exit 1
fi

echo "Outbox MVCC posture verification OK. Evidence: $OUT"
