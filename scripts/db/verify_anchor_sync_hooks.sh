#!/usr/bin/env bash
set -euo pipefail

# verify_anchor_sync_hooks.sh
#
# Phase-0 structural readiness proof for hybrid anchor-sync.
# This verifier is intentionally NOT a runtime workflow gate.
# It proves the schema hooks exist (columns + index), and emits evidence.
#
# Evidence: evidence/phase0/anchor_sync_hooks.json

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/anchor_sync_hooks.json"
mkdir -p "$EVIDENCE_DIR"

CHECK_ID="DB-ANCHOR-SYNC-HOOKS"
GATE_ID="INT-G24"
INVARIANT_ID="INV-113"

echo "==> Anchor-sync hooks verifier (structural only)"

export CHECK_ID GATE_ID INVARIANT_ID
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
export EVIDENCE_FILE DATABASE_URL

if python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

dburl = os.environ["DATABASE_URL"]

def q(sql: str) -> str:
    out = subprocess.check_output(
        ["psql", dburl, "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "-X", "-c", sql],
        text=True,
    )
    return out.strip()

errors = []

table_exists = q("SELECT to_regclass('public.evidence_packs') IS NOT NULL;") == "t"
if not table_exists:
    errors.append("missing_table:evidence_packs")

required_cols = {
    "signer_participant_id": "text",
    "signature_alg": "text",
    "signature": "text",
    "signed_at": "timestamp with time zone",
    "anchor_type": "text",
    "anchor_ref": "text",
    "anchored_at": "timestamp with time zone",
}

cols = {}
if table_exists:
    rows = subprocess.check_output(
        [
            "psql",
            dburl,
            "-q",
            "-t",
            "-A",
            "-v",
            "ON_ERROR_STOP=1",
            "-X",
            "-c",
            "SELECT column_name, data_type FROM information_schema.columns "
            "WHERE table_schema='public' AND table_name='evidence_packs';",
        ],
        text=True,
    ).splitlines()
    for r in rows:
        if not r:
            continue
        name, dtype = r.split("|", 1)
        cols[name] = dtype
    for name, dtype in required_cols.items():
        if name not in cols:
            errors.append(f"missing_column:{name}")
        elif cols.get(name) != dtype:
            errors.append(f"column_type_mismatch:{name}:{cols.get(name)}")

idx_name = "idx_evidence_packs_anchor_ref"
idx_info = {}
if table_exists:
    idx_row = q(
        "SELECT indexname, indexdef FROM pg_indexes "
        f"WHERE schemaname='public' AND tablename='evidence_packs' AND indexname='{idx_name}';"
    )
    if not idx_row:
        errors.append(f"missing_index:{idx_name}")
    else:
        name, definition = idx_row.split("|", 1)
        idx_info = {"name": name, "definition": definition}
        if "(anchor_ref)" not in definition.replace(" ", ""):
            errors.append("index_columns_mismatch:anchor_ref")
        if "WHERE" not in definition.upper() or "ANCHOR_REF IS NOT NULL" not in definition.upper():
            # not strictly required for correctness, but expected for Phase-0 shape
            errors.append("index_predicate_unexpected")

ok = len(errors) == 0
out = {
    "check_id": os.environ["CHECK_ID"],
    "gate_id": os.environ["GATE_ID"],
    "invariant_id": os.environ["INVARIANT_ID"],
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": "PASS" if ok else "FAIL",
    "ok": ok,
    "checked_objects": ["public.evidence_packs", f"public.{idx_name}"],
    "required_columns": required_cols,
    "found_columns": cols,
    "index": idx_info,
    "errors": errors,
    "notes": "Structural only: columns + index; no runtime anchoring workflow implied in Phase-0.",
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
raise SystemExit(0 if ok else 1)
PY
then
  echo "✅ Anchor-sync hooks verifier passed"
else
  echo "❌ Anchor-sync hooks verifier failed"
  exit 1
fi
