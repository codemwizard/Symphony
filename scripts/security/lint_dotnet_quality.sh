#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${DOTNET_LINT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/dotnet_lint_quality.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT

status="PASS"
note=""
targets=()

if ls "$ROOT_DIR"/*.sln >/dev/null 2>&1; then
  while IFS= read -r f; do
    targets+=("$f")
  done < <(ls -1 "$ROOT_DIR"/*.sln | LC_ALL=C sort)
else
  while IFS= read -r f; do
    targets+=("$f")
  done < <(find "$ROOT_DIR" -name '*.csproj' -o -name '*.fsproj' | LC_ALL=C sort)
fi

if [[ "${#targets[@]}" -eq 0 ]]; then
  note="no_dotnet_projects_found"
else
  if ! command -v dotnet >/dev/null 2>&1; then
    status="FAIL"
    note="dotnet_cli_missing"
  fi
fi

if [[ "$status" == "PASS" && "${#targets[@]}" -gt 0 ]]; then
  for t in "${targets[@]}"; do
    echo "=== TARGET: $t ===" >> "$tmp_out"

    echo "--- dotnet restore ---" >> "$tmp_out"
    if ! dotnet restore "$t" -v minimal >> "$tmp_out" 2>&1; then
      status="FAIL"
    fi

    echo "--- dotnet format --verify-no-changes ---" >> "$tmp_out"
    if ! dotnet format "$t" --verify-no-changes --verbosity minimal >> "$tmp_out" 2>&1; then
      status="FAIL"
    fi

    echo "--- dotnet build -warnaserror ---" >> "$tmp_out"
    if ! dotnet build "$t" -warnaserror -nologo -v minimal >> "$tmp_out" 2>&1; then
      status="FAIL"
    fi
  done
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

targets_json="$(python3 - <<'PY' "${targets[@]:-}"
import json,sys
print(json.dumps([x for x in sys.argv[1:] if x]))
PY
)"

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-G18\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"note\": \"${note}\"" \
  "\"targets\": ${targets_json}" \
  "\"targets_count\": ${#targets[@]}" \
  "\"output_lines\": ${lines_json}"

if [[ "$status" != "PASS" ]]; then
  echo "dotnet quality lint failed. Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "dotnet quality lint passed. Evidence: $EVIDENCE_FILE"
