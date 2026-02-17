#!/usr/bin/env bash
set -euo pipefail

# verify_table_conventions.sh
#
# Catalog-based verifier for table conventions declared in schema/table_conventions.yml.
# This is an enforcement hook, not a documentation artifact.
#
# Requires: DATABASE_URL

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SPEC_FILE="$ROOT_DIR/schema/table_conventions.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/table_conventions.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "ERROR: missing spec file: schema/table_conventions.yml" >&2
  exit 2
fi

python3 - <<'PY' "$SPEC_FILE" "$EVIDENCE_FILE"
import json
import os
import subprocess
import sys
from pathlib import Path

spec_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
db_url = os.environ.get("DATABASE_URL")
if not db_url:
    raise SystemExit("DATABASE_URL is required")

try:
    import yaml  # type: ignore
except Exception as e:
    raise SystemExit(f"pyyaml_missing:{e}")

ts = os.environ.get("EVIDENCE_TS")
sha = os.environ.get("EVIDENCE_GIT_SHA")
fp = os.environ.get("EVIDENCE_SCHEMA_FP")

def psql(query: str):
    cmd = ["psql", db_url, "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "-X", "-c", query]
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()

def norm_type(t: str) -> str:
    t = (t or "").strip().lower()
    return {
        "timestamptz": "timestamp with time zone",
        "timestamp with time zone": "timestamp with time zone",
        "uuid": "uuid",
        "text": "text",
        "jsonb": "jsonb",
        "bigint": "bigint",
        "integer": "integer",
        "int": "integer",
        "boolean": "boolean",
    }.get(t, t)

spec = yaml.safe_load(spec_path.read_text(encoding="utf-8")) or {}
tables = spec.get("tables") or {}
if not isinstance(tables, dict) or not tables:
    raise SystemExit("spec_missing_tables")

missing = []
mismatched = []
checked = []

for fqtn, cfg in tables.items():
    required_cols = (cfg or {}).get("required_columns") or []
    required_uniques = (cfg or {}).get("required_uniques") or []
    required_indexes = (cfg or {}).get("required_indexes") or []

    if not isinstance(required_cols, list):
        raise SystemExit(f"{fqtn}:required_columns_not_list")

    schema, _, table = fqtn.partition(".")
    if not table:
        raise SystemExit(f"{fqtn}:table_key_not_fqtn")

    for col in required_cols:
        name = (col or {}).get("name")
        want_type = norm_type((col or {}).get("type") or "")
        want_not_null = bool((col or {}).get("not_null", False))

        q = f"""
SELECT data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = '{schema}' AND table_name = '{table}' AND column_name = '{name}';
"""
        try:
            res = psql(q)
        except subprocess.CalledProcessError as e:
            missing.append({"table": fqtn, "column": name, "error": e.output.strip()})
            continue

        if not res:
            missing.append({"table": fqtn, "column": name, "reason": "missing_column"})
            continue

        data_type, is_nullable = (res.split("|", 1) + ["", ""])[:2]
        data_type = (data_type or "").strip().lower()
        is_nullable = (is_nullable or "").strip().upper()

        checked.append({"table": fqtn, "column": name, "data_type": data_type, "is_nullable": is_nullable})

        if want_type and data_type != want_type:
            mismatched.append(
                {"table": fqtn, "column": name, "kind": "type", "want": want_type, "have": data_type}
            )
        if want_not_null and is_nullable != "NO":
            mismatched.append(
                {"table": fqtn, "column": name, "kind": "nullability", "want": "NOT NULL", "have": is_nullable}
            )

    # Uniques: accept either UNIQUE constraint or UNIQUE index with matching columns.
    for u in required_uniques:
        cols = (u or {}).get("columns") or []
        if not cols:
            continue
        col_list = ", ".join([f"'{c}'" for c in cols])
        q = f"""
SELECT EXISTS (
  SELECT 1
  FROM pg_index i
  JOIN pg_class t ON t.oid = i.indrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = '{schema}'
    AND t.relname = '{table}'
    AND i.indisunique
    AND (
      SELECT array_agg(a.attname::text ORDER BY ordinality)
      FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
    ) = ARRAY[{col_list}]::text[]
);
"""
        ok = psql(q)
        if ok != "t":
            missing.append({"table": fqtn, "unique_columns": cols, "reason": "missing_unique"})

    # Indexes: accept any index (unique or not) with matching columns.
    for ix in required_indexes:
        cols = (ix or {}).get("columns") or []
        if not cols:
            continue
        col_list = ", ".join([f"'{c}'" for c in cols])
        q = f"""
SELECT EXISTS (
  SELECT 1
  FROM pg_index i
  JOIN pg_class t ON t.oid = i.indrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = '{schema}'
    AND t.relname = '{table}'
    AND (
      SELECT array_agg(a.attname::text ORDER BY ordinality)
      FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
      JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
    ) = ARRAY[{col_list}]::text[]
);
"""
        ok = psql(q)
        if ok != "t":
            missing.append({"table": fqtn, "index_columns": cols, "reason": "missing_index"})

status = "PASS" if not missing and not mismatched else "FAIL"

out = {
    "check_id": "DB-TABLE-CONVENTIONS",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": fp,
    "status": status,
    "spec_file": str(spec_path),
    "tables_checked": sorted(list(tables.keys())),
    "checked_columns": checked,
    "missing": missing,
    "mismatched": mismatched,
}

out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print(f"❌ Table conventions verification failed. Evidence: {out_path}", file=sys.stderr)
    if missing:
        print(f"Missing: {len(missing)}", file=sys.stderr)
    if mismatched:
        print(f"Mismatched: {len(mismatched)}", file=sys.stderr)
    raise SystemExit(1)

print(f"Table conventions verification OK. Evidence: {out_path}")
PY
