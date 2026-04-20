#!/usr/bin/env bash
# ============================================================
# test_execution_truth_anchor_smoke.sh
# Task: TSK-P2-PREAUTH-003-REM-05 (work item 2)
#
# Degradation harness: drives scripts/db/verify_execution_truth_anchor.sh
# against a deliberately-weakened database state and asserts the verifier
# exits non-zero for each scenario. The harness itself exits 0 only when
# ALL seven degradations produce verifier-non-zero. This proves the
# verifier is not fail-open on any of its seven proof surfaces.
#
# Each scenario applies its DDL inside a SAVEPOINT-like block and restores
# the state afterwards. If any restore fails, the harness aborts loudly so
# a human inspects before CI continues.
# ============================================================
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERIFIER="$ROOT_DIR/scripts/db/verify_execution_truth_anchor.sh"
test -x "$VERIFIER" || { echo "ERR: verifier not executable: $VERIFIER" >&2; exit 1; }

FK_NAME="execution_records_interpretation_version_id_fkey"

apply_sql() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "$1" >/dev/null; }

assert_verifier_fails() {
    local label="$1"
    set +e
    bash "$VERIFIER" >/dev/null 2>&1
    local rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
        echo "FAIL: scenario $label — verifier exited 0 on degraded state" >&2
        return 1
    fi
    echo "PASS: scenario $label — verifier rc=$rc"
    return 0
}

run_scenario() {
    local label="$1"
    local degrade_sql="$2"
    local restore_sql="$3"

    echo "==> scenario $label"
    apply_sql "$degrade_sql"
    local ok=1
    if ! assert_verifier_fails "$label"; then
        ok=0
    fi
    if ! apply_sql "$restore_sql"; then
        echo "CRITICAL: scenario $label restore failed — DB may be in degraded state" >&2
        exit 2
    fi
    [[ $ok -eq 1 ]] || return 1
    return 0
}

# Scenario 1: drop NOT NULL on interpretation_version_id
run_scenario "1/not_null_drop" \
    "ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id DROP NOT NULL;" \
    "ALTER TABLE public.execution_records ALTER COLUMN interpretation_version_id SET NOT NULL;"

# Scenario 2: drop UNIQUE determinism constraint
run_scenario "2/unique_drop" \
    "ALTER TABLE public.execution_records DROP CONSTRAINT execution_records_determinism_unique;" \
    "ALTER TABLE public.execution_records ADD CONSTRAINT execution_records_determinism_unique UNIQUE (tenant_id, input_hash, interpretation_version_id, runtime_version);"

# Scenario 3: drop FK to interpretation_packs
run_scenario "3/fk_drop" \
    "ALTER TABLE public.execution_records DROP CONSTRAINT $FK_NAME;" \
    "ALTER TABLE public.execution_records ADD CONSTRAINT $FK_NAME FOREIGN KEY (interpretation_version_id) REFERENCES public.interpretation_packs(interpretation_pack_id) ON DELETE RESTRICT;"

# Scenario 4: drop append-only trigger
run_scenario "4/append_only_trigger_drop" \
    "DROP TRIGGER execution_records_append_only_trigger ON public.execution_records;" \
    "CREATE TRIGGER execution_records_append_only_trigger BEFORE UPDATE OR DELETE ON public.execution_records FOR EACH ROW EXECUTE FUNCTION public.execution_records_append_only();"

# Scenario 5: drop temporal-binding trigger
run_scenario "5/temporal_binding_trigger_drop" \
    "DROP TRIGGER execution_records_temporal_binding_trigger ON public.execution_records;" \
    "CREATE TRIGGER execution_records_temporal_binding_trigger BEFORE INSERT ON public.execution_records FOR EACH ROW EXECUTE FUNCTION public.enforce_execution_interpretation_temporal_binding();"

# Scenario 6: flip SECURITY DEFINER to SECURITY INVOKER on append-only function
run_scenario "6/security_invoker" \
    "ALTER FUNCTION public.execution_records_append_only() SECURITY INVOKER;" \
    "ALTER FUNCTION public.execution_records_append_only() SECURITY DEFINER;"

# Scenario 7: reset search_path on temporal-binding function
run_scenario "7/search_path_reset" \
    "ALTER FUNCTION public.enforce_execution_interpretation_temporal_binding() RESET search_path;" \
    "ALTER FUNCTION public.enforce_execution_interpretation_temporal_binding() SET search_path = pg_catalog, public;"

# Sanity: after all restores, the verifier must pass again
bash "$VERIFIER" >/dev/null 2>&1 || { echo "FAIL: post-restore verifier rc != 0 — state not cleanly restored" >&2; exit 1; }

echo "PASS: all 7 degradation scenarios caught; verifier clean post-restore"
