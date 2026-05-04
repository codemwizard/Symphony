# TSK-P2-GOV-CONV-009 PLAN - Verify Phase-2 human and machine contract alignment

Task: TSK-P2-GOV-CONV-009
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-GOV-CONV-006, TSK-P2-GOV-CONV-008
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-009.CONTRACT_ALIGNMENT_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create a verifier proving that `docs/PHASE2/PHASE2_CONTRACT.md` does not contain
delivery-claim invariant references unsupported by `docs/PHASE2/phase2_contract.yml`.

Done means unsupported human claims fail closed and PASS evidence records alignment
for the live repository.

## Regulated Surface Compliance

Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The human contract is explanatory. The machine contract is authoritative. This
verifier prevents human-readable prose from becoming an unverified source of
delivery claims.

## Pre-conditions

- TSK-P2-GOV-CONV-006 is complete.
- TSK-P2-GOV-CONV-008 is complete.
- `PHASE2_CONTRACT.md` and `phase2_contract.yml` exist.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_gov_conv_009.sh` | Create | Verify human/machine contract alignment |
| `evidence/phase2/gov_conv_009_human_machine_contract_alignment.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-009/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-009/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Editing human contract text
- Editing machine contract rows
- Editing canonical Phase-2 contract verifier
- CI wiring

## Stop Conditions

- Stop if prerequisite contract files are missing.
- Stop if unsupported claims cannot be distinguished from explanatory text.
- Stop if missing authority references would be accepted.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Extract machine rows [ID gov_conv_009_w01]

Parse `phase2_contract.yml` and extract invariant IDs and required rows.

Done when structured machine row extraction works.

### Step 2 - Extract human claims [ID gov_conv_009_w02]

Inspect `PHASE2_CONTRACT.md` for delivery-claim invariant references and required
authority references.

Done when human claims and references are listed in evidence.

### Step 3 - Reject drift [ID gov_conv_009_w03]

Fail for unsupported claims or missing authority/verifier/evidence references.

Done when bad fixtures fail.

### Step 4 - Add negative fixtures [ID gov_conv_009_w04]

Add fixtures for unsupported invariant claim, missing authority statement, and
missing verifier reference.

Done when each fixture fails for the expected reason.

### Step 5 - Emit evidence [ID gov_conv_009_w05]

Emit `gov_conv_009_human_machine_contract_alignment.json`.

Done when live evidence has `alignment_status: PASS`.

## Verification