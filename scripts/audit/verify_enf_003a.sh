#!/usr/bin/env bash
# verify_enf_003a.sh — ENF-003A static + behavioural verifier
# Checks run_task.sh has all three ENF-003 blocks and exits 51/50 as expected.
# Emits evidence/phase1/enf_003a_run_task_evidence_ack_gate.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_003a_run_task_evidence_ack_gate.json"
RUN_TASK="$REPO_ROOT/scripts/agent/run_task.sh"
ACK_DIR="$REPO_ROOT/.toolchain/evidence_ack"
TASK_ID="ENF-003A"
TEST_TASK="TEST-ENF003A-VERIFY"
TASK_DIR_CLEANUP="$REPO_ROOT/tasks/$TEST_TASK"
PLAN_DIR_CLEANUP="$REPO_ROOT/docs/plans/phase1/$TEST_TASK"

_cleanup_test_task() {
    rm -rf "$TASK_DIR_CLEANUP" "$PLAN_DIR_CLEANUP"
    rm -f "$REPO_ROOT/.toolchain/evidence_ack/${TEST_TASK}".*
}
trap _cleanup_test_task EXIT

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
gate_marker_confirmed="false"
retry_marker_confirmed="false"
cleanup_marker_confirmed="false"
exit_51_on_missing_ack_confirmed="false"
exit_50_on_retry_limit_confirmed="false"

echo "[1/5] Checking all three ENF-003 markers in run_task.sh..."
if grep -q "ENF-003: evidence ack gate" "$RUN_TASK"; then
    echo "✅ PASS: evidence ack gate marker present"
    checks+=("gate_marker_present")
    gate_marker_confirmed="true"
else
    echo "❌ FAIL: evidence ack gate marker missing"
    failures+=("gate_marker_missing")
fi

if grep -q "ENF-003: retry counter increment on failure" "$RUN_TASK"; then
    echo "✅ PASS: retry counter marker present"
    checks+=("retry_marker_present")
    retry_marker_confirmed="true"
else
    echo "❌ FAIL: retry counter marker missing"
    failures+=("retry_marker_missing")
fi

if grep -q "ENF-003: cleanup on success" "$RUN_TASK"; then
    echo "✅ PASS: cleanup marker present"
    checks+=("cleanup_marker_present")
    cleanup_marker_confirmed="true"
else
    echo "❌ FAIL: cleanup marker missing"
    failures+=("cleanup_marker_missing")
fi

echo ""
echo "[2/5] Negative test — .required present, no ack file, expect exit 51..."
# Create minimal valid task so meta parse succeeds and the ack gate is reachable
TASK_DIR="$REPO_ROOT/tasks/$TEST_TASK"
PLAN_DIR="$REPO_ROOT/docs/plans/phase1/$TEST_TASK"
mkdir -p "$TASK_DIR" "$PLAN_DIR"
cat > "$TASK_DIR/meta.yml" <<METAEOF
schema_version: 1
phase: '1'
task_id: $TEST_TASK
title: "Temporary test task for ENF-003A verifier"
owner_role: QA_VERIFIER
status: planned
verification:
  - echo "verify"
evidence:
  - evidence/phase1/${TEST_TASK}.json
implementation_plan: docs/plans/phase1/$TEST_TASK/PLAN.md
implementation_log: docs/plans/phase1/$TEST_TASK/EXEC_LOG.md
METAEOF
echo "# temp" > "$PLAN_DIR/PLAN.md"
echo "# temp" > "$PLAN_DIR/EXEC_LOG.md"

mkdir -p "$ACK_DIR"
touch "$ACK_DIR/${TEST_TASK}.required"
# Ensure no stale retries from previous test runs
rm -f "$ACK_DIR/${TEST_TASK}.retries"

set +e
output_51="$(bash "$RUN_TASK" "$TEST_TASK" 2>&1)"
exit_51=$?
set -e

rm -f "$ACK_DIR/${TEST_TASK}.required"

if [[ $exit_51 -eq 51 ]]; then
    echo "✅ PASS: run_task.sh exited 51 with .required and no ack"
    checks+=("exit_51_on_missing_ack")
    exit_51_on_missing_ack_confirmed="true"
else
    echo "❌ FAIL: run_task.sh exited $exit_51 (expected 51)"
    failures+=("exit_51_not_returned:got_$exit_51")
fi

if echo "$output_51" | grep -q "EVIDENCE ACK REQUIRED"; then
    echo "✅ PASS: 'EVIDENCE ACK REQUIRED' message present"
    checks+=("ack_required_message_present")
else
    echo "❌ FAIL: 'EVIDENCE ACK REQUIRED' message missing"
    failures+=("ack_required_message_missing")
fi

echo ""
echo "[3/5] Negative test — retry count >= 3, expect exit 50..."
echo "3" > "$ACK_DIR/${TEST_TASK}.retries"
rm -f "$ACK_DIR/${TEST_TASK}.required"

set +e
output_50="$(bash "$RUN_TASK" "$TEST_TASK" 2>&1)"
exit_50=$?
set -e

rm -f "$ACK_DIR/${TEST_TASK}.retries"

if [[ $exit_50 -eq 50 ]]; then
    echo "✅ PASS: run_task.sh exited 50 with retry count >= 3"
    checks+=("exit_50_on_retry_limit")
    exit_50_on_retry_limit_confirmed="true"
else
    echo "❌ FAIL: run_task.sh exited $exit_50 (expected 50)"
    failures+=("exit_50_not_returned:got_$exit_50")
fi

if echo "$output_50" | grep -q "HARD BLOCK"; then
    echo "✅ PASS: 'HARD BLOCK' message present"
    checks+=("hard_block_message_present")
else
    echo "❌ FAIL: 'HARD BLOCK' message missing"
    failures+=("hard_block_message_missing")
fi

echo ""
echo "[4/5] Negative test — ack file with root_cause='pending' must stay blocked..."
mkdir -p "$ACK_DIR"
touch "$ACK_DIR/${TEST_TASK}.required"
echo "0" > "$ACK_DIR/${TEST_TASK}.retries"
cat > "$ACK_DIR/${TEST_TASK}.ack.attempt_0" <<YMLEOF
task_id: $TEST_TASK
evidence_read: true
root_cause: pending
acknowledged_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
YMLEOF

set +e
output_pending="$(bash "$RUN_TASK" "$TEST_TASK" 2>&1)"
exit_pending=$?
set -e

rm -f "$ACK_DIR/${TEST_TASK}.required" "$ACK_DIR/${TEST_TASK}.retries" "$ACK_DIR/${TEST_TASK}.ack.attempt_0"
# Clean up temp task directory now that all tests are done
rm -rf "$TASK_DIR_CLEANUP" "$PLAN_DIR_CLEANUP"

if [[ $exit_pending -eq 51 ]]; then
    echo "✅ PASS: run_task.sh still exits 51 with pending root_cause in ack"
    checks+=("pending_root_cause_still_blocked")
else
    echo "❌ FAIL: run_task.sh exited $exit_pending with pending root_cause (should be 51)"
    failures+=("pending_root_cause_bypass:got_$exit_pending")
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
    "gate_marker_confirmed": stob("$gate_marker_confirmed"),
    "retry_marker_confirmed": stob("$retry_marker_confirmed"),
    "cleanup_marker_confirmed": stob("$cleanup_marker_confirmed"),
    "exit_51_on_missing_ack_confirmed": stob("$exit_51_on_missing_ack_confirmed"),
    "exit_50_on_retry_limit_confirmed": stob("$exit_50_on_retry_limit_confirmed"),
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-003A PASS"
    exit 0
else
    echo "❌ ENF-003A FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi
