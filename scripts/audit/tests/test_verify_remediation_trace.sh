#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_REPO="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO"' EXIT

cp -a "$ROOT/." "$TMP_REPO/"

run_once() {
  local out_path="$1"
  (
    cd "$TMP_REPO"
    PRE_CI_CONTEXT=1 \
    SYMPHONY_ENV=development \
    SYMPHONY_EVIDENCE_DETERMINISTIC=1 \
    bash scripts/audit/verify_remediation_trace.sh >/dev/null
    cp evidence/phase0/remediation_trace.json "$out_path"
  )
}

FIRST_OUT="$(mktemp)"
SECOND_OUT="$(mktemp)"
trap 'rm -f "$FIRST_OUT" "$SECOND_OUT"; rm -rf "$TMP_REPO"' EXIT

run_once "$FIRST_OUT"
run_once "$SECOND_OUT"

cmp -s "$FIRST_OUT" "$SECOND_OUT"

python3 - <<'PY' "$FIRST_OUT"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
if payload.get("status") != "PASS":
    raise SystemExit("status mismatch")
if "changed_file_count" in payload or "trace_docs" in payload or "triggered_file_count" in payload:
    raise SystemExit("unstable diff inventory field still present")
if "satisfying_docs" not in payload:
    raise SystemExit("satisfying_docs missing")
print("ok")
PY

echo "test_verify_remediation_trace.sh passed"
