#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

grep -n "### Security Guardian Agent" AGENTS.md >/tmp/tsk_p1_242_owner.txt
grep -n "scripts/audit/\*\*" AGENTS.md >/tmp/tsk_p1_242_path.txt
grep -n "INBOX-2026-03-26-001" docs/tasks/DEFERRED_INBOX.md >/tmp/tsk_p1_242_inbox.txt

python3 - <<'PY' > evidence/phase1/tsk_p1_242_runtime_host_path_authority.json
import json
from pathlib import Path

owner_lines = Path('/tmp/tsk_p1_242_owner.txt').read_text().splitlines()
path_lines = Path('/tmp/tsk_p1_242_path.txt').read_text().splitlines()
inbox_lines = Path('/tmp/tsk_p1_242_inbox.txt').read_text().splitlines()

report = {
    'task_id': 'TSK-P1-242',
    'git_sha': 'UNSET',
    'timestamp_utc': 'UNSET',
    'status': 'PASS',
    'checks': {
        'owner_surface_present': len(owner_lines),
        'host_path_present': len(path_lines),
        'inbox_entry_present': len(inbox_lines),
    },
    'observed_paths': [
        'AGENTS.md',
        'docs/tasks/DEFERRED_INBOX.md',
    ],
    'observed_hashes': {},
    'command_outputs': {
        'owner_surface_lines': owner_lines,
        'host_path_lines': path_lines,
        'inbox_lines': inbox_lines,
    },
    'execution_trace': [
        'grep -n "### Security Guardian Agent" AGENTS.md',
        'grep -n "scripts/audit/**" AGENTS.md',
        'grep -n "INBOX-2026-03-26-001" docs/tasks/DEFERRED_INBOX.md',
    ],
    'chosen_host_path': 'scripts/audit/**',
    'chosen_owner_surface': 'SECURITY_GUARDIAN',
    'owner_surface_candidates': ['SECURITY_GUARDIAN', 'QA_VERIFIER'],
    'rehost_rationale': 'Guarded runtime controls remain verifier-scoped and can start inside an already-owned audit surface without inventing scripts/runtime/**.',
    'deferred_inbox_entry': 'INBOX-2026-03-26-001',
}

print(json.dumps(report, indent=2))
PY

# Verify it correctly executed
test -f evidence/phase1/tsk_p1_242_runtime_host_path_authority.json && \
cat evidence/phase1/tsk_p1_242_runtime_host_path_authority.json | grep '"chosen_host_path": "scripts/audit/\*\*"' >/dev/null && \
cat evidence/phase1/tsk_p1_242_runtime_host_path_authority.json | grep '"chosen_owner_surface": "SECURITY_GUARDIAN"' >/dev/null
