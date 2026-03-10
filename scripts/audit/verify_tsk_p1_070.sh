#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_070_remediation_casefile_scaffolder.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/repo"
cp -R "$ROOT/docs" "$tmpdir/repo/"
mkdir -p "$tmpdir/repo/scripts/audit"
cp "$ROOT/scripts/audit/new_remediation_casefile.sh" "$tmpdir/repo/scripts/audit/"

(
  cd "$tmpdir/repo"
  bash scripts/audit/new_remediation_casefile.sh \
    --phase phase1 \
    --slug debug-scaffold-test \
    --failure-signature PRECI.TEST.SCAFFOLD \
    --origin-gate-id pre_ci.test \
    --repro-command "scripts/dev/pre_ci.sh" >/tmp/tsk_p1_070_path.txt
)
case_dir="$(cat /tmp/tsk_p1_070_path.txt)"
plan="$tmpdir/repo/$case_dir/PLAN.md"
log="$tmpdir/repo/$case_dir/EXEC_LOG.md"

failures=()
[[ -f "$plan" ]] || failures+=("missing_plan")
[[ -f "$log" ]] || failures+=("missing_exec_log")
rg -q "failure_signature: PRECI.TEST.SCAFFOLD" "$plan" "$log" || failures+=("missing_failure_signature")
rg -q "repro_command: scripts/dev/pre_ci.sh" "$plan" "$log" || failures+=("missing_repro_command")
rg -q "verification_commands_run:" "$plan" "$log" || failures+=("missing_verification_commands_run")
rg -q "final_status:" "$plan" "$log" || failures+=("missing_final_status")
rg -q "origin_gate_id: pre_ci.test" "$plan" "$log" || failures+=("missing_origin_gate_id")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out = sys.argv[1]
timestamp_utc = sys.argv[2]
git_sha = sys.argv[3]
schema_fingerprint = sys.argv[4]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-070",
  "task_id": "TSK-P1-070",
  "timestamp_utc": timestamp_utc,
  "git_sha": git_sha,
  "schema_fingerprint": schema_fingerprint,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-070 verification passed. Evidence: {out}")
PY
