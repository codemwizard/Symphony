#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/security_secrets_scan.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

status="PASS"
tmp_hits="$(mktemp)"
trap 'rm -f "$tmp_hits"' EXIT
scan_error=""

patterns=(
  "PRIVATE_KEY::-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
  "AWS_KEY_ID::AKIA[0-9A-Z]{16}"
  "AWS_SECRET::(?i)aws_secret_access_key"
  "CLIENT_SECRET::(?i)client_secret"
  "REFRESH_TOKEN::(?i)refresh_token"
  "BEARER_TOKEN::(?i)bearer\\s+[a-z0-9\\-_\\.]+"
  "OPENBAO_TOKEN::(?i)openbao_token"
  "VAULT_TOKEN::(?i)vault_token"
)

rg_scan() {
  local name="$1"
  local regex="$2"
  shift 2
  local rc=0
  rg -n --no-messages -S --pcre2 -e "$regex" -- "$@" \
    | awk -F: -v n="$name" '{ if ($1 ~ /scan_secrets\.sh$/) next; print n ":" $1 ":" $2 }' >> "$tmp_hits" || rc=$? # symphony:allow_or_true
  # rg returns 1 when no matches; this is not an execution failure.
  if [[ "$rc" -ne 0 && "$rc" -ne 1 ]]; then
    scan_error="rg_failed:$name:rc=$rc"
    return 1
  fi
  return 0
}

grep_scan() {
  local name="$1"
  local regex="$2"
  shift 2
  local rc=0
  grep -RInE \
    --exclude 'scan_secrets.sh' \
    "$regex" "$@" \
    | awk -F: -v n="$name" '{ if ($1 ~ /scan_secrets\.sh$/) next; print n ":" $1 ":" $2 }' >> "$tmp_hits" || rc=$? # symphony:allow_or_true
  # grep returns 1 when no matches; this is not an execution failure.
  if [[ "$rc" -ne 0 && "$rc" -ne 1 ]]; then
    scan_error="grep_failed:$name:rc=$rc"
    return 1
  fi
  return 0
}

mapfile -d '' tracked_files < <(git -C "$ROOT_DIR" ls-files -z)
if [[ "${#tracked_files[@]}" -eq 0 ]]; then
  scan_error="git_ls_files_empty_or_failed"
fi

if [[ -z "$scan_error" ]]; then
  if command -v rg >/dev/null 2>&1; then
    for p in "${patterns[@]}"; do
      name="${p%%::*}"
      regex="${p#*::}"
      rg_scan "$name" "$regex" "${tracked_files[@]}" || break
    done
  else
    for p in "${patterns[@]}"; do
      name="${p%%::*}"
      regex="${p#*::}"
      grep_scan "$name" "$regex" "${tracked_files[@]}" || break
    done
  fi
fi

count="$(wc -l < "$tmp_hits" | tr -d ' ')"
if [[ "$count" != "0" || -n "$scan_error" ]]; then
  status="FAIL"
fi

hits_json="$(python3 - <<'PY' "$tmp_hits"
import json,sys
p=sys.argv[1]
items=[]
with open(p,'r',encoding='utf-8',errors='ignore') as f:
    for line in f:
        line=line.strip()
        if line:
            items.append(line)
items=sorted(set(items))
print(json.dumps(items))
PY
)"

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-G07\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"hit_count\": ${count}" \
  "\"scan_error\": \"${scan_error}\"" \
  "\"hits\": ${hits_json}"

if [[ "$status" != "PASS" ]]; then
  echo "Secrets scan failed: ${count} potential hits."
  if [[ -n "$scan_error" ]]; then
    echo "Secrets scan execution error: $scan_error"
  fi
  echo "Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "Secrets scan passed. Evidence: $EVIDENCE_FILE"
