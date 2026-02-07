#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/security_dotnet_deps_audit.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

status="PASS"
note=""
tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT

if ! command -v dotnet >/dev/null 2>&1; then
  status="FAIL"
  note="dotnet_cli_missing"
  write_json "$EVIDENCE_FILE" \
    "\"check_id\": \"SEC-G08\"" \
    "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
    "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
    "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
    "\"status\": \"${status}\"" \
    "\"note\": \"${note}\""
  echo "dotnet CLI not found."
  exit 1
fi

target=""
if ls "$ROOT_DIR"/*.sln >/dev/null 2>&1; then
  target="$(ls -1 "$ROOT_DIR"/*.sln | head -n 1)"
else
  sln_found="$(find "$ROOT_DIR" -maxdepth 4 -name '*.sln' | head -n 1)"
  if [[ -n "$sln_found" ]]; then
    target="$sln_found"
  fi
fi

if [[ -n "$target" ]]; then
  if ! dotnet list "$target" package --vulnerable --include-transitive > "$tmp_out" 2>&1; then
    status="FAIL"
  fi
else
  mapfile -t projects < <(find "$ROOT_DIR" -name '*.csproj' -o -name '*.fsproj' | LC_ALL=C sort)
  if [[ "${#projects[@]}" -eq 0 ]]; then
    status="PASS"
    note="no_dotnet_projects_found"
  else
    for p in "${projects[@]}"; do
      echo "=== $p ===" >> "$tmp_out"
      if ! dotnet list "$p" package --vulnerable --include-transitive >> "$tmp_out" 2>&1; then
        status="FAIL"
      fi
      echo "" >> "$tmp_out"
    done
  fi
fi

raw_output="$(cat "$tmp_out")"
if [[ "$status" == "PASS" ]]; then
  if command -v rg >/dev/null 2>&1; then
    if echo "$raw_output" | rg -qi "has the following vulnerable packages"; then
      status="FAIL"
    fi
  else
    if echo "$raw_output" | grep -qiE "has the following vulnerable packages"; then
      status="FAIL"
    fi
  fi
fi

lines_json="$(python3 - <<'PY' "$tmp_out"
import json,sys
p=sys.argv[1]
lines=[]
try:
    with open(p,'r',encoding='utf-8',errors='ignore') as f:
        for line in f:
            line=line.rstrip()
            if line.strip():
                lines.append(line[:300])
except FileNotFoundError:
    pass
print(json.dumps(lines[:2000]))
PY
)"

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-G08\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"note\": \"${note}\"" \
  "\"output_lines\": ${lines_json}"

if [[ "$status" != "PASS" ]]; then
  echo "Dependency audit failed."
  echo "Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "Dependency audit passed. Evidence: $EVIDENCE_FILE"
