# TSK-P2-RLS-BYPASS-008 PLAN - Aggregate RLS bypass blocker evidence

Task: TSK-P2-RLS-BYPASS-008
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-RLS-BYPASS-001 through TSK-P2-RLS-BYPASS-007
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-008.BLOCKER_RESOLUTION_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Create a bounded governance index proving the app.bypass_rls blocker has supporting
remediation evidence.

Done means all prerequisite evidence exists and validates, no overbroad status claim
is present, and `rls_bypass_blocker_resolution.json` reports PASS.

## Regulated Surface Compliance

Create Stage A approval metadata before editing:

- `docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md`
- `scripts/audit/verify_rls_bypass_blocker_resolution.sh`
- `evidence/phase2/rls_bypass_blocker_resolution.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The bypass blocker can be resolved without Phase-2 closeout being triggered. This
task preserves that distinction mechanically.

## Pre-conditions

- TSK-P2-RLS-BYPASS-001 through 007 are complete.
- All prerequisite evidence files exist and validate.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/governance/RLS_BYPASS_CLOSEOUT_BLOCKER_RESOLUTION.md` | Create | Bounded blocker evidence index |
| `scripts/audit/verify_rls_bypass_blocker_resolution.sh` | Create | Verify index and prerequisite evidence |
| `evidence/phase2/rls_bypass_blocker_resolution.json` | Emit | Aggregated blocker evidence |
| `tasks/TSK-P2-RLS-BYPASS-008/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-008/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Closeout approval artifacts
- Wave 8 status changes
- Schema/source/baseline edits
- Future-phase artifacts

## Stop Conditions

- Stop if any prerequisite evidence is missing or inadmissible.
- Stop if runtime isolation evidence lacks required PASS values.
- Stop if terminal policy evidence reports remaining bypass predicates.
- Stop if index text makes overbroad status claims.

## Implementation Steps

### Step 1 - Create blocker index [ID rls_bypass_008_w01]

Create the governance index listing prerequisite tasks and evidence paths.

Done when all seven prerequisite tasks are listed.

### Step 2 - Bound the claim [ID rls_bypass_008_w02]

State that this artifact resolves only the app.bypass_rls blocker and does not
trigger Phase-2 closeout.

Done when the boundary statement is explicit.

### Step 3 - Create verifier [ID rls_bypass_008_w03]

Create `verify_rls_bypass_blocker_resolution.sh` to validate prerequisite evidence.

Done when missing or inadmissible evidence fixtures fail.

### Step 4 - Reject overclaims [ID rls_bypass_008_w04]

Reject overbroad status claims and unopened evidence namespaces.

Done when overclaim fixtures fail.

### Step 5 - Emit evidence [ID rls_bypass_008_w05]

Emit `rls_bypass_blocker_resolution.json`.

Done when blocker_resolution_status is PASS.

## Verification

```bash
test -x scripts/audit/verify_rls_bypass_blocker_resolution.sh && bash scripts/audit/verify_rls_bypass_blocker_resolution.sh > evidence/phase2/rls_bypass_blocker_resolution.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-008 --evidence evidence/phase2/rls_bypass_blocker_resolution.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_blocker_resolution.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, prerequisite_evidence,
missing_evidence, inadmissible_evidence, blocker_resolution_status, and
overbroad_claims.

Rollback
Remove the blocker-resolution index, verifier, and evidence. Do not modify underlying
remediation evidence.

Risk
Risk	Consequence	Mitigation
Blocker resolution overclaims closeout	False governance state	Verifier rejects overbroad claims
Missing prerequisite accepted	Fake closure	Evidence presence and schema checks
Inadmissible evidence accepted	Weak proof	Required Wave-8 fields checked
