#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-232 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-PROOF"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-PROOF/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-PROOF
title: "Proof Test"
owner_role: SECURITY_GUARDIAN
status: planned
EOF

chmod +x scripts/audit/task_proof_integrity_gate.py
export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

echo "[Test N1] Running with SIMULATE_PROOF_DECORATIVE=1"
export SIMULATE_PROOF_DECORATIVE=1
export SIMULATE_PROOF_ORPHAN=0
export SIMULATE_PROOF_OVERCLAIM=0

set +e
N1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PROOF/meta.yml" --gates "scripts/audit/task_proof_integrity_gate.py")
N1_STATUS=$?
set -e

if echo "$N1_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N1_OUT" | grep 'PROOF_THEATER' >/dev/null; then
    echo "Negative test N1 passed: Decorative validation rejected."
else
    echo "ERROR: Failed to restrict decorative proof statements."
    echo "$N1_OUT"
    exit 1
fi

echo "[Test N2] Running with SIMULATE_PROOF_ORPHAN=1"
export SIMULATE_PROOF_DECORATIVE=0
export SIMULATE_PROOF_ORPHAN=1

set +e
N2_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PROOF/meta.yml" --gates "scripts/audit/task_proof_integrity_gate.py")
N2_STATUS=$?
set -e

if echo "$N2_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N2_OUT" | grep 'PROOF_THEATER' >/dev/null; then
    echo "Negative test N2 passed: Orphan evidence restricted."
else
    echo "ERROR: Failed to reject orphan evidence."
    echo "$N2_OUT"
    exit 1
fi

echo "[Test N3] Running with SIMULATE_PROOF_OVERCLAIM=1"
export SIMULATE_PROOF_ORPHAN=0
export SIMULATE_PROOF_OVERCLAIM=1

set +e
N3_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PROOF/meta.yml" --gates "scripts/audit/task_proof_integrity_gate.py")
N3_STATUS=$?
set -e

if echo "$N3_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N3_OUT" | grep 'PROOF_THEATER' >/dev/null; then
    echo "Negative test N3 passed: Semantic overclaim rejected."
else
    echo "ERROR: Failed to reject proof overclaim theater."
    echo "$N3_OUT"
    exit 1
fi

echo "[Test P1] Running strictly valid fixture"
export SIMULATE_PROOF_OVERCLAIM=0

set +e
P1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-PROOF/meta.yml" --gates "scripts/audit/task_proof_integrity_gate.py")
P1_STATUS=$?
set -e

if echo "$P1_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test P1 passed."
else
    echo "ERROR: Strict proof alignment rejected!"
    echo "$P1_OUT"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_232_proof_integrity.json
{
  "task_id": "TSK-P1-232",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_decorative_verifier": "PASS",
    "N2_orphan_evidence": "PASS",
    "N3_proof_overclaim": "PASS",
    "P1_valid_proof": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity"],
  "hard_scope_constraints": "Declares limits enforcing strict mapping parity over semantic guessing.",
  "proof_chain_requirements": "Requires AC + Verifier + Evidence interlocking.",
  "decorative_verifier_result": $N1_OUT,
  "orphan_evidence_result": $N2_OUT,
  "overclaimed_proof_result": $N3_OUT,
  "valid_fixture_result": $P1_OUT
}
EOF

echo "TSK-P1-232 Verification complete."
