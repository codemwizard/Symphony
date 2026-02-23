# TSK-P1-ESC-001 PLAN

Task: TSK-P1-ESC-001
Failure Signature: PHASE1.ESC.001.STATE_MODEL_ATOMIC_TRANSITIONS_REQUIRED
Canonical Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Add escrow state machine schema primitives (`escrow_accounts`, `escrow_events`) with append-only event posture.
- Implement `transition_escrow_state`, `release_escrow`, and `expire_escrows` with SECURITY DEFINER hardening.
- Add verifier evidence proving legal transitions, illegal transition rejection SQLSTATEs, and expiry reachability.

## Verification Commands
- `bash scripts/db/verify_tsk_p1_esc_001.sh --evidence evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-ESC-001 --evidence evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
