#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT_DIR/evidence/phase1/tsk_p1_073_remediation_artifact_freshness.json"
mkdir -p "$(dirname "$OUT")"
source "$ROOT_DIR/scripts/lib/evidence.sh"
source "$ROOT_DIR/scripts/audit/lib/git_diff_range_only.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

BASE_REF="${BASE_REF:-$(git_resolve_base_ref)}"
HEAD_REF="${HEAD_REF:-HEAD}"
if ! git_ensure_ref "$BASE_REF"; then
  echo "ERROR: base_ref_not_found:$BASE_REF"
  exit 1
fi

CHANGED_FILES_FILE="$(mktemp)"
trap 'rm -f "$CHANGED_FILES_FILE"' EXIT
git_changed_files_range "$BASE_REF" "$HEAD_REF" > "$CHANGED_FILES_FILE"

ROOT_DIR="$ROOT_DIR" OUT="$OUT" CHANGED_FILES_FILE="$CHANGED_FILES_FILE" BASE_REF="$BASE_REF" HEAD_REF="$HEAD_REF" python3 - <<'PY'
import json, os, re
from pathlib import Path
root = Path(os.environ['ROOT_DIR'])
out = Path(os.environ['OUT'])
changed = [ln.strip() for ln in Path(os.environ['CHANGED_FILES_FILE']).read_text(encoding='utf-8', errors='ignore').splitlines() if ln.strip()]

guarded_prefixes = (
    'scripts/dev/pre_ci.sh',
    'scripts/audit/',
    'scripts/security/',
    '.github/workflows/',
)
casefile_re = re.compile(r'^docs/plans/.+/(PLAN|EXEC_LOG)\.md$')
triggered = [p for p in changed if p.startswith(guarded_prefixes)]
# Ignore pure evidence churn.
triggered = [p for p in triggered if not p.startswith('evidence/')]
freshness_docs = [p for p in changed if casefile_re.match(p)]
failures = []
if triggered and not freshness_docs:
    failures.append('missing_remediation_or_task_casefile_update')
payload = {
  'check_id': 'TSK-P1-073',
  'task_id': 'TSK-P1-073',
  'timestamp_utc': os.environ.get('EVIDENCE_TS'),
  'git_sha': os.environ.get('EVIDENCE_GIT_SHA'),
  'schema_fingerprint': os.environ.get('EVIDENCE_SCHEMA_FP'),
  'status': 'PASS' if not failures else 'FAIL',
  'base_ref': os.environ.get('BASE_REF'),
  'head_ref': os.environ.get('HEAD_REF'),
  'triggered_files': triggered,
  'freshness_docs': freshness_docs,
  'failures': failures,
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
if failures:
    raise SystemExit(1)
print(f"Remediation artifact freshness verification passed. Evidence: {out}")
PY
