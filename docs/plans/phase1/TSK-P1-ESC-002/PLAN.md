# TSK-P1-ESC-002 PLAN

Task: TSK-P1-ESC-002
Failure Signature: PHASE1.ESC.002.CEILING_AND_TENANT_ISOLATION_REQUIRED
Canonical Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Repro Command
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Scope
- Bind programs to a canonical budget envelope (`programs.program_escrow_id` FK).
- Introduce explicit envelope balance row (`escrow_envelopes`) that is locked `FOR UPDATE` during reservations.
- Implement `authorize_escrow_reservation()` as a SECURITY DEFINER primitive that fails closed on oversubscription.
- Add a deterministic verifier that proves ceiling enforcement under 50 concurrent reservation attempts.

## Verification Commands
- `bash scripts/db/verify_tsk_p1_esc_002.sh --evidence evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-ESC-002 --evidence evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

