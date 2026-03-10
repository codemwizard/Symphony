#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_062_worktree_cleanup_and_guards.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

python3 - <<'PY' "$ROOT" "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP"
import json, subprocess, sys
from pathlib import Path
root = Path(sys.argv[1])
out = Path(sys.argv[2])
ts, sha, fp = sys.argv[3:6]
text = subprocess.check_output(["git", "worktree", "list", "--porcelain"], cwd=root, text=True)
entries = []
cur = {}
for line in text.splitlines():
    if not line.strip():
        if cur:
            entries.append(cur)
            cur = {}
        continue
    key, _, value = line.partition(" ")
    if key == "worktree":
        cur[key] = value
    else:
        cur.setdefault(key, []).append(value)
if cur:
    entries.append(cur)
failures = []
for e in entries:
    if 'prunable' in e:
        failures.append(f"prunable_worktree:{e.get('worktree')}")
    wp = e.get('worktree', '')
    if wp.startswith('/tmp/') and ('Symphony' in wp or 'symphony-' in wp):
        failures.append(f"unexpected_temp_worktree:{wp}")
    if wp and not Path(wp).exists():
        failures.append(f"missing_worktree_path:{wp}")
payload = {
  'check_id': 'TSK-P1-062',
  'task_id': 'TSK-P1-062',
  'timestamp_utc': ts,
  'git_sha': sha,
  'schema_fingerprint': fp,
  'status': 'PASS' if not failures else 'FAIL',
  'worktree_count': len(entries),
  'worktrees': [{'worktree': e.get('worktree'), 'branch': (e.get('branch') or [None])[0], 'detached': 'detached' in e, 'prunable': 'prunable' in e} for e in entries],
  'failures': failures,
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
if failures:
    raise SystemExit(1)
print(f"TSK-P1-062 verification passed. Evidence: {out}")
PY
