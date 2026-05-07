# TSK-P2-RLS-BYPASS-009 PLAN - Record carry-forward obligations

Task: TSK-P2-RLS-BYPASS-009
Owner: INVARIANTS_CURATOR
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-009.CARRY_FORWARD_RECORD_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Create a bounded carry-forward record for the three non-immediate obligations from
the Phase-2 closeout review.

Done means the record lists methodology adapter extraction, dwell-time forensic
enforcement, and sovereign authorization schema as carry-forward obligations, while
the verifier proves no prohibited future-phase artifacts or readiness claims are
introduced.

## Regulated Surface Compliance

Create Stage A approval metadata before editing:

- `docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md`
- `scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh`
- `evidence/phase2/phase2_closeout_carry_forward_obligations.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The closeout review separated one immediate app.bypass_rls blocker from three real
but non-immediate obligations. This task prevents those obligations from being lost
while also preventing them from becoming unauthorized current execution tasks.

## Pre-conditions

- `PHASE_EXECUTION_ENVELOPE.md` has been read and applied.
- Current Phase-2 governance artifacts are readable.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md` | Create | Carry-forward governance record |
| `scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh` | Create | Verify carry-forward boundaries |
| `evidence/phase2/phase2_closeout_carry_forward_obligations.json` | Emit | Carry-forward evidence |
| `tasks/TSK-P2-RLS-BYPASS-009/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-009/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Implementing any carry-forward obligation
- Creating future-phase task packs
- Creating future-phase evidence namespaces
- Editing schema, runtime source, or CI workflows
- Claiming Phase-2 closeout

## Stop Conditions

- Stop if the record would create task metadata outside lifecycle phase `2`.
- Stop if prohibited readiness/opening language is required.
- Stop if current artifacts claim dwell-time enforcement as implemented.
- Stop if any of the three obligations is omitted.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create record [ID rls_bypass_009_w01]

Create the carry-forward governance record with exactly three obligations.

Done when all three are present.

### Step 2 - Define obligation boundaries [ID rls_bypass_009_w02]

For each obligation, record owner domain, rationale, blocker-escalation condition,
and future executable boundary.

Done when each entry is complete.

### Step 3 - Claim-check dwell-time item [ID rls_bypass_009_w03]

Scan current Phase-2 governance artifacts for implemented claims around dwell-time
forensic enforcement.

Done when claim-check results are recorded.

### Step 4 - Create verifier [ID rls_bypass_009_w04]

Create `verify_phase2_closeout_carry_forward_obligations.sh`.

Done when missing-obligation, future-artifact, prohibited-language, and claim-conflict
fixtures fail.

### Step 5 - Emit evidence [ID rls_bypass_009_w05]

Emit `phase2_closeout_carry_forward_obligations.json`.

Done when carry_forward_status is PASS.

## Verification

```bash
test -x scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh && bash scripts/audit/verify_phase2_closeout_carry_forward_obligations.sh > evidence/phase2/phase2_closeout_carry_forward_obligations.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-009 --evidence evidence/phase2/phase2_closeout_carry_forward_obligations.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/phase2_closeout_carry_forward_obligations.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, obligations,
claim_check_results, prohibited_artifacts_found, prohibited_claims, and
carry_forward_status.

Rollback
Remove the carry-forward record, verifier, and evidence. Do not create or delete any
future implementation artifacts as rollback.

Risk
Risk	Consequence	Mitigation
Carry-forward becomes hidden implementation plan	Unauthorized scope	Verifier rejects executable future artifacts
Conditional dwell-time item misfiled	Closeout blocker missed	Claim-check fails closed
Obligations ignored	Future drift	Required exact three-item record
