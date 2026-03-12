# TSK-P1-DEMO-017 Plan

Task ID: TSK-P1-DEMO-017

## objective
Create a repeatable tenant and programme provisioning runbook for partner onboarding without introducing a self-service UI.

## scope
1. Provisioning order and command checklist (including migration/bootstrap steps).
2. Required policy/programme configuration fields and default values.
3. Supplier seed data prerequisites and validation.
4. Pre-go-live isolation verification checklist and rollback notes.

## acceptance_criteria
- Runbook is deterministic and operator-executable.
- Policy/config/supplier seed requirements are explicit and complete.
- Isolation checks are mandatory before partner go-live.

## remediation_trace
failure_signature: PHASE1.DEMO.017.PROVISIONING_RUNBOOK_GAP
repro_command: bash scripts/audit/verify_tsk_p1_demo_017.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_demo_017.sh
final_status: planned
origin_task_id: TSK-P1-DEMO-017
origin_gate_id: PHASE1_DEMO_PARTNER_PROVISIONING
