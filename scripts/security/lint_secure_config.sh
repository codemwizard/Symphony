#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/security_secure_config_lint.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

status="PASS"
tmp_hits="$(mktemp)"
trap 'rm -f "$tmp_hits"' EXIT

rules=(
  "DISABLE_AUDIT_LOGGING::(?i)disable[_-]?audit|audit[_-]?disable|no[_-]?audit"
  "INSECURE_TLS::(?i)tls\\s*1\\.0|tls\\s*1\\.1|ssl\\s*3\\.0"
  "ALLOW_INSECURE_HTTP::(?i)AllowInsecureHttp|http://"
  "SKIP_CERT_VALIDATION::(?i)ServerCertificateCustomValidationCallback|DangerousAcceptAnyServerCertificateValidator"
  "DEV_AUTH_BYPASS::(?i)DisableAuth|BypassAuth|AllowAnonymous\\s*\\("
)

scan_paths=(
  "infra"
  "docker"
  "infra/docker"
  "infra/openbao"
  ".github"
  "src"
  "services"
)

rg_scan() {
  local name="$1"
  local regex="$2"
  local path="$3"
  rg -n --no-messages -S --pcre2 "$regex" "$path" \
    --glob '!**/.git/**' \
    --glob '!**/evidence/**' \
    --glob '!**/bin/**' \
    --glob '!**/obj/**' \
    --glob '!**/.venv/**' \
    --glob '!**/node_modules/**' \
    | awk -F: -v n="$name" '{print n ":" $1 ":" $2}' >> "$tmp_hits" || true
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
    "$regex" "$path" \
    | awk -F: -v n="$name" '{print n ":" $1 ":" $2}' >> "$tmp_hits" || true
}

for p in "${scan_paths[@]}"; do
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

hits_json="$(python3 - <<'PY' "$tmp_hits"
import json,sys
from pathlib import Path

p=Path(sys.argv[1])
items=[]
for raw in p.read_text(encoding='utf-8',errors='ignore').splitlines():
    raw=raw.strip()
    if not raw:
        continue
    try:
        rule,path,line_no = raw.split(":", 2)
    except ValueError:
        items.append(raw)
        continue
    if rule == "ALLOW_INSECURE_HTTP":
        try:
            ln = int(line_no)
            content = Path(path).read_text(encoding='utf-8',errors='ignore').splitlines()
            if 1 <= ln <= len(content):
                line = content[ln-1]
                if ("127.0.0.1" in line) or ("localhost" in line) or ("0.0.0.0" in line):
                    continue
        except Exception:
            pass
    items.append(raw)
items=sorted(set(items))
print(json.dumps(items))
PY
)"

count="$(python3 - <<'PY' "$hits_json"
import json,sys
items=json.loads(sys.argv[1]) if sys.argv[1] else []
print(len(items))
PY
)"
if [[ "$count" != "0" ]]; then
  status="FAIL"
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-G09\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"hit_count\": ${count}" \
  "\"hits\": ${hits_json}"

if [[ "$status" != "PASS" ]]; then
  echo "Secure config lint failed: ${count} hits."
  echo "Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "Secure config lint passed. Evidence: $EVIDENCE_FILE"
