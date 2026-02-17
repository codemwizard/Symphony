# Phase 0001-0005 Task Checklist

**Phase Key:** 0001-0005  
**Phase Name:** Database Foundation  
**Status:** ✅ COMPLETE

---

## Core Implementation

- [x] Migration 0001: Init with uuid_strategy()
- [x] Migration 0002: Payment outbox with append-only trigger
- [x] Migration 0003: Policy versions with is_active flag
- [x] Migration 0004: Ledger entries with monotonic sequences
- [x] Migration 0005: Outbox functions (retry ceiling, sequence management)

## Invariant Verification

- [x] Create `scripts/db/tests/test_db_functions.sh`
- [x] Test 1: uuid_strategy function exists
- [x] Test 2: uuid_strategy returns known strategy
- [x] Test 3: allocate_outbox_sequence monotonic (CTE pattern)
- [x] Test 4: retry ceiling finite (max_retries ≤ 10)
- [x] Test 5: append-only trigger exists
- [x] Test 6: policy_versions.is_active column exists
- [x] Test 7: **Exactly one ACTIVE policy** at boot (strengthened)
- [x] Test 8: No PUBLIC privileges on core tables

## CI Integration

- [x] Add DB function tests step to `.github/workflows/invariants.yml`
- [x] Tests run after `verify_invariants.sh` in `db_verify_invariants` job

## Documentation

- [x] Phase documents moved to `Phase_0001-0005/` directory
- [x] Final walkthrough created with verification evidence

---

## Unit Tests Created/Run

| Test | File | Result |
|------|------|--------|
| uuid_strategy exists | `test_db_functions.sh` | ✅ PASS |
| uuid_strategy known value | `test_db_functions.sh` | ✅ PASS |
| monotonic sequence | `test_db_functions.sh` | ✅ PASS |
| retry ceiling finite | `test_db_functions.sh` | ✅ PASS |
| append-only trigger | `test_db_functions.sh` | ✅ PASS |
| is_active column | `test_db_functions.sh` | ✅ PASS |
| exactly one active policy | `test_db_functions.sh` | ✅ PASS |
| no PUBLIC privileges | `test_db_functions.sh` | ✅ PASS |
