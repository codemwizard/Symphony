# TSK-P2-GOV-CONV-013 PLAN - Verify Phase-2 ratification artifact integrity

Task: TSK-P2-GOV-CONV-013
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-GOV-CONV-012
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-013.RATIFICATION_VERIFIER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create `scripts/audit/verify_phase2_ratification.sh`, a reusable verifier for
Phase-2 ratification markdown and approval sidecar integrity.

Done means the verifier rejects cross-reference mismatch, invalid sidecars, missing
prerequisite evidence, and overbroad phase claims.

## Regulated Surface Compliance

Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Ratification artifacts must remain verifiable after creation. The reusable verifier
keeps approval metadata, prerequisite evidence, and claim boundaries mechanically
checkable.

## Pre-conditions

- TSK-P2-GOV-CONV-012 is complete.
- Ratification markdown and sidecar artifacts exist.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_phase2_ratification.sh` | Create | Reusable ratification verifier |
| `evidence/phase2/phase2_ratification_status.json` | Emit | Ratification status evidence |
| `tasks/TSK-P2-GOV-CONV-013/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-013/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Editing ratification artifacts
- Editing contracts or policies
- CI wiring
- Future-phase artifact creation

## Stop Conditions

- Stop if ratification artifacts do not exist.
- Stop if artifact discovery is ambiguous.
- Stop if sidecar schema validation cannot run.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Locate artifacts [ID gov_conv_013_w01]

Find the active Phase-2 ratification markdown and approval sidecar.

Done when exactly one artifact set is found or ambiguity fails.

### Step 2 - Validate cross-references [ID gov_conv_013_w02]

Check markdown sidecar reference and sidecar artifact_ref consistency.

Done when mismatched fixtures fail.

### Step 3 - Validate sidecar schema [ID gov_conv_013_w03]

Validate the approval sidecar against repository schema.

Done when invalid sidecars fail.

### Step 4 - Verify prerequisite evidence [ID gov_conv_013_w04]

Check references to Phase-2 contract status, contract wiring, human/machine
alignment, and policy alignment evidence.

Done when missing-evidence fixtures fail.

### Step 5 - Reject overbroad claims [ID gov_conv_013_w05]

Reject claims that all Phase-2 implementation is complete or future phases are open.

Done when overbroad-claim fixtures fail.

### Step 6 - Emit evidence [ID gov_conv_013_w06]

Emit `phase2_ratification_status.json`.

Done when live evidence reports `ratification_status: PASS`.

## Verification