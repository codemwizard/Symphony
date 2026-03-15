# REM-2026-03-14 demo-runbook-hardening-batch PLAN

failure_signature: PHASE1.DEMO.RUNBOOK.HARDENING.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P1-DEMO-018,TSK-P1-DEMO-019,TSK-P1-DEMO-020,TSK-P1-DEMO-021,TSK-P1-DEMO-022
origin_gate_id: PHASE1_DEMO_RUNBOOK_HARDENING_BATCH
first_observed_utc: 2026-03-14T00:00:00Z
where: local planning and task-pack creation on feat/ui-wire-wave-e

## repro_command
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy`
- `bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-DEMO-018 --task TSK-P1-DEMO-019 --task TSK-P1-DEMO-020 --task TSK-P1-DEMO-021 --task TSK-P1-DEMO-022`

## scope_boundary
- In scope: task-pack creation, verifier scaffolding, remediation trace scaffolding, and later regulated-surface implementation for the host-based demo runbook/tooling batch.
- Out of scope: schema changes, product-feature changes, Kubernetes-first deployment, and any synthetic human approval artifact pretending the batch is already approved.

## initial_hypotheses
- The batch requires a durable remediation trace because it touches `scripts/**` and regulated operator/security docs.
- The existing branch approval sidecar for Wave E should not be mutated until implementation scope is concrete and human-reviewed.
- Task-pack readiness must pass before any regulated implementation begins.

## verification_commands_run
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy`
- `bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-DEMO-018 --task TSK-P1-DEMO-019 --task TSK-P1-DEMO-020 --task TSK-P1-DEMO-021 --task TSK-P1-DEMO-022`

## approval_references
- Existing branch approval remains at `approvals/2026-03-13/BRANCH-feat-ui-wire-wave-e.approval.json` for the prior Wave E batch.
- Before implementing this new batch on regulated surfaces, branch approval scope and `evidence/phase1/approval_metadata.json` must be refreshed to the actual implementation diff.

## final_status
- planned
