#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-233 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-DEPENDS"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-DEPENDS/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-DEPENDS
title: "Dependency Test"
owner_role: SECURITY_GUARDIAN
status: planned
depends_on:
  - FIXTURE-PARENT
EOF

chmod +x scripts/audit/task_dependency_truth_gate.py
export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

echo "[Test N1] Running with SIMULATE_DEPENDENCY_UNPROVEN=1"
export SIMULATE_DEPENDENCY_UNPROVEN=1
export SIMULATE_DEPENDENCY_MISSING_OUTPUT=0

set +e
N1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-DEPENDS/meta.yml" --gates "scripts/audit/task_dependency_truth_gate.py")
N1_STATUS=$?
set -e

if echo "$N1_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N1_OUT" | grep 'UNPROVEN_DEPENDENCY' >/dev/null; then
    echo "Negative test N1 passed: Unproven dependency blocked."
else
    echo "ERROR: Failed to restrict completely unproven dependencies."
    echo "$N1_OUT"
    exit 1
fi

echo "[Test N2] Running with SIMULATE_DEPENDENCY_MISSING_OUTPUT=1"
export SIMULATE_DEPENDENCY_UNPROVEN=0
export SIMULATE_DEPENDENCY_MISSING_OUTPUT=1

set +e
N2_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-DEPENDS/meta.yml" --gates "scripts/audit/task_dependency_truth_gate.py")
N2_STATUS=$?
set -e

if echo "$N2_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N2_OUT" | grep 'MISSING_DEPENDENCY_OUTPUT' >/dev/null; then
    echo "Negative test N2 passed: Missing dependency output blocked."
else
    echo "ERROR: Failed to restrict missing dependency artifacts."
    echo "$N2_OUT"
    exit 1
fi

echo "[Test P1] Running strictly valid fixture with mechanical guarantees"
export SIMULATE_DEPENDENCY_MISSING_OUTPUT=0

set +e
P1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-DEPENDS/meta.yml" --gates "scripts/audit/task_dependency_truth_gate.py")
P1_STATUS=$?
set -e

if echo "$P1_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test P1 passed."
else
    echo "ERROR: Strict dependency verification failed!"
    echo "$P1_OUT"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)

cat << EOF > evidence/phase1/tsk_p1_233_dependency_truth.json
{
  "task_id": "TSK-P1-233",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_unproven_dependency": "PASS",
    "N2_missing_output": "PASS",
    "P1_valid_dependency": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity"],
  "unproven_dependency_result": $N1_OUT,
  "missing_output_result": $N2_OUT,
  "valid_dependency_result": $P1_OUT
}
EOF

echo "TSK-P1-233 Verification complete."
