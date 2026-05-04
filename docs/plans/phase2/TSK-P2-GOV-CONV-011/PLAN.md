# TSK-P2-GOV-CONV-011 PLAN - Verify Phase-2 policy authority alignment

Task: TSK-P2-GOV-CONV-011
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-GOV-CONV-010
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-011.POLICY_ALIGNMENT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create a verifier that rejects authority drift in
`docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md`.

Done means prohibited Phase-2 readiness claims, missing authority references, and
missing claim-evidence requirements all fail closed.

## Regulated Surface Compliance

Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The Phase-2 policy is a scoped policy guard. It must not redefine apex operation
rules, phase taxonomy, or contract claim semantics. This verifier catches explicit
authority drift and unsupported readiness language.

## Pre-conditions

- TSK-P2-GOV-CONV-010 is complete.
- `docs/operations/AGENTIC_SDLC_PHASE2_POLICY.md` exists.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_gov_conv_011.sh` | Create | Verify Phase-2 policy authority alignment |
| `evidence/phase2/gov_conv_011_phase2_policy_alignment.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-011/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-011/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Editing policy text
- Editing apex/lifecycle documents
- Editing machine contract rows
- CI wiring
- Ratification artifact creation

## Stop Conditions

- Stop if the Phase-2 policy document is missing.
- Stop if prohibited phase-open language cannot be detected in fixtures.
- Stop if authority references cannot be inspected.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Inspect policy references [ID gov_conv_011_w01]

Create `verify_gov_conv_011.sh` to inspect the Phase-2 policy for authority
references and claim-evidence requirements.

Done when observed references are recorded in evidence.

### Step 2 - Reject prohibited readiness claims [ID gov_conv_011_w02]

Reject claims that Phase-2 is open, complete, ratified, or delivery-claimable
without ratification.

Done when prohibited-claim fixtures fail.

### Step 3 - Reject missing authorities [ID gov_conv_011_w03]

Reject policies missing apex, lifecycle, machine contract, verifier, or evidence
claim requirements.

Done when missing-reference fixtures fail.

### Step 4 - Add negative fixtures [ID gov_conv_011_w04]

Add fixtures covering prohibited readiness language and missing references.

Done when all fixtures fail as expected.

### Step 5 - Emit evidence [ID gov_conv_011_w05]

Emit `gov_conv_011_phase2_policy_alignment.json`.

Done when live evidence reports `policy_alignment_status: PASS`.

## Verification