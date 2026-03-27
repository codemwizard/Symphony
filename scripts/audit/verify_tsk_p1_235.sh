#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-235 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-AUTHORITY"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-AUTHORITY/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-AUTHORITY
title: "Authority Test"
owner_role: SECURITY_GUARDIAN
status: planned
EOF

chmod +x scripts/audit/task_execution_authority_gate.py
export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

echo "[Test N1] Running with SIMULATE_AUTHORITY_DIRECT_INVOCATION=1"
export SIMULATE_AUTHORITY_DIRECT_INVOCATION=1
export SIMULATE_AUTHORITY_PARTIAL_BYPASS=0
# Assume the unified bash wrapper handles marking
export SYMPHONY_CANONICAL_ENTRYPOINT=1 

set +e
N1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-AUTHORITY/meta.yml" --gates "scripts/audit/task_execution_authority_gate.py")
N1_STATUS=$?
set -e

if echo "$N1_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N1_OUT" | grep 'NON_AUTHORITATIVE_EXECUTION' >/dev/null; then
    echo "Negative test N1 passed: Direct partial gate execution blocked."
else
    echo "ERROR: Failed to restrict direct individual gate calls."
    echo "$N1_OUT"
    exit 1
fi

echo "[Test N2] Running with SIMULATE_AUTHORITY_PARTIAL_BYPASS=1"
export SIMULATE_AUTHORITY_DIRECT_INVOCATION=0
export SIMULATE_AUTHORITY_PARTIAL_BYPASS=1

set +e
N2_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-AUTHORITY/meta.yml" --gates "scripts/audit/task_execution_authority_gate.py")
N2_STATUS=$?
set -e

if echo "$N2_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N2_OUT" | grep 'NON_AUTHORITATIVE_EXECUTION' >/dev/null; then
    echo "Negative test N2 passed: Script bypass wrapper blocked."
else
    echo "ERROR: Failed to trace missing python runner boundary."
    echo "$N2_OUT"
    exit 1
fi

echo "[Test P1] Running verified canonical route"
export SIMULATE_AUTHORITY_DIRECT_INVOCATION=0
export SIMULATE_AUTHORITY_PARTIAL_BYPASS=0

set +e
P1_OUT=$(bash scripts/audit/verify_task.sh "$TMP_DIR/tasks/FIXTURE-AUTHORITY/meta.yml" --gates "scripts/audit/task_execution_authority_gate.py")
P1_STATUS=$?
set -e

if echo "$P1_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test P1 passed."
else
    echo "ERROR: Valid execution shell trace rejected!"
    echo "$P1_OUT"
    exit 1
fi

git_sha=$(git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_235_execution_authority.json
{
  "task_id": "TSK-P1-235",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_direct_invocation": "PASS",
    "N2_partial_bypass": "PASS",
    "P1_canonical_flow": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity", "next_action"],
  "direct_invocation_result": $N1_OUT,
  "partial_bypass_result": $N2_OUT,
  "canonical_flow_result": $P1_OUT
}
EOF

echo "TSK-P1-235 Verification complete."
