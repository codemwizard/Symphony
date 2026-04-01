#!/usr/bin/env bash
# fix_encoding.sh
# Fixes BOM and garbled UTF-8 characters in all _staging/ files.
# Caused by PowerShell Set-Content -Encoding UTF8 on Windows.
#
# Run this from the repo root on Ubuntu immediately after git pull:
#   bash _staging/fix_encoding.sh
#
# Safe to run multiple times — idempotent.

set -euo pipefail

STAGING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$STAGING_DIR/.." && pwd)"
cd "$ROOT"

echo "==> Fixing encoding in _staging/ ..."
echo "    Root: $ROOT"
echo "    Staging: $STAGING_DIR"

fixed=0
skipped=0

while IFS= read -r -d '' file; do
    # Strip UTF-8 BOM (\xef\xbb\xbf) — present on every file
    sed -i 's/\xef\xbb\xbf//' "$file"

    # Fix garbled multi-byte sequences produced by Windows CP1252 -> UTF-8 double-encoding.
    # Each line below maps a garbled sequence back to the correct Unicode character.

    # Em dash (—) — most common, appears in all markdown files
    sed -i 's/—/—/g' "$file"

    # Right arrow (→)
    sed -i 's/→/→/g' "$file"

    # ✅ check mark
    sed -i 's/✅/✅/g' "$file"

    # ⏳ hourglass
    sed -i 's/⏳/⏳/g' "$file"

    # ❌ cross mark
    sed -i 's/❌/❌/g' "$file"

    # 🔴 red circle
    sed -i 's/🔴/🔴/g' "$file"

    # ⚠️  warning (two variants)
    sed -i 's/⚠️/⚠️/g' "$file"

    # Box-drawing characters used in directory tree diagrams
    sed -i 's/├──/├──/g' "$file"
    sed -i 's/└──/└──/g' "$file"
    sed -i 's/│   /│   /g' "$file"
    sed -i 's/│/│/g' "$file"

    # ≥ (greater than or equal)
    sed -i 's/≥/≥/g' "$file"

    fixed=$((fixed + 1))
done < <(find "$STAGING_DIR" -type f -print0)

echo "==> Done. Fixed $fixed files."
echo ""
echo "==> Verifying sample file (MANIFEST.md first line):"
head -1 "$STAGING_DIR/symphony-enforcement-v1/MANIFEST.md"
echo ""
echo "==> Verifying no BOM remains:"
bom_count=$(grep -rl $'\xef\xbb\xbf' "$STAGING_DIR" 2>/dev/null | wc -l)
if [[ "$bom_count" -eq 0 ]]; then
    echo "    No BOM found — clean."
else
    echo "    WARNING: $bom_count file(s) still contain BOM:"
    grep -rl $'\xef\xbb\xbf' "$STAGING_DIR"
fi
echo ""
echo "==> Verifying no garbled sequences remain:"
garbled_count=$(grep -rl '—\|→\|✅\|⏳\|❌\|Γö£\|Γöö\|│' "$STAGING_DIR" 2>/dev/null | wc -l)
if [[ "$garbled_count" -eq 0 ]]; then
    echo "    No garbled sequences found — clean."
else
    echo "    WARNING: $garbled_count file(s) still contain garbled sequences:"
    grep -rl '—\|→\|✅\|⏳\|❌\|Γö£\|Γöö\|│' "$STAGING_DIR"
fi
