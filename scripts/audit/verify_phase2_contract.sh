#!/bin/bash

# Canonical Phase-2 contract verifier
# Verifies docs/PHASE2/phase2_contract.yml

set -euo pipefail

CONTRACT_FILE="docs/PHASE2/phase2_contract.yml"
EVIDENCE_FILE="evidence/phase2/phase2_contract_status.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize violation arrays
MALFORMED_ROWS=()
INVALID_STATUSES=()
MISSING_INVARIANTS=()
MISSING_VERIFIERS=()
MISSING_EVIDENCE=()
TASK_ID_ROWS=()

echo "Starting Phase-2 contract verification..."

# Check 1: Verify contract file exists and is valid YAML
if [ ! -f "$CONTRACT_FILE" ]; then
    echo "ERROR: Phase-2 contract file does not exist"
    exit 1
fi

if ! python3 -c "import yaml; yaml.safe_load(open('$CONTRACT_FILE'))" 2>/dev/null; then
    echo "ERROR: Phase-2 contract is not valid YAML"
    exit 1
fi

# Parse contract and validate
python3 << 'PYTHON_EOF'
import yaml
import json
import sys

def load_contract():
    with open('docs/PHASE2/phase2_contract.yml', 'r') as f:
        return yaml.safe_load(f)

def load_invariants():
    with open('docs/invariants/INVARIANTS_MANIFEST.yml', 'r') as f:
        invariants = yaml.safe_load(f)
    
    registered_ids = set()
    for inv in invariants:
        registered_ids.add(inv.get('id', ''))
        for alias in inv.get('aliases', []):
            registered_ids.add(alias)
    
    return registered_ids

def validate_contract():
    contract = load_contract()
    registered_invariants = load_invariants()
    
    # Valid status vocabulary
    valid_statuses = {'phase1_prerequisite', 'planned', 'implemented', 'deferred_to_phase3'}
    
    # Required fields for each row
    required_fields = ['invariant_id', 'status', 'required', 'gate_id', 'verifier', 'evidence_path']
    
    violations = {
        'malformed_rows': [],
        'invalid_statuses': [],
        'missing_invariants': [],
        'missing_verifiers': [],
        'missing_evidence': [],
        'task_id_rows': []
    }
    
    if 'rows' not in contract:
        violations['malformed_rows'].append("Contract missing 'rows' section")
        return violations
    
    for i, row in enumerate(contract.get('rows', [])):
        # Check for task_id rows
        invariant_id = row.get('invariant_id', '')
        if invariant_id.startswith('TSK-P2-'):
            violations['task_id_rows'].append(f"Row {i}: task_id found ({invariant_id})")
            continue
        
        # Check required fields
        missing_fields = []
        for field in required_fields:
            if field not in row or not row[field]:
                missing_fields.append(field)
        
        if missing_fields:
            violations['malformed_rows'].append(f"Row {i}: missing fields {', '.join(missing_fields)}")
            continue
        
        # Check status vocabulary
        status = row.get('status', '')
        if status not in valid_statuses:
            violations['invalid_statuses'].append(f"Row {i}: invalid status '{status}'")
        
        # Check invariant registration
        if invariant_id not in registered_invariants:
            violations['missing_invariants'].append(f"Row {i}: unregistered invariant '{invariant_id}'")
        
        # Check verifier exists for required rows
        if row.get('required', False):
            verifier = row.get('verifier', '')
            if not verifier or not verifier.startswith('scripts/'):
                violations['missing_verifiers'].append(f"Row {i}: missing or invalid verifier '{verifier}'")
            
            evidence = row.get('evidence_path', '')
            if not evidence or not evidence.startswith('evidence/'):
                violations['missing_evidence'].append(f"Row {i}: missing or invalid evidence_path '{evidence}'")
    
    return violations

def main():
    violations = validate_contract()
    
    # Generate evidence
    evidence = {
        "task_id": "TSK-P2-GOV-CONV-006",
        "git_sha": "$(git rev-parse HEAD 2>/dev/null || echo unknown)",
        "timestamp_utc": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
        "contract_file": "docs/PHASE2/phase2_contract.yml",
        "status": "PASS" if all(len(v) == 0 for v in violations.values()) else "FAIL",
        "violations": violations,
        "total_rows": len(load_contract().get('rows', [])),
        "summary": {
            "malformed_rows": len(violations['malformed_rows']),
            "invalid_statuses": len(violations['invalid_statuses']),
            "missing_invariants": len(violations['missing_invariants']),
            "missing_verifiers": len(violations['missing_verifiers']),
            "missing_evidence": len(violations['missing_evidence']),
            "task_id_rows": len(violations['task_id_rows'])
        }
    }
    
    with open('evidence/phase2/phase2_contract_status.json', 'w') as f:
        json.dump(evidence, f, indent=2)
    
    # Print summary
    print(f"Contract verification: {evidence['status']}")
    print(f"Total rows: {evidence['total_rows']}")
    for violation_type, count in evidence['summary'].items():
        if count > 0:
            print(f"  {violation_type}: {count}")
    
    # Exit with appropriate code
    if evidence['status'] == 'PASS':
        print("All checks passed")
        sys.exit(0)
    else:
        print("Contract verification failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
PYTHON_EOF

# Check the result
if [ $? -eq 0 ]; then
    echo "Phase-2 contract verification PASSED"
    exit 0
else
    echo "Phase-2 contract verification FAILED"
    exit 1
fi
