# TSK-P1-DEMO-030 Execution Log

failure_signature: PHASE1.DEMO.030.TASK_LINE_COLLISION
origin_task_id: TSK-P1-DEMO-030
Plan: docs/plans/phase1/TSK-P1-DEMO-030/PLAN.md

## repro_command
`bash scripts/audit/verify_tsk_p1_demo_030.sh`

## verification_commands_run
- `bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-DEMO-030`
- `bash scripts/audit/verify_agent_conformance.sh`
- `bash scripts/dev/pre_ci.sh`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy`
- `bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-DEMO-029 --task TSK-P1-DEMO-030`
- `bash scripts/audit/verify_tsk_p1_demo_030.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-030 --evidence evidence/phase1/tsk_p1_demo_030_branch_repair.json`
- `bash scripts/audit/verify_human_governance_review_signoff.sh`
- `bash scripts/audit/verify_invproc_06_ci_wiring_closeout.sh`
- `bash scripts/audit/verify_tsk_p1_063.sh`
- `bash scripts/dev/pre_ci.sh`

## final_status
COMPLETED

## execution_notes
- Task pack created because demo task IDs on feat/ui-wire-wave-e no longer match the canonical `001..028` line from main.
- Scope repaired before branch surgery so the task explicitly covers the destination branch `feat/demo-deployment-repair` and its branch-linked approval artifacts.
- Implementation must move deployment repair work onto a new main-based branch instead of rewriting the published Wave-E branch.
- After the branch move, full `pre_ci` exposed a `TSK-P1-063` Git-mutation audit gap for the new verifier surface; remediation casefile and audit-doc repair are now in scope for this task.
- Local `main` was fast-forward aligned with `origin/main`, the dirty Wave-E tree was moved onto `feat/demo-deployment-repair`, canonical `TSK-P1-DEMO-024..028` remained intact from updated mainline, and the provisioning sample-pack task was rehomed to `TSK-P1-DEMO-029`.
- Final branch-linked approval artifacts now point to `approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.*`, and full `pre_ci` passed on the repaired branch after the targeted Git-mutation audit remediation.

## Final Summary
- Repaired the demo task-line collision on a clean main-based branch instead of rewriting the published Wave-E branch.
- Preserved canonical `TSK-P1-DEMO-024..028` identities from mainline and rehomed the sample-pack work to `TSK-P1-DEMO-029`.
- Refreshed branch-linked approval metadata for `feat/demo-deployment-repair` and closed the Git-mutation audit remediation so the repaired branch passes full `pre_ci`.
