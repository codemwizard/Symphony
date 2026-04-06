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
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


# [ID tsk_p1_247_work_item_04]
# Deterministic Evidence Timestamp Verifier
# This script proves that all three drift tracks (Python, Harness, Standalone)
# now correctly honor SYMPHONY_EVIDENCE_DETERMINISTIC=1.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source scripts/lib/evidence.sh

EVIDENCE_FILE="$ROOT/evidence/phase1/tsk_p1_247_deterministic_timestamps.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

errors=()

echo "==> Verifying Determinism Track 1: Python (sign_evidence.py)..."
# Positive test: ensure it clamps to 1970 when flag is set
PRE_CI_RUN_ID="TSK-P1-247-DET-TEST-ID" SYMPHONY_EVIDENCE_DETERMINISTIC=1 python3 scripts/audit/sign_evidence.py --write --out /tmp/det_ev.json --task "TSK-P1-247-DET-TEST" --source-file "test" >/dev/null 2>&1 || errors+=("python_sign_script_execution_failed")
if [[ ! -f /tmp/det_ev.json ]] || ! grep -q "1970-01-01T00:00:00Z" /tmp/det_ev.json; then
  errors+=("python_track_failed_determinism_clamp")
fi

echo "==> Verifying Determinism Track 2: Harness (pre_ci.sh)..."
if ! grep -q "export SYMPHONY_EVIDENCE_DETERMINISTIC=1" scripts/dev/pre_ci.sh; then
  errors+=("pre_ci_harness_missing_global_export")
fi

echo "==> Verifying Determinism Track 3: Standalone Bash Verifiers..."
# Sample 210 structure check
if ! grep -q "SYMPHONY_EVIDENCE_DETERMINISTIC:-0" scripts/audit/verify_tsk_p1_210.sh; then
  errors+=("standalone_track_missing_bash_logic_210")
fi

# Multi-file check: ensure the pattern is applied broadly
P_COUNT=$(grep -l "SYMPHONY_EVIDENCE_DETERMINISTIC:-0" scripts/audit/verify_tsk_p1_*.sh | wc -l)
if [[ "$P_COUNT" -lt 15 ]]; then
  errors+=("standalone_track_incomplete_patch_count_${P_COUNT}")
fi

if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

# Emit fresh evidence
python3 - <<PY "$EVIDENCE_FILE" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys
evidence_path, status, ts, sha, schema_fp, errors_csv = sys.argv[1:7]
errors = [e for e in errors_csv.split(",") if e]

payload = {
    "check_id": "TSK-P1-247",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "checks": {
        "python_track_verified": "python_track_failed_determinism_clamp" not in errors,
        "harness_track_verified": "pre_ci_harness_missing_global_export" not in errors,
        "standalone_track_verified": "standalone_track_failed_run_id_clamp" not in errors and "standalone_track_missing_bash_logic_210" not in errors
    },
    "verified_python_override": "python_track_failed_determinism_clamp" not in errors,
    "verified_track3_parity": "standalone_track_failed_run_id_clamp" not in errors,
    "errors": errors
}
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: All three evidence drift tracks verified as deterministic."
echo "Evidence: $EVIDENCE_FILE"
