# TSK-P2-RLS-BYPASS-007 PLAN - Prove runtime tenant isolation without app.bypass_rls

Task: TSK-P2-RLS-BYPASS-007
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-RLS-BYPASS-002, TSK-P2-RLS-BYPASS-003, TSK-P2-RLS-BYPASS-004, TSK-P2-RLS-BYPASS-005
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-007.RUNTIME_ISOLATION_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Create a runtime/RLS behavior verifier proving tenant isolation works without
`app.bypass_rls`.

Done means same-tenant access succeeds, cross-tenant access is rejected, active
policy definitions remain clean, and the verifier does not use inadmissible proof
patterns.

## Regulated Surface Compliance

Create Stage A approval metadata before editing:

- `scripts/audit/verify_rls_bypass_runtime_isolation.sh`
- `evidence/phase2/rls_bypass_runtime_isolation.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Tenant isolation must be proven behaviorally after the runtime and schema changes.
String absence and migration inspection are not enough.

## Pre-conditions

- TSK-P2-RLS-BYPASS-002, 003, 004, and 005 are complete.
- DATABASE_URL is set.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_rls_bypass_runtime_isolation.sh` | Create | Runtime tenant-isolation verifier |
| `evidence/phase2/rls_bypass_runtime_isolation.json` | Emit | Runtime isolation evidence |
| `tasks/TSK-P2-RLS-BYPASS-007/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-007/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Source edits
- Migration edits
- Baseline edits
- CI wiring
- Phase closeout artifact creation

## Stop Conditions

- Stop if prerequisites are incomplete.
- Stop if DATABASE_URL is missing.
- Stop if verifier uses app.bypass_rls, superuser-only proof, session_replication_role, or advisory checks.
- Stop if active policy cross-check finds app.bypass_rls.

## Implementation Steps

### Step 1 - Create verifier [ID rls_bypass_007_w01]

Create `verify_rls_bypass_runtime_isolation.sh`.

Done when it runs via DATABASE_URL and does not set app.bypass_rls.

### Step 2 - Block inadmissible proof [ID rls_bypass_007_w02]

Reject superuser-only, session_replication_role, bypass-setting, and advisory-only
proof modes.

Done when negative fixtures fail.

### Step 3 - Positive same-tenant proof [ID rls_bypass_007_w03]

Run same-tenant access scenarios.

Done when legitimate same-tenant access succeeds.

### Step 4 - Negative cross-tenant proof [ID rls_bypass_007_w04]

Run cross-tenant read/write attempts.

Done when unauthorized access is rejected.

### Step 5 - Cross-check policies [ID rls_bypass_007_w05]

Inspect active RLS policy definitions during proof.

Done when no active policy contains app.bypass_rls.

### Step 6 - Emit evidence [ID rls_bypass_007_w06]

Emit `rls_bypass_runtime_isolation.json`.

Done when evidence records positive and negative test outcomes.

## Verification

```bash
test -x scripts/audit/verify_rls_bypass_runtime_isolation.sh && bash scripts/audit/verify_rls_bypass_runtime_isolation.sh > evidence/phase2/rls_bypass_runtime_isolation.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-007 --evidence evidence/phase2/rls_bypass_runtime_isolation.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_runtime_isolation.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, runtime_role_used,
bypass_setting_used, positive_test_passed, negative_test_passed, and
policy_cross_check.

Rollback
Remove the runtime verifier and evidence. Do not modify schema, baseline, or source
files in this verifier rollback.

Risk
Risk	Consequence	Mitigation
String-only proof	False closure	Runtime positive and negative scenarios required
Superuser-only success	Inadmissible evidence	Verifier rejects privileged proof modes
Positive path broken	Availability regression	Same-tenant positive case required
