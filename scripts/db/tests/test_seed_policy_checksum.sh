#!/usr/bin/env bash
# ============================================================
# test_seed_policy_checksum.sh
# Tests the fail-fast logic in seed_policy_from_env.sh
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

TEST_VERSION="v9.9.9-test"
MATCH_CHECKSUM="chk_match_123"
MISMATCH_CHECKSUM="chk_mismatch_999"

PASS=0
FAIL=0

run_test_case() {
  local desc="$1"
  local version="$2"
  local checksum="$3"
  local should_fail="$4"

  echo -n "  $desc: "

  # Run the seed script in a subshell with env vars
  set +e
  OUTPUT=$(export POLICY_VERSION="$version" POLICY_CHECKSUM="$checksum"; \
           bash schema/seeds/ci/seed_policy_from_env.sh 2>&1)
  EXIT_CODE=$?
  set -e

  if [[ "$should_fail" == "true" ]]; then
    if [[ $EXIT_CODE -ne 0 ]]; then
      if echo "$OUTPUT" | grep -q "Policy checksum mismatch"; then
        echo "✅ PASS (Failed as expected with specific error)"
        ((PASS++))
      else
        echo "❌ FAIL (Failed but missing expected error message)"
        echo "output: $OUTPUT"
        ((FAIL++))
      fi
    else
      echo "❌ FAIL (Expected failure, but succeeded)"
      ((FAIL++))
    fi
  else
    if [[ $EXIT_CODE -eq 0 ]]; then
      echo "✅ PASS"
      ((PASS++))
    else
      echo "❌ FAIL (Unexpected failure)"
      echo "output: $OUTPUT"
      ((FAIL++))
    fi
  fi
}

echo "==> Testing Policy Seeding Logic"


# Get current active policy
EXISTING_POLICY=$(psql "$DATABASE_URL" -t -A -c "SELECT version||'|'||checksum FROM policy_versions WHERE is_active = true LIMIT 1;")

if [[ -z "$EXISTING_POLICY" ]]; then
  echo "⚠️  No active policy found. Cannot test conflict logic against existing row."
  echo "   Skipping tests that require existing active policy."
else
  # Extract version and checksum
  IFS='|' read -r CURRENT_VERSION CURRENT_CHECKSUM <<< "$EXISTING_POLICY"
  
  echo "ℹ️  Found active policy: $CURRENT_VERSION (checksum: ${CURRENT_CHECKSUM:0:8}...)"

  # 1. Idempotent Seed (Same Checksum)
  # Should succeed (no-op)
  run_test_case "Idempotent seed (match)" "$CURRENT_VERSION" "$CURRENT_CHECKSUM" "false"

  # 2. Mismatch Seed (Different Checksum)
  # Should fail with specific error
  FAKE_CHECKSUM="mismatch_checksum_$(date +%s)"
  run_test_case "Checksum mismatch (diff)" "$CURRENT_VERSION" "$FAKE_CHECKSUM" "true"
fi

echo ""
echo "Summary: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then exit 1; fi
