# TSK-P2-W5-FIX-01 PLAN — Fix column name mismatch in enforce_transition_authority()

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification
     command MUST be explicitly mapped using tracking IDs.
-->

Task: TSK-P2-W5-FIX-01
Owner: DB_FOUNDATION
Depends on: (root task — no dependencies)
failure_signature: P2.W5-FIX.COLUMN-MISMATCH.RUNTIME_CRASH
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

The `enforce_transition_authority()` function (migration 0140, line 19) references column
`decision_id` in its WHERE clause, but the `policy_decisions` table PK is
`policy_decision_id` (migration 0134, line 15). This mismatch passes compilation due to
PostgreSQL's deferred PL/pgSQL column resolution but crashes at runtime with
`column "decision_id" does not exist` on every INSERT to `state_transitions`. After this
task closes, the function body will reference the correct column, live INSERTs will succeed
for valid data, and the evidence file at `evidence/phase2/tsk_p2_w5_fix_01.json` will
contain before/after behavioral proof.

---

## Architectural Context

This is the root task of the Wave 5 stabilization chain. No other Wave 5 trigger can be
tested until this crash is eliminated — the function is invoked as a BEFORE INSERT trigger
(`trg_enforce_transition_authority`) and will abort every INSERT attempt. SECURITY DEFINER
hardening (FIX-04), trigger ordering (FIX-05), and FK constraints (FIX-03) are all
meaningless on a function that cannot execute.

Anti-patterns guarded against:
- **Editing migration 0140**: Forward-only mandate. Fix via new migration 0145.
- **Bundling SECURITY DEFINER**: Single-concern isolation. That is FIX-04.
- **Structural-only testing**: Must prove runtime behavior, not just pg_proc existence.

---

## Pre-conditions

- [ ] Current branch is NOT `main`.
- [ ] `DATABASE_URL` is set to a live PostgreSQL instance with migrations 0134-0144 applied.
- [ ] MIGRATION_HEAD is currently `0144`.
- [ ] This PLAN.md exists and has been reviewed (regulated surface: schema/migrations/**).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0145_fix_enforce_transition_authority_column.sql` | CREATE | Forward-only fix: CREATE OR REPLACE FUNCTION with corrected column reference |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update from 0144 to 0145 |
| `scripts/db/verify_tsk_p2_w5_fix_01.sh` | CREATE | Behavioral verification with live INSERT tests |
| `evidence/phase2/tsk_p2_w5_fix_01.json` | CREATE | Evidence artifact produced by verifier |
| `docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md` | MODIFY | Append execution history |
| `tasks/TSK-P2-W5-FIX-01/meta.yml` | MODIFY | Update status to completed |
| `docs/architecture/THREAT_MODEL.md` | MODIFY | Step 9: Structural change governance — security implications |
| `docs/architecture/COMPLIANCE_MAP.md` | MODIFY | Step 9: Map change to compliance control |
| `schema/baseline.sql` | MODIFY | Step 10: Regenerated after migration 0145 |
| `schema/baselines/current/0001_baseline.sql` | MODIFY | Step 10: Regenerated baseline |
| `schema/baselines/current/baseline.cutoff` | MODIFY | Step 10: Updated cutoff |
| `schema/baselines/current/baseline.meta.json` | MODIFY | Step 10: Updated metadata |
| `docs/decisions/ADR-0010-baseline-policy.md` | MODIFY | Step 11: Dated justification for baseline change |
| `evidence/phase0/baseline_drift.json` | MODIFY | Step 13: Regenerated evidence |
| `evidence/phase0/baseline_governance.json` | MODIFY | Step 13: Regenerated evidence |
| `evidence/phase0/schema_hash.txt` | MODIFY | Step 13: Regenerated evidence |
| `evidence/phase0/structural_doc_linkage.json` | MODIFY | Step 13: Regenerated evidence |

---

## Stop Conditions

- **If migration 0145 references any column that does not exist in the target table** → STOP
- **If verifier script does not execute a live INSERT** → STOP (structural-only check is insufficient)
- **If approval metadata not created before editing regulated surface** → STOP
- **If negative test N1 is skipped (bug not proven before fix)** → STOP
- **If ≥3 weak signals (subjective wording without hard failing) are detected** → STOP
- **If baseline not regenerated after migration** → STOP (PRECI.DB.BASELINE will fail)
- **If ADR-0010 not updated** → STOP (baseline governance gate will fail)
- **If THREAT_MODEL.md or COMPLIANCE_MAP.md not updated** → STOP (PRECI.STRUCTURAL.CHANGE_RULE will flag)

---

## Implementation Steps

### Step 1: Reproduce the Bug
**What:** `[ID w5_fix_01_work_01]` Execute a live INSERT into `state_transitions` and capture the raw PostgreSQL error.
**How:** Run an INSERT statement via `psql "$DATABASE_URL"` that triggers `enforce_transition_authority()`. The function will crash on the `decision_id` reference.
**Done when:** EXEC_LOG.md contains the exact error text `column "decision_id" does not exist` as `failure_signature`.

```sql
-- This INSERT will fail with: column "decision_id" does not exist
INSERT INTO state_transitions (
    transition_id, entity_type, entity_id, from_state, to_state,
    execution_id, policy_decision_id, transition_hash
) VALUES (
    gen_random_uuid(), 'test_entity', gen_random_uuid()::text,
    'PENDING', 'APPROVED',
    '<valid_execution_id>', '<valid_policy_decision_id>',
    encode(sha256('test'::bytea), 'hex')
);
```

### Step 2: Write the Migration
**What:** `[ID w5_fix_01_work_02]` Create `schema/migrations/0145_fix_enforce_transition_authority_column.sql`.
**How:** Use `CREATE OR REPLACE FUNCTION enforce_transition_authority()` with the corrected column reference: `WHERE policy_decision_id = NEW.policy_decision_id`. Copy the full function body from 0140 and change only the column reference. Do NOT add SECURITY DEFINER.
**Done when:** `psql "$DATABASE_URL" -tAc "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_authority'" | grep -q 'policy_decision_id'` exits 0.

### Step 3: Update MIGRATION_HEAD
**What:** `[ID w5_fix_01_work_03]` Update MIGRATION_HEAD to 0145.
**How:** `echo 0145 > schema/migrations/MIGRATION_HEAD`
**Done when:** `cat schema/migrations/MIGRATION_HEAD` returns `0145`.

### Step 4: Write the Verification Script
**What:** `[ID w5_fix_01_work_04]` Create `scripts/db/verify_tsk_p2_w5_fix_01.sh` with live behavioral tests.
**How:** The script must:
1. Use `psql "$DATABASE_URL"` (not bare psql)
2. Execute N1: Verify the function body no longer references bare `decision_id`
3. Execute N2: INSERT with non-existent policy_decision_id → must get application-level exception
4. Execute P1: INSERT with valid policy_decision_id → must succeed
5. Write evidence JSON to `evidence/phase2/tsk_p2_w5_fix_01.json`
**Done when:** Script exits 0 and evidence JSON exists.

### Step 5: Run Verification and Generate Evidence
**What:** `[ID w5_fix_01_work_05]` Execute the verifier script.
**How:** `bash scripts/db/verify_tsk_p2_w5_fix_01.sh`
**Done when:** Evidence JSON exists with all `must_include` fields.

### Step 6: Structural Change Governance (MANDATORY — Step 9)
**What:** `[ID w5_fix_01_work_06]` Document the change in architecture records.
**How:**
1. Append entry to `docs/architecture/THREAT_MODEL.md`: Document that migration 0145 corrects a column reference — no new attack surface introduced, but the pre-fix state allowed silent runtime crashes that masked authority enforcement failures.
2. Append entry to `docs/architecture/COMPLIANCE_MAP.md`: Map the change to the authority enforcement control (referential integrity of policy_decision lookup).
**Done when:** Both files contain dated entries referencing TSK-P2-W5-FIX-01 and migration 0145.

### Step 7: Schema Baseline Regeneration (MANDATORY — Steps 10-11)
**What:** `[ID w5_fix_01_work_07]` Regenerate baseline and satisfy ADR-0010.
**How:**
1. Provision a clean DB (dev or ephemeral) with all migrations through 0145 applied
2. Run `scripts/db/generate_baseline_snapshot.sh` to regenerate baseline files
3. Append dated entry to `docs/decisions/ADR-0010-baseline-policy.md`:
   `- 2026-XX-XX: Baseline regenerated after fixing column reference in enforce_transition_authority (migration 0145, TSK-P2-W5-FIX-01).`
**Done when:** `schema/baseline.sql` and `schema/baselines/current/0001_baseline.sql` exist and ADR-0010 has the entry.

### Step 8: DDL Lock-Risk Check (Step 12)
**What:** `[ID w5_fix_01_work_08]` Verify DDL allowlisting requirements.
**How:** Run `scripts/security/lint_ddl_lock_risk.sh` against migration 0145. CREATE OR REPLACE FUNCTION is typically not flagged, but if it is, calculate SHA-256 fingerprint and append to `docs/security/ddl_allowlist.json`.
**Done when:** Linter passes or allowlist entry is created.

### Step 9: Stage Evidence Files (MANDATORY — Step 13)
**What:** `[ID w5_fix_01_work_09]` Stage all regenerated phase0 evidence.
**How:**
```bash
git add evidence/phase0/schema_hash.txt
git add evidence/phase0/baseline_governance.json
git add evidence/phase0/baseline_drift.json
git add evidence/phase0/structural_doc_linkage.json
```
**Done when:** All four files are staged and fresh.

### Step 10: Update EXEC_LOG.md
**What:** `[ID w5_fix_01_work_10]` Append final remediation trace markers.
**How:** Update EXEC_LOG.md with `verification_commands_run` and `final_status`.
**Done when:** All 5 remediation trace markers present.

---

## Verification

```bash
# [ID w5_fix_01_work_02] Column reference is correct
psql "$DATABASE_URL" -tAc "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_authority'" | grep -q 'policy_decision_id' || exit 1

# [ID w5_fix_01_work_03] MIGRATION_HEAD updated
test "$(cat schema/migrations/MIGRATION_HEAD)" = '0145' || exit 1

# [ID w5_fix_01_work_04] [ID w5_fix_01_work_05] Full behavioral verification
bash scripts/db/verify_tsk_p2_w5_fix_01.sh || exit 1

# [ID w5_fix_01_work_05] Evidence exists
test -f evidence/phase2/tsk_p2_w5_fix_01.json || exit 1

# [ID w5_fix_01_work_06] Remediation trace complete
grep -q 'failure_signature' docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md && \
grep -q 'origin_task_id' docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md && \
grep -q 'repro_command' docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md && \
grep -q 'verification_commands_run' docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md && \
grep -q 'final_status' docs/plans/phase2/TSK-P2-W5-FIX-01/EXEC_LOG.md || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_01.json`

Required fields:
- `task_id`: "TSK-P2-W5-FIX-01"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `column_reference_verified`: boolean — pg_proc body contains correct reference
- `negative_test_results`: object with N1 (pre-fix crash proof) and N2 (post-fix rejection proof)
- `positive_test_results`: object with P1 (valid INSERT succeeds)

---

## Rollback

If this task must be reverted:
1. Create migration `0146_rollback_fix_01.sql` that restores the original (broken) function body
2. Update MIGRATION_HEAD to 0146
3. Update task status back to 'ready' in meta.yml
4. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Column reference still wrong after migration | Every INSERT fails at runtime | Verification script live INSERT test (P1) |
| Bug not proven before fix | Cannot distinguish fix from coincidence | N1 negative test in EXEC_LOG with exact error text |
| SECURITY DEFINER accidentally added | Scope violation, blocks FIX-04 | Code review of migration 0145 — grep for 'SECURITY DEFINER' |
| Bare psql used in verifier | CI failure in ephemeral environments | grep verification script for DATABASE_URL |
| Anti-pattern: structural-only testing | False PASS with broken runtime | Verifier executes live INSERT, not just pg_proc query |

---

## Anti-Drift Cheating Limits

After this task completes, the following attack surfaces remain open:
- **search_path injection**: Function lacks SECURITY DEFINER (addressed in FIX-04)
- **Trigger bypass via superuser**: No mitigation until Wave 6 hardening
- **Non-deterministic trigger ordering**: Alphabetical firing order (addressed in FIX-05)
- **Missing FK enforcement**: Dangling references still possible (addressed in FIX-03)

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists (Stage A: pre-push, branch-linked)
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
