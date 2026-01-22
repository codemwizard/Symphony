#!/usr/bin/env bash
# ============================================================
# archive_guardrail.sh — Prevent regression to legacy schema/v1
# ============================================================
# This script enforces that:
#   1. No workflow or script references schema/v1
#   2. No script applies files from _archive/schema
#
# Add to CI: scripts/ci/archive_guardrail.sh
# ============================================================
set -euo pipefail

echo "🔒 Checking archive guardrails..."

FAILED=0

# Resolve repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

# ------------------------------------------------------------
# Check 1: No workflow/script references schema/v1
# ------------------------------------------------------------
echo "  Checking for schema/v1 references..."

# Exclude this script itself and the archive README
if grep -r "schema/v1" .github/ scripts/ \
    --include="*.yml" --include="*.yaml" --include="*.sh" \
    2>/dev/null | grep -v "archive_guardrail.sh" | grep -v "#.*schema/v1"; then
  echo "::error::Forbidden reference to schema/v1 detected in workflows or scripts"
  FAILED=1
fi

# ------------------------------------------------------------
# Check 2: No script applies _archive/schema
# ------------------------------------------------------------
echo "  Checking for _archive/schema application..."

if grep -r "_archive/schema" scripts/ \
    --include="*.sh" \
    2>/dev/null | grep -v "archive_guardrail.sh" | grep -E "(psql|source|\.|\bsh\b).*_archive/schema"; then
  echo "::error::Forbidden application of archived schema detected"
  FAILED=1
fi

# ------------------------------------------------------------
# Result
# ------------------------------------------------------------
if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "❌ Archive guardrails FAILED"
  echo "   schema/v1 is archived and must not be applied."
  echo "   Use scripts/db/migrate.sh for schema changes."
  exit 1
fi

echo "✅ Archive guardrails passed."
