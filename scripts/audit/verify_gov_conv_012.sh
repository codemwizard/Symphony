#!/bin/bash

# Verification script for TSK-P2-GOV-CONV-012
# Create Phase-2 ratification artifacts

set -euo pipefail

TASK_ID="TSK-P2-GOV-CONV-012"
EVIDENCE_PATH="evidence/phase2/gov_conv_012_phase2_ratification_artifacts.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array
checks=()

echo "Starting verification for ${TASK_ID}..."

# Check 1: Verify prerequisite tasks are complete
echo "Check 1: Verify prerequisite tasks complete"
PREREQ_TASKS=("TSK-P2-GOV-CONV-006" "TSK-P2-GOV-CONV-007" "TSK-P2-GOV-CONV-009" "TSK-P2-GOV-CONV-011")
ALL_PREREQS_COMPLETE=true

for prereq in "${PREREQ_TASKS[@]}"; do
    if [ ! -f "tasks/$prereq/meta.yml" ]; then
        ALL_PREREQS_COMPLETE=false
        echo "✗ Prerequisite task $prereq not found"
        break
    fi
    
    STATUS=$(grep "^status:" "tasks/$prereq/meta.yml" | cut -d: -f2- | tr -d ' ')
    if [ "$STATUS" != "completed" ]; then
        ALL_PREREQS_COMPLETE=false
        echo "✗ Prerequisite task $prereq not completed: $STATUS"
        break
    fi
done

if [ "$ALL_PREREQS_COMPLETE" = true ]; then
    checks+=("prerequisite_tasks_complete:PASS")
    echo "✓ All prerequisite tasks are completed"
else
    checks+=("prerequisite_tasks_complete:FAIL")
    echo "✗ Prerequisite tasks are not complete"
    exit 1
fi

# Check 2: Verify prerequisite evidence files exist
echo "Check 2: Verify prerequisite evidence files exist"
EVIDENCE_FILES=(
    "evidence/phase2/gov_conv_006_contract_verifier.json"
    "evidence/phase2/gov_conv_007_phase2_contract_wiring.json"
    "evidence/phase2/gov_conv_009_human_machine_contract_alignment.json"
    "evidence/phase2/gov_conv_011_phase2_policy_alignment.json"
)

MISSING_EVIDENCE=()
for evidence_file in "${EVIDENCE_FILES[@]}"; do
    if [ ! -f "$evidence_file" ]; then
        MISSING_EVIDENCE+=("$evidence_file")
    fi
done

if [ ${#MISSING_EVIDENCE[@]} -eq 0 ]; then
    checks+=("prerequisite_evidence_exists:PASS")
    echo "✓ All prerequisite evidence files exist"
else
    checks+=("prerequisite_evidence_exists:FAIL")
    echo "✗ Missing evidence files: ${MISSING_EVIDENCE[*]}"
    exit 1
fi

# Check 3: Verify ratification markdown exists
echo "Check 3: Verify ratification markdown exists"
if [ -f "approvals/2026-05-03/PHASE2-RATIFICATION.md" ]; then
    checks+=("ratification_markdown_exists:PASS")
    echo "✓ Ratification markdown exists"
else
    checks+=("ratification_markdown_exists:FAIL")
    echo "✗ Ratification markdown does not exist"
    exit 1
fi

# Check 4: Verify approval sidecar exists
echo "Check 4: Verify approval sidecar exists"
if [ -f "approvals/2026-05-03/PHASE2-RATIFICATION.approval.json" ]; then
    checks+=("approval_sidecar_exists:PASS")
    echo "✓ Approval sidecar exists"
else
    checks+=("approval_sidecar_exists:FAIL")
    echo "✗ Approval sidecar does not exist"
    exit 1
fi

# Check 5: Verify sidecar schema validity
echo "Check 5: Verify sidecar schema validity"
if python3 -c "import json; json.load(open('approvals/2026-05-03/PHASE2-RATIFICATION.approval.json'))" 2>/dev/null; then
    checks+=("sidecar_schema_valid:PASS")
    echo "✓ Sidecar schema is valid"
else
    checks+=("sidecar_schema_valid:FAIL")
    echo "✗ Sidecar schema is invalid"
    exit 1
fi

# Check 6: Verify sidecar has required fields
echo "Check 6: Verify sidecar has required fields"
REQUIRED_FIELDS=("approval_id" "approval_date" "approver" "approval_type" "status" "scope" "prerequisites" "ratified_artifacts")
MISSING_FIELDS=()

for field in "${REQUIRED_FIELDS[@]}"; do
    if ! python3 -c "
import json
with open('approvals/2026-05-03/PHASE2-RATIFICATION.approval.json', 'r') as f:
    data = json.load(f)
if '$field' not in data:
    exit(1)
" 2>/dev/null; then
        MISSING_FIELDS+=("$field")
    fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
    checks+=("sidecar_required_fields:PASS")
    echo "✓ Sidecar has all required fields"
else
    checks+=("sidecar_required_fields:FAIL")
    echo "✗ Sidecar missing required fields: ${MISSING_FIELDS[*]}"
    exit 1
fi

# Check 7: Verify cross-references are correct
echo "Check 7: Verify cross-references are correct"
SIDEcar_REFERENCE=$(python3 -c "
import json
with open('approvals/2026-05-03/PHASE2-RATIFICATION.approval.json', 'r') as f:
    data = json.load(f)
print(data.get('cross_references', {}).get('markdown_artifact', ''))
" 2>/dev/null || echo "")

MARKDOWN_REFERENCE=$(grep "Approval Sidecar:" approvals/2026-05-03/PHASE2-RATIFICATION.md | cut -d: -f2- | tr -d ' \`\`' || grep "\*\*Approval Sidecar\*\*:" approvals/2026-05-03/PHASE2-RATIFICATION.md | cut -d: -f2- | tr -d ' \`\`' || echo "")

if [ "$SIDEcar_REFERENCE" = "approvals/2026-05-03/PHASE2-RATIFICATION.md" ] && [ "$MARKDOWN_REFERENCE" = "approvals/2026-05-03/PHASE2-RATIFICATION.approval.json" ]; then
    checks+=("cross_references_correct:PASS")
    echo "✓ Cross-references are correct"
else
    checks+=("cross_references_correct:FAIL")
    echo "✗ Cross-references are incorrect"
    exit 1
fi

# Check 8: Verify no overbroad completion claims
echo "Check 8: Verify no overbroad completion claims"
OVERBROAD_CLAIMS=0

# Check for claims about runtime implementation completion
if grep -q "runtime.*complete\|implementation.*complete\|system.*ready" approvals/2026-05-03/PHASE2-RATIFICATION.md; then
    OVERBROAD_CLAIMS=$((OVERBROAD_CLAIMS + 1))
fi

# Check for claims about Phase-3/Phase-4 readiness
if grep -q "Phase-3.*ready\|Phase-4.*ready\|opens.*Phase-3\|opens.*Phase-4" approvals/2026-05-03/PHASE2-RATIFICATION.md; then
    OVERBROAD_CLAIMS=$((OVERBROAD_CLAIMS + 1))
fi

if [ "$OVERBROAD_CLAIMS" -eq 0 ]; then
    checks+=("no_overbroad_claims:PASS")
    echo "✓ No overbroad completion claims found"
else
    checks+=("no_overbroad_claims:FAIL")
    echo "✗ Found $OVERBROAD_CLAIMS overbroad completion claims"
    exit 1
fi

# Check 9: Verify bounded scope declaration
echo "Check 9: Verify bounded scope declaration"
if grep -q "Bounded Scope\|does not claim\|excludes.*runtime\|excludes.*Phase-3" approvals/2026-05-03/PHASE2-RATIFICATION.md; then
    checks+=("bounded_scope_declared:PASS")
    echo "✓ Bounded scope declared"
else
    checks+=("bounded_scope_declared:FAIL")
    echo "✗ Bounded scope not declared"
    exit 1
fi

# Check 10: Verify regulated surface scope
echo "Check 10: Verify regulated surface scope"
REGULATED_COUNT=$(python3 -c "
import json
with open('approvals/2026-05-03/PHASE2-RATIFICATION.approval.json', 'r') as f:
    data = json.load(f)
regulated_surfaces = data.get('regulated_surfaces', [])
print(len(regulated_surfaces))
" 2>/dev/null || echo "0")

if [ "$REGULATED_COUNT" -gt 0 ]; then
    checks+=("regulated_surface_scope:PASS")
    echo "✓ Regulated surface scope defined ($REGULATED_COUNT surfaces)"
else
    checks+=("regulated_surface_scope:FAIL")
    echo "✗ Regulated surface scope not defined"
    exit 1
fi

# Generate evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "PASS",
  "checks": [
$(printf '    "%s"' "${checks[@]}" | paste -sd ',' -)
  ],
  "ratification_status": "PASS",
  "artifacts": {
    "markdown": "approvals/2026-05-03/PHASE2-RATIFICATION.md",
    "sidecar": "approvals/2026-05-03/PHASE2-RATIFICATION.approval.json",
    "sidecar_valid": true,
    "cross_references_correct": true
  },
  "prerequisites": {
    "tasks_completed": ${#PREREQ_TASKS[@]},
    "evidence_files": ${#EVIDENCE_FILES[@]},
    "missing_evidence": ${#MISSING_EVIDENCE[@]}
  },
  "scope_validation": {
    "bounded_scope_declared": true,
    "overbroad_claims": $OVERBROAD_CLAIMS,
    "regulated_surfaces": $REGULATED_COUNT
  },
  "summary": {
    "total_checks": ${#checks[@]},
    "passed_checks": ${#checks[@]},
    "failed_checks": 0
  }
}
EOF

echo "Evidence written to $EVIDENCE_PATH"
echo "All checks passed"

exit 0
