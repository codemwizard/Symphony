#!/usr/bin/env bash
set -euo pipefail

command -v rg >/dev/null 2>&1 || { echo "rg (ripgrep) is required"; exit 2; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TARGETS=(libs services)
# NOTE: These guardrails are scoped to application code in libs/services only.
# DML in DB functions (schema/) is allowed and intentionally out of scope here.

echo "[guardrails] Checking for forbidden legacy DB role APIs..."

LEGACY_PATTERNS=(
  "\\bcurrentRole\\b"
  "\\bsetRole\\b\\s*\\("
  "\\bexecuteTransaction\\b\\s*\\("
)


for pat in "${LEGACY_PATTERNS[@]}"; do
  if rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    "$pat" "${TARGETS[@]}" >/dev/null; then
    echo "❌ Forbidden legacy pattern found: $pat"
    rg -n --hidden \
      --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
      "$pat" "${TARGETS[@]}"
    exit 1
  fi
done

echo "[guardrails] Checking role SQL usage outside libs/db..."

ROLE_SQL='SET ROLE|RESET ROLE|SET LOCAL ROLE'
if rg -n --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  --glob '!libs/db/**' \
  "$ROLE_SQL" "${TARGETS[@]}" >/dev/null; then
  echo "❌ Role SQL found outside libs/db (must be encapsulated in libs/db only):"
  rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!libs/db/**' \
    "$ROLE_SQL" "${TARGETS[@]}"
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
  if rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!libs/db/**' \
    "$pat" "${TARGETS[@]}" >/dev/null; then
    echo "❌ Raw pg usage found outside libs/db:"
    rg -n --hidden \
      --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
      --glob '!libs/db/**' \
      "$pat" "${TARGETS[@]}"
    exit 1
  fi
done

echo "[guardrails] Checking testOnly import allowlist..."
TESTONLY_IMPORT='from\\s+["'\''](?:symphony/)?libs/db/testOnly["'\'']|require\\(["'\''](?:symphony/)?libs/db/testOnly["'\'']\\)'
if rg -n --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  --glob '!tests/**' --glob '!libs/db/__tests__/**' \
  "$TESTONLY_IMPORT" "${TARGETS[@]}" >/dev/null; then
  echo "❌ Forbidden import of libs/db/testOnly outside tests:"
  rg -n --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
    --glob '!tests/**' --glob '!libs/db/__tests__/**' \
    "$TESTONLY_IMPORT" "${TARGETS[@]}"
  exit 1
fi

if [[ "${ENFORCE_NO_DB_QUERY:-0}" == "1" ]]; then
  echo "[guardrails] Phase B enabled: forbidding db.query(...) usage..."
  if rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' \
  "db\\.query\\s*\\(" "${TARGETS[@]}" >/dev/null; then
    echo "❌ Forbidden usage found: db.query("
    rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' "db\\.query\\s*\\(" "${TARGETS[@]}"
    exit 1
  fi
fi

echo "[guardrails] Checking outbox anti-patterns..."

# Narrow match: old delete-on-claim CTE shape (WITH due + SKIP LOCKED + DELETE ... USING due)
DELETE_ON_CLAIM_REGEX='WITH\\s+due\\s+AS\\s*\\([\\s\\S]{0,5000}?FOR\\s+UPDATE\\s+SKIP\\s+LOCKED[\\s\\S]{0,5000}?\\)[\\s\\S]{0,5000}?DELETE\\s+FROM\\s+payment_outbox_pending[\\s\\S]{0,5000}?USING\\s+due'
if rg -n -U --pcre2 --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
  "$DELETE_ON_CLAIM_REGEX" "${TARGETS[@]}" >/dev/null; then
  echo "❌ delete-on-claim CTE pattern found"
  rg -n -U --pcre2 --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
    "$DELETE_ON_CLAIM_REGEX" "${TARGETS[@]}"
  exit 1
fi

# Narrow match: INSERT into attempts with DISPATCHING nearby
DISPATCHING_INSERT_REGEX="INSERT\\s+INTO\\s+payment_outbox_attempts[\\s\\S]{0,400}\\b(?:DISPATCHING|'DISPATCHING')(?:\\s*::\\s*outbox_attempt_state)?\\b"
if rg -n -U --pcre2 --hidden \
  --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
  "$DISPATCHING_INSERT_REGEX" "${TARGETS[@]}" >/dev/null; then
  echo "❌ DISPATCHING insert found (payment_outbox_attempts)"
  rg -n -U --pcre2 --hidden \
    --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
    "$DISPATCHING_INSERT_REGEX" "${TARGETS[@]}"
  exit 1
fi

if rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
  "(INSERT INTO|UPDATE|DELETE FROM)\\s+payment_outbox_pending" "${TARGETS[@]}" >/dev/null; then
  echo "❌ Direct DML against payment_outbox_pending found outside DB functions"
  rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
    "(INSERT INTO|UPDATE|DELETE FROM)\\s+payment_outbox_pending" "${TARGETS[@]}"
  exit 1
fi

if rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
  "(INSERT INTO|UPDATE|DELETE FROM)\\s+payment_outbox_attempts" "${TARGETS[@]}" >/dev/null; then
  echo "❌ Direct DML against payment_outbox_attempts found outside DB functions"
  rg -n --hidden --glob '!**/node_modules/**' --glob '!**/*.md' --glob '!**/*.txt' --glob '!reports/**' \
    "(INSERT INTO|UPDATE|DELETE FROM)\\s+payment_outbox_attempts" "${TARGETS[@]}"
  exit 1
fi

echo "✅ DB role guardrails passed."
