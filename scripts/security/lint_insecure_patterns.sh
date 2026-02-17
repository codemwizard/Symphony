#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/security_insecure_patterns.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

status="PASS"
tmp_hits="$(mktemp)"
trap 'rm -f "$tmp_hits"' EXIT

rules=(
  "SQL_SELECT_STAR::\\bSELECT\\s+\\*\\b"
  "EF_FROM_SQL_RAW_INTERP::FromSqlRaw\\s*\\(\\s*\\$\\\""
  "EF_EXEC_SQL_RAW_INTERP::ExecuteSqlRaw\\s*\\(\\s*\\$\\\""
  "EF_FROM_SQL_RAW_CONCAT::FromSqlRaw\\s*\\(.*\\+"
  "EF_EXEC_SQL_RAW_CONCAT::ExecuteSqlRaw\\s*\\(.*\\+"
  "INSECURE_RANDOM_FOR_CRYPTO::new\\s+Random\\s*\\("
  "WEAK_HASH_MD5::\\bMD5\\b"
  "WEAK_HASH_SHA1::\\bSHA1\\b"
  "BINARYFORMATTER::\\bBinaryFormatter\\b"
  "HARDCODED_PASSWORD_JSON::\"(password|pwd|clientSecret|connectionString)\"\\s*:"
)

scan_roots=(
  "src"
  "services"
  "tests"
)

rg_scan() {
  local name="$1"
  local regex="$2"
  local path="$3"
  rg -n --no-messages -S --pcre2 "$regex" "$path" \
    --glob '**/*.cs' \
    --glob '**/*.fs' \
    --glob '**/*.vb' \
    --glob '**/*.sql' \
    --glob '**/*.json' \
    --glob '**/*.config' \
    --glob '!**/.git/**' \
    --glob '!**/evidence/**' \
    --glob '!**/bin/**' \
    --glob '!**/obj/**' \
    --glob '!**/.venv/**' \
    --glob '!**/node_modules/**' \
    | awk -F: -v n="$name" '{print n ":" $1 ":" $2}' >> "$tmp_hits" || true # symphony:allow_or_true
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
    --include '*.cs' \
    --include '*.fs' \
    --include '*.vb' \
    --include '*.sql' \
    --include '*.json' \
    --include '*.config' \
    "$regex" "$path" \
    | awk -F: -v n="$name" '{print n ":" $1 ":" $2}' >> "$tmp_hits" || true # symphony:allow_or_true
}

for p in "${scan_roots[@]}"; do
  [[ -e "$ROOT_DIR/$p" ]] || continue
  for r in "${rules[@]}"; do
    name="${r%%::*}"
    regex="${r#*::}"
    if command -v rg >/dev/null 2>&1; then
      rg_scan "$name" "$regex" "$ROOT_DIR/$p"
    else
      grep_scan "$name" "$regex" "$ROOT_DIR/$p"
    fi
  done
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
  "\"check_id\": \"SEC-G10\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"hit_count\": ${count}" \
  "\"hits\": ${hits_json}"

if [[ "$status" != "PASS" ]]; then
  echo "Insecure pattern lint failed: ${count} hits."
  echo "Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "Insecure pattern lint passed. Evidence: $EVIDENCE_FILE"
