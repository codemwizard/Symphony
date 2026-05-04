#!/bin/bash

# Reusable Phase-2 ratification verifier
# Verifies Phase-2 ratification markdown and approval sidecar integrity

set -euo pipefail

EVIDENCE_PATH="evidence/phase2/phase2_ratification_status.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()
violations=()

echo "Starting Phase-2 ratification verification..."

# Function to find the most recent ratification artifacts
find_ratification_artifacts() {
    local approval_dir="approvals"
    local latest_date=""
    local ratification_files=()
    
    # Find all ratification files
    for date_dir in "$approval_dir"/*; do
        if [ -d "$date_dir" ] && [ -f "$date_dir/PHASE2-RATIFICATION.md" ] && [ -f "$date_dir/PHASE2-RATIFICATION.approval.json" ]; then
            ratification_files+=("$date_dir")
        fi
    done
    
    # Sort by date and get the most recent
    if [ ${#ratification_files[@]} -gt 0 ]; then
        latest_date=$(printf '%s\n' "${ratification_files[@]}" | sort -r | head -1)
        echo "$latest_date"
    else
        echo ""
    fi
}

# Step 1: Locate artifacts
echo "Step 1: Locate artifacts"
RATIFICATION_DIR=$(find_ratification_artifacts)

if [ -z "$RATIFICATION_DIR" ]; then
    violations+=("No ratification artifacts found")
    echo "✗ No ratification artifacts found"
else
    checks+=("artifacts_found:PASS")
    echo "✓ Found ratification artifacts in $RATIFICATION_DIR"
    
    MARKDOWN_FILE="$RATIFICATION_DIR/PHASE2-RATIFICATION.md"
    SIDECAR_FILE="$RATIFICATION_DIR/PHASE2-RATIFICATION.approval.json"
fi

# Step 2: Validate cross-references
echo "Step 2: Validate cross-references"
if [ -n "$RATIFICATION_DIR" ]; then
    # Check sidecar references markdown
    SIDECAR_REF_MARKDOWN=$(python3 -c "
import json
with open('$SIDECAR_FILE', 'r') as f:
    data = json.load(f)
print(data.get('cross_references', {}).get('markdown_artifact', ''))
" 2>/dev/null || echo "")
    
    # Check markdown references sidecar
    MARKDOWN_REF_SIDECAR=$(grep "\*\*Approval Sidecar\*\*:" "$MARKDOWN_FILE" | cut -d: -f2- | tr -d ' \`\`' || grep "Approval Sidecar:" "$MARKDOWN_FILE" | cut -d: -f2- | tr -d ' \`\`' || echo "")
    
    if [ "$SIDECAR_REF_MARKDOWN" = "$MARKDOWN_FILE" ] && [ "$MARKDOWN_REF_SIDECAR" = "$SIDECAR_FILE" ]; then
        checks+=("cross_references_valid:PASS")
        echo "✓ Cross-references are valid"
    else
        violations+=("Cross-reference mismatch")
        echo "✗ Cross-reference mismatch"
    fi
fi

# Step 3: Validate sidecar schema
echo "Step 3: Validate sidecar schema"
if [ -n "$RATIFICATION_DIR" ]; then
    if python3 -c "
import json
try:
    with open('$SIDECAR_FILE', 'r') as f:
        data = json.load(f)
    
    required_fields = ['approval_id', 'approval_date', 'approver', 'approval_type', 'status', 'scope', 'prerequisites', 'ratified_artifacts']
    missing_fields = [field for field in required_fields if field not in data]
    
    if missing_fields:
        print(f'Missing required fields: {missing_fields}')
        exit(1)
    else:
        print('Sidecar schema valid')
        exit(0)
except Exception as e:
    print(f'Schema validation error: {e}')
    exit(1)
" 2>/dev/null; then
        checks+=("sidecar_schema_valid:PASS")
        echo "✓ Sidecar schema is valid"
    else
        violations+=("Invalid sidecar schema")
        echo "✗ Invalid sidecar schema"
    fi
fi

# Step 4: Verify prerequisite evidence
echo "Step 4: Verify prerequisite evidence"
if [ -n "$RATIFICATION_DIR" ]; then
    MISSING_EVIDENCE=()
    
    # Check prerequisite evidence files referenced in sidecar
    EVIDENCE_FILES=$(python3 -c "
import json
with open('$SIDECAR_FILE', 'r') as f:
    data = json.load(f)
prereqs = data.get('prerequisites', [])
for prereq in prereqs:
    print(prereq.get('evidence', ''))
" 2>/dev/null)
    
    for evidence_file in $EVIDENCE_FILES; do
        if [ ! -f "$evidence_file" ]; then
            MISSING_EVIDENCE+=("$evidence_file")
        fi
    done
    
    if [ ${#MISSING_EVIDENCE[@]} -eq 0 ]; then
        checks+=("prerequisite_evidence_valid:PASS")
        echo "✓ All prerequisite evidence files exist"
    else
        violations+=("Missing prerequisite evidence")
        echo "✗ Missing prerequisite evidence: ${MISSING_EVIDENCE[*]}"
    fi
fi

# Step 5: Reject overbroad claims
echo "Step 5: Reject overbroad claims"
if [ -n "$RATIFICATION_DIR" ]; then
    OVERBROAD_CLAIMS=0
    
    # Check for claims about Phase-2 implementation completion (excluding governance convergence)
    if grep -q "Phase-2 is complete\|Phase-2 implementation.*complete\|all.*Phase-2.*implementation.*complete\|Phase-2.*ready.*production" "$MARKDOWN_FILE"; then
        OVERBROAD_CLAIMS=$((OVERBROAD_CLAIMS + 1))
    fi
    
    # Check for claims about future phases being open
    if grep -q "Phase-3.*open\|Phase-4.*open\|opens.*Phase-3\|opens.*Phase-4" "$MARKDOWN_FILE"; then
        OVERBROAD_CLAIMS=$((OVERBROAD_CLAIMS + 1))
    fi
    
    if [ "$OVERBROAD_CLAIMS" -eq 0 ]; then
        checks+=("no_overbroad_claims:PASS")
        echo "✓ No overbroad claims found"
    else
        violations+=("Overbroad claims detected")
        echo "✗ Overbroad claims detected: $OVERBROAD_CLAIMS"
    fi
fi

# Step 6: Verify bounded scope
echo "Step 6: Verify bounded scope"
if [ -n "$RATIFICATION_DIR" ]; then
    if grep -q "Bounded Scope\|does not claim\|excludes.*runtime\|excludes.*Phase-3" "$MARKDOWN_FILE"; then
        checks+=("bounded_scope_present:PASS")
        echo "✓ Bounded scope declaration present"
    else
        violations+=("Missing bounded scope declaration")
        echo "✗ Missing bounded scope declaration"
    fi
fi

# Generate evidence
STATUS="PASS"
if [ ${#violations[@]} -gt 0 ]; then
    STATUS="FAIL"
fi

python3 << PYTHON_EOF
import json

checks = [line.strip() for line in '''${checks[@]}'''.split() if line.strip()]
violations = [line.strip() for line in '''${violations[@]}'''.split() if line.strip()]

evidence = {
    "task_id": "verify_phase2_ratification",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "checks": checks,
    "violations": violations,
    "ratification_status": "$STATUS",
    "artifacts": {
        "directory": "${RATIFICATION_DIR:-null}",
        "markdown_file": "${MARKDOWN_FILE:-null}",
        "sidecar_file": "${SIDECAR_FILE:-null}"
    },
    "validation_results": {
        "artifacts_found": len([c for c in checks if "artifacts_found:PASS" in checks]) > 0,
        "cross_references_valid": len([c for c in checks if "cross_references_valid:PASS" in checks]) > 0,
        "sidecar_schema_valid": len([c for c in checks if "sidecar_schema_valid:PASS" in checks]) > 0,
        "prerequisite_evidence_valid": len([c for c in checks if "prerequisite_evidence_valid:PASS" in checks]) > 0,
        "no_overbroad_claims": len([c for c in checks if "no_overbroad_claims:PASS" in checks]) > 0,
        "bounded_scope_present": len([c for c in checks if "bounded_scope_present:PASS" in checks]) > 0
    },
    "summary": {
        "total_checks": len(checks),
        "passed_checks": len(checks),
        "failed_checks": len(violations),
        "violation_count": len(violations)
    }
}

with open("$EVIDENCE_PATH", "w") as f:
    json.dump(evidence, f, indent=2)
PYTHON_EOF

echo "Evidence written to $EVIDENCE_PATH"

if [ "$STATUS" = "PASS" ]; then
    echo "Phase-2 ratification verification PASSED"
    exit 0
else
    echo "Phase-2 ratification verification FAILED"
    exit 1
fi
