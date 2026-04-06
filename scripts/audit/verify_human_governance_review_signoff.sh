#!/usr/bin/env bash
set -euo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$([ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" = "1" ] && echo "1970-01-01T00:00:00Z" || date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase1"
EVIDENCE_FILE="${EVIDENCE_FILE:-$EVIDENCE_DIR/human_governance_review_signoff.json}"
BRANCH_NAME="${BRANCH_NAME:-${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git -C "$ROOT_DIR" branch --show-current)}}}"
mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
EVIDENCE_RUN_ID="${SYMPHONY_RUN_ID:-standalone-${EVIDENCE_TS}}"
export ROOT_DIR EVIDENCE_FILE BRANCH_NAME
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP EVIDENCE_RUN_ID

python3 <<'PY'
import json
import os
import re
from pathlib import Path

root = Path(os.environ['ROOT_DIR'])
out = Path(os.environ['EVIDENCE_FILE'])
branch = os.environ['BRANCH_NAME'].strip()
errors = []

metadata_path = root / 'evidence/phase1/approval_metadata.json'
metadata = None
if metadata_path.exists():
    metadata = json.loads(metadata_path.read_text(encoding='utf-8'))

metadata_approval_ref = ''
metadata_branch = ''
metadata_review_scope = []
if metadata:
    metadata_approval_ref = str(metadata.get('human_approval', {}).get('approval_artifact_ref', ''))
    metadata_review_scope = metadata.get('change_scope', {}).get('paths_changed', []) or []
    m = re.search(r'BRANCH-(.+)\.md$', metadata_approval_ref)
    if m:
        metadata_branch = m.group(1).replace('-', '/')

if (not branch or branch == 'HEAD') and metadata_branch:
    branch = metadata_branch

if not branch:
    errors.append('missing_branch_name')

branch_key = branch.replace('/', '-')
md_matches = sorted((root / 'approvals').glob(f'*/BRANCH-{branch_key}.md'))
json_matches = sorted((root / 'approvals').glob(f'*/BRANCH-{branch_key}.approval.json'))

# In CI and post-merge contexts the current branch/ref may not match the approval
# branch. Fall back to the approval metadata artifact, which is the canonical
# machine-readable link between the branch review and the merged state.
if (not md_matches or not json_matches) and metadata_approval_ref:
    fallback_md = root / metadata_approval_ref
    if fallback_md.exists():
        md_matches = [fallback_md]
        fallback_json = fallback_md.with_suffix('.approval.json')
        if fallback_json.exists():
            json_matches = [fallback_json]

if not md_matches:
    errors.append(f'missing_branch_approval_markdown:{branch}')
if not json_matches:
    errors.append(f'missing_branch_approval_sidecar:{branch}')

approval_md = md_matches[-1] if md_matches else None
approval_json = json_matches[-1] if json_matches else None
sidecar = None
if approval_json and approval_json.exists():
    sidecar = json.loads(approval_json.read_text(encoding='utf-8'))
    if sidecar.get('approval', {}).get('status') != 'APPROVED':
        errors.append('approval_status_not_approved')
    if sidecar.get('approval', {}).get('approver_id', '').strip() == '':
        errors.append('missing_approver_id')
    if sidecar.get('verification', {}).get('pre_ci_passed') is not True:
        errors.append('pre_ci_not_recorded_true')

approval_md_text = approval_md.read_text(encoding='utf-8') if approval_md and approval_md.exists() else ''
if approval_md_text and '## 8. Cross-References (Machine-Readable)' not in approval_md_text:
    errors.append('missing_machine_readable_cross_reference_header')

if not metadata_path.exists():
    errors.append('missing_approval_metadata')
else:
    metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
    human = metadata.get('human_approval', {})
    if human.get('approval_artifact_ref') != str(approval_md.relative_to(root)) if approval_md else None:
        errors.append('approval_metadata_ref_mismatch')
    if sidecar and human.get('approver_id') != sidecar.get('approval', {}).get('approver_id'):
        errors.append('approval_metadata_approver_mismatch')

changed = []
import subprocess
try:
    base = subprocess.check_output(['git','-C',str(root),'merge-base','HEAD','origin/main'], text=True).strip()
    changed = [p for p in subprocess.check_output(['git','-C',str(root),'diff','--name-only',f'{base}...HEAD'], text=True).splitlines() if p]
except Exception as exc:
    errors.append(f'changed_files_probe_failed:{exc}')

reviewed_files = sidecar.get('scope', {}).get('paths_changed', []) if sidecar else []
# If the current branch diff does not match the approval branch (for example on
# merged main or unrelated CI refs), validate against the metadata-declared scope.
coverage_source = changed
if metadata_review_scope:
    current_branch_key = branch.replace('/', '-')
    metadata_branch_key = metadata_branch.replace('/', '-') if metadata_branch else ''
    if current_branch_key != metadata_branch_key or not changed:
        coverage_source = metadata_review_scope

missing_review_coverage = sorted(set(coverage_source) - set(reviewed_files)) if coverage_source else []
if missing_review_coverage:
    errors.append('review_scope_missing_changed_files:' + ','.join(missing_review_coverage[:20]))

payload = {
    'check_id': 'TASK-OI-10',
    'run_id': os.environ['EVIDENCE_RUN_ID'],
    'timestamp_utc': os.environ['EVIDENCE_TS'],
    'git_sha': os.environ['EVIDENCE_GIT_SHA'],
    'schema_fingerprint': os.environ['EVIDENCE_SCHEMA_FP'],
    'status': 'PASS' if not errors else 'FAIL',
    'reviewer_id': sidecar.get('approval', {}).get('approver_id') if sidecar else None,
    'signed_at_utc': sidecar.get('approval', {}).get('approved_at_utc') if sidecar else None,
    'change_ref': f'branch/{branch}' if branch else None,
    'review_artifact_ref': str(approval_md.relative_to(root)) if approval_md else None,
    'review_sidecar_ref': str(approval_json.relative_to(root)) if approval_json else None,
    'reviewed_files': reviewed_files,
    'changed_files': changed,
    'coverage_source_files': coverage_source,
    'errors': errors,
}
out.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
if errors:
    raise SystemExit(1)
print(f"Human governance review signoff verification passed. Evidence: {out}")
PY
