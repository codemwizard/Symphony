#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "=== TSK-P1-228 Verification ==="

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PROCESS_DOC="docs/operations/TASK_CREATION_PROCESS.md"

# N1 Fixture
cat << 'EOF' > "$TMP_DIR/fixture_missing.md"
## 8) Anti-Drift Authoring Policy
Some rules are here but no mention of one-primary-objective or placeholders.
EOF

# Validation script
cat << 'PY' > "$TMP_DIR/validate_rules.py"
import sys
from pathlib import Path

def validate(doc_path):
    text = Path(doc_path).read_text().lower()
    rules = [
        "one primary objective",
        "out_of_scope",
        "stop_conditions",
        "proof_guarantees",
        "proof_limitations",
        "placeholder verifier",
        "parity",
        "cheating modes"
    ]
    missing = [r for r in rules if r not in text]
    if missing:
        print(f"FAILED: Document missing required rules: {missing}")
        return False
    print("PASS: All anti-drift rules present.")
    return True

if __name__ == "__main__":
    if not validate(sys.argv[1]):
        sys.exit(1)
PY

echo "[Test N1] Running against fixture missing rules"
set +e
python3 "$TMP_DIR/validate_rules.py" "$TMP_DIR/fixture_missing.md"
N1_STATUS=$?
set -e
if [ $N1_STATUS -eq 0 ]; then
    echo "ERROR: Fixture missing process rules was accepted!"
    exit 1
else
    echo "Negative test passed: Incomplete document safely rejected."
fi

echo "[Test P1] Running against canonical TASK_CREATION_PROCESS.md"
if python3 "$TMP_DIR/validate_rules.py" "$PROCESS_DOC"; then
    echo "Positive test passed: Canonical document holds all required rules."
else
    echo "ERROR: Canonical process document lacks required anti-drift rules!"
    exit 1
fi

git_sha=$(git rev-parse HEAD || echo "UNKNOWN")
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat << EOF > evidence/phase1/tsk_p1_228_process_hardening.json
{
  "task_id": "TSK-P1-228",
  "git_sha": "$git_sha",
  "timestamp_utc": "$timestamp",
  "status": "PASS",
  "checks": ["N1", "P1"],
  "required_process_rules": [
    "One Primary Objective",
    "Explicit Boundaries",
    "Honest Proof",
    "No Placeholder Verifiers",
    "Document Parity",
    "Anti-Drift Cheating Limits"
  ],
  "rejected_gap_case": "fixture_missing.md",
  "document_path": "docs/operations/TASK_CREATION_PROCESS.md"
}
EOF

echo "TSK-P1-228 Verification complete."
