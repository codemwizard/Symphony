# TSK-P3-CAP-000 Governance Cleanup Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-000
Execution-Surface: P3-SURF-000
DAG-Nodes: TSK-P3-CLEAN-001 through TSK-P3-CLEAN-008
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false

---

## Purpose

This document is the surface-specific implementation plan for the Pre-Phase 3
governance cleanup wave on `P3-SURF-000`. It prepares the cleanup nodes that
must later be converted into atomic task packs through `CREATE-TASK` mode.

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approval artifacts, or evidence files.

## Sequencing Rule

`depends_on` and `blocked_by` are separate fields.

- `depends_on` defines the structural DAG order. These are normal predecessor
  tasks that must be completed before the current task can start.
- `blocked_by` defines active impediments, root gates, governance conflicts,
  missing doctrine, failed readiness checks, or remediation blockers.
- `blocked_by` must not duplicate normal predecessors already listed in
  `depends_on`.
- A wave/root gate such as `TSK-P3-CLEAN-001` may block otherwise independent
  nodes even when their direct `depends_on` list is empty.
- Transitive dependency blockage is derived from the DAG and must not be copied
  into `blocked_by`.

The Pre-Phase 3 Wave is run as one sequenced wave, not as parallel work.

## Wave 0 Sequence

| Node | Direct `depends_on` | Active `blocked_by` | Sequencing Note |
|---|---|---|---|
| TSK-P3-CLEAN-001 | none | none | Root cleanup gate. Run first. |
| TSK-P3-CLEAN-002 | none | TSK-P3-CLEAN-001 | Independent cleanup, but wave-gated by CLEAN-001. |
| TSK-P3-CLEAN-003 | none | TSK-P3-CLEAN-001 | Independent cleanup, but wave-gated by CLEAN-001. |
| TSK-P3-CLEAN-004 | none | TSK-P3-CLEAN-001 | Resolves execution-envelope conflict; not the wave root gate unless later promoted. |
| TSK-P3-CLEAN-005 | none | TSK-P3-CLEAN-001 | Independent cleanup, but wave-gated by CLEAN-001. |
| TSK-P3-CLEAN-006 | none | TSK-P3-CLEAN-001 | Independent cleanup, but wave-gated by CLEAN-001. |
| TSK-P3-CLEAN-007 | TSK-P3-CLEAN-001, TSK-P3-CLEAN-003 | none after dependencies resolve | Maintains DAG artifacts after contract/invariant cleanup. |
| TSK-P3-CLEAN-008 | TSK-P3-CLEAN-007 | none after dependencies resolve | Maintains implementation-plan registry after DAG maintenance. |

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode. Atomic task packs
must be generated with `scripts/agent/generate_task_pack.py` and must satisfy
`docs/operations/TASK_CREATION_PROCESS.md`, including proof-graph alignment,
evidence contracts, failure modes, stop conditions, and readiness verification.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| TSK-P3-CLEAN-001 | Repair Phase 3 contract parse defect | 3 | `docs/PHASE3/phase3_contract.yml` | Contract parses as YAML; P3-004 row remains semantically intact; no Phase 3 execution claim is introduced. | YAML parser command plus contract consistency check; evidence path must be declared by generated task pack. | Stop if repair changes contract meaning, adds execution authorization, or hides malformed rows. |
| TSK-P3-CLEAN-002 | Rewrite Phase 3 README planning posture | 3 | `docs/PHASE3/README.md` | README no longer describes the stale external-trust-surface posture; README states planning-only posture and points to source pack, boundary, DAG, and master plan. | Documentation consistency check proving stale phrases are removed and canonical references exist. | Stop if README claims Phase 3 implementation is executable under the active envelope. |
| TSK-P3-CLEAN-003 | Add doctrine references to Phase 3 invariant register | 3 | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` | INV-301 through INV-310 cite governing doctrines; each invariant preserves roadmap/implementation status honesty. | Static consistency check that every invariant row has doctrine references and no invariant is promoted without verifier evidence. | Stop if any invariant is marked implemented or if doctrine is invented locally. |
| TSK-P3-CLEAN-004 | Reconcile Phase 3 opening posture with active execution envelope | 3 | `docs/PHASE3/PHASE3_OPENING_ACT.md`, planning notes as approved by governance | Opening posture conflict is explicitly resolved, deferred, or escalated; the root execution envelope remains the controlling authority. | Consistency check comparing opening act, source pack, master plan, and execution envelope claims. | Stop if the task attempts to update the root envelope without human authority or claims Phase 3 executable status. |
| TSK-P3-CLEAN-005 | Resolve non-canonical MADD/MAIN duplicate doctrine copy | 3 | `docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2.md` or approved archive target | Duplicate is archived, marked non-canonical, or intentionally merged; canonical citation target remains clear. | Search check showing Phase 3 planning cites only canonical MADD/MAIN doctrine and excludes duplicate prompt-response material. | Stop if duplicate doctrine is treated as canonical or merged without source-lineage decision. |
| TSK-P3-CLEAN-006 | Verify archived Phase 3 files are excluded from task generation | 3 | `docs/PHASE3/archive/**`, ingestion/task-generation exclusion docs if needed | Archived review/draft files are marked non-canonical and excluded from ingestion/task generation. | Search or policy check proving archived files are not cited as governing sources. | Stop if archived files remain eligible as doctrine or task-generation input. |
| TSK-P3-CLEAN-007 | Maintain Phase 3 DAG artifacts after cleanup | 3 | `docs/PHASE3/PHASE3_TASK_DAG.md`, `docs/PHASE3/phase3_task_dag.yml` | Human and machine DAGs agree on statuses, `depends_on`, `blocked_by`, surfaces, and task-creation gates after CLEAN-001 and CLEAN-003. | DAG consistency check covering all Wave 0 nodes and surface mappings. | Stop if `blocked_by` duplicates normal `depends_on` predecessors or DAG and master plan diverge. |
| TSK-P3-CLEAN-008 | Maintain Phase 3 implementation-plan registry after DAG maintenance | 3 | `docs/PHASE3/implementation_plans/README.md`, `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | Registry status matches actual plan files; `TSK-P3-CAP-000` is marked created-planning; downstream plans remain not-created unless files exist. | Registry consistency check proving listed plan files and statuses match disk state. | Stop if registry claims task packs exist or stores atomic PLAN/EXEC_LOG content. |

## Atomic Task Handoff Requirements

No cleanup node may enter `IMPLEMENT-TASK` directly from this plan. The next
step for each eligible node is `CREATE-TASK` mode.

Every generated atomic task pack must include:

- exactly one primary objective;
- direct `depends_on` values from this plan and the DAG;
- active `blocked_by` values from this plan, excluding normal DAG predecessors;
- `touches` limited to the future task row;
- observable acceptance criteria;
- deterministic verifier commands;
- concrete evidence output paths in the lifecycle phase namespace;
- failure mode `Evidence file missing`;
- stop conditions for scope drift and execution-envelope conflict;
- `must_read` references to `AGENT_ENTRYPOINT.md`,
  `docs/operations/TASK_CREATION_PROCESS.md`,
  `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md`, and this plan.

## Readiness Checks For This Plan

This implementation plan is complete when:

- all eight `TSK-P3-CLEAN-00*` nodes are represented;
- the sequence uses `depends_on` for structural predecessors and `blocked_by`
  only for active impediments;
- `TSK-P3-CAP-000` is referenced by the implementation-plan registry;
- no atomic task pack files are created by this planning step;
- the active execution-envelope caveat remains explicit.
