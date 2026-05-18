# Phase 3 Phase Execution Reference

Status: Non-canonical reference
Purpose: IDE / agent orientation guide for executing a full Symphony phase from
planning inception through task implementation without drifting from the
canonical process.

This document is a reference only. It does not override canonical governance.
For authority, always defer to the exact documents cited below.

## Scope

This guide explains how an agent should start a phase, build its canonical
planning stack, create task packs, and reach `RESUME-TASK` / `IMPLEMENT-TASK`
correctly. It is written from the Phase 3 execution path we just completed, but
the sequence is based on the general canonical process rather than on
Phase-3-only improvisation.

## 1. Start With Root Control, Not The Phase Docs

Before creating or modifying anything, read these in order:

1. [AGENT_ENTRYPOINT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/AGENT_ENTRYPOINT.md:1)
2. [PHASE_EXECUTION_ENVELOPE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_EXECUTION_ENVELOPE.md:1)
3. [AGENT_PROMPT_ROUTER.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AGENT_PROMPT_ROUTER.md:1)
4. [AI_AGENT_OPERATION_MANUAL.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AI_AGENT_OPERATION_MANUAL.md:1)

What these do:
- `AGENT_ENTRYPOINT.md` is the session entrypoint and mode gate.
- `PHASE_EXECUTION_ENVELOPE.md` is the root control artifact for whether the
  phase is legally executable.
- `AGENT_PROMPT_ROUTER.md` decides whether you are in
  `CREATE-IMPLEMENTATION-PLAN`, `CREATE-TASK`, `RESUME-TASK`,
  `IMPLEMENT-TASK`, `REMEDIATE`, or `PUSH-READY-CHECK`.
- `AI_AGENT_OPERATION_MANUAL.md` is the apex operational authority.

If you do not identify exactly one mode, stop there. Do not write files.

## 2. Determine Whether The Phase Is Openable

Before building phase plans, inspect the lifecycle and artifact rules:

1. [PHASE_LIFECYCLE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_LIFECYCLE.md:1)
2. [lifecycle_phase_artifacts.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/rules/lifecycle_phase_artifacts.yml:1)
3. The phase’s opening act and contract artifacts

For Phase 3, the canonical opening/readiness stack was:

1. [PHASE3_OPENING_ACT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_OPENING_ACT.md:1)
2. [PHASE3_CONTRACT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_CONTRACT.md:1)
3. [phase3_contract.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_contract.yml:1)

The lesson: do not start from a wave. Start from whether the phase has an
admissible lifecycle posture at all.

## 3. Build The Canonical Planning Spine

If the mode is `CREATE-IMPLEMENTATION-PLAN`, the canonical process is:

1. [IMPLEMENTATION_PLAN_CREATION_PROCESS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md:1)
2. [AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md:1)

The required planning artifact ladder is:

1. phase source pack
2. capability boundary
3. execution surface map
4. task universe and DAG
5. master implementation plan
6. surface-specific implementation plans
7. atomic task packs

For Phase 3, the canonical planning spine became:

1. [PHASE3_SOURCE_PACK.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_SOURCE_PACK.md:1)
2. [PHASE3_CAPABILITY_BOUNDARY.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md:1)
3. [PHASE3_EXECUTION_SURFACE_MAP.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md:1)
4. [PHASE3_TASK_DAG.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_TASK_DAG.md:1)
5. [phase3_task_dag.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_dag.yml:1)
6. [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md:1)
7. [implementation_plans/README.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/implementation_plans/README.md:1)

Do not create task packs until these artifacts agree.

## 4. Use The Master Plan As The Phase Task-Universe Authority

The phase master implementation plan is the full planning universe for the
phase. For Phase 3, that authority was:

- [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md:1)

What to do here:
- create the broad phase plan and wave segmentation
- register work-package nodes
- bind them to execution surfaces
- keep doctrine and future-phase isolation explicit
- register CAP plans in the implementation plan index

Do not jump from the master plan straight to code. The next layer is
surface-specific planning.

## 5. Refine With Surface-Specific CAP Plans

Once the master plan and DAG exist, create the capability / surface plans under:

- [docs/PHASE3/implementation_plans/](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/implementation_plans)

Use these as the pattern:
- broad wave plans: `TSK-P3-PLAN-*`
- surface or capability plans: `TSK-P3-CAP-*`

Each CAP must:
- refine a node already present in the master plan
- cite doctrine and non-goals
- avoid inventing new phase scope
- clarify support-node routing and anti-drift constraints

Phase 3 used this step repeatedly before every `CREATE-TASK` batch.

## 6. Only Then Create Atomic Task Packs

When the mode becomes `CREATE-TASK`, switch to:

1. [TASK_CREATION_PROCESS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/TASK_CREATION_PROCESS.md:1)
2. [AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md:1)

The required atomic artifacts are:

1. `tasks/<TASK_ID>/meta.yml`
2. `docs/plans/phase<N>/<TASK_ID>/PLAN.md`
3. `docs/plans/phase<N>/<TASK_ID>/EXEC_LOG.md`

The important state model is:
- `planned`
- `task-packed`
- `resume-ready`
- `completed`

In historical Phase 3 truth surfaces, `tasks-created` must be read as
`task-packed`, not as implemented.

## 7. Repair The Task Pack Before Implementation If Needed

Before implementation, task creation must be checked mechanically:

1. `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks --scope all`
2. `bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>`

If the pack, plan, or log drift from each other, repair the task pack before
starting code work. This was a major Phase 3 lesson: do not compensate for
broken packs during implementation if you can fix the contract first.

## 8. Use `RESUME-TASK` To Determine Whether Implementation Is Legal

Before `IMPLEMENT-TASK`, re-read:

1. [AGENT_ENTRYPOINT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/AGENT_ENTRYPOINT.md:1)
2. [AGENT_PROMPT_ROUTER.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/AGENT_PROMPT_ROUTER.md:1)
3. [SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md:1)

The canonical rule is:
- do not implement directly from “task exists”
- inspect for `resume-ready`

That means:
- meta present
- plan present
- log present
- readiness passes
- verifier contract is executable
- dependencies are completed
- blockers are cleared

Only after that may the task enter `IMPLEMENT-TASK`.

## 9. Implement The Task, Produce Proof, Then Mark Completion

The implementation process is governed by:

1. [SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md:1)
2. [AGENT_ENTRYPOINT.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/AGENT_ENTRYPOINT.md:1)

In raw canonical form, `IMPLEMENT-TASK` boot is:
1. `scripts/audit/verify_agent_conformance.sh`
2. `scripts/dev/pre_ci.sh`
3. `scripts/agent/run_task.sh <TASK_ID>`

Operational Phase 3 practice refined this at wave level:
- task-specific proof and evidence were produced per task
- wave-end `pre_ci.sh` was run once per wave for cost reasons
- final wave closeout only occurred after the wave-end `pre_ci.sh` pass

That wave-level optimization worked because the task packs and truth surfaces
were kept consistent and the wave closeout still used the canonical parity gate.

## 10. Keep The Canonical Truth Surfaces Reconciled

After planning, task creation, implementation, and wave closeout, reconcile:

1. [PHASE3_MASTER_IMPLEMENTATION_PLAN.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md:1)
2. [PHASE3_TASK_DAG.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/PHASE3_TASK_DAG.md:1)
3. [phase3_task_dag.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_dag.yml:1)
4. [phase3_task_registry.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_registry.yml:1)
5. [PHASE3_RUNTIME_TASKS.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/tasks/PHASE3_RUNTIME_TASKS.md:1) when runtime task indexing is affected

If these drift, future agents will make sequencing or readiness mistakes even
if the implementation itself is correct.

## 11. Phase-Level Closeout Heuristic Used In Practice

Phase 3 did not use a single standalone “phase closeout script.” In practice,
phase closeout meant:

1. every phase DAG node intended for delivery was `completed`
2. every wave had passed its wave-end `pre_ci.sh`
3. the master plan, DAG, registry, and runtime task indexes were reconciled
4. evidence and verifier artifacts existed for the implemented nodes
5. remediation items were either closed or intentionally deferred

This is the practical checklist an IDE agent should use until a single explicit
phase-closeout procedure is canonicalized.

## 12. What To Read Before Opening The Next Phase

To open the next phase, read:

1. [PHASE_LIFECYCLE.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/PHASE_LIFECYCLE.md:289)
2. [lifecycle_phase_artifacts.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/rules/lifecycle_phase_artifacts.yml:1)
3. the next phase stub/contract files

The minimum required artifacts for Phase 4 are:
- `docs/PHASE4/PHASE4_CONTRACT.md`
- `docs/PHASE4/phase4_contract.yml`
- `evidence/phase4/**`

At the moment, Phase 4 still has:
- [README.md](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE4/README.md:1) marking it not open
- [phase4_contract.yml](/home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE4/phase4_contract.yml:1) as a non-claimable stub
- no `PHASE4_CONTRACT.md`

So Phase 4 is not yet openable without additional canonical opening work.

## 13. Short Practical Sequence For A Fresh Agent

If you are starting a new phase from scratch, the safe sequence is:

1. read `AGENT_ENTRYPOINT.md`
2. read `PHASE_EXECUTION_ENVELOPE.md`
3. classify mode with `AGENT_PROMPT_ROUTER.md`
4. confirm phase lifecycle/opening posture with `PHASE_LIFECYCLE.md`
5. build source pack, capability boundary, execution surface map, DAG, and master plan
6. create CAP plans for the new surfaces or waves
7. create atomic task packs with `TASK_CREATION_PROCESS.md`
8. verify packs mechanically
9. inspect `RESUME-TASK` legality
10. implement, prove, emit evidence
11. run wave-end `pre_ci.sh`
12. reconcile truth surfaces
13. only then treat the wave or phase as closed
