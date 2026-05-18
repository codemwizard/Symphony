# Branch Approval — Phase 4 Preparation, Approval-Parity Repair, And Rule 1 Remediation

**Date**: 2026-05-18  
**Approver**: mwiza  
**Scope**: Prepare the governed Phase 4 artifact set without switching the root execution envelope away from Phase 3, repair the active branch approval parity surfaces, and replace the structural-change exception bypass with real Rule 1 invariants linkage.  
**Status**: APPROVED

## Scope

This approval authorizes pre-open preparation work for Phase 4 under the still-active
Phase 3 envelope. It does not authorize a claim that Phase 4 is open. It authorizes
creation of the structural Phase 4 contract, policy, verifier, and planning artifacts
needed for lawful opening work, plus the next-phase anti-drift stubs for Phase 5.
It also authorizes the branch-governance repair needed to make the active approval
bundle and Rule 1 structural linkage mechanically valid after the prior commit
closed through exception files.

Approved regulated preparation surfaces:
- `docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md`
- `scripts/audit/verify_phase4_contract.sh`
- `docs/invariants/INVARIANTS_ROADMAP.md`
- `evidence/phase1/approval_metadata.json`

Approved preparation artifact surfaces:
- `docs/PHASE4/README.md`
- `docs/PHASE4/PHASE4_CONTRACT.md`
- `docs/PHASE4/phase4_contract.yml`
- `docs/PHASE4/PHASE4_SOURCE_PACK.md`
- `docs/PHASE4/PHASE4_CAPABILITY_BOUNDARY.md`
- `docs/PHASE4/PHASE4_EXECUTION_SURFACE_MAP.md`
- `docs/PHASE4/PHASE4_MASTER_IMPLEMENTATION_PLAN.md`
- `docs/PHASE4/PHASE4_TASK_DAG.md`
- `docs/PHASE4/phase4_task_dag.yml`
- `docs/PHASE4/implementation_plans/README.md`
- `docs/PHASE4/implementation_plans/TSK-P4-CAP-001_settlement_finality_and_rate_authority.md`
- `docs/PHASE4/implementation_plans/TSK-P4-CAP-002_statutory_allocations_and_kill_criteria.md`
- `docs/PHASE5/README.md`
- `docs/PHASE5/phase5_contract.yml`
- `docs/plans/phase3/REM-2026-05-18_structural_change_rule1_remediation/PLAN.md`
- `docs/plans/phase3/REM-2026-05-18_structural_change_rule1_remediation/EXEC_LOG.md`

## Change Reason

Human direction is to implement the approved Phase 4 opening plan as far as the
current lifecycle posture legally allows, then remediate the resulting branch
governance drift. The branch may prepare the structural artifacts needed for
Phase 4 while keeping the repository truthful that Phase 3 remains the active
lifecycle phase until Phase 3 closeout and a formal `PHASE4-OPENING` bundle are
completed. The same approval also authorizes the narrow governance repair needed
to restore approval-metadata parity and replace the prior exception-path Rule 1
closeout with explicit `INV-301` through `INV-310` linkage in `docs/invariants/**`.

## Boundaries

This approval does:
- authorize preparation of the Phase 4 contract, policy, verifier, and planning spine;
- authorize creation of the non-claimable Phase 5 stubs as a mandatory forward-governance baseline;
- authorize updates to Phase 4 stub documents so they become opening-ready preparation artifacts.
- authorize alignment of the active Stage A approval markdown, sidecar, and approval metadata evidence;
- authorize a remediation casefile and a narrow invariants roadmap linkage note for the already-registered Phase 3 structural invariants.

This approval does **not**:
- open Phase 4;
- authorize edits to `docs/operations/PHASE_EXECUTION_ENVELOPE.md`;
- authorize creation of `approvals/*/PHASE4-OPENING.*`;
- claim that Phase 3 closeout is complete;
- authorize runtime implementation tasks under Phase 4.

## Verification Plan

- `bash scripts/audit/verify_phase4_contract.sh`
- `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations`
- `PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feat/p3-wave1-lineage=foundations`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `bash scripts/audit/preflight_structural_staged.sh`

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-05-18/BRANCH-feat-p3-wave1-lineage=foundations.approval.json
