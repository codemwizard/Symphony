# TSK-P2-PREAUTH-007-15 PLAN — INV-175 & INV-176 DB Verifiers

Task: TSK-P2-PREAUTH-007-15
Owner: SECURITY_GUARDIAN
Gap Source: G-06, G-07, G-12 (W7_GAP_ANALYSIS.md lines 164-165, 170)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-15.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any regulated file without prior approval metadata.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Create dedicated DB-querying verifier scripts for INV-175 (Data Authority Enforced) and INV-176 (State Machine Enforced). These replace the existing grep-based YAML manifest verifiers with real `SERIALIZABLE` negative tests against the live database.

**What Exists Today (from G-06, G-12):**
- `verify_tsk_p2_preauth_007_02.sh` only checks `grep -A 5 "id: INV-175" INVARIANTS_MANIFEST.yml` — this is NOT enforcement.
- `verify_tsk_p2_preauth_007_03.sh` delegates to a Wave 5 structural verifier that checks trigger existence and SECURITY DEFINER status, but performs NO behavioral test.
- No dedicated `verify_inv_175.sh` or `verify_inv_176.sh` scripts exist anywhere in the repository.

**What Must Be Built:**
- Dedicated invariant-specific verifier scripts that query DB state directly.
- Each must use `SERIALIZABLE READ ONLY DEFERRABLE` isolation for read checks.
- Mutation-based negative tests execute in isolated rollback transactions.
- Zero persistent side effects.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.
- [ ] `state_transitions` table exists with `data_authority` column (NOT NULL, ENUM `data_authority_level`).
- [ ] Triggers on `state_transitions` exist and are functional.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_preauth_007_15.sh` | CREATE | Combined verifier for INV-175 and INV-176 |
| `evidence/phase2/tsk_p2_preauth_007_15.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If verifier checks YAML manifest instead of database** → STOP
- **If negative tests use default transaction isolation** → STOP (must be SERIALIZABLE)
- **If negative tests leave persistent data in the database** → STOP (must ROLLBACK)

---

## Implementation Steps

### Step 1: INV-175 Verifier Logic (Data Authority Enforced)

**Corrected Column Reference (from G-02):**
- Column name is `data_authority` (NOT `data_authority_level`)
- ENUM type is `data_authority_level` with values: `phase1_indicative_only`, `non_reproducible`, `derived_unverified`, `policy_bound_unsigned`, `authoritative_signed`, `superseded`, `invalidated`
- The spec value `policy_authoritative` does NOT exist — correct value is `authoritative_signed`

**Positive Test:**
```sql
-- Verify the column exists and is NOT NULL
SELECT column_name, is_nullable, data_type
FROM information_schema.columns
WHERE table_name = 'state_transitions' AND column_name = 'data_authority';
-- Expected: is_nullable = 'NO'
```

**Negative Test (from G-07, line 165):**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Attempt to INSERT a row with data_authority='authoritative_signed' but execution_id=NULL
-- This must be REJECTED by the table's NOT NULL constraint or trigger
INSERT INTO state_transitions (
  -- ... required columns ...
  data_authority, execution_id
) VALUES (
  'authoritative_signed', NULL
);
-- If we reach here, the test FAILED — authoritative rows without execution_id should be blocked
ROLLBACK;
```

### Step 2: INV-176 Verifier Logic (State Machine Enforced)

**What Must Be Proven (from G-12, line 170):**
The real bug is a scope delegation error — Wave 7 delegates INV-176 enforcement to a Wave 5 structural verifier that only checks trigger existence. It performs NO behavioral test. The verifier must prove that an invalid state transition is actually rejected.

**Positive Test:**
```sql
-- Verify the state machine trigger exists
SELECT tgname FROM pg_trigger
WHERE tgrelid = 'state_transitions'::regclass
  AND tgname = 'ai_01_update_current_state';
-- Expected: row returned
```

**Negative Test (from G-07, line 165):**
```sql
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Attempt to INSERT an invalid (from_state, to_state) pair
-- This must be REJECTED by the state machine trigger
INSERT INTO state_transitions (
  -- ... required columns ...
  from_state, to_state
) VALUES (
  'completed', 'draft'  -- Invalid backwards transition
);
-- If we reach here, the test FAILED — the state machine did not reject the transition
ROLLBACK;
```

### Step 3: Script Harness

The verifier script must:
1. Use `DATABASE_URL` environment variable.
2. Run each positive check in a `SERIALIZABLE READ ONLY DEFERRABLE` transaction.
3. Run each negative test in its own `BEGIN; ... ROLLBACK;` block.
4. Emit structured JSON evidence with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`.
5. Exit 0 only if ALL positive checks pass AND ALL negative tests are correctly rejected.

### Step 4: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_15.sh > evidence/phase2/tsk_p2_preauth_007_15.json
```

### Step 5: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.
