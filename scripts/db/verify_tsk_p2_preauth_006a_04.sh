#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006A-04
# Verifies data_authority columns exist on state_transitions with default 'non_reproducible'

set -e

TASK_ID="TSK-P2-PREAUTH-006A-04"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006a_04.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if columns exist
DATA_AUTHORITY_EXISTS=$(psql -tAc "SELECT 1 FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'data_authority'" 2>/dev/null || echo "0")
AUDIT_GRADE_EXISTS=$(psql -tAc "SELECT 1 FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'audit_grade'" 2>/dev/null || echo "0")
AUTHORITY_EXPLANATION_EXISTS=$(psql -tAc "SELECT 1 FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'authority_explanation'" 2>/dev/null || echo "0")

# Check defaults
DATA_AUTHORITY_DEFAULT=$(psql -tAc "SELECT column_default FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'data_authority'" 2>/dev/null || echo "")
AUDIT_GRADE_DEFAULT=$(psql -tAc "SELECT column_default FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'audit_grade'" 2>/dev/null || echo "")
AUTHORITY_EXPLANATION_DEFAULT=$(psql -tAc "SELECT column_default FROM information_schema.columns WHERE table_name = 'state_transitions' AND column_name = 'authority_explanation'" 2>/dev/null || echo "")

# Check MIGRATION_HEAD
MIGRATION_HEAD=$(cat schema/migrations/MIGRATION_HEAD)

# Build evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "data_authority_exists": $([ "$DATA_AUTHORITY_EXISTS" = "1" ] && echo "true" || echo "false"),
    "audit_grade_exists": $([ "$AUDIT_GRADE_EXISTS" = "1" ] && echo "true" || echo "false"),
    "authority_explanation_exists": $([ "$AUTHORITY_EXPLANATION_EXISTS" = "1" ] && echo "true" || echo "false"),
    "data_authority_default": "$DATA_AUTHORITY_DEFAULT",
    "audit_grade_default": "$AUDIT_GRADE_DEFAULT",
    "authority_explanation_default": "$AUTHORITY_EXPLANATION_DEFAULT",
    "migration_head": "$MIGRATION_HEAD"
  },
  "columns_exist": $([ "$DATA_AUTHORITY_EXISTS" = "1" ] && [ "$AUDIT_GRADE_EXISTS" = "1" ] && [ "$AUTHORITY_EXPLANATION_EXISTS" = "1" ] && echo "true" || echo "false"),
  "defaults_applied": $([ -n "$DATA_AUTHORITY_DEFAULT" ] && [ -n "$AUDIT_GRADE_DEFAULT" ] && [ -n "$AUTHORITY_EXPLANATION_DEFAULT" ] && echo "true" || echo "false"),
  "migration_head": "$MIGRATION_HEAD"
}
EOF

# Verify checks passed
if [ "$DATA_AUTHORITY_EXISTS" != "1" ]; then
  echo "FAIL: data_authority column does not exist"
  exit 1
fi

if [ "$AUDIT_GRADE_EXISTS" != "1" ]; then
  echo "FAIL: audit_grade column does not exist"
  exit 1
fi

if [ "$AUTHORITY_EXPLANATION_EXISTS" != "1" ]; then
  echo "FAIL: authority_explanation column does not exist"
  exit 1
fi

if [ -z "$DATA_AUTHORITY_DEFAULT" ]; then
  echo "FAIL: data_authority column has no default"
  exit 1
fi

if ! echo "$DATA_AUTHORITY_DEFAULT" | grep -q "non_reproducible"; then
  echo "FAIL: data_authority default is not 'non_reproducible'"
  exit 1
fi

if [ "$MIGRATION_HEAD" != "0121" ]; then
  echo "FAIL: MIGRATION_HEAD is $MIGRATION_HEAD, expected 0121"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006A-04 verification complete"
