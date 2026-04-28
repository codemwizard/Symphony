# TSK-P2-W6-REM-01: Fix Column Name Mismatch in enforce_transition_authority()

## Mission

Fix the runtime-breaking column reference in `enforce_transition_authority()` (migration 0140).
The function references `decision_id` but the `policy_decisions` table PK is `policy_decision_id`.
This causes every INSERT to `state_transitions` to fail with a raw PostgreSQL error.

## Constraints

- **Forward-only:** Migration 0140 is immutable. Fix via new migration 0145.
- **Single concern:** Do NOT add SECURITY DEFINER (that is REM-02's scope).
- **Behavioral proof:** Must demonstrate failing INSERT before fix and successful INSERT after fix.
- **Regulated surface:** Stage A approval artifact must exist BEFORE creating migration file.

## The Bug

```
File: schema/migrations/0140_create_enforce_transition_authority.sql, line 19
Code: WHERE decision_id = NEW.policy_decision_id

Expected: WHERE policy_decision_id = NEW.policy_decision_id

Root cause: PostgreSQL deferred resolution — PL/pgSQL functions compile without
column validation. The error only surfaces at execution time.
```

## Implementation Steps

### Step 1: Pre-Edit Documentation
- [ ] Create Stage A approval artifact
- [ ] Validate against approval_metadata.schema.json
- [ ] Create initial EXEC_LOG.md entry with failure_signature

### Step 2: Reproduce the Bug
- [ ] Execute live INSERT into `state_transitions` with valid data
- [ ] Capture exact error: `column "decision_id" does not exist`
- [ ] Record in EXEC_LOG.md as `failure_signature`
- [ ] Record reproduction command as `repro_command`

### Step 3: Write Migration
- [ ] Create `schema/migrations/0145_fix_enforce_transition_authority_column.sql`
- [ ] Use `CREATE OR REPLACE FUNCTION` to redefine with corrected column reference
- [ ] Do NOT add SECURITY DEFINER (out of scope)

### Step 4: Update MIGRATION_HEAD
- [ ] Set MIGRATION_HEAD to `0145`

### Step 5: Write Verification Script
- [ ] Create `scripts/db/verify_tsk_p2_w6_rem_01.sh`
- [ ] Script must use `psql "$DATABASE_URL"` (not bare psql)
- [ ] Script must execute live INSERT tests (not just grep function body)

### Step 6: Run Verification
- [ ] Execute verification script
- [ ] Generate evidence JSON at `evidence/phase2/tsk_p2_w6_rem_01.json`

### Step 7: Post-Edit Documentation
- [ ] Update EXEC_LOG.md with verification_commands_run and final_status

## Verification Commands

```bash
# 1. Function body contains corrected column reference
psql "$DATABASE_URL" -tAc "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_authority'" | grep -q 'policy_decision_id' || exit 1

# 2. Function body does NOT contain broken reference
psql "$DATABASE_URL" -tAc "SELECT prosrc FROM pg_proc WHERE proname = 'enforce_transition_authority'" | grep -qv 'WHERE decision_id' || exit 1

# 3. MIGRATION_HEAD is correct
test "$(cat schema/migrations/MIGRATION_HEAD)" = '0145' || exit 1

# 4. Full verification script
bash scripts/db/verify_tsk_p2_w6_rem_01.sh || exit 1

# 5. Evidence exists
test -f evidence/phase2/tsk_p2_w6_rem_01.json || exit 1
```

## Failure Mode Table

| Failure | Consequence | Detection |
|---------|-------------|-----------|
| Column reference still wrong | Every INSERT fails at runtime | Verification script live INSERT test |
| Bug not proven before fix | Cannot distinguish fix from coincidence | N1 negative test in EXEC_LOG |
| SECURITY DEFINER added | Scope violation, blocks REM-02 | Code review of migration 0145 |
| Bare psql used | CI failure in ephemeral environments | grep verification script for DATABASE_URL |

## Approval References

- REGULATED_SURFACE_PATHS.yml
- approval_metadata.schema.json
- REMEDIATION_TRACE_WORKFLOW.md

## Evidence Path

- `evidence/phase2/tsk_p2_w6_rem_01.json`
