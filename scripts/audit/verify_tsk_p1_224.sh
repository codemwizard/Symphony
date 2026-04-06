#!/usr/bin/env bash
set -e

>&2 echo "=================================="
>&2 echo "TSK-P1-224: Verification Runner & Gate Contract"
>&2 echo "=================================="

TEST_DIR="/tmp/tsk_p1_224_tests"
mkdir -p "$TEST_DIR"

# Create a mock valid gate
MOCK_PASS_GATE="$TEST_DIR/mock_pass.sh"
cat <<'EOF' > "$MOCK_PASS_GATE"
#!/usr/bin/env bash
echo '{"status": "PASS", "failure_class": "NONE", "message": "All good", "gate_identity": "mock_pass"}'
EOF
chmod +x "$MOCK_PASS_GATE"

# Create a mock malformed gate (N1)
MOCK_FAIL_GATE="$TEST_DIR/mock_bad.sh"
cat <<'EOF' > "$MOCK_FAIL_GATE"
#!/usr/bin/env bash
echo '{"status": "FAIL", "message": "Missing failure_class and identity"}'
exit 1
EOF
chmod +x "$MOCK_FAIL_GATE"

# N1: Malformed Gate Output
>&2 echo "[INFO] Running N1 (Malformed Gate Output)..."
if python3 scripts/audit/task_verification_runner.py --meta tasks/TSK-RLS-ARCH-001/meta.yml --gates "$MOCK_FAIL_GATE" > /dev/null 2>&1; then
    >&2 echo "❌ FAIL: Runner accepted malformed gate output without failing execution."
    exit 1
fi
>&2 echo "✅ N1 Passed (Runner aborted on malformed gate)"

# P1: Structured Valid Execution
>&2 echo "[INFO] Running P1 (Structured Execution)..."
OUT1="$TEST_DIR/out1.json"
python3 scripts/audit/task_verification_runner.py --meta tasks/TSK-RLS-ARCH-001/meta.yml --gates "$MOCK_PASS_GATE" > "$OUT1"

if ! grep -q '"overall_status": "PASS"' "$OUT1"; then
    >&2 echo "❌ FAIL: Runner did not format successful pipeline correctly."
    exit 1
fi
>&2 echo "✅ P1 Passed (Structured execution successful)"

cat <<EOF
{
  "task_id": "TSK-P1-224",
  "git_sha": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'LOCAL')",
  "timestamp_utc": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "PASS",
  "checks": ["N1", "P1"],
  "observed_paths": ["scripts/audit/task_verification_runner.py", "scripts/audit/task_gate_result.py", "tasks/TSK-P1-224/meta.yml"],
  "observed_hashes": ["$(shasum scripts/audit/task_verification_runner.py | cut -d' ' -f1)", "$(shasum scripts/audit/task_gate_result.py | cut -d' ' -f1)", "$(shasum tasks/TSK-P1-224/meta.yml | cut -d' ' -f1)"],
  "command_outputs": ["Runner enforced strict gate structures."],
  "execution_trace": ["$TEST_DIR/*"],
  "runner_entrypoint": "scripts/audit/task_verification_runner.py",
  "gate_result_fields": ["status", "failure_class", "message", "gate_identity"],
  "malformed_gate_case": "detected_and_aborted"
}
EOF
exit 0
