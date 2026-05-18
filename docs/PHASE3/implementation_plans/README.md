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

Broad wave-scoped implementation plans may also appear here when they define a
consecutive dependency-safe batch derived from the canonical Phase 3 task
sequence. Those plans do not replace the required surface-specific CAP plans.

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
| TSK-P3-CAP-000 | `TSK-P3-CAP-000_governance_cleanup.md` | P3-SURF-000 | TSK-P3-CLEAN-001 through TSK-P3-CLEAN-008 | created-planning | Consumed by completed `TSK-P3-CLEAN-*` task packs |
| TSK-P3-CAP-001 | `TSK-P3-CAP-001_dependency_graph.md` | P3-SURF-001 | TSK-P3-WP-001 | created-planning | Wave 1 lineage surface plan created; shared support reconciliation with `TSK-P3-CAP-002` required before task-pack extraction |
| TSK-P3-CAP-002 | `TSK-P3-CAP-002_policy_authority_lineage.md` | P3-SURF-002 | TSK-P3-WP-002 | created-planning | Wave 1 policy/authority surface plan created; shared support reconciliation with `TSK-P3-CAP-001` required before task-pack extraction |
| TSK-P3-CAP-003 | `TSK-P3-CAP-003_projection_legitimacy.md` | P3-SURF-003 | TSK-P3-WP-003 | created-planning | Wave 2 projection surface plan created; shared support reconciliation with `TSK-P3-CAP-006` and prior Wave 1 surfaces required before task-pack extraction |
| TSK-P3-CAP-004 | `TSK-P3-CAP-004_contradiction_detection.md` | P3-SURF-004 | TSK-P3-WP-004 | created-planning | Wave 3 contradiction surface plan created; shared migration reconciliation with prior Wave 1/Wave 2 surfaces and `TSK-P3-CAP-005` required before task-pack extraction |
| TSK-P3-CAP-005 | `TSK-P3-CAP-005_failure_evidence_continuity.md` | P3-SURF-005 | TSK-P3-WP-005 | created-planning | Wave 3 failure surface plan created; contradiction-output anchoring and shared migration reconciliation with `TSK-P3-CAP-004` required before task-pack extraction |
| TSK-P3-CAP-006 | `TSK-P3-CAP-006_authority_delegation.md` | P3-SURF-006 | TSK-P3-WP-006 | created-planning | Wave 2 authority surface plan created; CAP-002 lineage anchoring and shared fixture reconciliation required before task-pack extraction |
| TSK-P3-CAP-007 | `TSK-P3-CAP-007_regulator_partition.md` | P3-SURF-007 | TSK-P3-WP-007 | created-planning | Wave 4 regulator surface plan created; shared observability reconciliation with `TSK-P3-CAP-003`, `TSK-P3-CAP-004`, `TSK-P3-CAP-005`, and `TSK-P3-CAP-009` required before task-pack extraction |
| TSK-P3-CAP-008 | `TSK-P3-CAP-008_conflict_of_interest.md` | P3-SURF-008 | TSK-P3-WP-008 | created-planning | Wave 4 COI surface plan created; CAP-006 lineage anchoring and explicit non-overlap with `TSK-P3-CAP-013` required before task-pack extraction |
| TSK-P3-CAP-009 | `TSK-P3-CAP-009_spatial_dnsh.md` | P3-SURF-009 | TSK-P3-WP-009 | created-planning | Wave 4 spatial surface plan created; bounded-nondeterminism declaration and shared observability/performance reconciliation with prior-wave surfaces required before task-pack extraction |
| TSK-P3-CAP-010 | `TSK-P3-CAP-010_dwell_time_forensics.md` | P3-SURF-010 | TSK-P3-WP-010 | created-planning | Wave 4 temporal forensic surface plan created; CAP-003/CAP-004/CAP-005 substrate anchoring required before task-pack extraction |
| TSK-P3-CAP-011 | `TSK-P3-CAP-011_verifier_ci.md` | P3-SURF-011 | TSK-P3-WP-011 | created-planning | Wave 5 verifier surface plan created; exhaustive invariant-to-verifier disposition and explicit non-overlap with `TSK-P3-CAP-013` required before task-pack extraction |
| TSK-P3-CAP-012 | `TSK-P3-CAP-012_phase3_activation_alignment.md` | P3-SURF-000 | TSK-P3-ACT-001 through TSK-P3-ACT-005 | created-planning | Consumed by completed `TSK-P3-ACT-*` task packs |
| TSK-P3-CAP-013 | `TSK-P3-CAP-013_runtime_verifier_segregation.md` | P3-SURF-012 | TSK-P3-WP-012 | created-planning | Wave 5 segregation surface plan created; CAP-005/CAP-006/CAP-008 substrate anchoring and explicit non-overlap with `TSK-P3-CAP-011` required before task-pack extraction |
| TSK-P3-CAP-014 | `TSK-P3-CAP-014_uncertainty_semantics.md` | P3-SURF-013 | TSK-P3-WP-013 | created-planning | Wave 5 uncertainty surface plan created; uncertainty-class completeness, operator-governed propagation, and authority-transfer record closure must be canonical before task-pack extraction |
| TSK-P3-CAP-015 | `TSK-P3-CAP-015_ai_governance_doctrine.md` | P3-SURF-000 | TSK-P3-GOV-005 | created-planning | Wave 5 AI governance plan created; advisory-only AI admissibility, model provenance, and explicit non-overlap with execution-phase AI capability routing required before task-pack extraction |

## Broad Wave Plans

| Plan ID | Expected File | Scope | Status | Note |
|---|---|---|---|---|
| TSK-P3-PLAN-001 | `TSK-P3-PLAN-001_wave1_lineage_foundations.md` | Wave 1 (`TSK-P3-WP-001`, `TSK-P3-WP-002`, `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, `TSK-P3-SUPPORT-SEC-001`) | created-planning | Defines the first consecutive dependency-safe Phase 3 execution batch and the CAP extraction order. |
| TSK-P3-PLAN-002 | `TSK-P3-PLAN-002_wave2_projection_authority_enforcement.md` | Wave 2 (`TSK-P3-WP-003`, `TSK-P3-SUPPORT-VERSION-001`, `TSK-P3-WP-006`, `TSK-P3-SUPPORT-FIXTURE-001`) | created-planning | Defines the second consecutive dependency-safe Phase 3 execution batch and the CAP extraction order for projection and authority surfaces. |
| TSK-P3-PLAN-003 | `TSK-P3-PLAN-003_wave3_contradiction_failure_composition.md` | Wave 3 (`TSK-P3-WP-004`, `TSK-P3-WP-005`, `TSK-P3-SUPPORT-MIG-001`) | created-planning | Defines the third consecutive dependency-safe Phase 3 execution batch and the CAP extraction order for contradiction and failure surfaces. |
| TSK-P3-PLAN-004 | `TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md` | Wave 4 (`TSK-P3-WP-007`, `TSK-P3-WP-008`, `TSK-P3-WP-009`, `TSK-P3-WP-010`, `TSK-P3-SUPPORT-OBS-001`, `TSK-P3-SUPPORT-PERF-001`) | created-planning | Defines the fourth consecutive dependency-safe Phase 3 execution batch and the CAP extraction order for regulator, COI, spatial, and temporal surfaces. |
| TSK-P3-PLAN-005 | `TSK-P3-PLAN-005_wave5_verifier_segregation_closeout.md` | Wave 5 (`TSK-P3-WP-012`, `TSK-P3-WP-011`, `TSK-P3-WP-013`, `TSK-P3-GOV-005`, `TSK-P3-SUPPORT-DOC-001`) | created-planning | Defines the fifth consecutive dependency-safe Phase 3 execution batch and the CAP extraction order for runtime/verifier segregation, verifier-closure, uncertainty semantics, and AI governance surfaces. |

## Atomic Task Handoff

Atomic task creation must use `CREATE-TASK` mode and may proceed only from a DAG
node whose blockers are closed and whose surface has all required
classifications in `docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md`.
