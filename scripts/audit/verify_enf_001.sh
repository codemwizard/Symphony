#!/usr/bin/env bash
# verify_enf_001.sh — ENF-001 static + behavioural verifier
# Checks run_task.sh has the DRD lockout gate and exits 99 with lockout active.
# Emits evidence/phase1/enf_001_run_task_drd_gate.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_001_run_task_drd_gate.json"
RUN_TASK="$REPO_ROOT/scripts/agent/run_task.sh"
LOCKOUT_DIR="$REPO_ROOT/.toolchain/pre_ci_debug"
LOCKOUT_FILE="$LOCKOUT_DIR/drd_lockout.env"
TASK_ID="ENF-001"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
gate_marker_confirmed="false"
exit_99_on_lockout_confirmed="false"
no_false_positive_confirmed="false"

echo "[1/4] Checking ENF-001 gate marker in run_task.sh..."
if grep -q "ENF-001: DRD lockout gate" "$RUN_TASK"; then
    echo "✅ PASS: ENF-001 marker found in run_task.sh"
    checks+=("gate_marker_present")
    gate_marker_confirmed="true"
else
    echo "❌ FAIL: ENF-001 marker not found in run_task.sh"
    failures+=("gate_marker_missing")
fi

echo ""
echo "[2/4] Negative test — lockout active, expect exit 99..."
mkdir -p "$LOCKOUT_DIR"
echo "DRD_LOCKED_SIGNATURE='ENF001_TEST'
DRD_LOCKED_GATE_ID='test.gate'
DRD_LOCKED_COUNT=1
DRD_LOCKED_AT='$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)'
DRD_SCAFFOLD_CMD='echo test'" > "$LOCKOUT_FILE"

set +e
lockout_output="$(bash "$RUN_TASK" DUMMY_TASK_ID 2>&1)"
lockout_exit=$?
set -e

rm -f "$LOCKOUT_FILE"

if [[ $lockout_exit -eq 99 ]]; then
    echo "✅ PASS: run_task.sh exited 99 with lockout active"
    checks+=("exit_99_on_lockout")
    exit_99_on_lockout_confirmed="true"
else
    echo "❌ FAIL: run_task.sh exited $lockout_exit (expected 99) with lockout active"
    failures+=("exit_99_not_returned:got_$lockout_exit")
fi

if echo "$lockout_output" | grep -q "DRD LOCKOUT"; then
    echo "✅ PASS: 'DRD LOCKOUT' message present in output"
    checks+=("drd_lockout_message_present")
else
    echo "❌ FAIL: 'DRD LOCKOUT' message missing from output"
    failures+=("drd_lockout_message_missing")
fi

echo ""
echo "[3/4] Positive test — no lockout, expect non-99..."
set +e
no_lockout_exit="$(bash "$RUN_TASK" DEFINITELY_NOT_A_TASK_ZZZ 2>/dev/null; echo $?)"
set -e

if [[ "$no_lockout_exit" -ne 99 ]]; then
    echo "✅ PASS: run_task.sh did not exit 99 without lockout (exited $no_lockout_exit)"
    checks+=("no_false_positive")
    no_false_positive_confirmed="true"
else
    echo "❌ FAIL: run_task.sh exited 99 without lockout present (false positive)"
    failures+=("false_positive_lockout_exit")
fi

echo ""
echo "[4/4] Emitting evidence..."
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
    "exit_99_on_lockout_confirmed": stob("$exit_99_on_lockout_confirmed"),
    "no_false_positive_confirmed": stob("$no_false_positive_confirmed"),
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-001 PASS"
    exit 0
else
    echo "❌ ENF-001 FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi
