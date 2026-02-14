#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking for privilege regressions in migrations"

bad=0
while IFS= read -r -d '' file; do
  # Block any CREATE grants on schema public to PUBLIC or symphony_* runtime roles.
  # Parse statements across newlines and ignore SQL comments.
  matches="$(
    perl -0777 -ne '
      s{/\*.*?\*/}{}gs;
      s{--[^\n]*}{}g;
      while (/GRANT\s+CREATE\s+ON\s+SCHEMA\s+public\s+TO\s+([^;]+);/ig) {
        my $roles = $1;
        if ($roles =~ /\bPUBLIC\b/i || $roles =~ /\bsymphony_[a-z0-9_]*\b/i) {
          print $roles, "\n";
        }
      }
    ' "$file"
  )"

  if [[ -n "$matches" ]]; then
    echo "ERROR: $file appears to grant CREATE on schema public to PUBLIC/runtime role"
    bad=$((bad + 1))
  fi
done < <(find schema/migrations -name '*.sql' -print0)

if [[ "$bad" -gt 0 ]]; then
  echo "SECURITY BLOCK: privilege escalation risk detected ($bad finding(s))"
  exit 1
fi

echo "✅ No obvious CREATE-grants regression detected"
