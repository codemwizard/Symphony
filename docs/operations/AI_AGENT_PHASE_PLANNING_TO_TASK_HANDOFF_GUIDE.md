# AI Agent Phase Planning To Task Handoff Guide

Status: Canonical
Owner: Operations / Governance
Audience: AI agents first; human programmers second

## Purpose

This document is the single operating guide for the new Symphony flow from
phase-level planning to atomic task creation. It exists because
`CREATE-IMPLEMENTATION-PLAN` is a separate mode from `CREATE-TASK`.

Use this guide when an agent or human needs to understand whether work is still
planning, whether it is ready for task scaffolding, and where each artifact
belongs.

This guide does not authorize implementation. It routes agents to the correct
mode and artifact layer.

## First Rule

Always start with `AGENT_ENTRYPOINT.md`.

Then classify the prompt using `docs/operations/AGENT_PROMPT_ROUTER.md`.

If the prompt asks for master plans, source packs, execution-surface maps,
phase DAGs, capability plans, cleanup plans, or readiness plans before atomic
task packs exist, the mode is:

```text
CREATE-IMPLEMENTATION-PLAN
```

If the prompt asks to create a real task pack with `tasks/<TASK_ID>/meta.yml`,
task `PLAN.md`, task `EXEC_LOG.md`, verifiers, and evidence expectations, the
mode is:

```text
CREATE-TASK
```

Do not merge these modes.

## Artifact Ladder

The planning-to-task ladder is:

```text
Governing doctrine
  -> phase source pack
  -> capability boundary
  -> execution surface map
  -> task universe and DAG
  -> master implementation plan
  -> surface-specific implementation plan
  -> atomic task pack
  -> task implementation
  -> verifier evidence and execution log
```

An agent must not skip from master implementation plan directly to
implementation.

## Artifact Ownership

| Layer | Example | Purpose | Creates atomic task pack? |
|---|---|---|---|
| Source pack | `docs/PHASE3/PHASE3_SOURCE_PACK.md` | Maps canonical inputs and blockers. | No |
| Capability boundary | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` | Routes capability domains to governing doctrine. | No |
| Execution surface map | `docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md` | Defines constitutionally owned implementation surfaces. | No |
| Phase DAG | `docs/PHASE3/PHASE3_TASK_DAG.md`, `docs/PHASE3/phase3_task_dag.yml` | Sequences planning nodes and blockers. | No |
| Master implementation plan | `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | Owns the full phase planning universe. | No |
| Surface-specific implementation plan | `docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md` | Refines a surface or cleanup wave into task candidates. | No |
| Atomic task pack | `tasks/<TASK_ID>/meta.yml`, `docs/plans/phase<N>/<TASK_ID>/PLAN.md`, `EXEC_LOG.md` | Defines one executable implementation unit. | Yes |

Atomic task `PLAN.md` and `EXEC_LOG.md` files never live inside the master
implementation plan. They live under `docs/plans/phase<N>/<TASK_ID>/`.

## Current Phase 3 Planning State

For Phase 3, the planning universe has been established but atomic cleanup
tasks are not yet created.

Current surface-specific governance cleanup plan:

```text
docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md
```

This plan covers the Pre-Phase 3 Wave:

```text
TSK-P3-CLEAN-001
TSK-P3-CLEAN-002
TSK-P3-CLEAN-003
TSK-P3-CLEAN-004
TSK-P3-CLEAN-005
TSK-P3-CLEAN-006
TSK-P3-CLEAN-007
TSK-P3-CLEAN-008
```

Those are not executable tasks until `CREATE-TASK` creates task packs for them.

## `depends_on` vs `blocked_by`

Use these fields precisely.

`depends_on` is structural sequence:

```yaml
depends_on:
  - TSK-P3-CLEAN-007
```

It means the listed predecessor is part of the expected DAG order and must be
completed before the current task can start.

`blocked_by` is active impediment handling:

```yaml
blocked_by:
  - TSK-P3-CLEAN-001
```

It means the task is currently halted by an active blocker, root gate,
governance conflict, missing doctrine, failed readiness check, remediation
blocker, or execution-envelope conflict.

Do not duplicate normal predecessors from `depends_on` in `blocked_by`.
Transitive dependency blockage is derived from the DAG.

When a human says to run a wave "at once," treat that as sequenced execution by
the DAG, not parallel execution, unless the plan explicitly says otherwise.

## Phase 3 Wave 0 Sequence

The Pre-Phase 3 Wave uses this sequencing model:

| Node | Direct `depends_on` | Active `blocked_by` |
|---|---|---|
| `TSK-P3-CLEAN-001` | none | none |
| `TSK-P3-CLEAN-002` | none | `TSK-P3-CLEAN-001` |
| `TSK-P3-CLEAN-003` | none | `TSK-P3-CLEAN-001` |
| `TSK-P3-CLEAN-004` | none | `TSK-P3-CLEAN-001` |
| `TSK-P3-CLEAN-005` | none | `TSK-P3-CLEAN-001` |
| `TSK-P3-CLEAN-006` | none | `TSK-P3-CLEAN-001` |
| `TSK-P3-CLEAN-007` | `TSK-P3-CLEAN-001`, `TSK-P3-CLEAN-003` | none after dependencies resolve |
| `TSK-P3-CLEAN-008` | `TSK-P3-CLEAN-007` | none after dependencies resolve |

`TSK-P3-CLEAN-004` records the execution-envelope conflict as its substantive
cleanup target. It is not the root wave blocker unless a later plan explicitly
promotes it to that role.

## Mode Handoff Rules

### Stay In `CREATE-IMPLEMENTATION-PLAN` When

- The output is a master plan, source pack, execution surface map, phase DAG, or
  surface-specific implementation plan.
- The work describes candidate task IDs but does not create task packs.
- The artifact states acceptance criteria and verifier expectations for future
  tasks but does not create verifier scripts or evidence files.
- The plan is refining `TSK-P3-CAP-*`, `TSK-P3-WP-*`, or cleanup-wave planning.

### Switch To `CREATE-TASK` When

- The next artifact must create `tasks/<TASK_ID>/meta.yml`.
- The next artifact must create `docs/plans/phase<N>/<TASK_ID>/PLAN.md`.
- The next artifact must create `docs/plans/phase<N>/<TASK_ID>/EXEC_LOG.md`.
- A single atomic implementation unit is being defined.

`CREATE-TASK` must follow `docs/operations/TASK_CREATION_PROCESS.md` and must
use the task generator.

## Atomic Task Creation Preconditions

Before converting a planning node into an atomic task pack, confirm:

- the node appears in the phase DAG;
- the node maps to an execution surface;
- the surface-specific implementation plan exists;
- governing doctrine is cited;
- direct `depends_on` and active `blocked_by` are known;
- touch paths are narrow enough for one agent role;
- at least one observable acceptance criterion exists;
- at least one deterministic verifier command or concrete evidence output is
  known;
- no active execution-envelope conflict is being ignored.

If any of these are missing, remain in `CREATE-IMPLEMENTATION-PLAN` or create a
cleanup/remediation planning item. Do not scaffold a fake task pack.

## Atomic Task Pack Requirements

Every atomic task pack must include:

- `tasks/<TASK_ID>/meta.yml`;
- `docs/plans/phase<N>/<TASK_ID>/PLAN.md`;
- `docs/plans/phase<N>/<TASK_ID>/EXEC_LOG.md`;
- exactly one primary objective;
- `depends_on` for structural predecessors;
- `blocked_by` only for active impediments;
- strict `touches`;
- observable acceptance criteria;
- deterministic verification;
- declared evidence path;
- failure mode `Evidence file missing`;
- stop conditions for scope drift and proof weakness;
- proof graph alignment under `TSK-P1-240` rules.

Implementation may not start until task-pack readiness passes.

## Stop Conditions For Agents

Stop and report instead of proceeding when:

- the prompt cannot be classified into exactly one mode;
- a planning artifact tries to create task packs;
- a task pack is requested without required `CREATE-TASK` inputs;
- `blocked_by` duplicates ordinary `depends_on` entries;
- a wave is treated as parallel when the DAG only authorizes sequence;
- a master implementation plan attempts to contain atomic task `PLAN.md` or
  `EXEC_LOG.md` content;
- a task is treated as implementation-ready without generated task pack files;
- the execution envelope blocks the requested work.

## Human Programmer Use

For human programmers, this guide answers where to look:

- Use the master implementation plan to understand the full phase universe.
- Use the phase DAG to understand sequencing.
- Use surface-specific implementation plans to understand task candidates.
- Use atomic task packs to implement work.
- Do not implement from planning nodes alone.

For AI agents, this guide is binding mode discipline: classify first, use the
right artifact layer, and never invent readiness.

