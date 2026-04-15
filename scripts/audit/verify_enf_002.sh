#!/usr/bin/env bash
# verify_enf_002.sh — ENF-002 static + behavioural verifier
# Checks verify_drd_casefile.sh installed and pre_ci_debug_contract.sh patched.
# Emits evidence/phase1/enf_002_verify_drd_casefile.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_002_verify_drd_casefile.json"
CASEFILE_SCRIPT="$REPO_ROOT/scripts/audit/verify_drd_casefile.sh"
CONTRACT="$REPO_ROOT/scripts/audit/pre_ci_debug_contract.sh"
LOCKOUT_DIR="$REPO_ROOT/.toolchain/pre_ci_debug"
LOCKOUT_FILE="$LOCKOUT_DIR/drd_lockout.env"
TASK_ID="ENF-002"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
script_executable_confirmed="false"
contract_patch_confirmed="false"
no_lockout_exit_0_confirmed="false"
lockout_no_casefile_exit_1_confirmed="false"

echo "[1/5] Checking verify_drd_casefile.sh exists and is executable..."
if [[ -x "$CASEFILE_SCRIPT" ]]; then
    echo "✅ PASS: verify_drd_casefile.sh exists and is executable"
    checks+=("script_executable")
    script_executable_confirmed="true"
else
    echo "❌ FAIL: verify_drd_casefile.sh missing or not executable"
    failures+=("script_not_executable")
fi

echo ""
echo "[2/5] Checking pre_ci_debug_contract.sh patch applied..."
if grep -q "verify_drd_casefile.sh --clear" "$CONTRACT"; then
    echo "✅ PASS: verify_drd_casefile.sh --clear present in contract"
    checks+=("contract_patch_applied")
    contract_patch_confirmed="true"
else
    echo "❌ FAIL: verify_drd_casefile.sh --clear not found in contract"
    failures+=("contract_patch_missing")
fi

if grep -q "rm \$PRE_CI_DRD_LOCKOUT_FILE" "$CONTRACT" 2>/dev/null; then
    echo "❌ FAIL: raw rm instruction still present in contract"
    failures+=("raw_rm_still_present")
else
    echo "✅ PASS: raw rm instruction absent from contract"
    checks+=("raw_rm_absent")
fi

echo ""
echo "[3/5] Positive test — no lockout, verify_drd_casefile.sh should exit 0..."
set +e
no_lockout_exit="$(bash "$CASEFILE_SCRIPT" 2>&1; echo $?)"
# Get just the exit code (last line)
no_lockout_code="${no_lockout_exit##*$'\n'}"
set -e

if [[ "$no_lockout_code" -eq 0 ]]; then
    echo "✅ PASS: verify_drd_casefile.sh exits 0 with no lockout"
    checks+=("no_lockout_exit_0")
    no_lockout_exit_0_confirmed="true"
else
    echo "❌ FAIL: verify_drd_casefile.sh exited $no_lockout_code with no lockout (expected 0)"
    failures+=("no_lockout_exit_nonzero:got_$no_lockout_code")
fi

echo ""
echo "[4/5] Negative test — lockout with no casefile, should exit 1..."
mkdir -p "$LOCKOUT_DIR"
echo "DRD_LOCKED_SIGNATURE='ENF002_TEST'
DRD_LOCKED_GATE_ID='test.gate'
DRD_LOCKED_COUNT=1
DRD_LOCKED_AT='$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)'
DRD_SCAFFOLD_CMD='echo test'" > "$LOCKOUT_FILE"

set +e
casefile_output="$(bash "$CASEFILE_SCRIPT" 2>&1)"
casefile_exit=$?
set -e

rm -f "$LOCKOUT_FILE"

if [[ $casefile_exit -eq 1 ]]; then
    echo "✅ PASS: verify_drd_casefile.sh exits 1 with lockout + no casefile"
    checks+=("lockout_no_casefile_exit_1")
    lockout_no_casefile_exit_1_confirmed="true"
else
    echo "❌ FAIL: verify_drd_casefile.sh exited $casefile_exit (expected 1)"
    failures+=("lockout_no_casefile_wrong_exit:got_$casefile_exit")
fi

echo ""
echo "[5/5] Emitting evidence..."
mkdir -p "$(dirname "$EVIDENCE_FILE")"

FAILURES_JSON="$(printf '%s\n' "${failures[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"
CHECKS_JSON="$(printf '%s\n' "${checks[@]:-}" | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')"

STATUS="PASS"
if [[ ${#failures[@]} -gt 0 ]]; then STATUS="FAIL"; fi

python3 - <<PY
import json
from pathlib import Path

def stob(s): return s.strip().lower() == "true"

evidence = {
    "task_id": "$TASK_ID",
    "run_id": "$RUN_ID",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "checks": $CHECKS_JSON,
    "failures": $FAILURES_JSON,
    "script_executable_confirmed": stob("$script_executable_confirmed"),
    "contract_patch_confirmed": stob("$contract_patch_confirmed"),
    "no_lockout_exit_0_confirmed": stob("$no_lockout_exit_0_confirmed"),
    "lockout_no_casefile_exit_1_confirmed": stob("$lockout_no_casefile_exit_1_confirmed"),
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-002 PASS"
    exit 0
else
    echo "❌ ENF-002 FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi
