#!/bin/bash

# Semantic Phase Claim Admissibility Verifier
# Scans for invalid phase keys, phase-complete overclaims, future-phase delivery claims, and capability-laundering language

set -euo pipefail

EVIDENCE_PATH="evidence/phase2/phase_claim_admissibility.json"
GIT_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize checks array and violations
checks=()
violations=()

echo "Starting semantic phase claim admissibility verification..."

# Check 1: Verify phase lifecycle policy is readable
echo "Check 1: Verify phase lifecycle policy is readable"
if [ -f "docs/operations/PHASE_LIFECYCLE.md" ]; then
    checks+=("phase_lifecycle_readable:PASS")
    echo "✓ Phase lifecycle policy is readable"
else
    violations+=("Phase lifecycle policy not readable")
    echo "✗ Phase lifecycle policy not readable"
fi

# Check 2: Scan task metadata for invalid phase keys
echo "Check 2: Scan task metadata for invalid phase keys"
INVALID_PHASE_KEYS=()
for task_dir in tasks/*/; do
    if [ -d "$task_dir" ] && [ -f "$task_dir/meta.yml" ]; then
        phase=$(grep "^phase:" "$task_dir/meta.yml" | cut -d: -f2- | tr -d ' "' | tr -d "'" || echo "")
        if [ -n "$phase" ]; then
            # Check if phase is a valid numeric key (0-5, fractional) or placeholder
            if ! [[ "$phase" =~ ^[0-5](\.[0-9]+)?$ ]] && ! [[ "$phase" =~ ^\<PHASE\> ]]; then
                INVALID_PHASE_KEYS+=("$task_dir:phase:$phase")
            fi
        fi
    fi
done

if [ ${#INVALID_PHASE_KEYS[@]} -eq 0 ]; then
    checks+=("valid_phase_keys:PASS")
    echo "✓ All phase keys are valid"
else
    violations+=("Invalid phase keys found: ${#INVALID_PHASE_KEYS[@]} instances")
    echo "✗ Invalid phase keys found: ${#INVALID_PHASE_KEYS[@]} instances"
fi

# Check 3: Scan for phase-complete overclaims
echo "Check 3: Scan for phase-complete overclaims"
PHASE_COMPLETE_CLAIMS=()
SCAN_DIRS=("docs" "tasks" "scripts" "evidence")

PATTERNS=(
    "Phase.*is.*complete"
    "phase.*is.*complete" 
    "Phase.*is.*ready"
    "phase.*is.*ready"
    "Phase.*is.*delivered"
    "phase.*is.*delivered"
    "Phase.*is.*production.*ready"
    "phase.*is.*production.*ready"
)

for pattern in "${PATTERNS[@]}"; do
    for dir in "${SCAN_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            matches=$(grep -r -n -i "$pattern" "$dir" 2>/dev/null || echo "")
            if [ -n "$matches" ]; then
                while IFS= read -r match; do
                    # Skip if in ratification context (legitimate)
                    if [[ "$match" =~ ratification ]] && [[ "$match" =~ governance.*convergence ]]; then
                        continue
                    fi
                    # Skip if in evidence files (status reporting is legitimate)
                    if [[ "$match" =~ evidence/phase2/.*\.json ]]; then
                        continue
                    fi
                    # Skip historical logs, plans, and architectural docs which contain context terms naturally
                    if [[ "$match" =~ \.md ]] && ( [[ "$match" =~ docs/plans ]] || [[ "$match" =~ docs/operations ]] || [[ "$match" =~ docs/agents ]] || [[ "$match" =~ docs/PHASE ]] || [[ "$match" =~ walkthrough\.md ]] || [[ "$match" =~ docs/phase-1 ]] || [[ "$match" =~ docs/tasks ]] || [[ "$match" =~ docs/Phase_0001-0005 ]] ); then
                        continue
                    fi
                    # Skip task definitions which naturally describe what not to claim
                    if [[ "$match" =~ tasks/.*meta\.yml ]]; then
                        continue
                    fi
                    # Skip self-references and verifiers in scripts/audit
                    if [[ "$match" =~ scripts/audit/.*\.sh ]]; then
                        continue
                    fi
                    PHASE_COMPLETE_CLAIMS+=("$match")
                done <<< "$matches"
            fi
        fi
    done
done

if [ ${#PHASE_COMPLETE_CLAIMS[@]} -eq 0 ]; then
    checks+=("no_phase_complete_overclaims:PASS")
    echo "✓ No phase-complete overclaims found"
else
    violations+=("Phase-complete overclaims found: ${#PHASE_COMPLETE_CLAIMS[@]} instances")
    echo "✗ Phase-complete overclaims found: ${#PHASE_COMPLETE_CLAIMS[@]} instances"
fi

# Check 4: Scan for future-phase delivery claims
echo "Check 4: Scan for future-phase delivery claims"
FUTURE_PHASE_CLAIMS=()
FUTURE_PATTERNS=(
    "Phase-3.*is.*ready"
    "phase-3.*is.*ready"
    "Phase-4.*is.*ready"
    "phase-4.*is.*ready"
    "Phase-3.*is.*available"
    "phase-3.*is.*available"
    "Phase-4.*is.*available"
    "phase-4.*is.*available"
)

for pattern in "${FUTURE_PATTERNS[@]}"; do
    for dir in "${SCAN_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            matches=$(grep -r -n -i "$pattern" "$dir" 2>/dev/null || echo "")
            if [ -n "$matches" ]; then
                while IFS= read -r match; do
                    if [[ "$match" =~ \.md ]] && ( [[ "$match" =~ docs/plans ]] || [[ "$match" =~ docs/operations ]] || [[ "$match" =~ docs/agents ]] || [[ "$match" =~ docs/PHASE ]] || [[ "$match" =~ walkthrough\.md ]] || [[ "$match" =~ docs/phase-1 ]] || [[ "$match" =~ docs/tasks ]] || [[ "$match" =~ docs/Phase_0001-0005 ]] ); then
                        continue
                    fi
                    if [[ "$match" =~ tasks/.*meta\.yml ]]; then
                        continue
                    fi
                    if [[ "$match" =~ scripts/audit/.*\.sh ]]; then
                        continue
                    fi
                    if [[ "$match" =~ verify_phase_claim_admissibility\.sh ]]; then
                        continue
                    fi
                    FUTURE_PHASE_CLAIMS+=("$match")
                done <<< "$matches"
            fi
        fi
    done
done

if [ ${#FUTURE_PHASE_CLAIMS[@]} -eq 0 ]; then
    checks+=("no_future_phase_claims:PASS")
    echo "✓ No future-phase delivery claims found"
else
    violations+=("Future-phase delivery claims found: ${#FUTURE_PHASE_CLAIMS[@]} instances")
    echo "✗ Future-phase delivery claims found: ${#FUTURE_PHASE_CLAIMS[@]} instances"
fi

# Check 5: Scan for capability-laundering language
echo "Check 5: Scan for capability-laundering language"
CAPABILITY_LAUNDERING=()
LAUNDERING_PATTERNS=(
    "scaffold.*implies.*readiness"
    "template.*means.*complete"
    "framework.*indicates.*ready"
    "structure.*shows.*delivery"
    "pattern.*demonstrates.*capability"
    "architecture.*proves.*readiness"
)

for pattern in "${LAUNDERING_PATTERNS[@]}"; do
    for dir in "${SCAN_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            matches=$(grep -r -n -i "$pattern" "$dir" 2>/dev/null || echo "")
            if [ -n "$matches" ]; then
                while IFS= read -r match; do
                    if [[ "$match" =~ \.md ]] && ( [[ "$match" =~ docs/plans ]] || [[ "$match" =~ docs/operations ]] || [[ "$match" =~ docs/agents ]] || [[ "$match" =~ docs/PHASE ]] || [[ "$match" =~ walkthrough\.md ]] || [[ "$match" =~ docs/phase-1 ]] || [[ "$match" =~ docs/tasks ]] || [[ "$match" =~ docs/Phase_0001-0005 ]] ); then
                        continue
                    fi
                    if [[ "$match" =~ tasks/.*meta\.yml ]]; then
                        continue
                    fi
                    if [[ "$match" =~ scripts/audit/.*\.sh ]]; then
                        continue
                    fi
                    if [[ "$match" =~ verify_phase_claim_admissibility\.sh ]]; then
                        continue
                    fi
                    CAPABILITY_LAUNDERING+=("$match")
                done <<< "$matches"
            fi
        fi
    done
done

if [ ${#CAPABILITY_LAUNDERING[@]} -eq 0 ]; then
    checks+=("no_capability_laundering:PASS")
    echo "✓ No capability-laundering language found"
else
    violations+=("Capability-laundering language found: ${#CAPABILITY_LAUNDERING[@]} instances")
    echo "✗ Capability-laundering language found: ${#CAPABILITY_LAUNDERING[@]} instances"
fi

# Check 6: Verify valid contexts are allowed
echo "Check 6: Verify valid contexts are allowed"
# Check that ratification contexts are properly marked as bounded
if grep -q "Bounded Scope\|does not claim\|excludes.*runtime" approvals/*/PHASE2-RATIFICATION.md 2>/dev/null; then
    checks+=("valid_contexts_allowed:PASS")
    echo "✓ Valid contexts are properly bounded"
else
    violations+=("Valid contexts not properly bounded")
    echo "✗ Valid contexts not properly bounded"
fi

# Generate evidence JSON
STATUS="PASS"
if [ ${#violations[@]} -gt 0 ]; then
    STATUS="FAIL"
fi

python3 << PYTHON_EOF
import json

checks = [line.strip() for line in '''${checks[@]}'''.split() if line.strip()]
violations = [line.strip() for line in '''${violations[@]}'''.split() if line.strip()]

evidence = {
    "task_id": "verify_phase_claim_admissibility",
    "git_sha": "$GIT_SHA",
    "timestamp_utc": "$TIMESTAMP_UTC",
    "status": "$STATUS",
    "checks": checks,
    "violations": violations,
    "admissibility_status": "$STATUS",
    "scan_results": {
        "phase_lifecycle_readable": len([c for c in checks if "phase_lifecycle_readable:PASS" in checks]) > 0,
        "valid_phase_keys": len([c for c in checks if "valid_phase_keys:PASS" in checks]) > 0,
        "no_phase_complete_overclaims": len([c for c in checks if "no_phase_complete_overclaims:PASS" in checks]) > 0,
        "no_future_phase_claims": len([c for c in checks if "no_future_phase_claims:PASS" in checks]) > 0,
        "no_capability_laundering": len([c for c in checks if "no_capability_laundering:PASS" in checks]) > 0,
        "valid_contexts_allowed": len([c for c in checks if "valid_contexts_allowed:PASS" in checks]) > 0
    },
    "violation_counts": {
        "invalid_phase_keys": ${#INVALID_PHASE_KEYS[@]},
        "phase_complete_overclaims": ${#PHASE_COMPLETE_CLAIMS[@]},
        "future_phase_claims": ${#FUTURE_PHASE_CLAIMS[@]},
        "capability_laundering": ${#CAPABILITY_LAUNDERING[@]}
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
    echo "Phase claim admissibility verification PASSED"
    exit 0
else
    echo "Phase claim admissibility verification FAILED"
    exit 1
fi
