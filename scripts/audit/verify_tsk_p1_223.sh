#!/usr/bin/env bash
set -e

>&2 echo "=================================="
>&2 echo "TSK-P1-223: Task Metadata Loader Primitive"
>&2 echo "=================================="

TEST_DIR="/tmp/tsk_p1_223_tests"
mkdir -p "$TEST_DIR"
MALFORMED_FILE="$TEST_DIR/malformed_meta.yml"

# N1: Malformed Metadata
>&2 echo "[INFO] Running N1 (Malformed Metadata)..."
echo "unbalanced: 'quotes" > "$MALFORMED_FILE"
if python3 scripts/audit/task_meta_loader.py --meta "$MALFORMED_FILE" > /dev/null 2>&1; then
    >&2 echo "❌ FAIL: Loader accepted structurally invalid YAML."
    exit 1
fi
MISSING_FIELD_FILE="$TEST_DIR/missing_field.yml"
echo "schema_version: 1" > "$MISSING_FIELD_FILE"
if python3 scripts/audit/task_meta_loader.py --meta "$MISSING_FIELD_FILE" > /dev/null 2>&1; then
    >&2 echo "❌ FAIL: Loader accepted YAML missing required fields."
    exit 1
fi
>&2 echo "✅ N1 Passed (Malformed explicitly rejected)"

# P1: Deterministic Load
>&2 echo "[INFO] Running P1 (Deterministic Load)..."
OUT1="$TEST_DIR/out1.json"
OUT2="$TEST_DIR/out2.json"
python3 scripts/audit/task_meta_loader.py --meta tasks/TSK-RLS-ARCH-001/meta.yml > "$OUT1"
python3 scripts/audit/task_meta_loader.py --meta tasks/TSK-RLS-ARCH-001/meta.yml > "$OUT2"

if ! cmp -s "$OUT1" "$OUT2"; then
    >&2 echo "❌ FAIL: Loader output is not deterministic."
    exit 1
fi
>&2 echo "✅ P1 Passed (Deterministic output correctly verified)"

# Emit JSON evidence
HASH=$(shasum "$OUT1" | cut -d' ' -f1)

cat <<EOF
{
  "task_id": "TSK-P1-223",
  "git_sha": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "0000000000000000000000000000000000000000" || git rev-parse HEAD 2>/dev/null || echo 'LOCAL')",
  "timestamp_utc": "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "PASS",
  "checks": ["N1", "P1"],
  "observed_paths": ["scripts/audit/task_meta_loader.py", "tasks/TSK-P1-223/meta.yml"],
  "observed_hashes": ["$(shasum scripts/audit/task_meta_loader.py | cut -d' ' -f1)", "$(shasum tasks/TSK-P1-223/meta.yml | cut -d' ' -f1)"],
  "command_outputs": ["Loader parses completely deterministically and fails fast on errors."],
  "execution_trace": ["$TEST_DIR/*"],
  "loaded_task_id": "TSK-RLS-ARCH-001",
  "deterministic_output_hash": "$HASH",
  "malformed_case_result": "explicit_non_zero_exit"
}
EOF
exit 0
