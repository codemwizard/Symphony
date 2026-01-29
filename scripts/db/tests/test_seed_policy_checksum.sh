#!/usr/bin/env bash
# ============================================================
# test_seed_policy_checksum.sh
# Tests the fail-fast logic in seed_policy_from_env.sh (Phase 1 semantics)
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

TEST_VERSION="v9.9.9-test"
MATCH_CHECKSUM="chk_match_123"
MISMATCH_CHECKSUM="chk_mismatch_999"
CREATED_TEST_POLICY=0

PASS=0
FAIL=0

psqlq() { psql "$DATABASE_URL" -t -A -X -v ON_ERROR_STOP=1 -c "$1"; }
active_tuple() { psqlq "SELECT version||'|'||checksum FROM public.policy_versions WHERE is_active = true LIMIT 1;"; }
total_rows() { psqlq "SELECT count(*) FROM public.policy_versions;"; }
version_rows() { local v="$1"; psqlq "SELECT count(*) FROM public.policy_versions WHERE version = '${v}';"; }

cleanup() {
  if [[ "$CREATED_TEST_POLICY" -ne 1 ]]; then
    return
  fi
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
DELETE FROM public.policy_versions WHERE version = '${TEST_VERSION}';
SQL
}
trap cleanup EXIT

assert_no_side_effects() {
  local baseline_active="$1"
  local baseline_total="$2"
  local baseline_vcount="$3"
  local v="$4"

  local now_active now_total now_vcount
  now_active="$(active_tuple)"
  now_total="$(total_rows)"
  now_vcount="$(version_rows "$v")"

  if [[ "$now_active" != "$baseline_active" ]]; then
    echo "❌ FAIL (Side effect: ACTIVE policy changed)"
    echo "  baseline_active=$baseline_active"
    echo "  now_active=$now_active"
    FAIL=$((FAIL+1))
    return 1
  fi
  if [[ "$now_total" != "$baseline_total" ]]; then
    echo "❌ FAIL (Side effect: row count changed)"
    echo "  baseline_total=$baseline_total now_total=$now_total"
    FAIL=$((FAIL+1))
    return 1
  fi
  if [[ "$now_vcount" != "$baseline_vcount" ]]; then
    echo "❌ FAIL (Side effect: version row count changed for $v)"
    echo "  baseline_vcount=$baseline_vcount now_vcount=$now_vcount"
    FAIL=$((FAIL+1))
    return 1
  fi
  return 0
}

run_test_case() {
  local desc="$1"
  local version="$2"
  local checksum="$3"
  local expect_exit="$4"
  local expect_pattern="${5:-}"
  local baseline_active="$6"
  local baseline_total="$7"
  local baseline_vcount="$8"
  local assert_version="$9"

  echo -n "  $desc: "

  # Run the seed script in a subshell with env vars
  set +e
  OUTPUT=$(export POLICY_VERSION="$version" POLICY_CHECKSUM="$checksum"; \
           unset SEED_POLICY_VERSION SEED_POLICY_CHECKSUM; \
           bash schema/seeds/ci/seed_policy_from_env.sh 2>&1)
  EXIT_CODE=$?
  set -e

  if [[ "$expect_exit" == "0" ]]; then
    if [[ $EXIT_CODE -ne 0 ]]; then
      echo "❌ FAIL (Unexpected failure)"
      echo "output: $OUTPUT"
      FAIL=$((FAIL+1))
      return
    fi
  else
    if [[ $EXIT_CODE -eq 0 ]]; then
      echo "❌ FAIL (Expected failure, but succeeded)"
      FAIL=$((FAIL+1))
      return
    fi
    if [[ -n "$expect_pattern" ]]; then
      if ! echo "$OUTPUT" | grep -Eq "$expect_pattern"; then
        echo "❌ FAIL (Failed but missing expected error message)"
        echo "expected_pattern: $expect_pattern"
        echo "output: $OUTPUT"
        FAIL=$((FAIL+1))
        return
      fi
    fi
  fi

  if ! assert_no_side_effects "$baseline_active" "$baseline_total" "$baseline_vcount" "$assert_version"; then
    echo "output: $OUTPUT"
    return
  fi

  echo "✅ PASS"
  PASS=$((PASS+1))
}

echo "==> Testing Policy Seeding Logic"


# Get current active policy
EXISTING_POLICY="$(active_tuple)"

if [[ -z "$EXISTING_POLICY" ]]; then
  echo "ℹ️  No active policy found. Attempting to seed from policy file."
  if [[ -x schema/seeds/dev/seed_policy_from_file.sh ]]; then
    schema/seeds/dev/seed_policy_from_file.sh || true
  fi
  EXISTING_POLICY="$(active_tuple)"
fi

if [[ -z "$EXISTING_POLICY" ]]; then
  echo "ℹ️  Still no active policy found. Inserting test ACTIVE policy for checksum tests."
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X <<SQL
INSERT INTO public.policy_versions (version, status, checksum)
VALUES ('${TEST_VERSION}', 'ACTIVE', '${MATCH_CHECKSUM}')
ON CONFLICT (version) DO NOTHING;
SQL
  EXISTING_POLICY="${TEST_VERSION}|${MATCH_CHECKSUM}"
  CREATED_TEST_POLICY=1
fi

# Extract version and checksum
IFS='|' read -r CURRENT_VERSION CURRENT_CHECKSUM <<< "$EXISTING_POLICY"

echo "ℹ️  Found active policy: $CURRENT_VERSION (checksum: ${CURRENT_CHECKSUM:0:8}...)"

# Baselines for side-effect assertions
BASE_ACTIVE="$(active_tuple)"
BASE_TOTAL="$(total_rows)"
BASE_VCOUNT="$(version_rows "$CURRENT_VERSION")"

# Pick an alternative version for "different version" test
ALT_VERSION="${TEST_VERSION}"
if [[ "$ALT_VERSION" == "$CURRENT_VERSION" ]]; then
  ALT_VERSION="v9.9.8-test"
fi

# 1) Idempotent seed (same version + same checksum) -> must succeed, no changes
run_test_case \
  "Idempotent seed (match)" \
  "$CURRENT_VERSION" "$CURRENT_CHECKSUM" \
  "0" "" \
  "$BASE_ACTIVE" "$BASE_TOTAL" "$BASE_VCOUNT" "$CURRENT_VERSION"

# 2) Same version + different checksum -> must fail closed with checksum mismatch message; no changes
FAKE_CHECKSUM="mismatch_checksum_$(date +%s)"
run_test_case \
  "Checksum mismatch (diff)" \
  "$CURRENT_VERSION" "$FAKE_CHECKSUM" \
  "nonzero" "Policy checksum mismatch" \
  "$BASE_ACTIVE" "$BASE_TOTAL" "$BASE_VCOUNT" "$CURRENT_VERSION"

# 3) Different version while an ACTIVE exists -> must fail closed (Phase 1: no rotation)
run_test_case \
  "Different version blocked (Phase 1 no-rotation)" \
  "$ALT_VERSION" "$MATCH_CHECKSUM" \
  "nonzero" "Active policy already exists" \
  "$BASE_ACTIVE" "$BASE_TOTAL" "$BASE_VCOUNT" "$CURRENT_VERSION"

echo ""
echo "Summary: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo "exit code 1"
  exit 1
fi
echo "exit code 0"
