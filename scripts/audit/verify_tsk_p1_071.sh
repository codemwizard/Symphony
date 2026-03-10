#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_071_failure_layer_taxonomy.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()
for token in "branch-content" "source-control parity" "bootstrap/toolchain" "shared governance state" "DB/environment"; do
  rg -q "$token" "$ROOT/scripts/dev/pre_ci.sh" "$ROOT/scripts/audit/pre_ci_debug_contract.sh" || failures+=("missing_taxonomy:$token")
done

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out = sys.argv[1]
timestamp_utc = sys.argv[2]
git_sha = sys.argv[3]
schema_fingerprint = sys.argv[4]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-071",
  "task_id": "TSK-P1-071",
  "timestamp_utc": timestamp_utc,
  "git_sha": git_sha,
  "schema_fingerprint": schema_fingerprint,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-071 verification passed. Evidence: {out}")
PY
