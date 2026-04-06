#!/usr/bin/env bash
set -e

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

echo "=== TSK-P1-226 Verification ==="

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/TEST-BLOCKER"
cat << 'EOF' > "$TMP_DIR/tasks/TEST-BLOCKER/meta.yml"
schema_version: 1
phase: '1'
task_id: TEST-BLOCKER
title: "Proof Blocker test pack"
owner_role: SECURITY_GUARDIAN
status: planned
touches: []
EOF

# Create a dummy downstream gate
cat << 'EOF' > "$TMP_DIR/dummy_downstream.py"
#!/usr/bin/env python3
import sys, json
from task_gate_result import GateResult
res = GateResult(status="PASS", failure_class="NONE", message="Downstream reached", gate_identity="dummy_downstream.py")
print(res.to_json())
EOF
chmod +x "$TMP_DIR/dummy_downstream.py"
chmod +x scripts/audit/task_proof_blocker_gate.py

# [ID tsk_p1_226_work_item_03] 
export PYTHONPATH="$REPO_ROOT/scripts/audit:$PYTHONPATH"
echo "[Test N1] Running blocked path (SIMULATE_PROOF_BLOCKER=1)"
export SIMULATE_PROOF_BLOCKER=1

set +e
BLOCKED_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/TEST-BLOCKER/meta.yml" --gates "scripts/audit/task_proof_blocker_gate.py" "$TMP_DIR/dummy_downstream.py")
set -e

if echo "$BLOCKED_OUT" | grep '"overall_status": "FAIL"' >/dev/null && echo "$BLOCKED_OUT" | grep '"status": "BLOCKED"' >/dev/null && echo "$BLOCKED_OUT" | grep '"FAILURE_CLASS": "PROOF_BLOCKED"' -i >/dev/null; then
    # Verify downstream gate did NOT execute!
    if echo "$BLOCKED_OUT" | grep 'Downstream reached' >/dev/null; then
        echo "ERROR: Runner executed downstream gate despite PROOF_BLOCKED!"
        exit 1
    fi
    echo "Negative test passed: Runner halted with PROOF_BLOCKED."
else
    echo "ERROR: Failed blocked logic structure."
    echo "$BLOCKED_OUT"
    exit 1
fi

# [ID tsk_p1_226_work_item_02] 
echo "[Test P1] Running unblocked path"
export SIMULATE_PROOF_BLOCKER=0
set +e
UNBLOCKED_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/TEST-BLOCKER/meta.yml" --gates "scripts/audit/task_proof_blocker_gate.py" "$TMP_DIR/dummy_downstream.py")
set -e

if echo "$UNBLOCKED_OUT" | grep '"overall_status": "PASS"' >/dev/null && echo "$UNBLOCKED_OUT" | grep 'Downstream reached' >/dev/null; then
    echo "Positive test passed: Runner completely executed downstream logic."
else
    echo "ERROR: Runner unexpectedly failed unblocked path."
    echo "$UNBLOCKED_OUT"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_226_proof_blocker.json
{
  "task_id": "TSK-P1-226",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_blocked_fails_closed_safely": "PASS",
    "P1_unblocked_passes_complete": "PASS"
  },
  "blocked_case_result": $BLOCKED_OUT,
  "unblocked_case_result": $UNBLOCKED_OUT,
  "fail_class": "PROOF_BLOCKED"
}
EOF

echo "TSK-P1-226 Verification Complete. Evidence written to evidence/phase1/tsk_p1_226_proof_blocker.json"
