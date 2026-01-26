#!/usr/bin/env bash
# ============================================================
# verify_invariants.sh — Single entrypoint verification (CI/local)
# ============================================================
# Requires: DATABASE_URL
#
# Env knobs:
#   REQUIRE_POLICY_SEED=1        -> FAIL if no seed source found
#   SKIP_POLICY_SEED=1           -> skip seeding
#   SEED_POLICY_FILE=/path/file  -> seed from JSON file (dev)
#   SEED_POLICY_VERSION=...      -> seed from env (CI)
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- 1. Pre-flight existence checks (Requirement #2 & Hardening) ---

# Verify binary dependencies (New Requirement)
command -v psql >/dev/null 2>&1 || { echo "❌ Error: psql not found in PATH"; exit 2; }
[[ -x "$SCRIPT_DIR/lint_migrations.sh" ]] || { echo "❌ Error: missing lint_migrations.sh"; exit 2; }
[[ -x "$SCRIPT_DIR/lint_search_path.sh" ]] || { echo "❌ Error: missing lint_search_path.sh"; exit 2; }
[[ -x "$SCRIPT_DIR/migrate.sh" ]] || { echo "❌ Error: missing migrate.sh"; exit 2; }
[[ -f "$SCRIPT_DIR/ci_invariant_gate.sql" ]] || { echo "❌ Error: missing ci_invariant_gate.sql"; exit 2; }
[[ -x "$REPO_ROOT/schema/seeds/dev/seed_policy_from_file.sh" ]] || { echo "❌ Error: missing seed_policy_from_file.sh"; exit 2; }

# --- 2. Execution ---
echo "🔎 Linting migrations..."
"$SCRIPT_DIR/lint_migrations.sh"

echo "🔒 Linting SECURITY DEFINER search_path..."
"$SCRIPT_DIR/lint_search_path.sh"

echo "🧱 Applying migrations (idempotent)..."
"$SCRIPT_DIR/migrate.sh"

# --- 3. Policy Seeding with REQUIRE_POLICY_SEED logic (Requirement #1) ---
if [[ "${SKIP_POLICY_SEED:-0}" != "1" ]]; then
  POLICY_FILE="${SEED_POLICY_FILE:-}"
  SEED_SUCCESS=0

  # Fail Fast: If a specific file was requested but is missing (Requirement #5)
  if [[ -n "${POLICY_FILE}" && ! -f "${POLICY_FILE}" ]]; then
    echo "❌ Error: SEED_POLICY_FILE was set but does not exist: $POLICY_FILE"
    exit 2
  fi

  # Fallback logic to find default files if no specific file was provided
  if [[ -z "${POLICY_FILE}" ]]; then
    if [[ -f "$REPO_ROOT/.policy/active-policy.json" ]]; then
      POLICY_FILE="$REPO_ROOT/.policy/active-policy.json"
    elif [[ -f "$REPO_ROOT/.symphony/policies/active-policy.json" ]]; then
      POLICY_FILE="$REPO_ROOT/.symphony/policies/active-policy.json"
    fi
  fi

  if [[ -n "${POLICY_FILE}" ]]; then
    echo "🌱 Seeding policy from file: $POLICY_FILE"
    "$REPO_ROOT/schema/seeds/dev/seed_policy_from_file.sh" "$POLICY_FILE"
    SEED_SUCCESS=1
  elif [[ -n "${SEED_POLICY_VERSION:-}" ]]; then
    # Explicit check for CI seed script existence (Requirement #1 part 2)
    if [[ -x "$REPO_ROOT/schema/seeds/ci/seed_policy_from_env.sh" ]]; then
      echo "🌱 Seeding policy from env: SEED_POLICY_VERSION"
      "$REPO_ROOT/schema/seeds/ci/seed_policy_from_env.sh"
      SEED_SUCCESS=1
    else
      echo "⚠️  SEED_POLICY_VERSION set but schema/seeds/ci/seed_policy_from_env.sh not found."
    fi
  fi

  # Final check for Requirement #1: Failure logic
  if [[ "$SEED_SUCCESS" -eq 0 ]]; then
    if [[ "${REQUIRE_POLICY_SEED:-0}" == "1" ]]; then
      echo "::error::Policy seed required but no source found (REQUIRE_POLICY_SEED=1)."
      exit 1
    else
      echo "ℹ️  No policy seed source found; skipping seeding (Optional mode)."
    fi
  fi
else
  echo "⏭️  SKIP_POLICY_SEED=1 set; skipping policy seed."
fi

# --- 4. CI Invariant Gate (Requirement #3) ---
echo "🧰 Running CI invariant gate..."
psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -X -f "$SCRIPT_DIR/ci_invariant_gate.sql" >/dev/null

echo "✅ Invariants verified."
