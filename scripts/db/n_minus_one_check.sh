#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIG_DIR="$ROOT/schema/migrations"
EVIDENCE_DIR="$ROOT/evidence/phase0"
OUT="$EVIDENCE_DIR/n_minus_one.json"

if [[ ! -d "$MIG_DIR" ]]; then
  echo "ERROR: migrations directory not found: $MIG_DIR" >&2
  exit 2
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql not found in PATH" >&2
  exit 2
fi

mapfile -t files < <(ls -1 "$MIG_DIR"/*.sql 2>/dev/null | sort)
if [[ ${#files[@]} -lt 2 ]]; then
  echo "ERROR: N-1 check requires at least 2 migrations" >&2
  exit 2
fi

last_migration="$(basename "${files[-1]}")"
prev_files=("${files[@]:0:${#files[@]}-1}")

make_db_url() {
  local base_url="$1"
  local dbname="$2"
  BASE_URL="$base_url" NEW_DB="$dbname" python3 - <<'PY'
import os
from urllib.parse import urlparse, urlunparse

base = os.environ["BASE_URL"]
new_db = os.environ["NEW_DB"]

u = urlparse(base)
path = f"/{new_db}"
print(urlunparse((u.scheme, u.netloc, path, u.params, u.query, u.fragment)))
PY
}

suffix="$(date +%s)_$$"
prev_db="symphony_nminusone_prev_${suffix}"
curr_db="symphony_nminusone_curr_${suffix}"

cleanup() {
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$prev_db\";" >/dev/null 2>&1 || true
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "DROP DATABASE IF EXISTS \"$curr_db\";" >/dev/null 2>&1 || true
}
trap cleanup EXIT

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "CREATE DATABASE \"$prev_db\";"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X -c "CREATE DATABASE \"$curr_db\";"

prev_url="$(make_db_url "$DATABASE_URL" "$prev_db")"
curr_url="$(make_db_url "$DATABASE_URL" "$curr_db")"

apply_migrations() {
  local db_url="$1"
  shift
  local mig_files=("$@")

  psql "$db_url" -v ON_ERROR_STOP=1 -X <<'SQL'
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  checksum TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
REVOKE ALL ON TABLE public.schema_migrations FROM PUBLIC;
SQL

  for file in "${mig_files[@]}"; do
    local version
    version="$(basename "$file")"
    local checksum
    checksum="$(sha256sum "$file" | awk '{print $1}')"

    psql "$db_url" -v ON_ERROR_STOP=1 -X <<SQL
BEGIN;
\i '$file'
INSERT INTO public.schema_migrations(version, checksum) VALUES ('$version', '$checksum');
COMMIT;
SQL
  done
}

apply_migrations "$prev_url" "${prev_files[@]}"
apply_migrations "$curr_url" "${files[@]}"

mkdir -p "$EVIDENCE_DIR"

prev_tsv="$(mktemp)"
curr_tsv="$(mktemp)"

psql "$prev_url" -X -A -t -F $'\t' -v ON_ERROR_STOP=1 \
  -c "SELECT table_name, column_name, data_type, udt_name, is_nullable, COALESCE(character_maximum_length::text,''), COALESCE(numeric_precision::text,''), COALESCE(numeric_scale::text,'') FROM information_schema.columns WHERE table_schema='public' ORDER BY table_name, column_name;" \
  > "$prev_tsv"

psql "$curr_url" -X -A -t -F $'\t' -v ON_ERROR_STOP=1 \
  -c "SELECT table_name, column_name, data_type, udt_name, is_nullable, COALESCE(character_maximum_length::text,''), COALESCE(numeric_precision::text,''), COALESCE(numeric_scale::text,'') FROM information_schema.columns WHERE table_schema='public' ORDER BY table_name, column_name;" \
  > "$curr_tsv"

PREV_TSV="$prev_tsv" CURR_TSV="$curr_tsv" OUT="$OUT" LAST_MIGRATION="$last_migration" \
python3 - <<'PY'
import json
import os
from pathlib import Path

def load_tsv(path: str):
    data = {}
    for line in Path(path).read_text(encoding="utf-8", errors="ignore").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 8:
            continue
        table, column, data_type, udt_name, is_nullable, char_len, num_prec, num_scale = parts
        data.setdefault(table, {})[column] = {
            "data_type": data_type,
            "udt_name": udt_name,
            "is_nullable": is_nullable,
            "character_maximum_length": char_len,
            "numeric_precision": num_prec,
            "numeric_scale": num_scale,
        }
    return data

prev = load_tsv(os.environ["PREV_TSV"])
curr = load_tsv(os.environ["CURR_TSV"])

missing_tables = [t for t in sorted(prev.keys()) if t not in curr]
missing_columns = []
type_mismatches = []

for table, cols in prev.items():
    if table not in curr:
        continue
    for col, spec in cols.items():
        if col not in curr[table]:
            missing_columns.append(f"{table}.{col}")
            continue
        cur_spec = curr[table][col]
        if spec != cur_spec:
            type_mismatches.append({
                "column": f"{table}.{col}",
                "prev": spec,
                "curr": cur_spec,
            })

ok = not missing_tables and not missing_columns and not type_mismatches

out = {
    "ok": ok,
    "last_migration": os.environ.get("LAST_MIGRATION"),
    "missing_tables": missing_tables,
    "missing_columns": missing_columns,
    "type_mismatches": type_mismatches,
    "prev_table_count": len(prev),
    "curr_table_count": len(curr),
}

Path(os.environ["OUT"]).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 - <<'PY'
import json
from pathlib import Path

out = json.loads(Path("evidence/phase0/n_minus_one.json").read_text(encoding="utf-8"))
if not out.get("ok"):
    raise SystemExit("N-1 compatibility check failed; see evidence/phase0/n_minus_one.json")
print("N-1 compatibility check OK. Evidence: evidence/phase0/n_minus_one.json")
PY

rm -f "$prev_tsv" "$curr_tsv"
