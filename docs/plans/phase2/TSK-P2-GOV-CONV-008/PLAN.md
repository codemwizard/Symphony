# TSK-P2-GOV-CONV-008 PLAN - Author Phase-2 human contract

Task: TSK-P2-GOV-CONV-008
Owner: ARCHITECT
Depends on: TSK-P2-GOV-CONV-005
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-008.HUMAN_CONTRACT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create `docs/PHASE2/PHASE2_CONTRACT.md` as a human-readable explanatory contract
that defers delivery-claim authority to `docs/PHASE2/phase2_contract.yml`.

Done means required sections and authority references exist, and the task-specific
verifier emits PASS evidence.

## Regulated Surface Compliance

Approval metadata is required before editing `docs/PHASE2/**`, `scripts/audit/**`,
or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

A human contract is needed for readability and governance review, but the machine
contract remains authoritative for delivery claims. This task avoids creating new
claims outside the machine contract.

## Pre-conditions

- TSK-P2-GOV-CONV-005 is complete.
- `docs/PHASE2/phase2_contract.yml` is invariant-centric.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/PHASE2/PHASE2_CONTRACT.md` | Create | Human-readable Phase-2 contract |
| `scripts/audit/verify_gov_conv_008.sh` | Create | Verify required sections/references |
| `evidence/phase2/gov_conv_008_phase2_human_contract.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-008/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-008/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Machine contract edits
- Verifier CI wiring
- Phase-2 policy document
- Ratification artifacts

## Stop Conditions

- Stop if the machine contract is not invariant-centric.
- Stop if the human doc introduces claims absent from the machine contract.
- Stop if machine authority references are omitted.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create contract document [ID gov_conv_008_w01]

Create PHASE2_CONTRACT.md with Phase-2 identity, capability boundary, non-goals,
required artifacts, and authority references.

Done when all required sections are present.

### Step 2 - Declare authority boundary [ID gov_conv_008_w02]

State that `phase2_contract.yml` is authoritative for delivery-claimable rows.

Done when the authority statement is explicit.

### Step 3 - Reference verifier/evidence [ID gov_conv_008_w03]

Reference `verify_phase2_contract.sh` and `phase2_contract_status.json`.

Done when both references are present.

### Step 4 - Create document verifier [ID gov_conv_008_w04]

Create `verify_gov_conv_008.sh` to check required sections and references.

Done when missing-section fixtures fail.

### Step 5 - Emit evidence [ID gov_conv_008_w05]

Emit `gov_conv_008_phase2_human_contract.json`.

Done when required booleans are true.

## Verification