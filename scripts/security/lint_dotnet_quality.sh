#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${DOTNET_LINT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="$EVIDENCE_DIR/dotnet_lint_quality.json"
DOTNET_LINT_TIMEOUT_SEC="${DOTNET_LINT_TIMEOUT_SEC:-60}"

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
relative_targets=()
format_env_blocked=0
processed_targets=0

run_dotnet_step() {
  local label="$1"
  shift
  local rc=0

  echo "--- $label ---" >> "$tmp_out"
  if command -v timeout >/dev/null 2>&1; then
    if timeout --signal=TERM "${DOTNET_LINT_TIMEOUT_SEC}s" "$@" >> "$tmp_out" 2>&1; then
      return 0
    else
      rc=$?
      return "$rc"
    fi
  else
    if "$@" >> "$tmp_out" 2>&1; then
      return 0
    else
      rc=$?
      return "$rc"
    fi
  fi
}

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
  for t in "${targets[@]}"; do
    relative_targets+=("${t#$ROOT_DIR/}")
  done
  if ! command -v dotnet >/dev/null 2>&1; then
    status="FAIL"
    note="dotnet_cli_missing"
  fi
fi

if [[ "$status" == "PASS" && "${#targets[@]}" -gt 0 ]]; then
  for t in "${targets[@]}"; do
    processed_targets=$((processed_targets + 1))
    echo "=== TARGET: $t ===" >> "$tmp_out"

    if run_dotnet_step "dotnet restore" dotnet restore "$t" -v minimal; then
      rc=0
    else
      rc=$?
    fi
    if [[ "$rc" -eq 124 ]]; then
      echo "TIMEOUT: dotnet restore (${DOTNET_LINT_TIMEOUT_SEC}s)" >> "$tmp_out"
      status="FAIL"
      note="dotnet_restore_timeout"
      break
    elif [[ "$rc" -ne 0 ]]; then
      status="FAIL"
      note="dotnet_restore_failed"
      break
    fi

    if run_dotnet_step "dotnet format --verify-no-changes" dotnet format "$t" --verify-no-changes --verbosity minimal; then
      rc=0
    else
      rc=$?
    fi
    if [[ "$rc" -ne 0 ]]; then
      if [[ "$rc" -eq 124 ]]; then
        echo "TIMEOUT: dotnet format --verify-no-changes (${DOTNET_LINT_TIMEOUT_SEC}s)" >> "$tmp_out"
        status="FAIL"
        note="dotnet_format_timeout"
        break
      fi

      if [[ "${GITHUB_ACTIONS:-}" != "true" ]] && \
         grep -Eq "SocketException \(13\): Permission denied|NamedPipeClientStream" "$tmp_out"; then
        format_env_blocked=1
        note="dotnet_format_env_blocked"
        echo "SHORT_CIRCUIT: dotnet_format_env_blocked" >> "$tmp_out"
        break
      else
        status="FAIL"
        note="dotnet_format_failed"
        break
      fi
    fi

    if run_dotnet_step "dotnet build -warnaserror" dotnet build "$t" -warnaserror -nologo -v minimal; then
      rc=0
    else
      rc=$?
    fi
    if [[ "$rc" -eq 124 ]]; then
      echo "TIMEOUT: dotnet build -warnaserror (${DOTNET_LINT_TIMEOUT_SEC}s)" >> "$tmp_out"
      status="FAIL"
      note="dotnet_build_timeout"
      break
    elif [[ "$rc" -ne 0 ]]; then
      status="FAIL"
      note="dotnet_build_failed"
      break
    fi
  done
fi

if [[ "$status" == "PASS" && "$format_env_blocked" -eq 1 ]]; then
  note="dotnet_format_env_blocked"
fi

summary_json="$(python3 - <<'PY' "$tmp_out"
import json,sys
from collections import Counter

p=sys.argv[1]
lines=[]
counter=Counter()
try:
    with open(p,'r',encoding='utf-8',errors='ignore') as f:
        for raw in f:
            line=raw.rstrip()
            if not line.strip():
                continue
            lines.append(line)
            if line.startswith("=== TARGET: "):
                counter["targets_seen"] += 1
            elif line == "--- dotnet restore ---":
                counter["restore_invocations"] += 1
            elif line == "--- dotnet format --verify-no-changes ---":
                counter["format_invocations"] += 1
            elif line == "--- dotnet build -warnaserror ---":
                counter["build_invocations"] += 1
            elif "Build succeeded." in line:
                counter["build_succeeded_markers"] += 1
            elif "Build FAILED." in line:
                counter["build_failed_markers"] += 1
            elif "Warning(s)" in line:
                counter["warning_lines"] += 1
            elif "Error(s)" in line:
                counter["error_lines"] += 1
            elif "Time Elapsed" in line:
                counter["time_elapsed_lines"] += 1
            elif "NamedPipeClientStream" in line or "SocketException (13): Permission denied" in line:
                counter["format_env_blocked_markers"] += 1
            elif line.startswith("TIMEOUT: "):
                counter["timeout_markers"] += 1
            elif line.startswith("SHORT_CIRCUIT: "):
                counter["short_circuit_markers"] += 1
except FileNotFoundError:
    pass

print(json.dumps(counter, sort_keys=True))
PY
)"

targets_json="$(python3 - <<'PY' "${relative_targets[@]:-}"
import json,sys
print(json.dumps([x for x in sys.argv[1:] if x]))
PY
)"

format_env_blocked_json=false
if [[ "$format_env_blocked" -eq 1 ]]; then
  format_env_blocked_json=true
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"SEC-G18\"" \
  "\"timestamp_utc\": \"${EVIDENCE_TS}\"" \
  "\"git_sha\": \"${EVIDENCE_GIT_SHA}\"" \
  "\"schema_fingerprint\": \"${EVIDENCE_SCHEMA_FP}\"" \
  "\"status\": \"${status}\"" \
  "\"note\": \"${note}\"" \
  "\"targets\": ${targets_json}" \
  "\"targets_count\": ${#targets[@]}" \
  "\"processed_targets_count\": ${processed_targets}" \
  "\"timeout_seconds\": ${DOTNET_LINT_TIMEOUT_SEC}" \
  "\"format_env_blocked\": ${format_env_blocked_json}" \
  "\"command_summary\": ${summary_json}"

if [[ "$status" != "PASS" ]]; then
  echo "dotnet quality lint failed. Evidence: $EVIDENCE_FILE"
  exit 1
fi

echo "dotnet quality lint passed. Evidence: $EVIDENCE_FILE"
