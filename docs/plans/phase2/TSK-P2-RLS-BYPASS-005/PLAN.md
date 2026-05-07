# TSK-P2-RLS-BYPASS-005 PLAN - Prove terminal RLS policies contain no app.bypass_rls

Task: TSK-P2-RLS-BYPASS-005
Owner: DB_FOUNDATION
Depends on: TSK-P2-RLS-BYPASS-004
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-005.TERMINAL_POLICY_VERIFY_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Create a reusable verifier proving terminal database RLS policies no longer contain
`app.bypass_rls` and still retain tenant-isolation predicates.

Done means database catalog inspection through DATABASE_URL reports no bypass
predicates and no missing tenant predicates.

## Regulated Surface Compliance

Create Stage A approval metadata before editing:

- `scripts/db/verify_rls_no_app_bypass_policies.sh`
- `evidence/phase2/rls_no_app_bypass_policies.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Migration text can be correct while the terminal database remains wrong. This task
checks the applied database policy state directly.

## Pre-conditions

- TSK-P2-RLS-BYPASS-004 is complete.
- Migration 0204 is applied to the verification database.
- DATABASE_URL is set.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/db/verify_rls_no_app_bypass_policies.sh` | Create | Terminal RLS policy verifier |
| `evidence/phase2/rls_no_app_bypass_policies.json` | Emit | Terminal policy evidence |
| `tasks/TSK-P2-RLS-BYPASS-005/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-005/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Creating migrations
- Editing baseline artifacts
- Editing application code
- Full runtime tenant proof
- CI wiring

## Stop Conditions

- Stop if migration 0204 is not applied.
- Stop if DATABASE_URL is unavailable.
- Stop if database catalog inspection cannot run.
- Stop if any active policy still has bypass semantics.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create DB verifier [ID rls_bypass_005_w01]

Create `verify_rls_no_app_bypass_policies.sh` using DATABASE_URL.

Done when it queries terminal policy state.

### Step 2 - Reject bypass predicates [ID rls_bypass_005_w02]

Fail if any active policy contains `app.bypass_rls`.

Done when bypass fixture fails.

### Step 3 - Require tenant predicates [ID rls_bypass_005_w03]

Fail if affected tenant-scoped policies lose tenant predicate coverage.

Done when missing-tenant-predicate fixture fails.

### Step 4 - Add negative coverage [ID rls_bypass_005_w04]

Create fixture or temporary policy tests for bypass and missing tenant predicate.

Done when both fail.

### Step 5 - Emit evidence [ID rls_bypass_005_w05]

Emit `rls_no_app_bypass_policies.json`.

Done when evidence validates and reports no remaining bypass policies.

## Verification

```bash
test -x scripts/db/verify_rls_no_app_bypass_policies.sh && bash scripts/db/verify_rls_no_app_bypass_policies.sh > evidence/phase2/rls_no_app_bypass_policies.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-005 --evidence evidence/phase2/rls_no_app_bypass_policies.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_no_app_bypass_policies.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, policy_rows_checked,
bypass_predicates_remaining, tenant_predicates_missing, and database_url_used.

Rollback
Remove the terminal policy verifier and evidence. Do not modify migrations as part
of rollback for this verifier task.

Risk
Risk	Consequence	Mitigation
Verifier checks files only	Terminal drift missed	Query pg_policies via DATABASE_URL
Tenant predicate accidentally removed	Isolation broken differently	Assert predicate presence
Missing DATABASE_URL	Non-portable proof	Hard fail without DATABASE_URL
