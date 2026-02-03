# Phase 0001-0005 Implementation Plan

**Phase Key:** 0001-0005  
**Phase Name:** Database Foundation

---

## Goal

Establish the database foundation for Symphony with mechanically enforced invariants, comprehensive testing, and CI integration.

## Proposed Changes

### Database Migrations

#### [MODIFY] `schema/migrations/0001_init.sql`
- Bootstrap core tables and append-only guardrails
- Search path hardening for SECURITY DEFINER

#### [MODIFY] `schema/migrations/0002_outbox_functions.sql`
- Outbox enqueue/claim/complete functions
- Strict lease fencing + idempotency

#### [MODIFY] `schema/migrations/0003_roles.sql`
- NOLOGIN runtime roles

#### [MODIFY] `schema/migrations/0004_privileges.sql`
- Revoke-first privilege posture

#### [MODIFY] `schema/migrations/0005_policy_versions.sql`
- Policy versions + single ACTIVE enforcement

#### [MODIFY] `schema/migrations/0006_repair_expired_leases_retry_ceiling.sql`
- Repair zombie leases + retry ceiling controls

#### [MODIFY] `schema/migrations/0007_outbox_pending_indexes.sql`
- Baseline due-claim index

#### [NEW] `schema/migrations/0008_outbox_terminal_uniqueness.sql`
- One terminal attempt per outbox_id (DISPATCHED/FAILED)

#### [MODIFY] `schema/migrations/0009_pending_fillfactor.sql`
- MVCC posture (fillfactor)

#### [NEW] `schema/migrations/0010_outbox_notify.sql`
- NOTIFY wakeup hook (wakeup-only)

#### [NEW] `schema/migrations/0011_ingress_attestations.sql`
- Append-only ingress attestation ledger

#### [NEW] `schema/migrations/0012_revocation_tables.sql`
- Append-only revocation tables (certs + tokens)

#### [NEW] `schema/migrations/0013_outbox_pending_indexes_concurrently.sql`
- no-tx CONCURRENTLY index for hot table

---

### Test Suite

#### [NEW] `scripts/db/tests/test_db_functions.sh`
10 tests including terminal uniqueness + NOTIFY emission.

#### [NEW] `scripts/db/tests/test_idempotency_zombie.sh`
Zombie replay/idempotency simulation.

#### [NEW] `scripts/db/tests/test_no_tx_migrations.sh`
No-tx marker support verification.

#### [NEW] `scripts/db/tests/test_outbox_pending_indexes.sh`
Due-claim index verification.

---

### CI Integration

#### [MODIFY] `.github/workflows/invariants.yml`
- Runs invariants fast checks, DB verify, and DB tests

## Verification Plan

### Automated Tests
```bash
# Run core DB tests
scripts/db/tests/test_db_functions.sh
scripts/db/tests/test_idempotency_zombie.sh
scripts/db/tests/test_no_tx_migrations.sh
scripts/db/tests/test_outbox_pending_indexes.sh
```

### CI Verification
DB verification and tests run automatically on every push/PR.
