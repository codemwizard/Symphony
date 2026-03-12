#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_074_hook_source_normalization.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

failures=()

for target in \
  "$ROOT/.githooks/pre-commit" \
  "$ROOT/.githooks/pre-push" \
  "$ROOT/scripts/dev/install_git_hooks.sh" \
  "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md"; do
  [[ -f "$target" ]] || failures+=("missing_target:$target")
done

rg -q 'install_hook pre-commit' "$ROOT/scripts/dev/install_git_hooks.sh" || failures+=("installer_missing_pre_commit_copy")
rg -q 'install_hook pre-push' "$ROOT/scripts/dev/install_git_hooks.sh" || failures+=("installer_missing_pre_push_copy")
if rg -q "cat > \\.git/hooks/" "$ROOT/scripts/dev/install_git_hooks.sh"; then
  failures+=("installer_still_writes_inline_hooks")
fi
rg -q '\.githooks/' "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md" || failures+=("docs_missing_tracked_source")
rg -q '\.git/hooks/' "$ROOT/docs/operations/LOCAL_HOOK_TOPOLOGY.md" || failures+=("docs_missing_installed_destination")

python3 - <<'PY' "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" "$(printf '%s\n' "${failures[@]}")"
import json, sys
out, ts, sha, fp = sys.argv[1:5]
failures = [x for x in sys.argv[5:] if x]
payload = {
  "check_id": "TSK-P1-074",
  "task_id": "TSK-P1-074",
  "timestamp_utc": ts,
  "git_sha": sha,
  "schema_fingerprint": fp,
  "status": "PASS" if not failures else "FAIL",
  "failures": failures,
}
open(out, "w", encoding="utf-8").write(json.dumps(payload, indent=2) + "\n")
if failures:
    raise SystemExit(1)
print(f"TSK-P1-074 verification passed. Evidence: {out}")
PY
