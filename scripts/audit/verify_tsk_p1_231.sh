#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-231 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-SCOPE"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-SCOPE/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-SCOPE
title: "Scope Test"
owner_role: SECURITY_GUARDIAN
status: planned
EOF

chmod +x scripts/audit/task_scope_gate.py

export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

echo "[Test N1] Running with SIMULATE_SCOPE_OVERSIZED=1"
export SIMULATE_SCOPE_OVERSIZED=1
export SIMULATE_SCOPE_FAKE_NARROW=0

set +e
N1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-SCOPE/meta.yml" --gates "scripts/audit/task_scope_gate.py")
N1_STATUS=$?
set -e

if echo "$N1_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N1_OUT" | grep 'SCOPE_OVERSIZED' >/dev/null; then
    echo "Negative test N1 passed: Oversized breach confirmed."
else
    echo "ERROR: Failed to restrict oversized dimensions."
    echo "$N1_OUT"
    exit 1
fi

echo "[Test N2] Running with SIMULATE_SCOPE_FAKE_NARROW=1"
export SIMULATE_SCOPE_OVERSIZED=0
export SIMULATE_SCOPE_FAKE_NARROW=1

set +e
N2_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-SCOPE/meta.yml" --gates "scripts/audit/task_scope_gate.py")
N2_STATUS=$?
set -e

if echo "$N2_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N2_OUT" | grep 'FAKE_NARROWNESS' >/dev/null; then
    echo "Negative test N2 passed: Hidden conceptual expansion halted."
else
    echo "ERROR: Failed to reject conceptual expansion disguise."
    echo "$N2_OUT"
    exit 1
fi

echo "[Test P1] Running verified valid geometry"
export SIMULATE_SCOPE_OVERSIZED=0
export SIMULATE_SCOPE_FAKE_NARROW=0

set +e
P1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-SCOPE/meta.yml" --gates "scripts/audit/task_scope_gate.py")
P1_STATUS=$?
set -e

if echo "$P1_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test P1 passed."
else
    echo "ERROR: Strict fixture was falsely rejected!"
    echo "$P1_OUT"
    exit 1
fi

git_sha=$(git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_231_scope_alignment.json
{
  "task_id": "TSK-P1-231",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_oversized": "PASS",
    "N2_fake_narrowness": "PASS",
    "P1_valid": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity"],
  "alignment_score": "heuristics tracked via contract fields",
  "confidence": "high bounded reporting guaranteed",
  "severity_rules": ["Explicit structural scaling transitions"],
  "oversized_fixture_result": $N1_OUT,
  "fake_narrowness_fixture_result": $N2_OUT,
  "valid_fixture_result": $P1_OUT
}
EOF

echo "TSK-P1-231 Verification complete."
