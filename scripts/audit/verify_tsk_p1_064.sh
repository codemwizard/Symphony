#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_064_git_regression_wiring.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()
rg -q "test_diff_semantics_parity_hostile_env.sh" "$ROOT/scripts/audit/run_phase0_ordered_checks.sh" || failures+=("run_phase0_missing_hostile_env_test")
rg -q "run_phase0_ordered_checks.sh" "$ROOT/scripts/dev/pre_ci.sh" || failures+=("pre_ci_missing_phase0_ordered_checks")
rg -q "run_phase0_ordered_checks.sh" "$ROOT/.github/workflows/invariants.yml" || failures+=("workflow_missing_phase0_ordered_checks")
if ! bash "$ROOT/scripts/audit/test_diff_semantics_parity_hostile_env.sh" >/dev/null; then
  failures+=("hostile_env_regression_failed")
fi

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s
' "${failures[@]}")"
import json, sys
out, ts, sha, fp = sys.argv[1:5]
failures = [x for x in sys.argv[5:] if x]
payload = {
  'check_id': 'TSK-P1-064',
  'task_id': 'TSK-P1-064',
  'timestamp_utc': ts,
  'git_sha': sha,
  'schema_fingerprint': fp,
  'status': 'PASS' if not failures else 'FAIL',
  'failures': failures,
}
open(out, 'w', encoding='utf-8').write(json.dumps(payload, indent=2) + '\n')
if failures:
    raise SystemExit(1)
print(f"TSK-P1-064 verification passed. Evidence: {out}")
PY
