#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/evidence/phase1/tsk_p1_063_git_script_audit.json"
AUDIT_DOC="$ROOT/docs/audits/GIT_MUTATION_SURFACE_AUDIT_2026-03-10.md"
mkdir -p "$(dirname "$OUT")"
source "$ROOT/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

python3 - <<'PY' "$ROOT" "$AUDIT_DOC" "$OUT" "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP"
import json, re, sys
from pathlib import Path
root = Path(sys.argv[1])
audit_doc = Path(sys.argv[2])
out = Path(sys.argv[3])
ts, sha, fp = sys.argv[4:7]
text = audit_doc.read_text(encoding='utf-8') if audit_doc.exists() else ''
failures = []
if not audit_doc.exists():
    failures.append('missing_audit_doc')
paths_in_doc = set(re.findall(r'`([^`]+)`', text))
script_pattern = re.compile(r'\bgit\b.*\b(commit|checkout|branch|switch|update-ref|worktree|fetch|clone|tag|merge|rebase|reset|stash|prune)', re.S)
found = []
for base in [root / 'scripts', root / '.githooks']:
    if not base.exists():
        continue
    for p in base.rglob('*'):
        if not p.is_file() or p.suffix == '.pyc':
            continue
        rel = p.relative_to(root).as_posix()
        txt = p.read_text(encoding='utf-8', errors='ignore')
        if script_pattern.search(txt):
            found.append(rel)
missing = [p for p in sorted(found) if p not in paths_in_doc]
if missing:
    failures.extend([f'missing_from_audit:{p}' for p in missing])
payload = {
  'check_id': 'TSK-P1-063',
  'task_id': 'TSK-P1-063',
  'timestamp_utc': ts,
  'git_sha': sha,
  'schema_fingerprint': fp,
  'status': 'PASS' if not failures else 'FAIL',
  'audited_paths': sorted(found),
  'missing_from_audit': missing,
  'failures': failures,
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
if failures:
    raise SystemExit(1)
print(f"TSK-P1-063 verification passed. Evidence: {out}")
PY
