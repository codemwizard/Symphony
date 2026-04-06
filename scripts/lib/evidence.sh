#!/usr/bin/env bash
# set -euo pipefail Removed for pipeline reliability

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
  if [[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]]; then
    echo "0000000000000000000000000000000000000000"
    return
  fi
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git rev-parse HEAD 2>/dev/null || echo "UNKNOWN"
  else
    echo "UNKNOWN"
  fi
}

get_git_sha() {
  git_sha
}

get_timestamp_utc() {
  evidence_now_utc
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
  ensure_evidence_write_allowed "$path"
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

ensure_evidence_write_allowed() {
  local path="$1"
  local env_name="${SYMPHONY_ENV:-}"

  if [[ -z "$env_name" && "${CI:-}" == "true" ]]; then
    env_name="ci"
  fi
  if [[ -z "$env_name" && "${GITHUB_ACTIONS:-}" == "true" ]]; then
    env_name="ci"
  fi
  if [[ -z "$env_name" ]]; then
    env_name="unknown"
  fi

  case "$path" in
    evidence/*|*/evidence/*)
      if [[ "$env_name" != "development" && "$env_name" != "ci" ]]; then
        echo "EVIDENCE_WRITE_FORBIDDEN_IN_ENV:${env_name}" >&2
        return 1
      fi
      ;;
  esac
}
