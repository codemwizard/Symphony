# TSK-P2-GOV-CONV-006 PLAN - Create canonical Phase-2 contract verifier

Task: TSK-P2-GOV-CONV-006
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-GOV-CONV-005
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-006.CONTRACT_VERIFIER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create `scripts/audit/verify_phase2_contract.sh`, the canonical fail-closed verifier
for `docs/PHASE2/phase2_contract.yml`.

Done means malformed rows, invalid statuses, unregistered invariants, missing
verifier/evidence fields, and task_id rows all fail deterministically, while the
live contract emits PASS evidence.

## Regulated Surface Compliance

- Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.
- Stage A approval must exist before edits.
- Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The rewritten machine contract needs an independent reusable verifier before it can
be wired into local or CI workflows. This task creates the verifier but deliberately
does not wire it into CI.

## Pre-conditions

- TSK-P2-GOV-CONV-005 is complete.
- `docs/PHASE2/phase2_contract.yml` is invariant-centric.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_phase2_contract.sh` | Create | Canonical Phase-2 contract verifier |
| `evidence/phase2/phase2_contract_status.json` | Emit | Contract verifier evidence |
| `tasks/TSK-P2-GOV-CONV-006/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-006/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- CI wiring
- `scripts/dev/pre_ci.sh` wiring
- Human-readable contract document
- Phase-2 policy document
- Ratification approval artifacts

## Stop Conditions

- Stop if the Phase-2 machine contract still uses task_id rows.
- Stop if the verifier cannot parse YAML as structured data.
- Stop if required violations are warnings rather than failures.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Parse contract structure [ID gov_conv_006_w01]

Create `verify_phase2_contract.sh` to parse `phase2_contract.yml` as YAML and
validate required row fields.

Done when malformed rows fail.

### Step 2 - Enforce status vocabulary [ID gov_conv_006_w02]

Reject statuses outside `phase1_prerequisite`, `planned`, `implemented`, and
`deferred_to_phase3`.

Done when invalid-status fixtures fail.

### Step 3 - Enforce references [ID gov_conv_006_w03]

Check that invariant IDs are registered and required rows have verifier and
evidence_path values.

Done when missing-reference fixtures fail.

### Step 4 - Add negative fixtures [ID gov_conv_006_w04]

Include negative checks for invalid status, missing invariant, missing verifier,
missing evidence_path, and task_id rows.

Done when each negative fixture fails for the expected reason.

### Step 5 - Emit evidence [ID gov_conv_006_w05]

Emit `phase2_contract_status.json`.

Done when violation arrays are empty only for a valid contract.

## Verification