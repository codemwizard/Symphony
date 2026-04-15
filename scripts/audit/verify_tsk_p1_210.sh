#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CS_FILE="$ROOT/services/ledger-api/dotnet/src/LedgerApi/ReadModels/SupervisoryRevealReadModelHandler.cs"
UI_FILE="$ROOT/src/supervisory-dashboard/index.html"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_210_supervisory_optimization.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"

errors=()

[[ -f "$CS_FILE" ]] || errors+=("csharp_file_missing")
[[ -f "$UI_FILE" ]] || errors+=("index_html_missing")

echo "==> Verifying TSK-P1-210 optimizations and deduplication..."

if [[ -f "$CS_FILE" ]]; then
  # Check for pre-indexing (ToLookup) in BuildProgrammeModel
  if ! grep -q 'ToLookup' "$CS_FILE"; then
    errors+=("csharp_missing_tolookup")
  fi

  # Check that BuildTimeline takes ILookup
  if ! grep -q 'BuildTimeline(ILookup' "$CS_FILE"; then
    errors+=("csharp_buildtimeline_signature_not_updated")
  fi
fi

if [[ -f "$UI_FILE" ]]; then
  # Check for _fetchWithFallback helper
  if ! grep -q 'function _fetchWithFallback' "$UI_FILE"; then
    errors+=("ui_missing_fetch_helper")
  fi

  # Check that it's used at least 4 times
  count=$(grep -c '_fetchWithFallback' "$UI_FILE" || true)
  if [[ "$count" -lt 5 ]]; then
    errors+=("ui_helper_underutilized")
  fi
fi

if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source scripts/lib/evidence.sh

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-210",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-210",
    "run_id": run_id,
    "checks": {
        "read_model_handler_pre_indexed": "csharp_missing_tolookup" not in errors and "csharp_buildtimeline_signature_not_updated" not in errors,
        "ui_fetch_helper_implemented": "ui_missing_fetch_helper" not in errors,
        "ui_fetch_helper_utilized": "ui_helper_underutilized" not in errors
    },
    "errors": errors
}
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: Fallback deduplication and reveal optimization verified."
echo "Evidence: $EVIDENCE"
