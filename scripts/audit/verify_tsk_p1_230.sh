#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-230 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/tasks/FIXTURE-AUTHORING"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-AUTHORING/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-AUTHORING
title: "Authoring Test"
owner_role: SECURITY_GUARDIAN
status: planned
EOF

chmod +x scripts/audit/task_authoring_gate.py

echo "[Test N1] Running with SIMULATE_AUTHORING_HOLLOW=1"
export SIMULATE_AUTHORING_HOLLOW=1
export PYTHONPATH="$ROOT_DIR/scripts/audit:$PYTHONPATH"

set +e
N1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-AUTHORING/meta.yml" --gates "scripts/audit/task_authoring_gate.py")
N1_STATUS=$?
set -e

if echo "$N1_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N1_OUT" | grep 'AUTHORING_THEATER' >/dev/null; then
    echo "Negative test N1 passed: Hollow contract surfaced."
else
    echo "ERROR: Failed to detect hollow contract."
    echo "$N1_OUT"
    exit 1
fi

echo "[Test N2] Running with SIMULATE_AUTHORING_ESCALATION=1"
export SIMULATE_AUTHORING_HOLLOW=0
export SIMULATE_AUTHORING_ESCALATION=1

set +e
N2_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-AUTHORING/meta.yml" --gates "scripts/audit/task_authoring_gate.py")
N2_STATUS=$?
set -e

if echo "$N2_OUT" | grep '"status": "FAIL"' >/dev/null && echo "$N2_OUT" | grep 'AUTHORING_THEATER' >/dev/null; then
    echo "Negative test N2 passed: Drift-density escalated."
else
    echo "ERROR: Failed to escalate repeated weak signals."
    echo "$N2_OUT"
    exit 1
fi

echo "[Test P1] Running strictly valid fixture"
export SIMULATE_AUTHORING_ESCALATION=0

set +e
P1_OUT=$(python3 scripts/audit/task_verification_runner.py --meta "$TMP_DIR/tasks/FIXTURE-AUTHORING/meta.yml" --gates "scripts/audit/task_authoring_gate.py")
P1_STATUS=$?
set -e

if echo "$P1_OUT" | grep '"overall_status": "PASS"' >/dev/null; then
    echo "Positive test P1 passed."
else
    echo "ERROR: Valid fixture rejected!"
    echo "$P1_OUT"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)

cat << EOF > evidence/phase1/tsk_p1_230_authoring_gate.json
{
  "task_id": "TSK-P1-230",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": {
    "N1_hollow": "PASS",
    "N2_escalation": "PASS",
    "P1_valid": "PASS"
  },
  "gate_result_contract_fields": ["status", "failure_class", "message", "gate_identity"],
  "current_mode": "report-only",
  "next_mode": "soft-block",
  "promotion_criteria": ["All Wave 1 packs green"],
  "rollback_conditions": ["False positive rate > 5%"],
  "drift_density_rules": ["3+ warnings = FAIL"],
  "invalid_fixture_result": $N1_OUT,
  "escalation_fixture_result": $N2_OUT,
  "valid_fixture_result": $P1_OUT
}
EOF

echo "TSK-P1-230 Verification complete."
