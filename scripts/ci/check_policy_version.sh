#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Policy Version Consistency Check
# =============================================================================
# 
# THIS CHECK VALIDATES: Code <-> File consistency
# NOT: File <-> Production DB (that's a deployment gate, not CI gate)
#
# Why?
# - CI runs against an ephemeral DB with seed data
# - Production DB is managed through governance, not seed files
# - CI should prove the BUILD is policy-consistent, not the environment
# =============================================================================

POLICY_FILE=".symphony/policies/active-policy.json"
POLICY_LOCK=".policy.lock"

# 1. Get declared policy version from active-policy.json
POLICY_VERSION_FILE=$(jq -r '.policy_version' "$POLICY_FILE" | xargs)

# 2. Get locked policy version from .policy.lock (if exists)
if [[ -f "$POLICY_LOCK" ]]; then
  POLICY_VERSION_LOCK=$(grep "version:" "$POLICY_LOCK" | awk '{print $2}' | xargs)
else
  echo "⚠️  .policy.lock not found, skipping lock validation"
  POLICY_VERSION_LOCK="$POLICY_VERSION_FILE"
fi

# 3. Validate file matches lock
if [[ "$POLICY_VERSION_FILE" != "$POLICY_VERSION_LOCK" ]]; then
  echo "❌ Policy version mismatch between file and lock"
  echo "File:  $POLICY_VERSION_FILE"
  echo "Lock:  $POLICY_VERSION_LOCK"
  echo ""
  echo "Update .policy.lock via approved governance process."
  exit 1
fi

echo "✅ Policy version verified: $POLICY_VERSION_FILE"

# 4. If DATABASE_URL is set (CI with test DB), also validate seed consistency
if [[ -n "${DATABASE_URL:-}" ]]; then
  # Check if policy_versions table exists
  TABLE_EXISTS=$(psql "$DATABASE_URL" -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'policy_versions');" \
    | xargs 2>/dev/null || echo "f")

  if [[ "$TABLE_EXISTS" == "t" ]]; then
    DB_POLICY_VERSION=$(
      psql "$DATABASE_URL" -tAc \
        "SELECT id FROM policy_versions WHERE active = true;" \
      | xargs
    )

    if [[ -n "$DB_POLICY_VERSION" ]] && [[ "$POLICY_VERSION_FILE" != "$DB_POLICY_VERSION" ]]; then
      echo "⚠️  CI seed mismatch (update schema/v1/010_seed_policy.sql)"
      echo "File: $POLICY_VERSION_FILE"
      echo "Seed: $DB_POLICY_VERSION"
      # Warning only - seed is for testing, not authoritative
    else
      echo "✅ CI seed matches file"
    fi
  fi
fi