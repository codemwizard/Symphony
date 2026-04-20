#!/usr/bin/env bash
set -euo pipefail

# test_execution_truth_anchor_smoke.sh
#
# Task: TSK-P2-PREAUTH-003-REM-05
#
# Negative harness that drives verify_execution_truth_anchor.sh against a
# deliberately-degraded database state. For each degradation we disable one
# of the seven proof surfaces, assert the verifier exits non-zero, then
# restore the original state. The overall harness exits 0 only when every
# degradation is detected.

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

VERIFIER="scripts/db/verify_execution_truth_anchor.sh"
FAIL=0

expect_verifier_fail() {
    local label="$1"
    if PRE_CI_CONTEXT=1 bash "$VERIFIER" >/dev/null 2>&1; then
        echo "  FAIL ($label): verifier exited 0 but state is degraded"
        FAIL=1
    else
        echo "  OK ($label): verifier exited non-zero as expected"
    fi
}

# Each scenario wraps an ALTER in a DO block that we undo afterwards.

# Scenario 1: drop append-only trigger
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DROP TRIGGER execution_records_append_only_trigger ON public.execution_records;" >/dev/null
expect_verifier_fail "append_only_trigger_dropped"
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "
  CREATE TRIGGER execution_records_append_only_trigger
  BEFORE UPDATE OR DELETE ON public.execution_records
  FOR EACH ROW EXECUTE FUNCTION public.execution_records_append_only();" >/dev/null

# Scenario 2: drop temporal-binding trigger
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "DROP TRIGGER execution_records_temporal_binding_trigger ON public.execution_records;" >/dev/null
expect_verifier_fail "temporal_binding_trigger_dropped"
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "
  CREATE TRIGGER execution_records_temporal_binding_trigger
  BEFORE INSERT ON public.execution_records
  FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_interpretation_temporal_binding();" >/dev/null

# Scenario 3: relax NOT NULL on interpretation_version_id
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id DROP NOT NULL;" >/dev/null
expect_verifier_fail "interpretation_version_id_nullable"
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id SET NOT NULL;" >/dev/null

# Scenario 4: drop UNIQUE determinism constraint
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "ALTER TABLE public.execution_records DROP CONSTRAINT execution_records_determinism_unique;" >/dev/null
expect_verifier_fail "determinism_unique_dropped"
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "
  ALTER TABLE public.execution_records
  ADD CONSTRAINT execution_records_determinism_unique
  UNIQUE (input_hash, interpretation_version_id, runtime_version);" >/dev/null

# Scenario 5: relax search_path on trigger function
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "ALTER FUNCTION public.execution_records_append_only() RESET search_path;" >/dev/null
expect_verifier_fail "search_path_unset"
psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -c "ALTER FUNCTION public.execution_records_append_only() SET search_path = pg_catalog, public;" >/dev/null

exit $FAIL
