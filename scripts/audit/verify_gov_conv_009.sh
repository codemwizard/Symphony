#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-009
# Verify Phase-2 human and machine contract alignment

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-009"
EVIDENCE_PATH="evidence/phase2/gov_conv_009_human_machine_contract_alignment.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Starting verification for ${TASK_ID}..."

# Run all verification in a single Python script to avoid shell variable issues
python3 << 'PYTHON_EOF'
import yaml
import re
import json
import sys
import subprocess
import os

def run_verification():
    checks = []
    
    # Check 1: Verify prerequisite tasks are complete
    print("Check 1: Verify prerequisite tasks complete")
    prereq_tasks = ["TSK-P2-GOV-CONV-006", "TSK-P2-GOV-CONV-008"]
    all_prereqs_complete = True
    
    for prereq in prereq_tasks:
        meta_file = f"tasks/{prereq}/meta.yml"
        if not os.path.exists(meta_file):
            all_prereqs_complete = False
            print(f"✗ Prerequisite task {prereq} not found")
            break
        
        try:
            with open(meta_file, 'r') as f:
                content = f.read()
                for line in content.split('\n'):
                    if line.startswith('status:'):
                        status = line.split(':', 1)[1].strip()
                        if status != 'completed':
                            all_prereqs_complete = False
                            print(f"✗ Prerequisite task {prereq} not completed: {status}")
                            break
                if not all_prereqs_complete:
                    break
        except Exception as e:
            all_prereqs_complete = False
            print(f"✗ Error reading {meta_file}: {e}")
            break
    
    if all_prereqs_complete:
        checks.append("prerequisite_tasks_complete:PASS")
        print("✓ All prerequisite tasks are completed")
    else:
        checks.append("prerequisite_tasks_complete:FAIL")
        print("✗ Prerequisite tasks are not complete")
        return False, checks
    
    # Check 2: Verify contract files exist
    print("Check 2: Verify contract files exist")
    machine_file = "docs/PHASE2/phase2_contract.yml"
    human_file = "docs/PHASE2/PHASE2_CONTRACT.md"
    
    if os.path.exists(machine_file) and os.path.exists(human_file):
        checks.append("contract_files_exist:PASS")
        print("✓ Both contract files exist")
    else:
        checks.append("contract_files_exist:FAIL")
        print("✗ Contract files missing")
        return False, checks
    
    # Check 3: Extract machine contract invariant IDs
    print("Check 3: Extract machine contract invariant IDs")
    try:
        with open(machine_file, 'r') as f:
            contract = yaml.safe_load(f)
        
        machine_invariants = []
        if 'rows' in contract:
            for row in contract['rows']:
                invariant_id = row.get('invariant_id', '')
                if invariant_id and invariant_id.startswith('INV-'):
                    machine_invariants.append(invariant_id)
        
        machine_count = len(machine_invariants)
        checks.append("machine_invariants_extracted:PASS")
        print(f"✓ Extracted {machine_count} machine contract invariants")
    except Exception as e:
        checks.append("machine_invariants_extracted:FAIL")
        print(f"✗ Failed to extract machine contract invariants: {e}")
        return False, checks
    
    # Check 4: Extract human contract invariant references
    print("Check 4: Extract human contract invariant references")
    try:
        with open(human_file, 'r') as f:
            content = f.read()
        
        human_invariants = set(re.findall(r'INV-\d+', content))
        human_count = len(human_invariants)
        checks.append("human_invariants_extracted:PASS")
        print(f"✓ Extracted {human_count} human contract invariants")
    except Exception as e:
        checks.append("human_invariants_extracted:FAIL")
        print(f"✗ Failed to extract human contract invariants: {e}")
        return False, checks
    
    # Check 5: Verify no unsupported invariant claims
    print("Check 5: Verify no unsupported invariant claims")
    machine_set = set(machine_invariants)
    human_set = set(human_invariants)
    unsupported = human_set - machine_set
    unsupported_count = len(unsupported)
    
    if unsupported_count == 0:
        checks.append("no_unsupported_invariants:PASS")
        print("✓ No unsupported invariant claims")
    else:
        checks.append("no_unsupported_invariants:FAIL")
        print(f"✗ Found {unsupported_count} unsupported invariant claims")
        print(f"  Unsupported invariants: {sorted(list(unsupported))}")
        return False, checks
    
    # Check 6: Verify authority boundary present in human contract
    print("Check 6: Verify authority boundary present")
    try:
        with open(human_file, 'r') as f:
            content = f.read()
        
        if ("phase2_contract.yml" in content and "authoritative" in content) or \
           ("authoritative" in content and "phase2_contract.yml" in content):
            checks.append("authority_boundary_present:PASS")
            print("✓ Authority boundary declared")
        else:
            checks.append("authority_boundary_present:FAIL")
            print("✗ Authority boundary not declared")
            return False, checks
    except Exception as e:
        checks.append("authority_boundary_present:FAIL")
        print(f"✗ Error checking authority boundary: {e}")
        return False, checks
    
    # Check 7: Verify verifier reference present
    print("Check 7: Verify verifier reference present")
    if "verify_phase2_contract.sh" in content:
        checks.append("verifier_reference_present:PASS")
        print("✓ Verifier reference present")
    else:
        checks.append("verifier_reference_present:FAIL")
        print("✗ Verifier reference not present")
        return False, checks
    
    # Check 8: Verify evidence reference present
    print("Check 8: Verify evidence reference present")
    if "phase2_contract_status.json" in content:
        checks.append("evidence_reference_present:PASS")
        print("✓ Evidence reference present")
    else:
        checks.append("evidence_reference_present:FAIL")
        print("✗ Evidence reference not present")
        return False, checks
    
    return True, checks, {
        'machine_invariants': machine_invariants,
        'human_invariants': sorted(list(human_invariants)),
        'unsupported_invariants': sorted(list(unsupported)),
        'machine_count': machine_count,
        'human_count': human_count,
        'unsupported_count': unsupported_count
    }

def main():
    try:
        result = run_verification()
        if len(result) == 2:
            success, checks = result
            result_data = None
        else:
            success, checks, result_data = result
        
        # For success case without data, call again to get the data
        if success and result_data is None:
            success, checks, result_data = run_verification()
        
        # Generate evidence
        evidence = {
            "task_id": os.environ.get('TASK_ID', 'TSK-P2-GOV-CONV-009'),
            "git_sha": os.environ.get('GIT_SHA', 'unknown'),
            "timestamp_utc": os.environ.get('TIMESTAMP_UTC', 'unknown'),
            "status": "PASS" if success else "FAIL",
            "checks": checks,
            "alignment_status": "PASS" if success else "FAIL"
        }
        
        if result_data:
            evidence.update({
                "machine_contract": {
                    "file": "docs/PHASE2/phase2_contract.yml",
                    "invariant_count": result_data['machine_count'],
                    "invariants": result_data['machine_invariants']
                },
                "human_contract": {
                    "file": "docs/PHASE2/PHASE2_CONTRACT.md",
                    "invariant_count": result_data['human_count'],
                    "invariants": result_data['human_invariants'],
                    "authority_boundary_present": True,
                    "verifier_reference_present": True,
                    "evidence_reference_present": True
                },
                "unsupported_invariants": result_data['unsupported_invariants'],
                "unsupported_count": result_data['unsupported_count'],
                "summary": {
                    "total_checks": len(checks),
                    "passed_checks": len([c for c in checks if c.endswith(":PASS")]),
                    "failed_checks": len([c for c in checks if c.endswith(":FAIL")])
                }
            })
        
        # Write evidence
        evidence_path = os.environ.get('EVIDENCE_PATH', 'evidence/phase2/gov_conv_009_human_machine_contract_alignment.json')
        with open(evidence_path, 'w') as f:
            json.dump(evidence, f, indent=2)
        
        print(f"Evidence written to {evidence_path}")
        
        if success:
            print("All checks passed")
            sys.exit(0)
        else:
            print("Verification failed")
            sys.exit(1)
            
    except Exception as e:
        print(f"FATAL ERROR: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF

exit $?
