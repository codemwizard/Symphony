#!/usr/bin/env bash
# ============================================================
# test_outbox_pending_indexes.sh — Verify due-claim index
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/outbox_pending_indexes.json"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

echo "==> Outbox pending index test"

EXPECTED_INDEX="idx_payment_outbox_pending_due_claim"
EXPECTED_COLS="next_attempt_at,lease_expires_at,created_at"

index_info="$(
  psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 -c "
    SELECT i.relname,
           string_agg(a.attname, ',' ORDER BY x.ordinality) AS cols,
           pg_get_indexdef(i.oid) AS def
    FROM pg_class t
    JOIN pg_namespace n ON n.oid = t.relnamespace
    JOIN pg_index ix ON t.oid = ix.indrelid
    JOIN pg_class i ON i.oid = ix.indexrelid
    JOIN LATERAL unnest(ix.indkey) WITH ORDINALITY AS x(attnum, ordinality) ON true
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = x.attnum
    WHERE n.nspname = 'public'
      AND t.relname = 'payment_outbox_pending'
      AND i.relname = '${EXPECTED_INDEX}'
    GROUP BY i.relname, i.oid;
  "
)"

ok=1
idx_name=""
idx_cols=""
idx_def=""
errors=()

if [[ -n "$index_info" ]]; then
  idx_name="$(echo "$index_info" | cut -d '|' -f 1)"
  idx_cols="$(echo "$index_info" | cut -d '|' -f 2)"
  idx_def="$(echo "$index_info" | cut -d '|' -f 3-)"
else
  ok=0
  errors+=("missing_index")
fi

if [[ "$idx_cols" != "$EXPECTED_COLS" ]]; then
  ok=0
  errors+=("index_columns_mismatch")
fi

OK="$ok" EXPECTED_INDEX="$EXPECTED_INDEX" EXPECTED_COLS="$EXPECTED_COLS" \
IDX_NAME="$idx_name" IDX_COLS="$idx_cols" IDX_DEF="$idx_def" ERRORS="${errors[*]}" \
EVIDENCE_FILE="$EVIDENCE_FILE" python3 - <<'PY'
import json
import os
from pathlib import Path

errors = [e for e in os.environ.get("ERRORS", "").split() if e]
out = {
  "check_id": "DB-OUTBOX-PENDING-INDEXES",
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": "PASS" if os.environ.get("OK") == "1" else "FAIL",
  "ok": os.environ.get("OK") == "1",
  "checked_objects": [
    "public.payment_outbox_pending",
    "public." + (os.environ.get("EXPECTED_INDEX") or ""),
  ],
  "expected_index": os.environ.get("EXPECTED_INDEX"),
  "expected_columns": os.environ.get("EXPECTED_COLS"),
  "index_name": os.environ.get("IDX_NAME"),
  "index_columns": os.environ.get("IDX_COLS"),
  "index_definition": os.environ.get("IDX_DEF"),
  "errors": errors,
}
Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if [[ "$ok" -ne 1 ]]; then
  echo "❌ Outbox pending index test failed"
  exit 1
fi

echo "✅ Outbox pending index test passed"
