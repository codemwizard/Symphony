# Policy Seed Phase 1: Implementation Plan and Tasks

## Goal
Make policy seeding Phase-1 correct and deterministic in minimal environments:
- Exactly one ACTIVE policy is allowed.
- Seeding is idempotent when the ACTIVE version matches and checksum matches.
- Seeding fails closed if a different ACTIVE version exists.
- Checksum tests detect the correct failure mode and assert no side effects.
- Tests are immune to environment variable bleed and report clear summaries.

## Scope
Patches covered by this plan:
- `schema/seeds/ci/seed_policy_from_env.sh`
- `scripts/db/tests/test_seed_policy_checksum.sh`

## Non-Goals
- Phase 2 policy rotation (GRACE/RETIRED flows).
- Altering schema or migration logic.
- Changing production seeding mechanisms beyond Phase 1 invariants.

## Implementation Plan
1) Phase-1 correct seeding logic in CI seed script
   - Read existing ACTIVE policy (version + checksum).
   - If ACTIVE exists and version differs: fail closed with explicit error.
   - If ACTIVE exists and version matches: validate checksum and return success.
   - When an ACTIVE policy exists, do not attempt any INSERT with status='ACTIVE'.
   - If no ACTIVE exists: insert ACTIVE (idempotent) and validate checksum.
   - Ensure `POLICY_*` overrides `SEED_*` when both are present.
   - Error messages must be stable for tests:
     - Must contain exactly: `Policy checksum mismatch`
     - Must contain exactly: `Active policy already exists`

2) Harden checksum tests to validate behavior, not just exit codes
   - Use explicit expected error strings (checksum mismatch, active version conflict).
   - Add a third test for "different version while ACTIVE exists".
   - Assert no side effects after each run:
     - ACTIVE (version, checksum) unchanged.
     - Total rows unchanged.
     - Row count for active version unchanged.
   - Ensure test runs even when DB is initially unseeded:
     - Attempt dev seed.
     - If still empty, insert a test ACTIVE row and clean it up after the test.

3) Validate test stability and output formatting
   - Confirm both test suites end with:
     - `Summary: N passed, 0 failed`
     - `exit code 0`
   - Ensure failures show `exit code 1` and a deterministic error.

## Tasks List
### A) Seed script correctness (CI)
- [ ] Update `schema/seeds/ci/seed_policy_from_env.sh` with Phase-1 ACTIVE logic:
      - Detect existing ACTIVE row.
      - Fail closed on different version.
      - Verify checksum on match.
      - Insert ACTIVE only when none exists.
- [ ] Ensure `POLICY_*` takes precedence over `SEED_*`.
- [ ] Keep errors explicit and stable for test assertions.

### B) Checksum test hardening
- [ ] Add helpers for DB queries (active tuple, total rows, version row counts).
- [ ] Add "no side effects" assertions after each test case.
- [ ] Add 3rd test case: different version blocked (Phase 1 no-rotation).
- [ ] Ensure `SEED_*` is unset before invoking the seed script.
- [ ] Ensure cleanup only removes test-inserted row.

### C) Verification
- [ ] Run: `bash -x scripts/db/tests/test_seed_policy_checksum.sh`
      - Expect: `3 passed, 0 failed` and `exit code 0`.
- [ ] Run: `scripts/db/tests/test_db_functions.sh`
      - Expect: `Summary: N passed, 0 failed` and `exit code 0`.
- [ ] Run: `scripts/dev/pre_ci.sh`
      - Expect: DB function tests pass, checksum tests pass, and no flakiness.

## Success Criteria
- Seeding fails closed on different ACTIVE version with a clear message.
- Idempotent seeding succeeds when version/checksum match.
- Checksum mismatch fails with the specific message.
- No test leaves residual policy rows behind.
- Pre-CI run is stable and consistently green.
- Seeding logic is deterministic even when `SEED_*` vars are exported.
