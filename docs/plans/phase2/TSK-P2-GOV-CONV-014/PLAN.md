# TSK-P2-GOV-CONV-014 PLAN - Create semantic phase claim admissibility verifier

Task: TSK-P2-GOV-CONV-014
Owner: SECURITY_GUARDIAN
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-014.CLAIM_ADMISSIBILITY_VERIFIER_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Create `scripts/audit/verify_phase_claim_admissibility.sh`, a semantic verifier
for phase-key and phase-claim admissibility.

Done means invalid phase keys, phase-complete overclaims, future-phase delivery
claims, and capability-laundering language fail closed, while approved non-claimable
contexts remain allowed.

## Regulated Surface Compliance

Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Numeric phase validation is insufficient. Agents can still drift through semantic
claims such as "Phase complete", "Phase-3 ready", or scaffold-as-readiness language.
This verifier blocks those patterns mechanically.

## Pre-conditions

- `docs/operations/PHASE_LIFECYCLE.md` is readable.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_phase_claim_admissibility.sh` | Create | Semantic phase-claim verifier |
| `evidence/phase2/phase_claim_admissibility.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-014/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-014/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Fixing existing violations
- Wiring verifier into local/CI gates
- Creating future-phase scaffold files
- Editing task metadata

## Stop Conditions

- Stop if phase lifecycle policy cannot be read.
- Stop if negative fixtures do not fail.
- Stop if exact violation path and pattern cannot be reported.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create verifier [ID gov_conv_014_w01]

Create the scanner for task metadata and configured governance docs.

Done when violations include path, field or line, and matched pattern.

### Step 2 - Enforce phase keys [ID gov_conv_014_w02]

Allow only lifecycle phase keys `0`, `1`, `2`, `3`, and `4`.

Done when dotted or named phase fixtures fail.

### Step 3 - Enforce semantic blocked patterns [ID gov_conv_014_w03]

Reject phase-open, phase-complete, phase-ready, delivery-claimable, future-phase
implementation, and capability-laundering language.

Done when semantic overclaim fixtures fail.

### Step 4 - Allow valid contexts [ID gov_conv_014_w04]

Allow approved ratification contexts and explicitly non-claimable scaffold language
without allowing broad overclaims.

Done when valid scaffold fixtures pass.

### Step 5 - Add negative fixtures [ID gov_conv_014_w05]

Add invalid phase key, phase-complete overclaim, future-phase claim, and scaffold
misuse fixtures.

Done when all fail for expected reasons.

### Step 6 - Emit evidence [ID gov_conv_014_w06]

Emit `phase_claim_admissibility.json`.

Done when live evidence includes scan stats and violation details.

## Verification