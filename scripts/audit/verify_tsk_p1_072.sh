#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_072_two_strike_escalation.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

failures=()
output="$(
  ROOT="$ROOT" PRE_CI_DEBUG_DIR="$tmpdir" PRE_CI_FAILURE_STATE_FILE="$tmpdir/state.env" bash -lc '
    source "$ROOT/scripts/audit/pre_ci_debug_contract.sh"
    pre_ci_debug_init
    pre_ci_set_context "bootstrap/toolchain" "PRECI.TEST.REPEAT" "pre_ci.bootstrap" "Bootstrap parity"
    pre_ci_record_failure
    pre_ci_record_failure
  ' 2>&1
)"
printf '%s\n' "$output" | rg -q 'TWO_STRIKE_NONCONVERGENCE=1' || failures+=("missing_two_strike_signal")
printf '%s\n' "$output" | rg -q 'ESCALATION=DRD_FULL_REQUIRED' || failures+=("missing_escalation_signal")
printf '%s\n' "$output" | rg -q 'Suggested scaffolder:' || failures+=("missing_scaffolder_hint")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out = sys.argv[1]
timestamp_utc = sys.argv[2]
git_sha = sys.argv[3]
schema_fingerprint = sys.argv[4]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-072",
  "task_id": "TSK-P1-072",
  "timestamp_utc": timestamp_utc,
  "git_sha": git_sha,
  "schema_fingerprint": schema_fingerprint,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-072 verification passed. Evidence: {out}")
PY
