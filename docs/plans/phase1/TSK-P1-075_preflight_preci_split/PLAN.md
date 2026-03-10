# TSK-P1-075 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Task: TSK-P1-075

## Goal
Implement the intended two-level local gate model: light pre-flight immediately after commit, heavy pre-CI on push.

## Scope
- Define the light pre-flight surface and responsibilities.
- Preserve the heavy push-time pre-CI surface.
- Ensure the two levels are distinct in code, docs, and verifier behavior.

## Acceptance Criteria
- Light pre-flight and heavy pre-CI are separate execution paths.
- Push-time parity remains heavy and authoritative.
- The light gate does not rerun the heavy stack.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_075.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
