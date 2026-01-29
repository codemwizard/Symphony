#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking for privilege regressions in migrations"

bad=0
while IFS= read -r -d '' file; do
  # Block any CREATE grants on schema public to PUBLIC or symphony_* runtime roles.
  if grep -Eqi "GRANT\s+CREATE\s+ON\s+SCHEMA\s+public\s+TO\s+(PUBLIC|symphony_)" "$file"; then
    echo "ERROR: $file appears to grant CREATE on schema public to PUBLIC/runtime role"
    bad=$((bad + 1))
  fi
done < <(find schema/migrations -name '*.sql' -print0)

if [[ "$bad" -gt 0 ]]; then
  echo "SECURITY BLOCK: privilege escalation risk detected ($bad finding(s))"
  exit 1
fi

echo "✅ No obvious CREATE-grants regression detected"
