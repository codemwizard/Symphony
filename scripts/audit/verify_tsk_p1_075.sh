#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_075_preflight_preci_split.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()

for target in \
  "$ROOT/.githooks/pre-commit" \
  "$ROOT/.githooks/pre-push" \
  "$ROOT/scripts/dev/pre_flight.sh" \
  "$ROOT/scripts/dev/pre_ci.sh" \
  "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md"; do
  [[ -f "$target" ]] || failures+=("missing_target:$target")
done

rg -q 'scripts/dev/pre_flight.sh' "$ROOT/.githooks/pre-commit" || failures+=("pre_commit_missing_pre_flight")
rg -q 'scripts/dev/pre_ci.sh' "$ROOT/.githooks/pre-push" || failures+=("pre_push_missing_pre_ci")
rg -q 'preflight_structural_staged.sh' "$ROOT/scripts/dev/pre_flight.sh" || failures+=("pre_flight_missing_structural_preflight")
if rg -q '(^|[[:space:]])(bash[[:space:]]+)?scripts/dev/pre_ci\\.sh([[:space:]]|$)' "$ROOT/scripts/dev/pre_flight.sh"; then
  failures+=("pre_flight_calls_pre_ci")
fi
rg -q 'Light commit-path pre-flight' "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md" || failures+=("docs_missing_light_gate")
rg -q 'Heavy push-time pre-CI' "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md" || failures+=("docs_missing_heavy_gate")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out, ts, sha, fp = sys.argv[1:5]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-075",
  "task_id": "TSK-P1-075",
  "timestamp_utc": ts,
  "git_sha": sha,
  "schema_fingerprint": fp,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-075 verification passed. Evidence: {out}")
PY
