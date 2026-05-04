# TSK-P2-GOV-CONV-007 PLAN - Wire Phase-2 contract verifier

Task: TSK-P2-GOV-CONV-007
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-GOV-CONV-006
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-007.CONTRACT_WIRING_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Wire `scripts/audit/verify_phase2_contract.sh` into local and CI paths under
`RUN_PHASE2_GATES=1`.

Done means local pre-CI and CI reference the same canonical verifier and evidence
path, with fail-closed behavior.

## Regulated Surface Compliance

Approval metadata is required before editing `scripts/dev/pre_ci.sh`,
`.github/workflows/**`, `scripts/audit/**`, or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

A verifier that is not wired into local and CI workflows does not enforce the
contract. This task creates local/CI parity for Phase-2 contract verification.

## Pre-conditions

- TSK-P2-GOV-CONV-006 is complete.
- `scripts/audit/verify_phase2_contract.sh` exists and is executable.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/dev/pre_ci.sh` | Modify | Add RUN_PHASE2_GATES verifier path |
| `.github/workflows/ci.yml` | Modify | Add CI/local parity wiring |
| `scripts/audit/verify_gov_conv_007.sh` | Create | Verify wiring |
| `evidence/phase2/gov_conv_007_phase2_contract_wiring.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-007/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-007/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Changing `verify_phase2_contract.sh` behavior
- Changing `phase2_contract.yml`
- Creating human contract/policy docs
- Ratification artifacts

## Stop Conditions

- Stop if canonical verifier is absent.
- Stop if local and CI cannot invoke the same verifier path.
- Stop if wiring is warning-only under `RUN_PHASE2_GATES=1`.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Wire local pre-CI [ID gov_conv_007_w01]

Update `scripts/dev/pre_ci.sh` so `RUN_PHASE2_GATES=1` invokes
`bash scripts/audit/verify_phase2_contract.sh > evidence/phase2/phase2_contract_status.json`.

Done when local pre-CI calls the canonical verifier fail-closed.

### Step 2 - Wire CI [ID gov_conv_007_w02]

Update `.github/workflows/ci.yml` to call the same verifier command or the local
parity path that calls it.

Done when CI wiring uses the same verifier and evidence path.

### Step 3 - Create wiring verifier [ID gov_conv_007_w03]

Create `verify_gov_conv_007.sh` to inspect pre-CI and CI wiring.

Done when missing, divergent, or advisory-only wiring fixtures fail.

### Step 4 - Emit evidence [ID gov_conv_007_w04]

Emit `gov_conv_007_phase2_contract_wiring.json`.

Done when local and CI wiring fields are true and advisory_only is false.

## Verification