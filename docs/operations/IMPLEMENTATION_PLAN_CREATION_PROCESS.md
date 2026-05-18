# Implementation Plan Creation Process

Status: Canonical
Owner: Operations / Governance

## Purpose

This document defines how agents create broad implementation plans before atomic
Symphony task packs exist.

Implementation plans are not task packs. They do not create `tasks/<TASK_ID>/`,
task `PLAN.md`, task `EXEC_LOG.md`, verifier scripts, migrations, or evidence
artifacts. They define source packs, constitutional execution surfaces, task
universes, DAG sequencing, doctrine dependencies, cleanup blockers, and
task-creation gates that later atomic task creation must obey.

Tasks do not define architecture. Tasks implement constitutionally owned
execution surfaces.

Use this process when the requested output is a phase source-pack index, master
implementation plan, execution-surface map, phase DAG, surface-specific
implementation plan, cleanup implementation plan, readiness plan, or similar
pre-task planning artifact.

---

## Relationship to Task Creation

```text
Governing doctrine
  -> phase source pack
  -> capability boundary
  -> constitutional execution surface map
  -> replay-aware task universe and DAG
  -> master implementation plan
  -> surface-specific implementation plan
  -> atomic task pack
  -> task implementation
  -> evidence / execution log
```

`TASK_CREATION_PROCESS.md` starts at atomic task-pack creation. This document
governs the planning layer immediately before that.

For the end-to-end AI-agent handoff from phase planning to task creation, see
`docs/operations/AI_AGENT_PHASE_PLANNING_TO_TASK_HANDOFF_GUIDE.md`.

---

## Required Phase Planning Artifacts

Before atomic task creation, each phase must have these planning artifacts or
explicit blockers explaining why they do not yet exist:

```text
docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md
docs/PHASE<N>/PHASE<N>_CAPABILITY_BOUNDARY.md
docs/PHASE<N>/PHASE<N>_EXECUTION_SURFACE_MAP.md
docs/PHASE<N>/PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md
docs/PHASE<N>/PHASE<N>_TASK_DAG.md
docs/PHASE<N>/phase<N>_task_dag.yml
docs/PHASE<N>/implementation_plans/README.md
docs/PHASE<N>/implementation_plans/<TSK-P<N>-WP-###>_<short_name>.md
```

`PHASE<N>_MASTER_IMPLEMENTATION_PLAN.md` is the full phase task-universe
authority. `PHASE<N>_TASK_DAG.md` and `phase<N>_task_dag.yml` are the sequencing
authority. A surface-specific implementation plan refines a DAG node; it must
not introduce new phase scope.

---

## Identifier Rules

All implementation-plan work items that may later become tasks must use a
`TSK-` prefix.

Allowed planning identifier forms:

- `TSK-P<N>-PLAN-<NNN>` for broad implementation-plan work items.
- `TSK-P<N>-CLEAN-<NNN>` for cleanup blockers that must be resolved before
  atomic task creation.
- `TSK-P<N>-WP-<NNN>` for work packages inside a master implementation plan.
- `TSK-P<N>-CAP-<NNN>` for capability-specific implementation-plan work.

Planning identifiers reserve future task identity space. They are not atomic
task IDs until a task pack exists under `tasks/<TASK_ID>/`.

Non-`TSK-` planning IDs are prohibited for newly created implementation-plan
work items.

---

## DAG Sequencing Fields

Implementation-plan DAGs may use both `depends_on` and `blocked_by`. These
fields are not interchangeable.

- `depends_on` defines the structural execution order. Each listed predecessor
  is expected workflow sequence and must be completed before the current node or
  task can start.
- `blocked_by` defines active impediments, such as root wave gates, governance
  conflicts, missing doctrine, failed readiness checks, remediation blockers, or
  unresolved execution-envelope conflicts.
- `blocked_by` must not duplicate normal predecessors already listed in
  `depends_on`.
- Transitive dependency blockage is derived from the DAG. Do not copy every
  transitive dependency into `blocked_by`.
- A wave/root gate may appear in `blocked_by` for otherwise independent nodes
  even when their direct `depends_on` list is empty.

When a wave is run "at once," agents must treat that as sequenced execution by
DAG order unless the plan explicitly authorizes parallel execution.

---

## Phase Source Pack Requirements

A phase source pack is an indexed set of governing inputs. It is not required to
be one file per requirement. One canonical document may satisfy multiple source
pack requirements when the mapping is explicit.

The phase source-pack index must map these categories to canonical sources:

1. phase purpose;
2. phase build scope;
3. phase exit criteria;
4. phase legality status;
5. authorized capability domains;
6. prohibited capability domains;
7. governing doctrines;
8. phase contract rows;
9. invariant register;
10. verifier expectations;
11. evidence expectations;
12. negative-test expectations;
13. replay obligations;
14. authority obligations;
15. carry-forward obligations;
16. existing completed or planned task packs;
17. archived or non-canonical documents to exclude;
18. execution envelope constraints;
19. unresolved blockers.

If any source-pack category cannot be mapped, the plan must record the gap
explicitly rather than infer doctrine, implementation scope, or execution
authority.

---

## Mandatory Planning Pipeline

Agents creating implementation plans must follow this ordered pipeline. Later
stages may not run until earlier stages are complete or explicitly blocked.

```text
Phase source pack
  -> invariant / replay / authority extraction
  -> capability boundary
  -> constitutional execution surface map
  -> execution authority surface classification
  -> surface ownership binding
  -> replay criticality classification
  -> constitutional state mutability classification
  -> lineage / projection ontology classification
  -> deterministic execution classification
  -> implementation surface expansion
  -> anti-fake-surface filtering
  -> semantic contamination filtering
  -> future-phase isolation
  -> doctrine-gap escalation
  -> full task universe
  -> replay-aware DAG
  -> master implementation plan
  -> surface-specific implementation plans
  -> atomic task creation
```

The ordering is mandatory because each classification depends on the surfaces
defined before it. Implementation expansion before replay, mutability, ontology,
and ownership classification produces speculative work and is invalid.

---

## Execution Surface Record Shape

Every constitutional execution surface must use this record shape in the
execution-surface map:

```yaml
surface_id:
title:
source_invariants:
source_contract_rows:
constitutional_owner:
replay_owner:
verifier_owner:
persistence_owner:
phase_owner:
override_authority:
execution_surface_type:
execution_authority_class:
replay_criticality:
state_mutability:
ontology_class:
determinism_class:
allowed_implementation_surfaces:
prohibited_semantics:
future_phase_routing:
doctrine_gap_status:
```

### Execution Authority Classes

- `authoritative`: may alter admissibility, create canonical lineage, or govern
  future reliance under doctrine.
- `projection-only`: produces replay-derived interpretation without mutating
  source lineage.
- `reconstructive`: rebuilds historical or projected state from canonical
  inputs.
- `observational`: records internal findings or metrics without constitutional
  truth authority.
- `accelerative`: improves replay or query performance without becoming source
  truth.
- `verifier-only`: proves a surface mechanically without creating the runtime
  surface being proved.
- `operational`: supports operation but has no constitutional authority unless
  separately promoted by doctrine.

---

## Planning Classifications

### Replay Criticality

- `replay-authoritative`
- `projection-state`
- `replay-derived`
- `replay-accelerative`
- `operational-exhaust`
- `transient-execution-state`

### Constitutional State Mutability

- `immutable-lineage`
- `supersedable-projection`
- `quarantined-state`
- `compensating-lineage`
- `revocable-authority`
- `derived-cache`

### Lineage / Projection Ontology

- `lineage-truth`
- `projection`
- `supersession`
- `quarantine`
- `compensating-reconstruction`
- `admissibility-projection`
- `authority-projection`

### Deterministic Execution

- `deterministic`
- `bounded-nondeterministic`
- `prohibited-nondeterministic`

### Doctrine-Gap Outcome

- `IMPLEMENT`: doctrine is sufficient for implementation planning.
- `DEFER`: work belongs to a later phase.
- `ESCALATE-DOCTRINE`: constitutional semantics are missing.
- `ESCALATE-ONTOLOGY`: terminology or classification is ambiguous.
- `ESCALATE-REPLAY`: replay model is undefined or contradictory.
- `ESCALATE-AUTHORITY`: authority semantics are undefined or contradictory.
- `REJECT`: proposed work is unconstitutional or phase-illegal.
- `SPLIT`: candidate mixes multiple surfaces or scopes and must be decomposed.

---

## Implementation Surface Expansion

After execution surfaces are classified, each surface must be evaluated against
implementation lanes:

- runtime;
- database / persistence;
- migration / backfill;
- security / access control;
- deterministic interfaces / serialization contracts;
- evidence / replay;
- fixtures;
- verifier / CI;
- performance / scale;
- versioning / compatibility;
- observability;
- documentation.

This matrix is not permission to create work in every lane. A support surface
may exist only if required by at least one of:

- replay legality;
- authority reconstruction;
- admissibility evaluation;
- deterministic enforcement;
- verifier closure;
- constitutional persistence.

Speculative APIs, dashboards, caches, migrations, versioning, observability, and
performance tasks are prohibited unless this anti-fake-surface rule is
satisfied.

---

## Semantic Contamination and Future-Phase Isolation

Every candidate surface and task-universe item must be filtered for semantic
contamination. The planning artifact must reject, defer, or escalate work that
imports:

- methodology semantics;
- settlement or statutory deduction semantics;
- disclosure or corporate reporting semantics;
- UI or operational workflow semantics;
- external registry or export semantics;
- sovereign governance semantics not already defined by doctrine.

Future-phase work must be routed to the correct phase instead of being absorbed
into the current phase. If a support surface appears useful but would create
irreversible future coupling, it must be deferred or escalated.

---

## Replay-Aware DAG Rules

The phase DAG must be derived from dependency order, not theme. Sequence by:

1. constitutional legality;
2. replay dependency;
3. authority dependency;
4. persistence dependency;
5. determinism dependency;
6. verifier dependency;
7. operational dependency.

Wave or domain grouping may be assigned only after the serial dependency order
is derived. A wave is a scheduling subdivision; it is not a phase boundary and
not an independent source of task legality.

---

## Required Inputs Before Creating Files

Before creating an implementation plan, the agent must identify:

1. the lifecycle phase or planning scope;
2. the phase source pack or source-pack requirements;
3. the capability boundary or governing scope document;
4. the governing doctrines;
5. the contract or invariant register, if one exists;
6. execution-surface candidates;
7. existing task packs that must not be recreated;
8. cleanup blockers before atomic task creation;
9. out-of-phase capabilities that must be routed elsewhere.

If any of these cannot be discovered from the repository, the plan must record
the gap explicitly rather than infer doctrine or implementation scope.

---

## Mandatory Process

### Step 1 - Read Governing Entry Documents

Read:

- `AGENT_ENTRYPOINT.md`
- `docs/operations/AGENT_PROMPT_ROUTER.md`
- `docs/operations/PHASE_EXECUTION_ENVELOPE.md`
- this document

If the active execution envelope contradicts the phase being planned, the plan
must record the contradiction as a blocker. The agent must not silently treat
the planned phase as executable.

### Step 2 - Build Or Validate The Phase Source Pack

Inspect the relevant phase specification, phase docs, legality matrix, contracts,
invariant registers, existing task directories, existing plans, migrations,
verifiers, evidence declarations, archived sources, and governing doctrines.

Create or update `docs/PHASE<N>/PHASE<N>_SOURCE_PACK.md` when requested or when
the phase lacks an index. The source pack must not invent doctrine.

### Step 3 - Classify Existing Work

Classify discovered work as:

- completed task pack;
- planned task pack;
- draft or archived source;
- governing doctrine;
- stale or contradictory artifact;
- missing but required artifact.

Completed task packs must not be recreated. Planned task packs may be referenced
only if their metadata, plan, and log resolve.

### Step 4 - Create Or Validate Execution Surfaces

Create or update `docs/PHASE<N>/PHASE<N>_EXECUTION_SURFACE_MAP.md` when needed.
Every surface must use the execution surface record shape and all classifications
defined above.

### Step 5 - Create The Full Task Universe

Group future work into implementation-plan work packages using `TSK-` prefixed
planning identifiers. Each work package or candidate task must declare:

- governing doctrine;
- source-pack reference;
- capability boundary row;
- execution surface ID;
- contract row or invariant IDs, if any;
- dependencies;
- allowed implementation surface;
- prohibited doctrine surface;
- replay, mutability, ontology, and determinism classifications;
- cleanup blockers;
- verifier/evidence expectations for later atomic tasks.

### Step 6 - Create The Replay-Aware DAG

Create or update the human and machine-readable DAG artifacts when needed. Every
DAG node must map to an execution surface, source-pack reference, and work
package or candidate task.

### Step 7 - Record Atomic Task Creation Gate

The implementation plan must state the conditions that must pass before atomic
task packs can be generated.

At minimum:

- source pack exists and maps all required categories or records blockers;
- governing doctrine exists;
- phase contract and invariant references are parseable;
- stale or archived sources are excluded;
- every capability maps to a boundary row;
- every DAG node maps to an execution surface;
- every surface has ownership, replay, mutability, ontology, determinism, and
  doctrine-gap classifications;
- no doctrine gap remains unresolved for nodes to be implemented;
- future task IDs will be created under `tasks/<TASK_ID>/` by
  `TASK_CREATION_PROCESS.md`.

---

## Output Requirements

Implementation plans must include:

- metadata block with `Constitutional-Status: PLANNING`;
- `NotebookLM-Ingestion: DO-NOT-INGEST` unless ratified separately;
- explicit statement that the plan is not an atomic task pack;
- `TSK-` prefixed cleanup/work-package identifiers;
- execution surface ownership and classifications;
- replay-aware dependency sequence;
- cleanup blockers;
- out-of-phase routing exclusions;
- doctrine-gap outcomes;
- acceptance criteria for readiness to create atomic tasks.

---

## Prohibited Actions

Agents creating implementation plans must not:

- create atomic task directories;
- mark tasks complete;
- emit evidence artifacts;
- create migrations or verifier scripts;
- promote invariants;
- define doctrine locally;
- cite archived or draft sources as governing doctrine;
- create support surfaces that fail the anti-fake-surface rule;
- claim implementation readiness when the execution envelope blocks it.

---

## Handoff to Atomic Task Creation

When an implementation plan is complete, atomic task creation must switch to
`CREATE-TASK` mode and follow `TASK_CREATION_PROCESS.md`.

`CREATE-TASK` may only create atomic task packs from a DAG node that has:

- source-pack reference;
- capability boundary mapping;
- execution surface ID;
- ownership binding;
- replay criticality classification;
- mutability classification;
- ontology classification;
- determinism classification;
- future-phase isolation result;
- doctrine-gap outcome of `IMPLEMENT` or `SPLIT`;
- no unresolved blockers.

Atomic tasks must cite:

- boundary row;
- execution surface ID;
- master plan work package;
- DAG node;
- surface-specific implementation plan;
- governing doctrine.

The implementation plan may provide candidate task IDs and sequencing, but the
actual task pack becomes real only when:

- `tasks/<TASK_ID>/meta.yml` exists;
- `docs/plans/phase<N>/<TASK_ID>/PLAN.md` exists;
- `docs/plans/phase<N>/<TASK_ID>/EXEC_LOG.md` exists;
- the task pack passes readiness verification.

At that point the node is **task-packed**. In Phase planning truth surfaces this
may continue to be labeled `tasks-created`, but that label means only:

- the atomic task pack exists;
- the verifier contract is structurally executable;
- the node may later enter `RESUME-TASK`.

It does **not** mean:

- implementation deliverables already exist;
- the task is `resume-ready`;
- the task has entered `IMPLEMENT-TASK`;
- evidence has already been emitted.
