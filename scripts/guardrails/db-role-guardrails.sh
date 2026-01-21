#!/usr/bin/env bash
set -euo pipefail

command -v rg >/dev/null 2>&1 || { echo "rg (ripgrep) is required"; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "[guardrails] Checking for forbidden legacy DB role APIs..."

LEGACY_PATTERNS=(
  "\\bcurrentRole\\b"
  "\\bsetRole\\b\\s*\\("
  "\\bexecuteTransaction\\b\\s*\\("
)


for pat in "${LEGACY_PATTERNS[@]}"; do
  if rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!scripts/guardrails/db-role-guardrails.sh' \
    "$pat" . >/dev/null; then
    echo "❌ Forbidden legacy pattern found: $pat"
    rg -n --hidden \
      --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
      --glob '!scripts/guardrails/db-role-guardrails.sh' \
      "$pat" .
    exit 1
  fi
done

echo "[guardrails] Checking role SQL usage outside libs/db..."

ROLE_SQL='SET ROLE|RESET ROLE|SET LOCAL ROLE'
if rg -n --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  --glob '!libs/db/**' \
  --glob '!scripts/**' \
  --glob '!scripts/guardrails/db-role-guardrails.sh' \
  "$ROLE_SQL" . >/dev/null; then
  echo "❌ Role SQL found outside libs/db (must be encapsulated in libs/db only):"
  rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!libs/db/**' \
    --glob '!scripts/**' \
    --glob '!scripts/guardrails/db-role-guardrails.sh' \
    "$ROLE_SQL" .
  exit 1
fi


echo "[guardrails] Checking raw pg usage outside libs/db..."

PG_IMPORT_PATTERNS=(
  "from\\s+['\"]pg['\"]"
  "require\\(['\"]pg['\"]\\)"
  "PoolClient"
  "new\\s+Pool\\s*\\("
  "pool\\.query\\s*\\("
)

for pat in "${PG_IMPORT_PATTERNS[@]}"; do
  if rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!libs/db/**' --glob '!tests/**' --glob '!scripts/**' "$pat" . >/dev/null; then
    echo "❌ Raw pg usage found outside libs/db:"
    rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!libs/db/**' --glob '!tests/**' --glob '!scripts/**' "$pat" .
    exit 1
  fi
done

echo "[guardrails] Checking testOnly import allowlist..."
if rg -n --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  --glob '!tests/**' --glob '!libs/db/__tests__/**' \
  --glob '!scripts/guardrails/db-role-guardrails.sh' \
  --glob '!scripts/**' \
  "libs/db/testOnly" . >/dev/null; then
  echo "❌ Forbidden import of libs/db/testOnly outside tests:"
  rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!tests/**' --glob '!libs/db/__tests__/**' \
    --glob '!scripts/guardrails/db-role-guardrails.sh' \
    --glob '!scripts/**' \
    "libs/db/testOnly" .
  exit 1
fi

TARGETS=(libs services)
if [[ "${ENFORCE_NO_DB_QUERY:-0}" == "1" ]]; then
  echo "[guardrails] Phase B enabled: forbidding db.query(...) usage..."
  if rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  "db\\.query\\s*\\(" "${TARGETS[@]}" >/dev/null; then
    echo "❌ Forbidden usage found: db.query("
    rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' "db\\.query\\s*\\(" .
    exit 1
  fi
fi

echo "✅ DB role guardrails passed."
