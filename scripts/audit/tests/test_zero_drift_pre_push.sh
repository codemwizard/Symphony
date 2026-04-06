#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/audit/verify_tsk_p1_255.sh"

grep -q "git -c core.hooksPath=/dev/null commit" "$SCRIPT"
grep -q "git diff --name-only --', '--', 'evidence" "$SCRIPT"
grep -q "git status --porcelain" "$SCRIPT"
! grep -qi "without-commit" "$SCRIPT"

bash "$SCRIPT"

python3 - <<'PY' "$ROOT/evidence/phase1/tsk_p1_255_pre_push_fixed_point.json"
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
if payload.get("status") != "PASS":
    raise SystemExit("status mismatch")
after = payload.get("after_commit", {})
if after.get("evidence_diff"):
    raise SystemExit("evidence diff not empty")
print("ok")
PY

echo "test_zero_drift_pre_push.sh passed"
