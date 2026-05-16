# Phase 3 Implementation Plans Registry

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3

## Purpose

This directory records surface-specific implementation plans created under
`CREATE-IMPLEMENTATION-PLAN` mode. These files are planning artifacts only. They
are not atomic task packs and must not include task `PLAN.md`, task
`EXEC_LOG.md`, verifier scripts, migrations, or evidence artifacts.

Surface-specific plans refine DAG nodes from `docs/PHASE3/PHASE3_TASK_DAG.md`.
They may not introduce new Phase 3 scope. If a surface-specific plan discovers a
missing doctrine, undefined replay model, undefined authority model, or
future-phase conflict, it must update the DAG blocker status instead of
inventing semantics.

## Required Plan Metadata

Each file in this directory must include:

- `Constitutional-Status: PLANNING`
- `NotebookLM-Ingestion: DO-NOT-INGEST`
- source pack reference;
- execution surface ID;
- DAG node ID;
- master implementation plan work package;
- governing doctrine;
- ownership binding;
- replay criticality classification;
- state mutability classification;
- ontology classification;
- determinism classification;
- doctrine-gap outcome;
- future-phase isolation result.

## Registry

| Plan ID | Expected File | Surface | DAG Node | Status | Blocker |
|---|---|---|---|---|---|
| TSK-P3-CAP-000 | `TSK-P3-CAP-000_governance_cleanup.md` | P3-SURF-000 | TSK-P3-CLEAN-001 through TSK-P3-CLEAN-008 | created-planning | Wave 0 atomic task packs not created |
| TSK-P3-CAP-001 | `TSK-P3-CAP-001_dependency_graph.md` | P3-SURF-001 | TSK-P3-WP-001 | not-created | Depends on Wave 0 |
| TSK-P3-CAP-002 | `TSK-P3-CAP-002_policy_authority_lineage.md` | P3-SURF-002 | TSK-P3-WP-002 | not-created | Depends on TSK-P3-WP-001 |
| TSK-P3-CAP-003 | `TSK-P3-CAP-003_projection_legitimacy.md` | P3-SURF-003 | TSK-P3-WP-003 | not-created | Depends on TSK-P3-WP-001 and TSK-P3-WP-002 |
| TSK-P3-CAP-004 | `TSK-P3-CAP-004_contradiction_detection.md` | P3-SURF-004 | TSK-P3-WP-004 | not-created | Depends on projection and authority surfaces |
| TSK-P3-CAP-005 | `TSK-P3-CAP-005_failure_evidence_continuity.md` | P3-SURF-005 | TSK-P3-WP-005 | not-created | Depends on contradiction surface |
| TSK-P3-CAP-006 | `TSK-P3-CAP-006_authority_delegation.md` | P3-SURF-006 | TSK-P3-WP-006 | not-created | Depends on policy/authority lineage |
| TSK-P3-CAP-007 | `TSK-P3-CAP-007_regulator_partition.md` | P3-SURF-007 | TSK-P3-WP-007 | not-created | Depends on contradiction and lineage surfaces |
| TSK-P3-CAP-008 | `TSK-P3-CAP-008_conflict_of_interest.md` | P3-SURF-008 | TSK-P3-WP-008 | not-created | Depends on authority surface |
| TSK-P3-CAP-009 | `TSK-P3-CAP-009_spatial_dnsh.md` | P3-SURF-009 | TSK-P3-WP-009 | not-created | Depends on lineage and failure surfaces |
| TSK-P3-CAP-010 | `TSK-P3-CAP-010_dwell_time_forensics.md` | P3-SURF-010 | TSK-P3-WP-010 | not-created | Depends on projection, contradiction, and failure surfaces |
| TSK-P3-CAP-011 | `TSK-P3-CAP-011_verifier_ci.md` | P3-SURF-011 | TSK-P3-WP-011 | not-created | Depends on all implementation surfaces |

## Atomic Task Handoff

Atomic task creation must use `CREATE-TASK` mode and may proceed only from a DAG
node whose blockers are closed and whose surface has all required
classifications in `docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md`.
