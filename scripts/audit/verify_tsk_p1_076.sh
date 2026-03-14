#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_076_local_gate_topology.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()
HOOKS_DIR="$(git -C "$ROOT" rev-parse --git-path hooks)"

for target in \
  "$ROOT/.githooks/pre-commit" \
  "$ROOT/.githooks/pre-push" \
  "$ROOT/scripts/dev/install_git_hooks.sh" \
  "$ROOT/scripts/dev/pre_flight.sh" \
  "$ROOT/scripts/dev/pre_ci.sh" \
  "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md" \
  "$ROOT/docs/operations/DEV_WORKFLOW.md"; do
  [[ -f "$target" ]] || failures+=("missing_target:$target")
done

bash "$ROOT/scripts/dev/install_git_hooks.sh" >/dev/null || failures+=("install_git_hooks_failed")

[[ -d "$HOOKS_DIR" ]] || failures+=("resolved_hooks_dir_missing:$HOOKS_DIR")
cmp -s "$ROOT/.githooks/pre-commit" "$HOOKS_DIR/pre-commit" || failures+=("installed_pre_commit_drift")
cmp -s "$ROOT/.githooks/pre-push" "$HOOKS_DIR/pre-push" || failures+=("installed_pre_push_drift")
rg -q 'scripts/dev/pre_flight.sh' "$HOOKS_DIR/pre-commit" || failures+=("installed_pre_commit_missing_pre_flight")
rg -q 'scripts/dev/pre_ci.sh' "$HOOKS_DIR/pre-push" || failures+=("installed_pre_push_missing_pre_ci")
rg -q 'Local hook model' "$ROOT/docs/operations/DEV_WORKFLOW.md" || failures+=("dev_workflow_missing_hook_section")
rg -q 'See `docs/operations/LOCAL_HOOK_TOPOLOGY.md`' "$ROOT/docs/operations/DEV_WORKFLOW.md" || failures+=("dev_workflow_missing_topology_link")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$HOOKS_DIR" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out, ts, sha, fp, hooks_dir = sys.argv[1:6]
failures = [x for x in sys.argv[6:] if x]
payload = {
  "check_id": "TSK-P1-076",
  "task_id": "TSK-P1-076",
  "timestamp_utc": ts,
  "git_sha": sha,
  "schema_fingerprint": fp,
  "resolved_hooks_dir": hooks_dir,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-076 verification passed. Evidence: {out}")
PY
