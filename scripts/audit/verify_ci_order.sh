#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/ci_order.json"

mkdir -p "$EVIDENCE_DIR"

pre_ci_file="$ROOT_DIR/scripts/dev/pre_ci.sh"
ci_file="$ROOT_DIR/.github/workflows/invariants.yml"

missing=()
notes=()

have_rg=0
if command -v rg >/dev/null 2>&1; then
  have_rg=1
fi

if [[ ! -f "$pre_ci_file" ]]; then
  missing+=("pre_ci_missing:scripts/dev/pre_ci.sh")
else
  if [[ "$have_rg" == "1" ]]; then
    rg -n "run_phase0_ordered_checks\\.sh" "$pre_ci_file" >/dev/null 2>&1 || missing+=("pre_ci_missing_ordered_runner")
  else
    grep -q "run_phase0_ordered_checks.sh" "$pre_ci_file" || missing+=("pre_ci_missing_ordered_runner")
  fi
fi

if [[ ! -f "$ci_file" ]]; then
  missing+=("ci_workflow_missing:.github/workflows/invariants.yml")
else
  if [[ "$have_rg" == "1" ]]; then
    rg -n "run_phase0_ordered_checks\\.sh" "$ci_file" >/dev/null 2>&1 || missing+=("ci_workflow_missing_ordered_runner")
  else
    grep -q "run_phase0_ordered_checks.sh" "$ci_file" || missing+=("ci_workflow_missing_ordered_runner")
  fi
fi

status="PASS"
if [[ ${#missing[@]} -ne 0 ]]; then
  status="FAIL"
fi

write_json "$EVIDENCE_FILE" \
  "\"check_id\": \"PHASE0-CI-ORDER\"" \
  "\"timestamp_utc\": \"$(evidence_now_utc)\"" \
  "\"git_sha\": \"$(git_sha)\"" \
  "\"schema_fingerprint\": \"$(schema_fingerprint)\"" \
  "\"status\": \"$status\"" \
  "\"missing\": $(python3 - <<'PY'
import json,sys
print(json.dumps(sys.argv[1:]))
PY
${missing[@]})"

if [[ "$status" == "FAIL" ]]; then
  echo "❌ CI order verification failed. Missing:" >&2
  printf ' - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "CI order verification OK. Evidence: $EVIDENCE_FILE"
