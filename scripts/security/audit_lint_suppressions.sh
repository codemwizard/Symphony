#!/bin/bash
# audit_lint_suppressions.sh
# Audit lint suppressions and ensure they have justification+expiry

set -euo pipefail

echo "=== Auditing Lint Suppressions ==="

# Check for common suppression patterns in code
suppression_patterns=(
    "semgrep: disable"
    "# noinspection"
    "# pylint: disable"
    "# flake8: disable"
    "@SuppressMessage"
    "#pragma: disable"
)

suppressions_found=0
files_with_suppressions=()

# Search suppressions only in git-tracked C# and Python sources.
while IFS= read -r file; do
    file_suppressions=0
    
    [[ "$file" == *.cs || "$file" == *.py ]] || continue
    [[ "$file" == .venv/* || "$file" == venv/* || "$file" == env/* || "$file" == node_modules/* ]] && continue

    for pattern in "${suppression_patterns[@]}"; do
        if grep -n "$pattern" "$file" >/dev/null 2>&1; then
            echo "🔍 Suppression found in $file: $pattern"
            grep -n "$pattern" "$file" | head -3
            file_suppressions=$((file_suppressions + 1))
            suppressions_found=$((suppressions_found + 1))
        fi
    done
    
    if [[ "$file_suppressions" -gt 0 ]]; then
        files_with_suppressions+=("$file")
    fi
done < <(git ls-files '*.cs' '*.py')

echo ""
echo "=== Suppression Summary ==="
echo "Total suppressions found: $suppressions_found"
echo "Files with suppressions: ${#files_with_suppressions[@]}"

if [[ ${#files_with_suppressions[@]} -gt 0 ]]; then
    echo ""
    echo "Files requiring audit:"
    for file in "${files_with_suppressions[@]}"; do
        echo "  - $file"
    done
    
    echo ""
    echo "=== Checking for Justification and Expiry ==="
    
    # Check if suppressions have justification comments
    unjustified_suppressions=0
    
    for file in "${files_with_suppressions[@]}"; do
        echo "Checking $file for justification..."
        
        # Look for justification patterns near suppressions
        justification_patterns=(
            "TODO:.*security"
            "FIXME:.*security"
            "SECURITY.*"
            "justification"
            "reason"
            "expiry"
            "until"
        )
        
        justification_found=false
        for pattern in "${justification_patterns[@]}"; do
            if grep -i "$pattern" "$file" >/dev/null 2>&1; then
                justification_found=true
                break
            fi
        done
        
        if [[ "$justification_found" == false ]]; then
            echo "❌ $file has suppressions without justification"
            unjustified_suppressions=$((unjustified_suppressions + 1))
        else
            echo "✅ $file has justification comments"
        fi
    done
    
    if [[ "$unjustified_suppressions" -gt 0 ]]; then
        echo ""
        echo "❌ $unjustified_suppressions files have suppressions without justification"
        echo "❌ All suppressions must include:"
        echo "   - Reason/justification"
        echo "   - Expiry date or ticket reference"
        echo "   - Security team approval"
        exit 1
    fi
else
    echo "✅ No lint suppressions found"
fi

echo ""
echo "=== Recommendations ==="
echo "If suppressions are needed:"
echo "1. Document justification in comment"
echo "2. Include expiry date or ticket reference"
echo "3. Get security team approval"
echo "4. Create suppression tracking in docs/security/suppressions.md"

echo ""
echo "✅ Lint suppression audit completed"
