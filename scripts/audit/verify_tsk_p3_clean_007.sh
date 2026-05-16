#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-007: Maintain Phase 3 DAG artifacts after cleanup

set -euo pipefail

export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export EVIDENCE_DIR="$ROOT/evidence/phase3"
export EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_007.json"
export TASK_ID="TSK-P3-CLEAN-007"
export GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
export TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Run Python validation script
python3 - << 'EOF'
import os
import sys
import yaml
import re
import json
import hashlib

ROOT = os.environ.get('ROOT')
HUMAN_DAG = os.path.join(ROOT, 'docs/PHASE3/PHASE3_TASK_DAG.md')
MACHINE_DAG = os.path.join(ROOT, 'docs/PHASE3/phase3_task_dag.yml')
EVIDENCE_PATH = os.environ.get('EVIDENCE_PATH')

checks = []
status = "PASS"

def add_check(name, result, detail=""):
    global status
    checks.append({"name": name, "result": result, "detail": detail})
    if result == "FAIL":
        status = "FAIL"

try:
    with open(MACHINE_DAG, 'r') as f:
        machine_data = yaml.safe_load(f)
    
    nodes = machine_data.get('nodes', [])
    
    overlap_found = False
    phantom_found = False
    
    node_ids = set(n['id'] for n in nodes)
    
    for node in nodes:
        deps = set(node.get('depends_on', []) or [])
        blocks = set(node.get('blocked_by', []) or [])
        
        # Check overlap
        intersection = deps.intersection(blocks)
        if intersection:
            overlap_found = True
            add_check("no_overlap_" + node['id'], "FAIL", f"Overlap in blocked_by and depends_on: {intersection}")
        
        # Check phantom dependencies
        for d in deps:
            if d not in node_ids:
                phantom_found = True
                add_check("phantom_dep_" + node['id'], "FAIL", f"Phantom dependency: {d}")
                
        for b in blocks:
            if b not in node_ids:
                phantom_found = True
                add_check("phantom_block_" + node['id'], "FAIL", f"Phantom blocked_by: {b}")

    if not overlap_found:
        add_check("no_blocked_by_depends_on_overlap", "PASS", "No overlap found between blocked_by and depends_on")
    if not phantom_found:
        add_check("no_phantom_dependencies", "PASS", "All dependencies exist in nodes list")

    # Check that human DAG and machine DAG match in node statuses
    with open(HUMAN_DAG, 'r') as f:
        human_content = f.read()

    # Parse human DAG table
    # Format: | TSK-P3-CLEAN-001 | P3-SURF-000 | None | None | complete | Fix... |
    human_statuses = {}
    for line in human_content.split('\n'):
        if line.startswith('| TSK-P3'):
            parts = [p.strip() for p in line.split('|')]
            if len(parts) == 8:
                # Wave 0 with Blocked By: empty | Node | Surface | Depends On | Blocked By | Status | Purpose | empty
                node_id = parts[1]
                node_status = parts[5]
                human_statuses[node_id] = node_status
            elif len(parts) == 7:
                # Wave 1 without Blocked By: empty | Node | Surface | Depends On | Status | Purpose | empty
                node_id = parts[1]
                node_status = parts[4]
                human_statuses[node_id] = node_status

    mismatch_found = False
    for node in nodes:
        nid = node['id']
        m_status = node.get('status', '')
        if nid in human_statuses:
            h_status = human_statuses[nid]
            if m_status != h_status:
                mismatch_found = True
                add_check("status_match_" + nid, "FAIL", f"Status mismatch: machine={m_status}, human={h_status}")

    if not mismatch_found:
        add_check("human_machine_status_match", "PASS", "Human and machine DAG statuses match")

    # Hashes
    paths = ["docs/PHASE3/PHASE3_TASK_DAG.md", "docs/PHASE3/phase3_task_dag.yml"]
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
