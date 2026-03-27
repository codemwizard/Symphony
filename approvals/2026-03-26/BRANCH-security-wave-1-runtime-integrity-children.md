## 1. Summary of Change

Refresh branch approval truth for `security/wave-1-runtime-integrity-children`
to cover the Green Finance wrong-diagnosis rollback and replacement task-pack
creation wave. This scope removes invalid diagnosis-linked artifacts, creates
the remediation casefile, creates the corrective `GF-W1-SCH-002A` and
`GF-W1-GOV-005A` packs, recreates repaired `GF-W1-SCH-003` through
`GF-W1-SCH-005` as narrowly targeted task packs, and updates the affected
Wave 1 dependency/registration documents.

## 2. Scope of Impact

This refreshed scope covers the branch work required for the remediation and
task-pack rebuild:

- `approvals/2026-03-26/BRANCH-security-wave-1-runtime-integrity-children.md`
- `approvals/2026-03-26/BRANCH-security-wave-1-runtime-integrity-children.approval.json`
- `evidence/phase1/approval_metadata.json`
- `docs/plans/phase1/REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback/PLAN.md`
- `docs/plans/phase1/REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback/EXEC_LOG.md`
- `tasks/GF-W1-SCH-002A/meta.yml`
- `docs/plans/phase0/GF-W1-SCH-002A/PLAN.md`
- `docs/plans/phase0/GF-W1-SCH-002A/EXEC_LOG.md`
- `tasks/GF-W1-GOV-005A/meta.yml`
- `docs/plans/phase0/GF-W1-GOV-005A/PLAN.md`
- `docs/plans/phase0/GF-W1-GOV-005A/EXEC_LOG.md`
- `tasks/GF-W1-SCH-003/meta.yml`
- `docs/plans/phase0/GF-W1-SCH-003/PLAN.md`
- `docs/plans/phase0/GF-W1-SCH-003/EXEC_LOG.md`
- `tasks/GF-W1-SCH-004/meta.yml`
- `docs/plans/phase0/GF-W1-SCH-004/PLAN.md`
- `docs/plans/phase0/GF-W1-SCH-004/EXEC_LOG.md`
- `tasks/GF-W1-SCH-005/meta.yml`
- `docs/plans/phase0/GF-W1-SCH-005/PLAN.md`
- `docs/plans/phase0/GF-W1-SCH-005/EXEC_LOG.md`
- `tasks/GF-W1-SCH-008/meta.yml`
- `tasks/GF-W1-PLT-001/meta.yml`
- `docs/tasks/PHASE0_TASKS.md`
- `docs/plans/GFW1_IMPLEMENTATION_PLAN_CORRECTED.md`
- `docs/plans/WAVE1_DAG.md`
- `docs/plans/wave1_dag.yml`

The rollback also removes the invalid diagnosis-linked artifacts under
`tasks/GF-W1-SCH-002` through `tasks/GF-W1-SCH-005`,
`docs/plans/phase0/GF-W1-SCH-002` through `docs/plans/phase0/GF-W1-SCH-005`,
the stale remediation folders from `2026-03-26`, and the invalid Green
Finance migrations `0081` through `0084` created under the wrong assumption.

## 3. Invariants & Phase Discipline

This refreshed approval preserves approval-trace integrity for `INV-119` while
authorizing the regulated-surface work required to restore the Green Finance
migration/task graph. It approves rollback and task-pack creation only. It does
not claim implementation of the future schema migrations or verifier code owned
by the newly created task packs.

## 4. AI Involvement Disclosure

Prepared with Codex acting in the Architect/Supervisor role. Human re-approval
is required because the reviewed branch scope has materially changed and now
includes regulated remediation and task-pack reconstruction.

## 5. Verification & Evidence

Verification for this refreshed approval requires:

- `bash scripts/audit/verify_human_governance_review_signoff.sh`
- `bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=security/wave-1-runtime-integrity-children`
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase0/GF-W1-SCH-002A/PLAN.md --meta tasks/GF-W1-SCH-002A/meta.yml`
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase0/GF-W1-GOV-005A/PLAN.md --meta tasks/GF-W1-GOV-005A/meta.yml`
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase0/GF-W1-SCH-003/PLAN.md --meta tasks/GF-W1-SCH-003/meta.yml`
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase0/GF-W1-SCH-004/PLAN.md --meta tasks/GF-W1-SCH-004/meta.yml`
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase0/GF-W1-SCH-005/PLAN.md --meta tasks/GF-W1-SCH-005/meta.yml`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/GF-W1-SCH-002A --json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/GF-W1-GOV-005A --json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/GF-W1-SCH-003 --json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/GF-W1-SCH-004 --json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/GF-W1-SCH-005 --json`
- `bash scripts/audit/verify_task_pack_readiness.sh --task GF-W1-SCH-002A`
- `bash scripts/audit/verify_task_pack_readiness.sh --task GF-W1-GOV-005A`
- `bash scripts/audit/verify_task_pack_readiness.sh --task GF-W1-SCH-003`
- `bash scripts/audit/verify_task_pack_readiness.sh --task GF-W1-SCH-004`
- `bash scripts/audit/verify_task_pack_readiness.sh --task GF-W1-SCH-005`

`pre_ci` cannot be recorded as passed until the branch reaches a truthful pass
state after later implementation work.

## 6. Risk Assessment

High integrity risk. A stale approval scope on this branch would make the
regulated rollback and Green Finance task-pack rebuild appear approved when they
were not. This refresh reduces that risk by making the branch approval package
match the actual remediation work now being performed.

## 7. Approval

Status: APPROVED
Approver: 0001
Approved At: 2026-03-27T03:24:04Z

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-03-26/BRANCH-security-wave-1-runtime-integrity-children.approval.json
