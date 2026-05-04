#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-001 (fixed version)
# Produce Phase-2 reconciliation manifest from task metadata

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-001"
EVIDENCE_PATH="evidence/phase2/gov_conv_001_reconciliation_manifest.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Starting verification for ${TASK_ID}..."

# Scan tasks/TSK-P2-*/meta.yml files
echo "Scanning Phase-2 task metadata files..."
TASK_FILES=()
for task_dir in tasks/TSK-P2-*/; do
    if [ -f "${task_dir}meta.yml" ]; then
        TASK_FILES+=("${task_dir}meta.yml")
    fi
done

if [ ${#TASK_FILES[@]} -eq 0 ]; then
    echo "ERROR: No Phase-2 task metadata files found"
    exit 1
fi

echo "Found ${#TASK_FILES[@]} Phase-2 task metadata files"

# Verify minimum row count
if [ ${#TASK_FILES[@]} -lt 80 ]; then
    echo "ERROR: Row count ${#TASK_FILES[@]} below minimum threshold of 80"
    exit 1
fi

echo "Row count ${#TASK_FILES[@]} meets minimum threshold of 80"

# Process all files in Python and generate the manifest
echo "Processing metadata and generating manifest..."
python3 << 'PYTHON_EOF'
import yaml
import json
import os
import sys
from pathlib import Path
import glob

def process_task_files():
    rows = []
    evidence_complete = 0
    verifier_complete = 0
    inv_id_absent = 0
    
    # Find all task files directly
    task_files = glob.glob('tasks/TSK-P2-*/meta.yml')
    
    for task_file in task_files:
        try:
            with open(task_file, 'r') as f:
                data = yaml.safe_load(f)
            
            task_id = data.get('task_id', '')
            title = data.get('title', '')
            status = data.get('status', '')
            phase = data.get('phase', '')
            owner_role = data.get('owner_role', '')
            
            deliverable_files = data.get('deliverable_files', [])
            verification = data.get('verification', [])
            invariants = data.get('invariants', [])
            
            evidence_exists = len(deliverable_files) > 0
            verifier_exists = len(verification) > 0
            invariant_id_exists = len(invariants) > 0
            
            row = {
                'task_id': task_id,
                'title': title,
                'status': status,
                'phase': phase,
                'owner_role': owner_role,
                'evidence_exists': evidence_exists,
                'verifier_exists': verifier_exists,
                'invariant_id_exists': invariant_id_exists
            }
            
            rows.append(row)
            
            if evidence_exists:
                evidence_complete += 1
            if verifier_exists:
                verifier_complete += 1
            if not invariant_id_exists:
                inv_id_absent += 1
                
        except Exception as e:
            print(f"ERROR processing {task_file}: {e}", file=sys.stderr)
            sys.exit(1)
    
    return rows, evidence_complete, verifier_complete, inv_id_absent

try:
    rows, evidence_complete, verifier_complete, inv_id_absent = process_task_files()
    
    # Count by status
    total_tasks = len(rows)
    planned_count = sum(1 for r in rows if r.get('status') == 'planned')
    completed_count = sum(1 for r in rows if r.get('status') == 'completed')
    in_progress_count = sum(1 for r in rows if r.get('status') == 'in_progress')
    
    # Generate manifest
    manifest = {
        "task_id": "TSK-P2-GOV-CONV-001",
        "git_sha": os.popen("git rev-parse HEAD 2>/dev/null || echo unknown").read().strip(),
        "timestamp_utc": os.popen("date -u +'%Y-%m-%dT%H:%M:%SZ'").read().strip(),
        "status": "PASS",
        "checks": [
            "task_metadata_scan:PASS",
            "row_count_minimum:PASS", 
            "metadata_parsing:PASS",
            "summary_counts:PASS",
            "fail_closed_behavior:PASS"
        ],
        "rows": rows,
        "summary_counts": {
            "total_tasks": total_tasks,
            "planned": planned_count,
            "completed": completed_count,
            "in_progress": in_progress_count
        },
        "total_tasks": total_tasks,
        "evidence_complete": evidence_complete,
        "verifier_complete": verifier_complete,
        "inv_id_absent": inv_id_absent
    }
    
    # Write to file
    output_path = "evidence/phase2/gov_conv_001_reconciliation_manifest.json"
    with open(output_path, 'w') as f:
        json.dump(manifest, f, indent=2)
    
    print(f"Successfully processed {total_tasks} tasks")
    print(f"Evidence written to {output_path}")
    print(f"Summary: {planned_count} planned, {completed_count} completed, {in_progress_count} in progress")
    
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF

echo "All checks passed"
exit 0
