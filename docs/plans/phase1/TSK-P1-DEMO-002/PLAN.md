# TSK-P1-DEMO-002 Plan

Task ID: TSK-P1-DEMO-002

## objective
Implement SMS secure-link issuance for evidence submissions.

## scope
1. Link token generation/signing.
2. Link TTL and tenant binding.
3. Expired/tampered token rejection.

## acceptance_criteria
- Security checks are fail-closed.
- Evidence includes positive and negative path verification.

## remediation_trace
failure_signature: PHASE1.DEMO.002.SECURE_LINK_ISSUANCE_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_demo_002.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_002.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-002
origin_gate_id: PHASE1_DEMO_EVIDENCE_EDGE
