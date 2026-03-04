#!/bin/bash
# verify_lint_renames_applied.sh
# Verify that misleading lint script has been renamed

set -euo pipefail

echo "=== R-019-A1: Verify misleading lint renamed ==="

OLD_SCRIPT="scripts/security/lint_sql_injection.sh"
NEW_SCRIPT="scripts/security/lint_security_definer_search_path.sh"

if [[ -f "$OLD_SCRIPT" ]]; then
    echo "❌ Old misleading lint script still exists: $OLD_SCRIPT"
    exit 1
fi

if [[ ! -f "$NEW_SCRIPT" ]]; then
    echo "❌ New correctly named script not found: $NEW_SCRIPT"
    exit 1
fi

echo "✅ Misleading lint script renamed to lint_security_definer_search_path.sh"

echo ""
echo "=== Verify references updated ==="

# Check if any files still reference the old name
old_refs=$(grep -r "lint_sql_injection.sh" . --exclude-dir=.git 2>/dev/null || true)

if [[ -n "$old_refs" ]]; then
    echo "⚠️  Files still reference old lint_sql_injection.sh:"
    echo "$old_refs"
    echo "These should be updated to reference lint_security_definer_search_path.sh"
else
    echo "✅ No references to old script name found"
fi

echo ""
echo "✅ R-019-A1 completed: Misleading lint renamed"
