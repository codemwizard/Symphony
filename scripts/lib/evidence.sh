#!/usr/bin/env bash
set -euo pipefail

# Evidence helper utilities (bash).
# Required fields: check_id, timestamp_utc, git_sha, status
# Optional: schema_fingerprint

# Env:
# - SYMPHONY_EVIDENCE_DETERMINISTIC=1 -> fixed timestamp

evidence_now_utc() {
  if [[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]]; then
    echo "1970-01-01T00:00:00Z"
  else
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

git_sha() {
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rev-parse HEAD 2>/dev/null || echo "UNKNOWN"
  else
    echo "UNKNOWN"
  fi
}

schema_fingerprint() {
  # Optional, best-effort: hash schema/baseline.sql if present
  if [[ -f "schema/baseline.sql" ]]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "schema/baseline.sql" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "schema/baseline.sql" | awk '{print $1}'
    else
      echo "UNKNOWN"
    fi
  else
    echo "UNKNOWN"
  fi
}

json_escape() {
  python3 - <<'PY' "$1"
import json,sys
print(json.dumps(sys.argv[1]))
PY
}

write_json() {
  local path="$1"; shift
  local dir
  dir="$(dirname "$path")"
  mkdir -p "$dir"
  {
    echo "{"
    local first=1
    for frag in "$@"; do
      if [[ "$first" -eq 0 ]]; then echo ","; fi
      first=0
      printf "  %s" "$frag"
    done
    echo
    echo "}"
  } > "$path"
}
