#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATIONS_DIR="$ROOT_DIR/schema/migrations"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/security_definer_dynamic_sql.json"
ALLOWLIST_FILE="$ROOT_DIR/docs/security/security_definer_dynamic_sql_allowlist.txt"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  echo "Migrations directory not found: $MIGRATIONS_DIR" >&2
  exit 1
fi

# Patterns that indicate dynamic SQL in PL/pgSQL
patterns=(
  "EXECUTE[[:space:]]+'"
  "EXECUTE[[:space:]]+\\$"
  "format\\("
  "quote_ident\\("
  "quote_literal\\("
)

allowlist=()
if [[ -f "$ALLOWLIST_FILE" ]]; then
  mapfile -t allowlist < "$ALLOWLIST_FILE"
fi

pattern_re="${patterns[0]}|${patterns[1]}|${patterns[2]}|${patterns[3]}|${patterns[4]}"

matches=()
while IFS= read -r -d '' file; do
  if command -v rg >/dev/null 2>&1; then
    while IFS= read -r line; do
      matches+=("$file:$line")
    done < <(rg -n -i -e "$pattern_re" "$file" || true)
  else
    while IFS= read -r line; do
      matches+=("$file:$line")
    done < <(grep -nEi "$pattern_re" "$file" || true)
  fi
done < <(find "$MIGRATIONS_DIR" -type f -name '*.sql' -print0)

# Filter allowlisted entries
filtered=()
for entry in "${matches[@]}"; do
  allowed=false
  for allow in "${allowlist[@]}"; do
    if [[ -n "$allow" ]] && [[ "$entry" == *"$allow"* ]]; then
      allowed=true
      break
    fi
  done
  if [[ "$allowed" == true ]]; then
    continue
  fi
  filtered+=("$entry")
done

printf '%s\n' "${filtered[@]}" | python3 - <<PY
import json, sys
lines = [ln.strip() for ln in sys.stdin.read().splitlines() if ln.strip()]
out = {
    "check_id": "SEC-SECDEF-DYNAMIC-SQL",
    "timestamp_utc": "${EVIDENCE_TS}",
    "git_sha": "${EVIDENCE_GIT_SHA}",
    "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
    "status": "FAIL" if lines else "PASS",
    "match_count": len(lines),
    "matches": lines,
}
with open("$EVIDENCE_FILE", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
PY

if [[ ${#filtered[@]} -gt 0 ]]; then
  echo "SECURITY DEFINER dynamic SQL lint failed" >&2
  printf '%s\n' "${filtered[@]}" >&2
  exit 1
fi

echo "SECURITY DEFINER dynamic SQL lint passed. Evidence: $EVIDENCE_FILE"
