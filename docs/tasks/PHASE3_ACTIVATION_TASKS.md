# Phase 3 Activation Tasks

Source of truth for the formal activation sequence created after explicit human
intervention on 2026-05-16. This file is the current activation-track task
index and supersedes the stale pre-entry register for activation governance.

| Task ID | Title | Owner | Depends On | Touches | Evidence |
|---|---|---|---|---|---|
| TSK-P3-ACT-001 | Build the missing Phase 3 lifecycle artifact set | SECURITY_GUARDIAN | TSK-P3-CLEAN-001, TSK-P3-CLEAN-002, TSK-P3-CLEAN-003, TSK-P3-CLEAN-004, TSK-P3-CLEAN-005, TSK-P3-CLEAN-006, TSK-P3-CLEAN-007, TSK-P3-CLEAN-008 | `docs/PHASE3/PHASE3_CONTRACT.md`, `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`, `scripts/audit/verify_phase3_contract.sh` | `evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json` |
| TSK-P3-ACT-002 | Create the formal Phase 3 opening approval artifact set | ARCHITECT | TSK-P3-ACT-001 | `approvals/2026-05-16/PHASE3-OPENING.md`, `approvals/2026-05-16/PHASE3-OPENING.approval.json`, `scripts/agent/verify_tsk_p3_act_002.sh` | `evidence/phase3/tsk_p3_act_002_opening_approval.json` |
| TSK-P3-ACT-003 | Rewrite the root execution envelope for active Phase 3 status | ARCHITECT | TSK-P3-ACT-001, TSK-P3-ACT-002 | `docs/operations/PHASE_EXECUTION_ENVELOPE.md`, `scripts/agent/verify_tsk_p3_act_003.sh`, `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | `evidence/phase3/tsk_p3_act_003_envelope_alignment.json` |
| TSK-P3-ACT-004 | Reconcile the legality layer and dependent Phase 3 planning posture | ARCHITECT | TSK-P3-ACT-003 | `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`, `docs/PHASE3/README.md`, `docs/PHASE3/PHASE3_SOURCE_PACK.md`, `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md`, `docs/PHASE3/PHASE3_OPENING_ACT.md`, `scripts/agent/verify_tsk_p3_act_004.sh` | `evidence/phase3/tsk_p3_act_004_legality_alignment.json` |
| TSK-P3-ACT-005 | Normalize existing Phase 3 plans and evidence for opened-phase use | ARCHITECT | TSK-P3-ACT-004 | `docs/plans/phase3/phase3_artifact_classification_manifest.json`, `docs/plans/phase3/PHASE3_OPENED_PHASE_ARTIFACT_CLASSIFICATION.md`, `scripts/agent/verify_tsk_p3_act_005.sh`, `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | `evidence/phase3/tsk_p3_act_005_artifact_normalization.json` |
