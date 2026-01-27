#!/usr/bin/env bash
set -euo pipefail

# record_invariants_exception.sh
#
# CI/helper utility:
# - For PRs that add exception files, emit a structured log line (JSON) to stdout.
# - Does NOT "approve" exceptions; it only records/audits.
#
# Usage:
#   scripts/audit/record_invariants_exception.sh [path ...]
#
EX_DIR="docs/invariants/exceptions"
files=()
if [[ "$#" -gt 0 ]]; then
  files=("$@")
else
  if [[ -d "${EX_DIR}" ]]; then
    while IFS= read -r -d '' f; do files+=("$f"); done < <(find "${EX_DIR}" -maxdepth 1 -type f -name "*.md" -print0)
  fi
fi

if [[ "${#files[@]}" -eq 0 ]]; then
  echo '{"event":"invariants_exception","status":"none"}'
  exit 0
fi

python3 - <<'PY' "${files[@]}"
import re, sys, json
def meta(path):
    t=open(path,"r",encoding="utf-8").read()
    m=re.search(r"^---\n(.*?)\n---\n", t, re.S)
    if not m:
        return {"path": path, "error":"missing_front_matter"}
    block=m.group(1)
    out={"path": path}
    for line in block.splitlines():
        if ":" in line:
            k,v=line.split(":",1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out

events=[meta(p) for p in sys.argv[1:]]
print(json.dumps({"event":"invariants_exception","exceptions":events}, indent=2))
PY
