# Phase 0001-0005 Implementation Plan

**Phase Key:** 0001-0005  
**Phase Name:** Database Foundation

---

## Goal

Establish the database foundation for Symphony with mechanically enforced invariants, comprehensive testing, and CI integration.

## Proposed Changes

### Database Migrations

#### [MODIFY] [0001_init.sql](file:///home/mwiza/workspaces/Symphony/schema/migrations/0001_init.sql)
- Bootstrap with `uuid_strategy()` function
- Search path hardening for SECURITY DEFINER

#### [MODIFY] [0002_outbox.sql](file:///home/mwiza/workspaces/Symphony/schema/migrations/0002_outbox.sql)
- Payment outbox table with append-only trigger
- Prevents DELETE/UPDATE operations

#### [MODIFY] [0003_policy.sql](file:///home/mwiza/workspaces/Symphony/schema/migrations/0003_policy.sql)
- Policy versions with `is_active` flag
- Exactly one active policy enforced at boot

#### [MODIFY] [0004_ledger.sql](file:///home/mwiza/workspaces/Symphony/schema/migrations/0004_ledger.sql)
- Ledger entries with monotonic sequences

#### [MODIFY] [0005_outbox_functions.sql](file:///home/mwiza/workspaces/Symphony/schema/migrations/0005_outbox_functions.sql)
- `allocate_outbox_sequence()` for monotonic allocation
- Retry ceiling enforcement (max_retries ≤ 10)

---

### Test Suite

#### [NEW] [test_db_functions.sh](file:///home/mwiza/workspaces/Symphony/scripts/db/tests/test_db_functions.sh)
8 comprehensive tests covering all DB invariants.

---

### CI Integration

#### [MODIFY] [invariants.yml](file:///home/mwiza/workspaces/Symphony/.github/workflows/invariants.yml)
- Added `Run DB function tests` step after `verify_invariants.sh`

## Verification Plan

### Automated Tests
```bash
# Run all DB function tests
scripts/db/tests/test_db_functions.sh
```

### CI Verification
DB tests run automatically in `db_verify_invariants` job on every push/PR.
