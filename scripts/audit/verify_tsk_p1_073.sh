#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_073_task_surface.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()
for target in \
  "$ROOT/scripts/audit/verify_remediation_artifact_freshness.sh" \
  "$ROOT/scripts/dev/pre_ci.sh" \
  "$ROOT/scripts/audit/run_invariants_fast_checks.sh" \
  "$ROOT/docs/process/debug-remediation-policy.md" \
  "$ROOT/docs/operations/REMEDIATION_TRACE_WORKFLOW.md"; do
  [[ -f "$target" ]] || failures+=("missing_target:$target")
done
rg -q "verify_remediation_artifact_freshness.sh" "$ROOT/scripts/dev/pre_ci.sh" || failures+=("pre_ci_missing_freshness_gate")
rg -q "verify_tsk_p1_073.sh" "$ROOT/scripts/audit/run_invariants_fast_checks.sh" || failures+=("fast_checks_missing_freshness_gate")
rg -q "freshness|CI-discovered|casefile" "$ROOT/docs/process/debug-remediation-policy.md" "$ROOT/docs/operations/REMEDIATION_TRACE_WORKFLOW.md" || failures+=("docs_missing_freshness_language")
BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD bash "$ROOT/scripts/audit/verify_remediation_artifact_freshness.sh" >/dev/null || failures+=("freshness_verifier_failed")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s
' "${failures[@]}")"
import json, sys
out, ts, sha, fp = sys.argv[1:5]
failures = [x for x in sys.argv[5:] if x]
payload = {
  'check_id': 'TSK-P1-073-TASK',
  'task_id': 'TSK-P1-073',
  'timestamp_utc': ts,
  'git_sha': sha,
  'schema_fingerprint': fp,
  'status': 'PASS' if not failures else 'FAIL',
  'failures': failures,
}
open(out, 'w', encoding='utf-8').write(json.dumps(payload, indent=2) + '\n')
if failures:
    raise SystemExit(1)
print(f"TSK-P1-073 verification passed. Evidence: {out}")
PY
