# TSK-P2-RLS-BYPASS-003 PLAN - Refactor Ledger API demo seeding away from app.bypass_rls

Task: TSK-P2-RLS-BYPASS-003
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-RLS-BYPASS-001
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-003.SEED_REFACTOR_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Remove `app.bypass_rls` dependency from Ledger API demo seed/bootstrap code without
making privileged behavior available to request-serving runtime.

Done means Program.cs has no active app.bypass_rls set_config usage, no ambient
privileged runtime fallback exists, and evidence proves the seed path is isolated.

## Regulated Surface Compliance

This task edits production-affecting source and regulated verifier/evidence paths.
Create Stage A approval metadata before editing:

- `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
- `scripts/audit/verify_rls_bypass_seed_refactor.sh`
- `evidence/phase2/rls_bypass_seed_refactor.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include:

- `failure_signature`
- `origin_task_id`
- `repro_command`
- `verification_commands_run`
- `final_status`

## Architectural Context

Seeding and bootstrap flows can need setup privileges, but they must not normalize
an ambient bypass inside application runtime. This task handles Program.cs seed
usage separately from runtime repositories and database policy migration.

## Pre-conditions

- TSK-P2-RLS-BYPASS-001 is complete.
- Inventory evidence classifies Program.cs findings as SEED or ADMIN, not RUNTIME.
- Stage A approval metadata exists before edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | Modify | Remove seed/bootstrap bypass setting |
| `scripts/audit/verify_rls_bypass_seed_refactor.sh` | Create | Verify seed refactor |
| `evidence/phase2/rls_bypass_seed_refactor.json` | Emit | Seed remediation evidence |
| `tasks/TSK-P2-RLS-BYPASS-003/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-003/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Stores.cs and ITenantReadinessProbe.cs remediation
- Schema migration
- Baseline regeneration
- CI workflow edits
- General administrative framework creation

## Stop Conditions

- Stop if inventory is missing or Program.cs findings are UNKNOWN.
- Stop if Program.cs findings are RUNTIME and need a runtime task.
- Stop if replacement requires hidden privileged runtime access.
- Stop if seed behavior cannot be isolated.

## Implementation Steps

### Step 1 - Confirm inventory classification [ID rls_bypass_003_w01]

Read inventory rows for Program.cs and record their classification in EXEC_LOG.

Done when Program.cs rows are confirmed SEED or ADMIN.

### Step 2 - Remove seed bypass [ID rls_bypass_003_w02]

Remove active app.bypass_rls set_config usage from Program.cs seed/bootstrap logic.

Done when Program.cs contains no active app.bypass_rls setting.

### Step 3 - Preserve non-runtime boundary [ID rls_bypass_003_w03]

Ensure any needed setup path is explicit, non-default, auditable, and not available
to normal request runtime.

Done when no ambient privileged runtime exposure is present.

### Step 4 - Create verifier [ID rls_bypass_003_w04]

Create `verify_rls_bypass_seed_refactor.sh` to reject active bypass usage and
forbidden privileged fallback patterns.

Done when negative fixtures fail.

### Step 5 - Prove runtime not exposed [ID rls_bypass_003_w05]

Verifier inspects startup/config surfaces to confirm request runtime cannot activate
the privileged seed mode.

Done when evidence records `request_runtime_privileged_mode_exposed: false`.

### Step 6 - Emit evidence [ID rls_bypass_003_w06]

Emit `rls_bypass_seed_refactor.json`.

Done when evidence validates and includes required Wave-8 fields.

## Verification

```bash
test -x scripts/audit/verify_rls_bypass_seed_refactor.sh && bash scripts/audit/verify_rls_bypass_seed_refactor.sh > evidence/phase2/rls_bypass_seed_refactor.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-003 --evidence evidence/phase2/rls_bypass_seed_refactor.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_seed_refactor.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, inventory_rows_consumed,
removed_seed_references, privileged_boundary_assessment,
request_runtime_privileged_mode_exposed, and forbidden_fallbacks.

Rollback
Restore only Program.cs and remove this task's verifier/evidence. Do not touch schema
or runtime repository remediation files.

Risk
Risk	Consequence	Mitigation
Seed path becomes hidden runtime admin mode	Bypass recreated under another name	Verifier rejects runtime-exposed privileged mode
Runtime finding treated as seed	Incomplete security fix	Stop condition requires split
Setup behavior breaks silently	Operational regression	Explicit boundary assessment in evidence
