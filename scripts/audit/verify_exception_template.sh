#!/usr/bin/env bash
set -euo pipefail

# verify_exception_template.sh
#
# Validates exception files under docs/invariants/exceptions/*.md
# or specific paths passed as arguments.
#
# Dependency-free (no PyYAML); parses simple YAML front matter:
# ---
# key: value
# ...
# ---

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
  echo "No exception files found to validate."
  exit 0
fi

python3 - <<'PY' "${files[@]}"
import re, sys, datetime

REQUIRED = ["exception_id","inv_scope","reason","author","created_at","expiry","follow_up_ticket"]

def parse_front_matter(text: str):
    # Extract first YAML front matter block only
    m = re.search(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    block = m.group(1)
    meta = {}
    for line in block.splitlines():
        line=line.strip()
        if not line or line.startswith("#"): 
            continue
        if ":" not in line:
            continue
        k,v=line.split(":",1)
        meta[k.strip()] = v.strip().strip('"').strip("'")
    return meta

def parse_date(s: str):
    return datetime.datetime.strptime(s, "%Y-%m-%d").date()

today = datetime.date.today()
errors = []

for path in sys.argv[1:]:
    try:
        text = open(path, "r", encoding="utf-8").read()
    except Exception as e:
        errors.append(f"{path}: cannot read: {e}")
        continue

    meta = parse_front_matter(text)
    if meta is None:
        errors.append(f"{path}: missing YAML front matter delimited by ---")
        continue

    for key in REQUIRED:
        if not meta.get(key):
            errors.append(f"{path}: missing required field '{key}'")
    # inv_scope format: "change-rule" or comma-separated INV-###
    scope = meta.get("inv_scope","")
    if scope:
        scope = scope.replace(" ", "")
        if not re.fullmatch(r"(change-rule|INV-\d{3}(,INV-\d{3})*)", scope):
            errors.append(f"{path}: inv_scope must be 'change-rule' or comma-separated INV-### tokens (got '{meta.get('inv_scope')}')")
    # date validations
    for dk in ["created_at","expiry"]:
        if meta.get(dk):
            try:
                parse_date(meta[dk])
            except Exception:
                errors.append(f"{path}: {dk} must be YYYY-MM-DD (got '{meta[dk]}')")
    # closed exceptions may be expired
    closed_at = meta.get('closed_at')
    if meta.get("expiry") and not closed_at:
        try:
            exp = parse_date(meta["expiry"])
            if exp <= today:
                errors.append(f"{path}: expiry must be in the future unless closed_at is set (got {exp})")
        except Exception:
            pass

if errors:
    print("❌ Exception template validation failed:")
    for e in errors:
        print(" -", e)
    sys.exit(2)

print("✅ Exception template validation passed.")
PY
