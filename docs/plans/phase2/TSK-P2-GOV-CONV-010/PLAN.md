# TSK-P2-GOV-CONV-010 PLAN - Author Phase-2 agentic SDLC policy

Task: TSK-P2-GOV-CONV-010
Owner: ARCHITECT
Depends on: TSK-P2-GOV-CONV-005
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-010.POLICY_AUTHORING_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create `docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md` as the Phase-2 scoped
agentic SDLC policy document.

Done means the policy contains required sections, defers to higher authorities, and
does not claim Phase-2 is open or complete.

## Regulated Surface Compliance

Approval metadata is required before editing `docs/operations/**`,
`scripts/audit/**`, or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Phase-2 policy needs scoped operating rules but must not compete with the operation
manual or lifecycle policy. It should define Phase-2 claim discipline and evidence
requirements.

## Pre-conditions

- TSK-P2-GOV-CONV-005 is complete.
- `docs/PHASE2/phase2_contract.yml` is invariant-centric.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md` | Create | Phase-2 policy guard |
| `scripts/audit/verify_gov_conv_010.sh` | Create | Verify required sections/references |
| `evidence/phase2/gov_conv_010_phase2_policy_authoring.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-010/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-010/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Editing apex operation manual
- Editing phase lifecycle policy
- Editing machine contract rows
- Ratification artifacts
- CI wiring

## Stop Conditions

- Stop if the machine contract is not invariant-centric.
- Stop if the policy claims Phase-2 is open or complete.
- Stop if the policy conflicts with higher authority documents.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create policy document [ID gov_conv_010_w01]

Create the Phase-2 policy with scope, authority hierarchy, execution rules,
evidence requirements, and anti-drift sections.

Done when all required sections exist.

### Step 2 - Declare authority hierarchy [ID gov_conv_010_w02]

Reference `AI_AGENT_OPERATION_MANUAL.md` as apex authority and `PHASE_LIFECYCLE.md`
as phase taxonomy authority.

Done when both references are explicit.

### Step 3 - Define claim requirements [ID gov_conv_010_w03]

Require machine contract rows, verifier output, and `evidence/phase2/**` evidence
for Phase-2 delivery claims.

Done when claim requirements are explicit.

### Step 4 - Create authoring verifier [ID gov_conv_010_w04]

Create `verify_gov_conv_010.sh` to check required sections and references.

Done when missing-reference fixtures fail.

### Step 5 - Emit evidence [ID gov_conv_010_w05]

Emit `gov_conv_010_phase2_policy_authoring.json`.

Done when `no_phase_open_claims` is true.

## Verification