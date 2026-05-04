# TSK-P2-GOV-CONV-012 PLAN - Create Phase-2 ratification artifacts

Task: TSK-P2-GOV-CONV-012
Owner: ARCHITECT
Depends on: TSK-P2-GOV-CONV-006, TSK-P2-GOV-CONV-007, TSK-P2-GOV-CONV-009, TSK-P2-GOV-CONV-011
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-012.RATIFICATION_ARTIFACT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create Phase-2 ratification markdown and approval sidecar artifacts that reference
the prerequisite verifier evidence and avoid overbroad completion claims.

Done means ratification artifacts exist, the sidecar validates, prerequisite evidence
is referenced, and the task-specific verifier emits PASS evidence.

## Regulated Surface Compliance

Approval metadata and sidecar schema compliance are required before ratification is
accepted. This task itself creates regulated approval artifacts and must preserve
schema-valid approval metadata.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Ratification normalizes the Phase-2 governance artifact set after contract, policy,
and verifier evidence exist. It must not claim all Phase-2 runtime implementation is
complete unless the machine contract evidence proves that scope.

## Pre-conditions

- TSK-P2-GOV-CONV-006, 007, 009, and 011 are complete.
- Their evidence files exist and validate.
- Approval date and approver metadata are available.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `approvals/YYYY-MM-DD/PHASE2-RATIFICATION.md` | Create | Human ratification artifact |
| `approvals/YYYY-MM-DD/PHASE2-RATIFICATION.approval.json` | Create | Machine-readable approval sidecar |
| `scripts/audit/verify_gov_conv_012.sh` | Create | Verify ratification artifact integrity |
| `evidence/phase2/gov_conv_012_phase2_ratification_artifacts.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-012/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-012/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Editing contracts or policies
- Editing verifier behavior
- CI wiring
- Opening Phase-3 or Phase-4

## Stop Conditions

- Stop if prerequisite tasks or evidence are incomplete.
- Stop if sidecar schema validation cannot pass.
- Stop if artifact would claim more than governance artifact ratification.
- Stop if machine-readable sidecar cross-reference is missing.

## Implementation Steps

### Step 1 - Create ratification markdown [ID gov_conv_012_w01]

Create `PHASE2-RATIFICATION.md` under the actual approval date directory with
scope, prerequisite task IDs, evidence references, and bounded ratification language.

Done when the markdown contains all prerequisite references.

### Step 2 - Create approval sidecar [ID gov_conv_012_w02]

Create the JSON sidecar with approver metadata, timestamp, change reference,
artifact reference, and regulated-surface scope.

Done when sidecar validates against schema.

### Step 3 - Add cross-reference section [ID gov_conv_012_w03]

Add the machine-readable cross-reference section and exact sidecar path.

Done when markdown and sidecar point to each other correctly.

### Step 4 - Create artifact verifier [ID gov_conv_012_w04]

Create `verify_gov_conv_012.sh` to validate artifact existence, sidecar schema,
prerequisite evidence references, and absence of overbroad completion claims.

Done when bad fixtures fail.

### Step 5 - Emit evidence [ID gov_conv_012_w05]

Emit `gov_conv_012_phase2_ratification_artifacts.json`.

Done when evidence records `sidecar_valid: true` and `missing_evidence: []`.

## Verification