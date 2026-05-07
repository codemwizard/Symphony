# TSK-P2-RLS-BYPASS-002 PLAN - Remove runtime Ledger API bypass dependencies

Task: TSK-P2-RLS-BYPASS-002
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-RLS-BYPASS-001
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-002.RUNTIME_REMOVAL_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Remove runtime-reachable `app.bypass_rls` dependency from scoped Ledger API source
files without replacing it with hidden privileged runtime behavior.

Done means scoped runtime files no longer set `app.bypass_rls`, forbidden privileged
fallbacks are absent, and a DATABASE_URL-backed runtime negative test rejects
cross-tenant access.

## Regulated Surface Compliance

This task edits regulated or production-affecting surfaces:

- `services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs`
- `services/ledger-api/dotnet/src/LedgerApi/Security/ITenantReadinessProbe.cs`
- `scripts/audit/verify_rls_bypass_runtime_removal.sh`
- `evidence/phase2/rls_bypass_runtime_removal.json`

Create and validate Stage A approval metadata before editing these paths. Stage B
approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include:

- `failure_signature`
- `origin_task_id`
- `repro_command`
- `verification_commands_run`
- `final_status`

## Architectural Context

The RLS policy fix is insufficient if runtime application code still activates
bypass semantics. This task removes runtime request/repository dependencies first,
so later policy migration does not leave application-level bypass assumptions behind.

## Pre-conditions

- TSK-P2-RLS-BYPASS-001 is complete.
- Inventory evidence exists and contains no UNKNOWN findings.
- Stage A approval metadata exists before regulated edits.
- DATABASE_URL is available for verifier runtime proof.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `services/ledger-api/dotnet/src/LedgerApi/Infrastructure/Stores.cs` | Modify | Remove runtime bypass setting |
| `services/ledger-api/dotnet/src/LedgerApi/Security/ITenantReadinessProbe.cs` | Modify | Remove readiness-probe bypass setting |
| `scripts/audit/verify_rls_bypass_runtime_removal.sh` | Create | Verify runtime removal |
| `evidence/phase2/rls_bypass_runtime_removal.json` | Emit | Runtime remediation evidence |
| `tasks/TSK-P2-RLS-BYPASS-002/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-002/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Schema policy changes
- Baseline regeneration
- Demo seed/bootstrap refactoring unless classified runtime-reachable
- Admin execution boundary creation
- CI workflow edits

## Stop Conditions

- Stop if inventory evidence is missing or has UNKNOWN findings.
- Stop if a runtime finding is outside this task's touch list.
- Stop if the replacement design uses hidden privileged runtime access.
- Stop if approval metadata is missing before regulated edits.

## Implementation Steps

### Step 1 - Confirm inventory rows [ID rls_bypass_002_w01]

Read the inventory evidence and record the exact rows consumed for Stores.cs and
ITenantReadinessProbe.cs in EXEC_LOG.

Done when no UNKNOWN runtime finding is ignored.

### Step 2 - Remove Stores.cs bypass [ID rls_bypass_002_w02]

Remove `app.bypass_rls` set_config usage from Stores.cs. Preserve legitimate tenant
context handling through explicit tenant IDs and normal RLS semantics.

Done when Stores.cs has no app.bypass_rls reference.

### Step 3 - Remove readiness probe bypass [ID rls_bypass_002_w03]

Remove bypass setting from ITenantReadinessProbe.cs without weakening readiness
validation.

Done when the probe has no app.bypass_rls reference.

### Step 4 - Create verifier [ID rls_bypass_002_w04]

Create `verify_rls_bypass_runtime_removal.sh` to scan scoped runtime files and
reject app.bypass_rls plus forbidden privileged fallback patterns.

Done when negative fixtures fail.

### Step 5 - Add runtime negative proof [ID rls_bypass_002_w05]

Use DATABASE_URL to prove a cross-tenant runtime access attempt is rejected without
app.bypass_rls.

Done when rejection is recorded in evidence.

### Step 6 - Emit evidence [ID rls_bypass_002_w06]

Emit `rls_bypass_runtime_removal.json` with Wave-8 evidence fields.

Done when evidence validates and forbidden_fallbacks is empty.

## Verification

```bash
test -x scripts/audit/verify_rls_bypass_runtime_removal.sh && bash scripts/audit/verify_rls_bypass_runtime_removal.sh > evidence/phase2/rls_bypass_runtime_removal.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-002 --evidence evidence/phase2/rls_bypass_runtime_removal.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_runtime_removal.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, changed_paths,
inventory_rows_consumed, removed_references, forbidden_fallbacks, and
runtime_negative_test.

Rollback
Restore only the scoped runtime files and remove this task's verifier/evidence.
Do not modify migrations or baseline artifacts as rollback for this task.

Risk
Risk	Consequence	Mitigation
Hidden privileged fallback added	Bypass survives under new name	Verifier checks forbidden fallback patterns
Runtime path missed	Incomplete remediation	Inventory dependency and stop condition
Cross-tenant proof omitted	Fake PASS	DATABASE_URL-backed negative test required
