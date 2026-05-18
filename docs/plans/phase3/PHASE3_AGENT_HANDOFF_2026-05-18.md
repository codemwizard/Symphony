# Phase 3 Agent Handoff

Status: Non-canonical reference
Date: 2026-05-18
Purpose: Minimal restart packet for a new IDE/agent session so work can resume
without depending on chat history.

## Read First

Before doing any work in a new session, read these in order:

1. [AGENT_ENTRYPOINT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/AGENT_ENTRYPOINT.md:1)
2. [PHASE_EXECUTION_ENVELOPE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_EXECUTION_ENVELOPE.md:1)
3. [AGENT_PROMPT_ROUTER.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AGENT_PROMPT_ROUTER.md:1)
4. [AI_AGENT_OPERATION_MANUAL.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AI_AGENT_OPERATION_MANUAL.md:1)
5. [PHASE3_PHASE_EXECUTION_REFERENCE_2026-05-18.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/plans/phase3/PHASE3_PHASE_EXECUTION_REFERENCE_2026-05-18.md:1)

## Current Phase 3 Ground Truth

Use these as the authoritative Phase 3 planning/execution surfaces:

1. [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md:1)
2. [PHASE3_TASK_DAG.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_TASK_DAG.md:1)
3. [phase3_task_dag.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_dag.yml:1)
4. [phase3_task_registry.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_registry.yml:1)
5. [PHASE3_RUNTIME_TASKS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/tasks/PHASE3_RUNTIME_TASKS.md:1)
6. [PHASE3_SOURCE_PACK.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_SOURCE_PACK.md:1)
7. [PHASE3_EXECUTION_SURFACE_MAP.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md:1)
8. [implementation_plans/README.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/implementation_plans/README.md:1)

## Phase Status

- Phase 3 Waves 1 through 5 have been implemented.
- Wave-end `pre_ci.sh` has passed through Wave 5.
- Phase 3 truth surfaces were reconciled so completed waves no longer remain
  mislabeled as `tasks-created` in the main master-plan and DAG views.
- Phase 4 is not yet open for development under
  [PHASE_LIFECYCLE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_LIFECYCLE.md:1).

## Important Remediation History

These files explain the major task-pack/process failures and the fixes already
applied:

1. [REM-2026-05-17_phase3_task_pack_stubbed_verification_and_status_drift/PLAN.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/plans/phase3/REM-2026-05-17_phase3_task_pack_stubbed_verification_and_status_drift/PLAN.md:1)
2. [REM-2026-05-17_phase3_task_pack_stubbed_verification_and_status_drift/EXEC_LOG.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/plans/phase3/REM-2026-05-17_phase3_task_pack_stubbed_verification_and_status_drift/EXEC_LOG.md:1)

## Process Fixes Already In Place

Do not re-open these as unresolved unless repo evidence contradicts them:

1. Proof-before-completion lifecycle is implemented.
2. DB task-pack generator closure surfaces were fixed.
3. DB-facing verifiers now fail closed on bootstrap/connection failure.
4. Baseline privilege-state visibility and baseline entrypoint issues were fixed.
5. Stage A approval vs wave-end `pre_ci` semantics were reconciled.

## If The Next Session Needs To Continue Execution Work

Follow this order:

1. classify mode from `AGENT_ENTRYPOINT.md`
2. verify whether the work is planning, task creation, resume, implementation,
   or remediation
3. use the Phase 3 reference guide above rather than reconstructing the Phase 3
   process from chat history
4. reconcile truth surfaces after any real work

## If The Next Session Wants To Open Phase 4

Read first:

1. [PHASE_LIFECYCLE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_LIFECYCLE.md:1)
2. [lifecycle_phase_artifacts.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/rules/lifecycle_phase_artifacts.yml:1)
3. [docs/PHASE4/README.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE4/README.md:1)
4. [docs/PHASE4/phase4_contract.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE4/phase4_contract.yml:1)

Current blocker summary:

- `docs/PHASE4/PHASE4_CONTRACT.md` is still missing
- `docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md` is still missing
- `scripts/audit/verify_phase4_contract.sh` is still missing
- no `PHASE4-OPENING` approval bundle exists yet

So the next session should not treat Phase 4 as open until those artifacts are
created and approved through the canonical process.
