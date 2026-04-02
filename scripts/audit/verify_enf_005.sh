#!/usr/bin/env bash
# verify_enf_005.sh — ENF-005 static + behavioural verifier
# Checks clear_drd_lockout_privileged.sh installed and verify_drd_casefile.sh patched.
# Emits evidence/phase1/enf_005_drd_lockout_sudo_gate.json.
# Exit 0 = PASS, Exit 1 = FAIL.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_FILE="$REPO_ROOT/evidence/phase1/enf_005_drd_lockout_sudo_gate.json"
WRAPPER="$REPO_ROOT/scripts/audit/clear_drd_lockout_privileged.sh"
CASEFILE_SCRIPT="$REPO_ROOT/scripts/audit/verify_drd_casefile.sh"
TASK_ID="ENF-005"

RUN_ID="${SYMPHONY_RUN_ID:-}"
GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

failures=()
checks=()
wrapper_script_exists_confirmed="false"
direct_rm_absent_confirmed="false"
sudo_call_present_confirmed="false"

echo "[1/5] Checking clear_drd_lockout_privileged.sh exists and is executable..."
if [[ -x "$WRAPPER" ]]; then
    echo "✅ PASS: clear_drd_lockout_privileged.sh exists and is executable"
    checks+=("wrapper_executable")
    wrapper_script_exists_confirmed="true"
else
    echo "❌ FAIL: clear_drd_lockout_privileged.sh missing or not executable"
    failures+=("wrapper_not_executable")
fi

echo ""
echo "[2/5] Checking wrapper has audit log write and file-existence guard..."
if grep -q "clear_log\|reset_log" "$WRAPPER"; then
    echo "✅ PASS: audit log reference found in wrapper"
    checks+=("wrapper_has_audit_log")
else
    echo "❌ FAIL: audit log reference missing from wrapper"
    failures+=("wrapper_no_audit_log")
fi

if grep -q "not present\|! -f\|-f.*DRD_LOCKOUT" "$WRAPPER"; then
    echo "✅ PASS: file-existence guard found in wrapper"
    checks+=("wrapper_has_existence_guard")
else
    echo "❌ FAIL: file-existence guard missing from wrapper"
    failures+=("wrapper_no_existence_guard")
fi

echo ""
echo "[3/5] Checking direct rm on DRD_LOCKOUT_FILE is absent from verify_drd_casefile.sh..."
# Should not find a bare 'rm "$DRD_LOCKOUT_FILE"' line (not preceded by sudo or inside the wrapper path)
if grep -n '^rm "\$DRD_LOCKOUT_FILE"' "$CASEFILE_SCRIPT" 2>/dev/null | grep -v "clear_drd_lockout_privileged"; then
    echo "❌ FAIL: direct bare rm on DRD_LOCKOUT_FILE still present in verify_drd_casefile.sh"
    failures+=("direct_rm_still_present")
else
    echo "✅ PASS: direct bare rm on DRD_LOCKOUT_FILE absent from verify_drd_casefile.sh"
    checks+=("direct_rm_absent")
    direct_rm_absent_confirmed="true"
fi

echo ""
echo "[4/5] Checking sudo call to clear_drd_lockout_privileged.sh is present in verify_drd_casefile.sh..."
if grep -q "sudo.*clear_drd_lockout_privileged" "$CASEFILE_SCRIPT"; then
    echo "✅ PASS: sudo call to wrapper present in verify_drd_casefile.sh"
    checks+=("sudo_call_present")
    sudo_call_present_confirmed="true"
else
    echo "❌ FAIL: sudo call to wrapper missing from verify_drd_casefile.sh"
    failures+=("sudo_call_missing")
fi

echo ""
echo "[5/5] Negative test — wrapper exits 1 with no lockout file present..."
set +e
no_file_output="$(bash "$WRAPPER" 2>&1)"
no_file_exit=$?
set -e

if [[ $no_file_exit -eq 1 ]]; then
    echo "✅ PASS: wrapper exits 1 when lockout file is absent"
    checks+=("wrapper_exit_1_no_lockout")
else
    echo "❌ FAIL: wrapper exited $no_file_exit (expected 1) when no lockout file present"
    failures+=("wrapper_wrong_exit_no_lockout:got_$no_file_exit")
fi

echo ""
echo "[6/6] Emitting evidence..."
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
    "wrapper_script_exists_confirmed": stob("$wrapper_script_exists_confirmed"),
    "direct_rm_absent_confirmed": stob("$direct_rm_absent_confirmed"),
    "sudo_call_present_confirmed": stob("$sudo_call_present_confirmed"),
    "sudoers_entry_note": "human_step_required",
}
Path("$EVIDENCE_FILE").write_text(json.dumps(evidence, indent=2) + "\n")
print(f"Evidence written: $EVIDENCE_FILE")
PY

echo ""
if [[ "$STATUS" == "PASS" ]]; then
    echo "✅ ENF-005 PASS"
    echo "   NOTE: sudoers entry is a human step — see docs/plans/phase1/ENF-005/EXEC_LOG.md"
    exit 0
else
    echo "❌ ENF-005 FAIL — ${#failures[@]} failure(s): ${failures[*]}"
    exit 1
fi
