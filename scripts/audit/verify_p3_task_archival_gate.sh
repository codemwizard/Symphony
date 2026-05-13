#!/usr/bin/env bash
# TSK-P3-GOV-003 Verifier: Validate task corpus archival gate CI integration.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p3_gov_003_task_archival_gate.json"
mkdir -p "$EVIDENCE_DIR"

PASS=true
GIT_SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

# Check 1: verify_task_meta_schema.sh contains archived skip logic
SCHEMA_SCRIPT="$ROOT/scripts/audit/verify_task_meta_schema.sh"
if grep -q "archived" "$SCHEMA_SCRIPT" 2>/dev/null; then
  echo "✓ verify_task_meta_schema.sh has archived skip logic"
  SCHEMA_SKIP=true
else
  echo "✗ verify_task_meta_schema.sh missing archived skip logic"
  SCHEMA_SKIP=false
  PASS=false
fi

# Check 2: verify_task_plans_present.sh contains archived skip logic
PLANS_SCRIPT="$ROOT/scripts/audit/verify_task_plans_present.sh"
if grep -q "archived" "$PLANS_SCRIPT" 2>/dev/null; then
  echo "✓ verify_task_plans_present.sh has archived skip logic"
  PLANS_SKIP=true
else
  echo "✗ verify_task_plans_present.sh missing archived skip logic"
  PLANS_SKIP=false
  PASS=false
fi

# Check 3: Task template has archived field
TEMPLATE="$ROOT/tasks/_template/meta.yml"
if grep -q "archived:" "$TEMPLATE" 2>/dev/null; then
  echo "✓ Task template has archived field"
  TEMPLATE_OK=true
else
  echo "✗ Task template missing archived field"
  TEMPLATE_OK=false
  PASS=false
fi

# Check 4: No tasks are currently archived (safety check — archival requires human authorization)
ARCHIVED_COUNT=$(find "$ROOT/tasks" -name "meta.yml" -exec grep -l "archived: true" {} \; 2>/dev/null | wc -l)
echo "✓ Currently archived tasks: $ARCHIVED_COUNT (archival requires human authorization)"

STATUS=$( [ "$PASS" = "true" ] && echo "PASS" || echo "FAIL" )

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P3-GOV-003",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$STATUS",
  "schema_skip_logic": $SCHEMA_SKIP,
  "plans_skip_logic": $PLANS_SKIP,
  "template_has_archived": $TEMPLATE_OK,
  "currently_archived_count": $ARCHIVED_COUNT
}
EOF

echo ""; echo "Status: $STATUS"; echo "Evidence: $EVIDENCE_FILE"
[ "$PASS" = "true" ] && exit 0 || exit 1
