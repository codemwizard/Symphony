#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking SECURITY DEFINER function hardening (search_path) in migrations"

violations=0

# Heuristic: only treat SECURITY DEFINER as a hardening requirement when it appears
# in the context of CREATE/ALTER FUNCTION (not comments, not grants text).
while IFS= read -r -d '' file; do
  # Fast path: if no SECURITY DEFINER anywhere, skip.
  grep -q "SECURITY DEFINER" "$file" || continue

  # Find line numbers where SECURITY DEFINER appears.
  # For each occurrence, look back ~25 lines for CREATE/ALTER FUNCTION.
  while IFS=: read -r lineno _; do
    start=$((lineno-25))
    if [[ "$start" -lt 1 ]]; then start=1; fi

    context="$(sed -n "${start},${lineno}p" "$file")"

    # Only enforce if context suggests this SECURITY DEFINER is in a function definition/change.
    if echo "$context" | grep -Eq "CREATE( OR REPLACE)? FUNCTION|ALTER FUNCTION"; then
      # Now require the hardening directive in nearby lines (same vicinity).
      # This catches: "... SECURITY DEFINER SET search_path = pg_catalog, public"
      near="$(sed -n "${start},$((lineno+25))p" "$file")"
      if ! echo "$near" | grep -q "SET search_path = pg_catalog, public"; then
        echo "ERROR: $file:$lineno has SECURITY DEFINER near CREATE/ALTER FUNCTION without safe search_path"
        violations=$((violations + 1))
      fi
    fi
  done < <(grep -n "SECURITY DEFINER" "$file" || true)

done < <(find schema/migrations -name '*.sql' -print0)

if [[ "$violations" -gt 0 ]]; then
  echo "SECURITY BLOCK: Found $violations violation(s)"
  exit 1
fi

echo "✅ SECURITY DEFINER hardening looks OK"
