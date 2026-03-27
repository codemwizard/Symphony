#!/usr/bin/env bash
# scripts/audit/verify_migration_sequence.sh
#
# PURPOSE
# -------
# Verify migration sequence integrity: no gaps, no duplicates, HEAD matches
#
# USAGE
# -----
# bash scripts/audit/verify_migration_sequence.sh [--schema-dir DIR] [--head-file FILE]

set -euo pipefail

SCHEMA_DIR="${1:-schema/migrations}"
HEAD_FILE="${2:-${SCHEMA_DIR}/MIGRATION_HEAD}"
VIOLATIONS=()

echo "==> Migration Sequence Guard"
echo "Schema directory: $SCHEMA_DIR"
echo "Head file: $HEAD_FILE"

# Check schema directory exists
if [[ ! -d "$SCHEMA_DIR" ]]; then
    echo "ERROR: Schema directory not found: $SCHEMA_DIR" >&2
    exit 1
fi

# Extract all migration numbers from .sql files
echo "Scanning for migration files..."
mapfile -t MIGRATION_FILES < <(find "$SCHEMA_DIR" -name "*.sql" -type f | sort)

if [[ ${#MIGRATION_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No migration files found in $SCHEMA_DIR" >&2
    exit 1
fi

# Extract migration numbers
declare -A MIGRATION_NUMBERS
for file in "${MIGRATION_FILES[@]}"; do
    filename=$(basename "$file")
    if [[ "$filename" =~ ^([0-9]{4})_ ]]; then
        num="${BASH_REMATCH[1]}"
        if [[ -n "${MIGRATION_NUMBERS[$num]:-}" ]]; then
            VIOLATIONS+=("DUPLICATE: Migration number $num appears in multiple files")
        fi
        MIGRATION_NUMBERS["$num"]="$file"
    else
        echo "WARNING: Skipping file without 4-digit prefix: $filename"
    fi
done

# Get sorted list of migration numbers
mapfile -t SORTED_NUMBERS < <(printf '%s\n' "${!MIGRATION_NUMBERS[@]}" | sort -n)

if [[ ${#SORTED_NUMBERS[@]} -eq 0 ]]; then
    echo "ERROR: No valid migration files found" >&2
    exit 1
fi

# Check for gaps in sequence
echo "Checking for gaps in sequence..."
for ((i=1; i<${#SORTED_NUMBERS[@]}; i++)); do
    prev="${SORTED_NUMBERS[$((i-1))]}"
    curr="${SORTED_NUMBERS[$i]}"
    
    # Calculate expected next number
    expected=$((10#$prev + 1))
    expected_formatted=$(printf "%04d" $expected)
    
    if [[ "$curr" != "$expected_formatted" ]]; then
        VIOLATIONS+=("GAP: Missing migration $expected_formatted between $prev and $curr")
    fi
done

# Get highest migration number
HIGHEST="${SORTED_NUMBERS[-1]}"
echo "Highest migration found: $HIGHEST"

# Check HEAD file
if [[ -f "$HEAD_FILE" ]]; then
    HEAD_CONTENT=$(cat "$HEAD_FILE" | tr -d '[:space:]')
    echo "HEAD file content: $HEAD_CONTENT"
    
    if [[ "$HEAD_CONTENT" != "$HIGHEST" ]]; then
        VIOLATIONS+=("HEAD_MISMATCH: Highest migration ($HIGHEST) does not match HEAD file ($HEAD_CONTENT)")
    fi
else
    echo "WARNING: HEAD file not found: $HEAD_FILE"
    VIOLATIONS+=("NO_HEAD_FILE: MIGRATION_HEAD file not found")
fi

# Check if this is a git repository and check for uncommitted migrations
if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Checking git status..."
    
    # Check for uncommitted migration files
    UNCOMMITTED=$(git status --porcelain "$SCHEMA_DIR"/*.sql 2>/dev/null || true)
    if [[ -n "$UNCOMMITTED" ]]; then
        echo "WARNING: Uncommitted migration files detected:"
        echo "$UNCOMMITTED"
    fi
    
    # Get the latest committed migration
    LATEST_COMMITTED=$(git log --pretty=format:"%h" -1 -- "$SCHEMA_DIR" 2>/dev/null || echo "none")
    if [[ "$LATEST_COMMITTED" != "none" ]]; then
        echo "Latest commit touching migrations: $LATEST_COMMITTED"
    fi
else
    echo "Not a git repository - skipping git checks"
fi

# Report results
echo ""
echo "Migration sequence analysis complete:"
echo "  Total migrations: ${#SORTED_NUMBERS[@]}"
echo "  Range: ${SORTED_NUMBERS[0]} to $HIGHEST"

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    echo ""
    echo "❌ VIOLATIONS FOUND:"
    for violation in "${VIOLATIONS[@]}"; do
        echo "  $violation"
    done
    exit 1
else
    echo "✅ No violations found"
    exit 0
fi
