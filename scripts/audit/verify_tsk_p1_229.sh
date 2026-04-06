#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-229 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-PARITY"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-PARITY/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-PARITY
title: "Parity Test"
owner_role: SECURITY_GUARDIAN
status: planned
EOF

chmod +x scripts/audit/task_parity_gate.py
export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

echo "[Test N1] Running with SIMULATE_PARITY_MISMATCH=1"
export SIMULATE_PARITY_MISMATCH=1
set +e
BLOCKED_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PARITY/meta.yml" --gates "scripts/audit/task_parity_gate.py")
N1_STATUS=$?
set -e

if echo "$BLOCKED_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$BLOCKED_OUT" | grep 'PARITY_DRIFT' >/dev/null; then
    echo "Negative test passed: Parity mismatch structured failure emitted."
else
    echo "ERROR: Failed to detect parity drift or emit correct contract fields."
    echo "$BLOCKED_OUT"
    exit 1
fi

echo "[Test P1] Running unblocked path"
export SIMULATE_PARITY_MISMATCH=0
set +e
UNBLOCKED_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PARITY/meta.yml" --gates "scripts/audit/task_parity_gate.py")
P1_STATUS=$?
set -e

if echo "$UNBLOCKED_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test passed: Aligned docs allowed strictly."
else
    echo "ERROR: Valid parity case false positive."
    echo "$UNBLOCKED_OUT"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_229_task_parity.json
{
  "task_id": "TSK-P1-229",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_mismatch": "PASS",
    "P1_aligned": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity"],
  "mismatched_fixture_result": $BLOCKED_OUT,
  "aligned_fixture_result": $UNBLOCKED_OUT,
  "compared_contract_sections": ["verification", "evidence"]
}
EOF

echo "TSK-P1-229 Verification complete."
