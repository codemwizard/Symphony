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

scan_roots=(
  "scripts"
  "src"
  "services"
  "schema"
  "infra"
  ".github"
  "packages"
  "tests"
)

rg_scan() {
  local name="$1"
  local regex="$2"
  local path="$3"
  rg -n --no-messages -S --pcre2 -e "$regex" -- "$path" \
    --glob '**/*.sh' \
    --glob '**/*.sql' \
    --glob '**/*.cs' \
    --glob '**/*.fs' \
    --glob '**/*.vb' \
    --glob '**/*.json' \
    --glob '**/*.yml' \
    --glob '**/*.yaml' \
    --glob '**/*.toml' \
    --glob '**/*.env' \
    --glob '**/*.config' \
    --glob 'Dockerfile*' \
    --glob '!**/.git/**' \
    --glob '!**/evidence/**' \
    --glob '!**/bin/**' \
    --glob '!**/obj/**' \
    --glob '!**/.venv/**' \
    --glob '!**/node_modules/**' \
    | awk -F: -v n="$name" '{ if ($1 ~ /scan_secrets\.sh$/) next; print n ":" $1 ":" $2 }' >> "$tmp_hits" || true
}

grep_scan() {
  local name="$1"
  local regex="$2"
  local path="$3"
  grep -RInE \
    --exclude-dir .git \
    --exclude-dir evidence \
    --exclude-dir bin \
    --exclude-dir obj \
    --exclude-dir .venv \
    --exclude-dir node_modules \
    --exclude 'scan_secrets.sh' \
    --include '*.sh' \
    --include '*.sql' \
    --include '*.cs' \
    --include '*.fs' \
    --include '*.vb' \
    --include '*.json' \
    --include '*.yml' \
    --include '*.yaml' \
    --include '*.toml' \
    --include '*.env' \
    --include '*.config' \
    --include 'Dockerfile*' \
    "$regex" "$path" \
    | awk -F: -v n="$name" '{ if ($1 ~ /scan_secrets\.sh$/) next; print n ":" $1 ":" $2 }' >> "$tmp_hits" || true
}

for root in "${scan_roots[@]}"; do
  [[ -e "$ROOT_DIR/$root" ]] || continue
  if command -v rg >/dev/null 2>&1; then
    for p in "${patterns[@]}"; do
      name="${p%%::*}"
      regex="${p#*::}"
      rg_scan "$name" "$regex" "$ROOT_DIR/$root"
    done
  else
    for p in "${patterns[@]}"; do
      name="${p%%::*}"
      regex="${p#*::}"
      grep_scan "$name" "$regex" "$ROOT_DIR/$root"
    done
  fi
done

count="$(wc -l < "$tmp_hits" | tr -d ' ')"
if [[ "$count" != "0" ]]; then
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
  "\"hits\": ${hits_json}"

if [[ "$status" != "PASS" ]]; then
  echo "Secrets scan failed: ${count} potential hits."
  echo "Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "Secrets scan passed. Evidence: $EVIDENCE_FILE"
