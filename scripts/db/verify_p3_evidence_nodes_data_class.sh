#!/usr/bin/env bash
# TSK-P3-W1-DB-007 Verifier: Validate evidence_nodes data_class column, ENUM, trigger, and registry.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p3_w1_db_007_data_class.json"
mkdir -p "$EVIDENCE_DIR"

if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL must be set" >&2
  exit 1
fi

CHECKS=()
PASS=true
GIT_SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

# Check 1: ENUM exists with exactly 6 values
ENUM_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM pg_enum WHERE enumtypid = 'public.constitutional_data_class'::regtype;" 2>/dev/null || echo "0")
if [ "$ENUM_COUNT" = "6" ]; then
  CHECKS+=("\"enum_values_count\": {\"status\": \"PASS\", \"count\": 6}")
  echo "✓ constitutional_data_class ENUM has 6 values"
else
  CHECKS+=("\"enum_values_count\": {\"status\": \"FAIL\", \"count\": $ENUM_COUNT}")
  echo "✗ constitutional_data_class ENUM has $ENUM_COUNT values (expected 6)"
  PASS=false
fi

# Check 2: data_class column exists on evidence_nodes
COL_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='evidence_nodes' AND column_name='data_class';" 2>/dev/null || echo "0")
if [ "$COL_EXISTS" = "1" ]; then
  CHECKS+=("\"column_exists\": {\"status\": \"PASS\"}")
  echo "✓ data_class column exists on evidence_nodes"
else
  CHECKS+=("\"column_exists\": {\"status\": \"FAIL\"}")
  echo "✗ data_class column missing from evidence_nodes"
  PASS=false
fi

# Check 3: Trigger exists
TRG_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM pg_trigger WHERE tgname='trg_enforce_data_class_monotonicity';" 2>/dev/null || echo "0")
if [ "$TRG_EXISTS" = "1" ]; then
  CHECKS+=("\"trigger_exists\": {\"status\": \"PASS\"}")
  echo "✓ trg_enforce_data_class_monotonicity trigger exists"
else
  CHECKS+=("\"trigger_exists\": {\"status\": \"FAIL\"}")
  echo "✗ trg_enforce_data_class_monotonicity trigger missing"
  PASS=false
fi

# Check 4: Monotonicity enforcement (negative test — downgrade must fail)
MONO_RESULT=$(psql "$DATABASE_URL" -tAc "
DO \$\$
BEGIN
  -- Insert test node
  INSERT INTO evidence_nodes (evidence_node_id, tenant_id, project_id, node_type, data_class, created_at)
  VALUES ('eeeeeeee-9999-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000003', 'verifier_test', 'evidentiary', NOW());
  -- Try downgrade
  UPDATE evidence_nodes SET data_class = 'operational' WHERE evidence_node_id = 'eeeeeeee-9999-0000-0000-000000000001';
  -- If we get here, downgrade was allowed (BAD)
  DELETE FROM evidence_nodes WHERE evidence_node_id = 'eeeeeeee-9999-0000-0000-000000000001';
  RAISE NOTICE 'MONOTONICITY_FAIL';
EXCEPTION WHEN SQLSTATE 'P3101' THEN
  DELETE FROM evidence_nodes WHERE evidence_node_id = 'eeeeeeee-9999-0000-0000-000000000001';
  RAISE NOTICE 'MONOTONICITY_PASS';
END;
\$\$;" 2>&1 | grep -o 'MONOTONICITY_[A-Z]*' || echo "MONOTONICITY_ERROR")

if [ "$MONO_RESULT" = "MONOTONICITY_PASS" ]; then
  CHECKS+=("\"monotonicity_enforced\": {\"status\": \"PASS\"}")
  echo "✓ Monotonicity enforced: evidentiary→operational blocked with P3101"
else
  CHECKS+=("\"monotonicity_enforced\": {\"status\": \"FAIL\", \"detail\": \"$MONO_RESULT\"}")
  echo "✗ Monotonicity NOT enforced: $MONO_RESULT"
  PASS=false
fi

# Check 5: data_class_registry.yml exists and has 6 classes
REGISTRY="$ROOT/docs/constitutional/data_class_registry.yml"
if [ -f "$REGISTRY" ]; then
  CLASS_COUNT=$(grep -c "^  [a-z]*:$" "$REGISTRY" 2>/dev/null || echo "0")
  if [ "$CLASS_COUNT" -ge 6 ]; then
    CHECKS+=("\"registry_complete\": {\"status\": \"PASS\", \"class_count\": $CLASS_COUNT}")
    echo "✓ data_class_registry.yml has $CLASS_COUNT classes"
  else
    CHECKS+=("\"registry_complete\": {\"status\": \"FAIL\", \"class_count\": $CLASS_COUNT}")
    echo "✗ data_class_registry.yml has $CLASS_COUNT classes (expected 6)"
    PASS=false
  fi
else
  CHECKS+=("\"registry_complete\": {\"status\": \"FAIL\", \"detail\": \"file missing\"}")
  echo "✗ data_class_registry.yml not found"
  PASS=false
fi

STATUS=$( [ "$PASS" = "true" ] && echo "PASS" || echo "FAIL" )
CHECKS_JSON=$(IFS=,; echo "${CHECKS[*]}")

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P3-W1-DB-007",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$STATUS",
  "checks": {$CHECKS_JSON},
  "enum_values_count": $ENUM_COUNT,
  "column_exists": $( [ "$COL_EXISTS" = "1" ] && echo true || echo false ),
  "trigger_exists": $( [ "$TRG_EXISTS" = "1" ] && echo true || echo false ),
  "monotonicity_enforced": $( [ "$MONO_RESULT" = "MONOTONICITY_PASS" ] && echo true || echo false )
}
EOF

echo ""
echo "Status: $STATUS"
echo "Evidence: $EVIDENCE_FILE"
[ "$PASS" = "true" ] && exit 0 || exit 1
