# TSK-P2-W5-FIX-12 PLAN — Convert verifiers from structural-only to behavioral

Task: TSK-P2-W5-FIX-12
Owner: QA_VERIFIER
Depends on: TSK-P2-W5-FIX-11
failure_signature: P2.W5-FIX.STRUCTURAL-ONLY.GOVERNANCE_THEATER
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Existing Wave 5 verifier scripts perform structural-only checks (table exists, column
exists, trigger exists) without live INSERT behavioral tests. A verifier that says "table
exists" without proving "INSERT with bad data is rejected" is governance theater. After
this task, each verifier includes at least one live INSERT behavioral test within a
transaction (BEGIN/ROLLBACK) and at least one negative test.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-11 status=completed.
- [ ] All schema fixes (FIX-01 through FIX-09) applied.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_tsk_p2_preauth_005_{00..08}.sh` | MODIFY | Add behavioral tests |
| `evidence/phase2/tsk_p2_w5_fix_12.json` | CREATE | Evidence |

---

## Implementation Steps

### Step 1: Classify Each Verifier
**What:** `[ID w5_fix_12_work_01]` Audit all 9 verifiers. For each, determine:
- Does it run `psql "$DATABASE_URL"` with a live query? (structural)
- Does it execute INSERT/UPDATE/DELETE? (behavioral)
- Does it have a negative test? (adversarial)

Record classification in EXEC_LOG.md.

### Step 2: Add Behavioral Tests
**What:** `[ID w5_fix_12_work_02]` For each structural-only verifier, add:
```bash
# Behavioral test in transaction
psql "$DATABASE_URL" <<'BEHAVIORAL_TEST'
BEGIN;
-- Setup: create test data
-- Positive test: valid INSERT must succeed
-- Negative test: invalid INSERT must fail
ROLLBACK;
BEHAVIORAL_TEST
```

### Step 3: Add Negative Tests
**What:** `[ID w5_fix_12_work_03]` Each verifier must include at least one case where the system correctly rejects invalid input.

### Step 4-5: Run all verifiers, generate evidence, update EXEC_LOG.

---

## Verification

```bash
for v in scripts/db/verify_tsk_p2_preauth_005_*.sh; do bash "$v" || exit 1; done
test -f evidence/phase2/tsk_p2_w5_fix_12.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_12.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, verifiers_upgraded, behavioral_tests_added

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Verifier wraps structural check | Still governance theater | Verify INSERT exists in script |
| Behavioral test not in transaction | Test data persists | ROLLBACK guard |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
