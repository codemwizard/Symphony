#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-227 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Create a fixture task missing the new fields (N1)
mkdir -p "$TMP_DIR/tasks/FIXTURE-MISSING-BASICS"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-MISSING-BASICS/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-MISSING-BASICS
title: "Missing fields"
owner_role: SUPERVISOR
status: planned
depends_on: []
touches: []
invariants: []
work: []
acceptance_criteria: []
verification: []
evidence: []
failure_modes: []
must_read: []
anti_patterns: []
EOF

# Create a fixture task with the new fields (P1)
mkdir -p "$TMP_DIR/tasks/FIXTURE-WITH-BASICS"
cat << 'EOF' > "$TMP_DIR/tasks/FIXTURE-WITH-BASICS/meta.yml"
schema_version: 1
phase: '1'
task_id: FIXTURE-WITH-BASICS
title: "Has fields"
owner_role: SUPERVISOR
status: planned
depends_on: []
touches: []
invariants: []
work: []
acceptance_criteria: []
verification: []
evidence: []
failure_modes: []
must_read: []
anti_patterns: []
out_of_scope: ["none"]
stop_conditions: ["none"]
proof_guarantees: ["none"]
proof_limitations: ["none"]
EOF

# Create a python script to validate these boundary constraints
cat << 'PY' > "$TMP_DIR/validate_boundaries.py"
import sys, yaml
from pathlib import Path

def validate(path):
    data = yaml.safe_load(Path(path).read_text())
    required_boundaries = ["out_of_scope", "stop_conditions", "proof_guarantees", "proof_limitations"]
    missing = [k for k in required_boundaries if k not in data]
    if missing:
        print(f"FAILED: Missing boundary fields: {missing}")
        return False
    print("PASS: All boundary fields present")
    return True

if __name__ == "__main__":
    if not validate(sys.argv[1]):
        sys.exit(1)
PY

echo "[Test N1] Running against fixture missing anti-drift sections"
set +e
python3 "$TMP_DIR/validate_boundaries.py" "$TMP_DIR/tasks/FIXTURE-MISSING-BASICS/meta.yml"
N1_STATUS=$?
set -e
if [ $N1_STATUS -eq 0 ]; then
    echo "ERROR: Fixture missing boundaries was permitted!"
    exit 1
else
    echo "Negative test passed: Fixture safely rejected."
fi

echo "[Test P1] Running against fixture containing anti-drift sections"
if python3 "$TMP_DIR/validate_boundaries.py" "$TMP_DIR/tasks/FIXTURE-WITH-BASICS/meta.yml"; then
    echo "Positive test passed: Valid fixture accepted."
else
    echo "ERROR: Valid fixture rejected!"
    exit 1
fi

echo "[Test P2] Checking canonical template"
if python3 "$TMP_DIR/validate_boundaries.py" "tasks/_template/meta.yml"; then
    echo "Canonical template OK."
else
    echo "ERROR: tasks/_template/meta.yml missing boundary fields!"
    exit 1
fi

git_sha=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD || echo "UNKNOWN")
timestamp=$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)

cat << EOF > evidence/phase1/tsk_p1_227_template_hardening.json
{
  "task_id": "TSK-P1-227",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": ["N1", "P1", "P2"],
  "required_boundary_fields": ["out_of_scope", "stop_conditions", "proof_guarantees", "proof_limitations"],
  "rejected_fixture_id": "FIXTURE-MISSING-BASICS",
  "strict_validation_commands": ["python3 validate_boundaries.py meta.yml"]
}
EOF

echo "TSK-P1-227 Verification complete."
