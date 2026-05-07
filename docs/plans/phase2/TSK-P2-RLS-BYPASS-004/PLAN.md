# TSK-P2-RLS-BYPASS-004 PLAN - Forward-only RLS policy migration

Task: TSK-P2-RLS-BYPASS-004
Owner: DB_FOUNDATION
Depends on: TSK-P2-RLS-BYPASS-001, TSK-P2-RLS-BYPASS-002, TSK-P2-RLS-BYPASS-003
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-004.POLICY_MIGRATION_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Create a forward-only migration removing `app.bypass_rls` from affected RLS policy
predicates without editing applied migrations or adding a replacement escape hatch.

Done means migration 0204 exists, MIGRATION_HEAD is 0204, migration lint passes, and
the verifier proves no active RLS policy contains `app.bypass_rls`.

## Regulated Surface Compliance

This task edits regulated schema and DB verifier surfaces. Stage A approval metadata
must exist before editing:

- `schema/migrations/0204_remove_app_bypass_rls_from_policies.sql`
- `schema/migrations/MIGRATION_HEAD`
- `scripts/db/verify_rls_bypass_policy_migration.sh`
- `evidence/phase2/rls_bypass_policy_migration.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The bypass is in terminal RLS policy state, but applied migrations are immutable.
The fix must be a new migration after the current head. The local filesystem reports
head `0203`.

## Pre-conditions

- TSK-P2-RLS-BYPASS-001, 002, and 003 are complete.
- No UNKNOWN inventory findings remain.
- DATABASE_URL is available.
- DATABASE_URL is available.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `schema/migrations/0204_remove_app_bypass_rls_from_policies.sql` | Create | Forward-only policy remediation |
| `schema/migrations/MIGRATION_HEAD` | Modify | Advance migration head to 0204 |
| `scripts/db/verify_rls_bypass_policy_migration.sh` | Create | Verify migration and terminal policy state |
| `evidence/phase2/rls_bypass_policy_migration.json` | Emit | Migration evidence |
| `tasks/TSK-P2-RLS-BYPASS-004/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-004/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Runtime source edits
- Seed/bootstrap edits
- Baseline regeneration
- CI workflow edits
- Phase closeout claims

## Stop Conditions

- Stop if prerequisites are incomplete.
- Stop if MIGRATION_HEAD is not 0203 at execution time.
- Stop if any replacement policy includes bypass semantics.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Confirm head [ID rls_bypass_004_w01]

Record the current migration head in EXEC_LOG.

Done when the observed migration head matches the prerequisite.

### Step 2 - Create migration [ID rls_bypass_004_w02]

Create migration 0204 to drop and recreate affected policies without
`app.bypass_rls`.

Done when migration is forward-only and scoped to affected policies.

### Step 3 - Preserve tenant predicate [ID rls_bypass_004_w03]

Keep tenant isolation based on explicit tenant context and reject replacement escape
hatches.

Done when migration contains no bypass-like constructs.

### Step 4 - Update MIGRATION_HEAD [ID rls_bypass_004_w04]

Set MIGRATION_HEAD to 0204.

Done when the head matches the new migration.

### Step 5 - Create verifier [ID rls_bypass_004_w05]

Create `verify_rls_bypass_policy_migration.sh` using DATABASE_URL.

Done when it fails for bypass predicates, bad migration lint, and head mismatch.

### Step 6 - Emit evidence [ID rls_bypass_004_w06]

Emit `rls_bypass_policy_migration.json`.

Done when evidence validates and reports no remaining bypass predicates.

## Verification

```bash
test -x scripts/db/verify_rls_bypass_policy_migration.sh && bash scripts/db/verify_rls_bypass_policy_migration.sh > evidence/phase2/rls_bypass_policy_migration.json || exit 1
bash scripts/db/lint_migrations.sh || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-004 --evidence evidence/phase2/rls_bypass_policy_migration.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_policy_migration.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, migration_applied,
target_policies, bypass_predicates_remaining, forbidden_escape_hatches,
migration_head_before, and migration_head_after.

Rollback
Create a new forward migration if rollback is required. Do not edit or delete the
0204 migration after it has been applied.

Risk
Risk	Consequence	Mitigation
Applied migration edited	Forward-only violation	Touch list allows only 0204 and MIGRATION_HEAD
Replacement escape hatch added	Security regression	Verifier blocks bypass-like constructs
Baseline updated too early	Drift confusion	Baseline task is separate
