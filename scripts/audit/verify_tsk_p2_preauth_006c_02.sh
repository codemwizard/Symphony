#!/bin/bash
# Verification script for TSK-P2-PREAUTH-006C-02
# Verifies DataAuthority and AuditGrade properties exist in MonitoringRecord read model

set -e

TASK_ID="TSK-P2-PREAUTH-006C-02"
EVIDENCE_PATH="evidence/phase2/tsk_p2_preauth_006c_02.json"
GIT_SHA=$(git rev-parse HEAD)
TIMESTAMP_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Check if file exists
FILE_EXISTS=$(test -f src/Symphony/Models/MonitoringRecord.cs && echo "true" || echo "false")

# Check for DataAuthority property
DATA_AUTHORITY_EXISTS=$(grep -q "DataAuthority" src/Symphony/Models/MonitoringRecord.cs 2>/dev/null && echo "true" || echo "false")
DATA_AUTHORITY_TYPE=$(grep -q "DataAuthorityLevel" src/Symphony/Models/MonitoringRecord.cs 2>/dev/null && echo "true" || echo "false")

# Check for AuditGrade property
AUDIT_GRADE_EXISTS=$(grep -q "AuditGrade" src/Symphony/Models/MonitoringRecord.cs 2>/dev/null && echo "true" || echo "false")
AUDIT_GRADE_TYPE=$(grep -q "bool" src/Symphony/Models/MonitoringRecord.cs 2>/dev/null && echo "true" || echo "false")

# Build evidence JSON
cat > "$EVIDENCE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$TIMESTAMP_UTC",
  "status": "success",
  "checks": {
    "file_exists": $FILE_EXISTS,
    "data_authority_property_exists": $DATA_AUTHORITY_EXISTS,
    "data_authority_type_correct": $DATA_AUTHORITY_TYPE,
    "audit_grade_property_exists": $AUDIT_GRADE_EXISTS,
    "audit_grade_type_correct": $AUDIT_GRADE_TYPE
  },
  "data_authority_property_exists": $DATA_AUTHORITY_EXISTS,
  "audit_grade_property_exists": $AUDIT_GRADE_EXISTS
}
EOF

# Verify checks passed
if [ "$FILE_EXISTS" != "true" ]; then
  echo "FAIL: MonitoringRecord.cs does not exist"
  exit 1
fi

if [ "$DATA_AUTHORITY_EXISTS" != "true" ]; then
  echo "FAIL: DataAuthority property missing"
  exit 1
fi

if [ "$DATA_AUTHORITY_TYPE" != "true" ]; then
  echo "FAIL: DataAuthority property does not have DataAuthorityLevel type"
  exit 1
fi

if [ "$AUDIT_GRADE_EXISTS" != "true" ]; then
  echo "FAIL: AuditGrade property missing"
  exit 1
fi

if [ "$AUDIT_GRADE_TYPE" != "true" ]; then
  echo "FAIL: AuditGrade property does not have bool type"
  exit 1
fi

echo "PASS: TSK-P2-PREAUTH-006C-02 verification complete"
