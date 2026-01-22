#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$ROOT/reports/outbox-evidence"
DB_URL="${OUTBOX_EVIDENCE_DB_URL:-${DATABASE_URL:-}}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

write_placeholder() {
  local path="$1"
  local message="$2"
  cat >"$path" <<EOF
-- ${message}
EOF
}

if [[ -n "$DB_URL" ]] && command -v psql >/dev/null 2>&1; then
  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT table_schema, table_name, privilege_type, grantee
     FROM information_schema.role_table_grants
     WHERE table_schema = 'public'
       AND table_name IN ('payment_outbox_pending','payment_outbox_attempts')
     ORDER BY 1,2,3,4;" >"$OUT_DIR/01_grants.tsv"

  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT routine_schema, routine_name, privilege_type, grantee
     FROM information_schema.role_routine_grants
     WHERE routine_schema = 'public'
       AND routine_name IN (
       'enqueue_payment_outbox',
       'claim_outbox_batch',
       'complete_outbox_attempt',
       'repair_expired_leases',
       'deny_outbox_attempts_mutation'
     )
     ORDER BY 1,2,3,4;" >>"$OUT_DIR/01_grants.tsv"

  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT pg_get_functiondef(p.oid)
     FROM pg_proc p
     JOIN pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN (
         'enqueue_payment_outbox',
         'claim_outbox_batch',
         'complete_outbox_attempt',
         'repair_expired_leases',
         'deny_outbox_attempts_mutation'
       )
     ORDER BY p.proname, p.oid;" >"$OUT_DIR/02_functions.sql"

  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT c.conname, pg_get_constraintdef(c.oid)
     FROM pg_constraint c
     JOIN pg_class t ON t.oid = c.conrelid
     WHERE t.relname IN ('payment_outbox_pending','payment_outbox_attempts')
     ORDER BY 1;" >"$OUT_DIR/03_invariants.sql"

  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT indexname, indexdef
     FROM pg_indexes
     WHERE schemaname = 'public'
       AND tablename IN ('payment_outbox_pending','payment_outbox_attempts')
     ORDER BY 1;" >>"$OUT_DIR/03_invariants.sql"
  psql "$DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
    "SELECT tgname, pg_get_triggerdef(oid)
     FROM pg_trigger
     WHERE tgrelid = 'public.payment_outbox_attempts'::regclass
       AND NOT tgisinternal
     ORDER BY 1;" >>"$OUT_DIR/03_invariants.sql"
else
  write_placeholder "$OUT_DIR/01_grants.tsv" "TODO: set OUTBOX_EVIDENCE_DB_URL or DATABASE_URL and re-run to capture grants."
  write_placeholder "$OUT_DIR/02_functions.sql" "TODO: set OUTBOX_EVIDENCE_DB_URL or DATABASE_URL and re-run to capture function definitions."
  write_placeholder "$OUT_DIR/03_invariants.sql" "TODO: set OUTBOX_EVIDENCE_DB_URL or DATABASE_URL and re-run to capture constraints/indexes."
fi

if [[ -f "$ROOT/schema/views/outbox_status_view.sql" ]]; then
  cp "$ROOT/schema/views/outbox_status_view.sql" "$OUT_DIR/04_views.sql"
else
  write_placeholder "$OUT_DIR/04_views.sql" "TODO: schema/views/outbox_status_view.sql not found."
fi

cat >"$OUT_DIR/05_tests_manifest.txt" <<'EOF'
# Outbox proof/test manifest (deterministic)

Unit:
- tests/unit/outboxAppendOnlyTrigger.spec.ts (expects SQLSTATE P0001 on UPDATE/DELETE)
- tests/unit/leaseRepairProof.spec.ts
- tests/unit/OutboxRelayer.spec.ts

Integration (DB-gated):
- tests/integration/outboxLeaseLossProof.spec.ts (expects SQLSTATE P7002 on stale lease completion)
- tests/integration/outboxCompleteConcurrencyProof.spec.ts (expects SQLSTATE P7002 on losers)
- tests/integration/outboxConcurrency.test.ts

Optional regression query:
SELECT COUNT(*) FROM payment_outbox_attempts WHERE state='DISPATCHING';
EOF

# Copy authoritative migration files for evidence
if [[ -f "$ROOT/schema/migrations/0001_init.sql" ]]; then
  cp "$ROOT/schema/migrations/0001_init.sql" "$OUT_DIR/06_schema_0001_init.sql"
fi
# Note: Privileges will be in a separate migration (e.g., 0002_privileges.sql)
# once created during fix-forward phase

echo "[reports] Wrote outbox evidence bundle to $OUT_DIR"
