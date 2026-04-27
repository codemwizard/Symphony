# TSK-P2-W5-FIX-03 PLAN — Add FK constraints to state_transitions

Task: TSK-P2-W5-FIX-03
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-02
failure_signature: P2.W5-FIX.MISSING-FKS.REFERENTIAL_INTEGRITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Migration 0137 declared `execution_id UUID NOT NULL` and `policy_decision_id UUID NOT NULL`
on `state_transitions` but created no FOREIGN KEY constraints. The DoD mandates: "No soft
references. No we validate in code." After this task closes, two FK constraints will exist
at the DB level, and the evidence will prove that orphan INSERTs are rejected by PostgreSQL
constraint enforcement (SQLSTATE 23503), not by trigger logic alone.

---

## Architectural Context

FKs are positioned after FIX-02 because the authority trigger (FIX-01) and state rules
trigger (FIX-02) must be correct first — FK violations fire after trigger validation, and
testing FK enforcement on a function that crashes masks the FK behavior.

Anti-patterns guarded against:
- **ON DELETE CASCADE on append-only table**: `state_transitions` is immutable. Cascade deletes would silently destroy audit history.
- **Soft FK via trigger only**: Triggers can be disabled by superuser. DB-level FKs cannot.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-02 status=completed with passing evidence.
- [ ] `DATABASE_URL` set, MIGRATION_HEAD = 0146.
- [ ] No orphaned rows in state_transitions.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0147_add_fks_to_state_transitions.sql` | CREATE | Add FK constraints |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0147 |
| `scripts/db/verify_tsk_p2_w5_fix_03.sh` | CREATE | Behavioral FK rejection test |
| `evidence/phase2/tsk_p2_w5_fix_03.json` | CREATE | Evidence artifact |
| `docs/architecture/THREAT_MODEL.md` | MODIFY | Step 9: Structural change governance |
| `docs/architecture/COMPLIANCE_MAP.md` | MODIFY | Step 9: Compliance mapping |
| `schema/baseline.sql` | MODIFY | Step 10: Regenerated baseline |
| `schema/baselines/current/*` | MODIFY | Step 10: Regenerated baseline files |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Step 11: Governance entry |
| `evidence/phase0/*` | MODIFY | Step 13: Regenerated evidence |
| `tasks/TSK-P2-W5-FIX-03/meta.yml` | MODIFY | Update status |

---

## Stop Conditions

- **If orphaned rows exist** → STOP (precondition failure)
- **If FK uses ON DELETE CASCADE** → STOP (violates append-only guarantee)
- **If verifier does not attempt INSERT with orphan ID** → STOP
- **If baseline not regenerated** → STOP

---

## Implementation Steps

### Step 1: Orphan Row Audit
**What:** `[ID w5_fix_03_work_01]` Query for orphaned execution_id and policy_decision_id values.
**How:**
```sql
SELECT count(*) FROM state_transitions st
LEFT JOIN execution_records er ON st.execution_id = er.execution_id
WHERE er.execution_id IS NULL;

SELECT count(*) FROM state_transitions st
LEFT JOIN policy_decisions pd ON st.policy_decision_id = pd.policy_decision_id
WHERE pd.policy_decision_id IS NULL;
```
**Done when:** Both counts are 0 and recorded in EXEC_LOG.md.

### Step 2: Write Migration
**What:** `[ID w5_fix_03_work_02]` Create `0147_add_fks_to_state_transitions.sql`.
**How:**
```sql
-- Precondition: no orphaned rows
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM state_transitions st LEFT JOIN execution_records er
               ON st.execution_id = er.execution_id WHERE er.execution_id IS NULL) THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: orphaned execution_id rows exist';
    END IF;
    IF EXISTS (SELECT 1 FROM state_transitions st LEFT JOIN policy_decisions pd
               ON st.policy_decision_id = pd.policy_decision_id WHERE pd.policy_decision_id IS NULL) THEN
        RAISE EXCEPTION 'PRECONDITION FAILED: orphaned policy_decision_id rows exist';
    END IF;
END $$;

ALTER TABLE state_transitions
    ADD CONSTRAINT fk_st_execution_id
    FOREIGN KEY (execution_id) REFERENCES execution_records(execution_id);

ALTER TABLE state_transitions
    ADD CONSTRAINT fk_st_policy_decision_id
    FOREIGN KEY (policy_decision_id) REFERENCES policy_decisions(policy_decision_id);
```
**Done when:** Both constraints visible in `information_schema.table_constraints`.

### Step 3: Update MIGRATION_HEAD
**What:** `[ID w5_fix_03_work_03]` Update to 0147.

### Step 4: Write Verification Script
**What:** `[ID w5_fix_03_work_04]` Behavioral FK test with live INSERT.
**How:** In a transaction: INSERT with non-existent execution_id → expect SQLSTATE 23503.
INSERT with non-existent policy_decision_id → expect SQLSTATE 23503. ROLLBACK.

### Step 5: Run Verification
**What:** `[ID w5_fix_03_work_05]` Execute verifier, produce evidence.

### Step 6: Structural Change Governance (Step 9)
**What:** `[ID w5_fix_03_work_06]` Update THREAT_MODEL.md and COMPLIANCE_MAP.md.

### Step 7: Baseline Regeneration (Steps 10-11)
**What:** `[ID w5_fix_03_work_07]` Regenerate baseline, update ADR-0010.

### Step 8: DDL Lock-Risk (Step 12)
**What:** `[ID w5_fix_03_work_08]` ALTER TABLE ADD CONSTRAINT may flag linter.

### Step 9: Stage Evidence (Step 13)
**What:** `[ID w5_fix_03_work_09]` Stage phase0 evidence files.

### Step 10: Update EXEC_LOG
**What:** `[ID w5_fix_03_work_10]` Final remediation trace markers.

---

## Verification

```bash
# [ID w5_fix_03_work_02] FK constraints exist
psql "$DATABASE_URL" -tAc "SELECT count(*) FROM information_schema.table_constraints WHERE table_name = 'state_transitions' AND constraint_type = 'FOREIGN KEY'" | grep -q '2' || exit 1

# [ID w5_fix_03_work_04] [ID w5_fix_03_work_05] Behavioral test
bash scripts/db/verify_tsk_p2_w5_fix_03.sh || exit 1

# [ID w5_fix_03_work_05] Evidence exists
test -f evidence/phase2/tsk_p2_w5_fix_03.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_03.json`

Required fields: task_id, git_sha, timestamp_utc, status, checks, fk_execution_id_verified, fk_policy_decision_id_verified, negative_test_results, positive_test_results

---

## Rollback

1. Create migration dropping both FK constraints
2. Update MIGRATION_HEAD
3. Regenerate baseline

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Orphaned rows block FK creation | Migration aborts | Precondition check |
| ON DELETE CASCADE used | Silent audit data loss | Code review + grep |
| FK violation not tested | False PASS | N1/N2 negative tests |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
