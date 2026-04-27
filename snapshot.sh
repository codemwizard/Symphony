#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="system_snapshot"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
ARCHIVE="system_snapshot_$TIMESTAMP.tar.gz"

PREV_SNAPSHOT=$(ls -t system_snapshot_*.tar.gz 2>/dev/null | head -n 1 || true)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "== Symphony Snapshot v2 (Full Intelligence Mode) =="

########################################
# 1. GIT STATE
########################################
git rev-parse HEAD > "$OUTPUT_DIR/git_commit.txt"
git status --porcelain > "$OUTPUT_DIR/git_status.txt"
git log --oneline -n 50 > "$OUTPUT_DIR/git_recent_history.txt"

########################################
# 2. MIGRATIONS + HEAD
########################################
cp schema/migrations/MIGRATION_HEAD "$OUTPUT_DIR/" 2>/dev/null || true

find schema/migrations -type f -name "*.sql" | sort > "$OUTPUT_DIR/migration_files.txt"

mkdir -p "$OUTPUT_DIR/migrations_tail"
tail -n 10 "$OUTPUT_DIR/migration_files.txt" | while read -r f; do
  cp "$f" "$OUTPUT_DIR/migrations_tail/" || true
done

########################################
# 3. INVARIANTS
########################################
mkdir -p "$OUTPUT_DIR/invariants"
cp -r docs/invariants "$OUTPUT_DIR/" 2>/dev/null || true

########################################
# 4. TASKS + PLANS
########################################
mkdir -p "$OUTPUT_DIR/tasks"
find tasks -name "meta.yml" -exec cp --parents {} "$OUTPUT_DIR/tasks/" \; 2>/dev/null || true
find docs/plans/phase2 -name "PLAN.md" -exec cp --parents {} "$OUTPUT_DIR/tasks/" \; 2>/dev/null || true

########################################
# 5. VERIFIERS + CI
########################################
mkdir -p "$OUTPUT_DIR/verifiers"
cp -r scripts/audit "$OUTPUT_DIR/" 2>/dev/null || true
cp scripts/dev/pre_ci.sh "$OUTPUT_DIR/" 2>/dev/null || true

########################################
# 6. EVIDENCE
########################################
mkdir -p "$OUTPUT_DIR/evidence"
find evidence -type f -name "*.json" -exec cp {} "$OUTPUT_DIR/evidence/" \; 2>/dev/null || true

########################################
# 7. SEMANTIC DIFF VS LAST SNAPSHOT
########################################
echo "[DIFF] Generating semantic diff..."

if [[ -n "$PREV_SNAPSHOT" ]]; then
  mkdir -p prev_snapshot
  tar -xzf "$PREV_SNAPSHOT" -C prev_snapshot

  diff -ru prev_snapshot "$OUTPUT_DIR" > "$OUTPUT_DIR/semantic_diff.txt" || true

  rm -rf prev_snapshot
else
  echo "NO PREVIOUS SNAPSHOT" > "$OUTPUT_DIR/semantic_diff.txt"
fi

########################################
# 8. INVARIANT COVERAGE GAP DETECTOR
########################################
echo "[CHECK] Invariant coverage..."

TOTAL_INVARIANTS=$(ls docs/invariants 2>/dev/null | wc -l)
TOTAL_VERIFIERS=$(ls scripts/audit 2>/dev/null | wc -l)

cat > "$OUTPUT_DIR/invariant_coverage.json" <<EOF
{
  "invariants_count": $TOTAL_INVARIANTS,
  "verifiers_count": $TOTAL_VERIFIERS,
  "gap": $((TOTAL_INVARIANTS - TOTAL_VERIFIERS))
}
EOF

########################################
# 9. MIGRATION RISK SCORING
########################################
echo "[RISK] Scanning migrations..."

RISK_FILE="$OUTPUT_DIR/migration_risk_report.txt"

echo "Migration Risk Report" > "$RISK_FILE"

grep -r "DROP TABLE" schema/migrations >> "$RISK_FILE" || true
grep -r "ALTER COLUMN" schema/migrations >> "$RISK_FILE" || true
grep -r "DELETE FROM" schema/migrations >> "$RISK_FILE" || true

########################################
# 10. AI SYSTEM GRAPH (CRITICAL)
########################################
echo "[GRAPH] Building system graph..."

cat > "$OUTPUT_DIR/system_graph.json" <<EOF
{
  "nodes": {
    "schema": "schema/migrations",
    "invariants": "docs/invariants",
    "tasks": "tasks",
    "plans": "docs/plans/phase2",
    "verifiers": "scripts/audit",
    "evidence": "evidence"
  },
  "rules": [
    "schema defines structure",
    "invariants define truth",
    "verifiers enforce invariants",
    "tasks define intent",
    "plans define execution",
    "evidence defines reality"
  ],
  "priority_order": [
    "invariants",
    "verifiers",
    "schema",
    "tasks",
    "plans",
    "evidence"
  ]
}
EOF

########################################
# 11. SYSTEM SUMMARY (AI ENTRY POINT)
########################################
cat > "$OUTPUT_DIR/SYSTEM_SUMMARY.md" <<EOF
# SYSTEM SNAPSHOT ($TIMESTAMP)

## Commit
$(cat $OUTPUT_DIR/git_commit.txt)

## Migration Head
$(cat $OUTPUT_DIR/MIGRATION_HEAD 2>/dev/null || echo "MISSING")

## Invariants
$TOTAL_INVARIANTS

## Verifiers
$TOTAL_VERIFIERS

## Risk Signals
$(wc -l < "$RISK_FILE") potential issues

## Snapshot Contents
- Schema (latest + tail migrations)
- Invariants
- Tasks + Plans
- Verifiers + CI
- Evidence
- Semantic diff
- Risk report
- System graph

## AI RULES
1. Invariants override everything
2. Verifiers define correctness
3. Schema is source of truth
4. Tasks define intent
5. Evidence validates reality
EOF

########################################
# FINAL PACKAGE
########################################
tar -czf "$ARCHIVE" "$OUTPUT_DIR"

echo ""
echo "✅ FULL SNAPSHOT READY:"
echo "$ARCHIVE"
