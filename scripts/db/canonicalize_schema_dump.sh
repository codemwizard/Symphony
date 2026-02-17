#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <input_sql> <output_sql>" >&2
  exit 1
fi

IN_PATH="$1"
OUT_PATH="$2"

if [[ ! -f "$IN_PATH" ]]; then
  echo "Input file not found: $IN_PATH" >&2
  exit 1
fi

python3 - <<PY
from pathlib import Path

inp = Path("$IN_PATH").read_text(encoding="utf-8").splitlines()
out = []
for line in inp:
    # Strip line comments and whitespace
    line = line.split("--", 1)[0].rstrip()
    if not line.strip():
        continue
    if line.startswith("\\\\restrict") or line.startswith("\\\\unrestrict"):
        continue
    # Remove volatile pg_dump header SET lines
    if line.startswith("SET "):
        continue
    if line.startswith("SELECT pg_catalog.set_config"):
        continue
    out.append(line)

# NOTE: Canonicalization is for comparison/hash only (not execution).
Path("$OUT_PATH").write_text("\n".join(sorted(out)) + "\n", encoding="utf-8")
PY
