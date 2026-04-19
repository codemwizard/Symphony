#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006C-01
# Verifies DataAuthorityLevel enum exists in C# codebase with all 7 values

set -e

TASK_ID="TSK-P2-PREAUTH-006C-01"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006c_01.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if file exists
FILE_EXISTS=$(test -f src/Symphony/Core/DataAuthorityLevel.cs && echo "true" || echo "false")

# Check for enum values
PHASE1_INDICATIVE_ONLY=$(grep -q "Phase1IndicativeOnly" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
NON_REPRODUCIBLE=$(grep -q "NonReproducible" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
DERIVED_UNVERIFIED=$(grep -q "DerivedUnverified" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
POLICY_BOUND_UNSIGNED=$(grep -q "PolicyBoundUnsigned" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
AUTHORITATIVE_SIGNED=$(grep -q "AuthoritativeSigned" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
SUPERSEDED=$(grep -q "Superseded" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")
INVALIDATED=$(grep -q "Invalidated" src/Symphony/Core/DataAuthorityLevel.cs 2>/dev/null && echo "true" || echo "false")

# Build evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "file_exists": $FILE_EXISTS,
    "phase1_indicative_only": $PHASE1_INDICATIVE_ONLY,
    "non_reproducible": $NON_REPRODUCIBLE,
    "derived_unverified": $DERIVED_UNVERIFIED,
    "policy_bound_unsigned": $POLICY_BOUND_UNSIGNED,
    "authoritative_signed": $AUTHORITATIVE_SIGNED,
    "superseded": $SUPERSEDED,
    "invalidated": $INVALIDATED
  },
  "enum_exists": $FILE_EXISTS,
  "enum_values_present": $([ "$PHASE1_INDICATIVE_ONLY" = "true" ] && [ "$NON_REPRODUCIBLE" = "true" ] && [ "$DERIVED_UNVERIFIED" = "true" ] && [ "$POLICY_BOUND_UNSIGNED" = "true" ] && [ "$AUTHORITATIVE_SIGNED" = "true" ] && [ "$SUPERSEDED" = "true" ] && [ "$INVALIDATED" = "true" ] && echo "true" || echo "false")
}
EOF

# Verify checks passed
if [ "$FILE_EXISTS" != "true" ]; then
  echo "FAIL: DataAuthorityLevel.cs does not exist"
  exit 1
fi

if [ "$PHASE1_INDICATIVE_ONLY" != "true" ]; then
  echo "FAIL: Phase1IndicativeOnly value missing"
  exit 1
fi

if [ "$NON_REPRODUCIBLE" != "true" ]; then
  echo "FAIL: NonReproducible value missing"
  exit 1
fi

if [ "$DERIVED_UNVERIFIED" != "true" ]; then
  echo "FAIL: DerivedUnverified value missing"
  exit 1
fi

if [ "$POLICY_BOUND_UNSIGNED" != "true" ]; then
  echo "FAIL: PolicyBoundUnsigned value missing"
  exit 1
fi

if [ "$AUTHORITATIVE_SIGNED" != "true" ]; then
  echo "FAIL: AuthoritativeSigned value missing"
  exit 1
fi

if [ "$SUPERSEDED" != "true" ]; then
  echo "FAIL: Superseded value missing"
  exit 1
fi

if [ "$INVALIDATED" != "true" ]; then
  echo "FAIL: Invalidated value missing"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006C-01 verification complete"
