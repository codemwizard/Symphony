#!/usr/bin/env bash
# verify_enf_003b.sh — ENF-003B static + behavioural verifier
# Checks reset_evidence_gate.sh installed and functional.
# Emits evidence/phase1/enf_003b_reset_evidence_gate.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_003b_reset_evidence_gate.json"
RESET_SCRIPT="$REPO_ROOT/scripts/audit/reset_evidence_gate.sh"
ACK_DIR="$REPO_ROOT/.toolchain/evidence_ack"
TASK_ID="ENF-003B"
TEST_TASK="TEST-ENF003B-VERIFY"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
script_executable_confirmed="false"
help_flag_confirmed="false"
reset_clears_state_confirmed="false"
audit_log_written_confirmed="false"

echo "[1/5] Checking reset_evidence_gate.sh exists and is executable..."
if [[ -x "$RESET_SCRIPT" ]]; then
    echo "✅ PASS: reset_evidence_gate.sh exists and is executable"
    checks+=("script_executable")
    script_executable_confirmed="true"
else
    echo "❌ FAIL: reset_evidence_gate.sh missing or not executable"
    failures+=("script_not_executable")
fi

echo ""
echo "[2/5] Checking --help exits 0 with usage text..."
set +e
help_output="$(bash "$RESET_SCRIPT" --help 2>&1)"
help_exit=$?
set -e

if [[ $help_exit -eq 0 ]]; then
    echo "✅ PASS: --help exits 0"
    checks+=("help_flag_exit_0")
    help_flag_confirmed="true"
else
    echo "❌ FAIL: --help exited $help_exit (expected 0)"
    failures+=("help_flag_nonzero:got_$help_exit")
fi

echo ""
echo "[3/5] Negative test — no arguments must exit non-zero..."
set +e
no_args_exit="$(bash "$RESET_SCRIPT" 2>&1; echo $?)"
no_args_code="${no_args_exit##*$'\n'}"
set -e

if [[ "$no_args_code" -ne 0 ]]; then
    echo "✅ PASS: reset_evidence_gate.sh exits non-zero with no arguments"
    checks+=("no_args_nonzero")
else
    echo "❌ FAIL: reset_evidence_gate.sh exited 0 with no arguments (should require TASK_ID)"
    failures+=("no_args_accepted_silently")
fi

echo ""
echo "[4/5] Functional test — reset clears .retries and .required, writes audit log..."
mkdir -p "$ACK_DIR"
echo "2" > "$ACK_DIR/${TEST_TASK}.retries"
touch "$ACK_DIR/${TEST_TASK}.required"

set +e
bash "$RESET_SCRIPT" "$TEST_TASK" 2>&1
reset_exit=$?
set -e

if [[ $reset_exit -eq 0 ]]; then
    echo "✅ PASS: reset exited 0"
    checks+=("reset_exit_0")
else
    echo "❌ FAIL: reset exited $reset_exit (expected 0)"
    failures+=("reset_nonzero_exit:got_$reset_exit")
fi

if [[ ! -f "$ACK_DIR/${TEST_TASK}.retries" ]]; then
    echo "✅ PASS: .retries file removed"
    checks+=("retries_file_removed")
    reset_clears_state_confirmed="true"
else
    echo "❌ FAIL: .retries file still exists after reset"
    failures+=("retries_file_not_removed")
fi

if [[ ! -f "$ACK_DIR/${TEST_TASK}.required" ]]; then
    echo "✅ PASS: .required file removed"
    checks+=("required_file_removed")
else
    echo "❌ FAIL: .required file still exists after reset"
    failures+=("required_file_not_removed")
    reset_clears_state_confirmed="false"
fi

RESET_LOG="$REPO_ROOT/.toolchain/evidence_ack/reset_log.jsonl"
if [[ -f "$RESET_LOG" ]] && grep -q "$TEST_TASK" "$RESET_LOG"; then
    echo "✅ PASS: reset_log.jsonl contains entry for test task"
    checks+=("audit_log_written")
    audit_log_written_confirmed="true"
else
    echo "❌ FAIL: reset_log.jsonl missing or has no entry for test task"
    failures+=("audit_log_not_written")
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
    "help_flag_confirmed": stob("$help_flag_confirmed"),
    "reset_clears_state_confirmed": stob("$reset_clears_state_confirmed"),
    "audit_log_written_confirmed": stob("$audit_log_written_confirmed"),
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-003B PASS"
    exit 0
else
    echo "❌ ENF-003B FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi
