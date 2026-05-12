#!/usr/bin/env bash
# TSK-P3-GOV-002 Verifier: Validate INV-301–310 seeded in invariant_registry.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_FILE="$EVIDENCE_DIR/tsk_p3_gov_002_invariant_seed.json"
mkdir -p "$EVIDENCE_DIR"

if [ -z "${DATABASE_URL:-}" ]; then echo "ERROR: DATABASE_URL must be set" >&2; exit 1; fi

PASS=true
GIT_SHA=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "UNKNOWN")

# Check 1: Exactly 10 INV-3% rows
INV_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%';" 2>/dev/null || echo "0")
[ "$INV_COUNT" = "10" ] && echo "✓ 10 Phase 3 invariants found" || { echo "✗ Found $INV_COUNT (expected 10)"; PASS=false; }

# Check 2: All non-blocking
BLOCKING=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%' AND is_blocking = true;" 2>/dev/null || echo "0")
[ "$BLOCKING" = "0" ] && echo "✓ All 10 are non-blocking (roadmap)" || { echo "✗ $BLOCKING are blocking"; PASS=false; }

# Check 3: Severity distribution (8 CRITICAL, 2 HIGH)
CRITICAL=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%' AND severity = 'CRITICAL';" 2>/dev/null || echo "0")
HIGH=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%' AND severity = 'HIGH';" 2>/dev/null || echo "0")
[ "$CRITICAL" = "8" ] && [ "$HIGH" = "2" ] && echo "✓ Severity: 8 CRITICAL + 2 HIGH" || { echo "✗ Severity: $CRITICAL CRITICAL + $HIGH HIGH (expected 8+2)"; PASS=false; }

# Check 4: No duplicates
DUPES=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) - COUNT(DISTINCT invariant_id) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%';" 2>/dev/null || echo "0")
[ "$DUPES" = "0" ] && echo "✓ No duplicate invariant_ids" || { echo "✗ $DUPES duplicates found"; PASS=false; }

# Check 5: Execution layer distribution (7 DB, 3 CI)
DB_LAYER=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%' AND execution_layer = 'DB';" 2>/dev/null || echo "0")
CI_LAYER=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM invariant_registry WHERE invariant_id LIKE 'INV-3%' AND execution_layer = 'CI';" 2>/dev/null || echo "0")
[ "$DB_LAYER" = "7" ] && [ "$CI_LAYER" = "3" ] && echo "✓ Execution layer: 7 DB + 3 CI" || { echo "✗ Execution layer: $DB_LAYER DB + $CI_LAYER CI (expected 7+3)"; PASS=false; }

STATUS=$( [ "$PASS" = "true" ] && echo "PASS" || echo "FAIL" )

cat > "$EVIDENCE_FILE" <<EOF
{
  "task_id": "TSK-P3-GOV-002",
  "git_sha": "$GIT_SHA",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "$STATUS",
  "checks": {
    "invariant_count": {"status": "$( [ "$INV_COUNT" = "10" ] && echo PASS || echo FAIL )", "count": $INV_COUNT},
    "all_non_blocking": {"status": "$( [ "$BLOCKING" = "0" ] && echo PASS || echo FAIL )"},
    "severity_distribution": {"status": "$( [ "$CRITICAL" = "8" ] && [ "$HIGH" = "2" ] && echo PASS || echo FAIL )", "critical": $CRITICAL, "high": $HIGH},
    "no_duplicates": {"status": "$( [ "$DUPES" = "0" ] && echo PASS || echo FAIL )"},
    "execution_layer": {"status": "$( [ "$DB_LAYER" = "7" ] && [ "$CI_LAYER" = "3" ] && echo PASS || echo FAIL )", "db": $DB_LAYER, "ci": $CI_LAYER}
  },
  "invariant_count": $INV_COUNT,
  "all_non_blocking": $( [ "$BLOCKING" = "0" ] && echo true || echo false ),
  "severity_distribution": {"critical": $CRITICAL, "high": $HIGH}
}
EOF

echo ""; echo "Status: $STATUS"; echo "Evidence: $EVIDENCE_FILE"
[ "$PASS" = "true" ] && exit 0 || exit 1
