#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-008: Maintain Phase 3 implementation-plan registry

set -euo pipefail

export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export EVIDENCE_DIR="$ROOT/evidence/phase3"
export EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_008.json"
export TASK_ID="TSK-P3-CLEAN-008"
export GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
export TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Run Python validation script
python3 - << 'EOF'
import os
import sys
import json
import hashlib

ROOT = os.environ.get('ROOT')
SUMMARY_PATH = os.path.join(ROOT, 'SYMPHONY_TASKS_CREATION_SUMMARY.md')
EVIDENCE_PATH = os.environ.get('EVIDENCE_PATH')

checks = []
status = "PASS"

def add_check(name, result, detail=""):
    global status
    checks.append({"name": name, "result": result, "detail": detail})
    if result == "FAIL":
        status = "FAIL"

try:
    with open(SUMMARY_PATH, 'r') as f:
        content = f.read()
    
    missing_tasks = []
    for i in range(1, 9):
        task_id = f"TSK-P3-CLEAN-00{i}"
        if task_id not in content:
            missing_tasks.append(task_id)
            
    if missing_tasks:
        add_check("registry_contains_all_tasks", "FAIL", f"Missing tasks in summary: {missing_tasks}")
    else:
        add_check("registry_contains_all_tasks", "PASS", "All 8 governance cleanup nodes are indexed in the summary registry")

    paths = ["SYMPHONY_TASKS_CREATION_SUMMARY.md"]
    hashes = {}
    for p in paths:
        fp = os.path.join(ROOT, p)
        if os.path.exists(fp):
            with open(fp, 'rb') as f:
                hashes[p] = hashlib.sha256(f.read()).hexdigest()

    evidence = {
        'task_id': os.environ.get('TASK_ID'),
        'git_sha': os.environ.get('GIT_SHA'),
        'timestamp_utc': os.environ.get('TIMESTAMP'),
        'status': status,
        'checks': checks,
        'observed_paths': paths,
        'observed_hashes': hashes
    }
    
    os.makedirs(os.path.dirname(EVIDENCE_PATH), exist_ok=True)
    with open(EVIDENCE_PATH, 'w') as f:
        json.dump(evidence, f, indent=2)

    print(status)
    if status == "FAIL":
        sys.exit(1)

except Exception as e:
    import traceback
    traceback.print_exc()
    print(f"FAIL: {str(e)}")
    sys.exit(1)

EOF
