# PHASE3_MASTER_IMPLEMENTATION_PLAN.md

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Generated-From-Process: docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md
Atomic-Task-Creation-Allowed: false
Depends-On:
  - docs/PHASE3/PHASE3_SOURCE_PACK.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
  - docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md
  - docs/PHASE3/PHASE3_TASK_DAG.md
  - docs/PHASE3/phase3_task_dag.yml
  - docs/PHASE3/implementation_plans/README.md
  - docs/PHASE3/phase3_contract.yml
  - docs/PHASE3/PHASE3_INVARIANT_REGISTER.md
  - docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md
  - docs/operations/AGENT_PROMPT_ROUTER.md
  - docs/operations/PHASE_EXECUTION_ENVELOPE.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  - docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
  - docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md
  - docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  - docs/architecture/PHASE_SPECIFICATION_AI_CAPABILITY_AUGMENTATION.md
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md

---

## Purpose

This document is the generated Phase 3 master implementation plan. It is the
full Phase 3 planning universe authority before surface-specific implementation
plans and before atomic task packs.

This plan is generated from the source-pack, execution-surface, classification,
anti-contamination, future-phase isolation, doctrine-gap, and replay-aware DAG
process in `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md`.

Anchor rule:

```text
Tasks do not define architecture.
Tasks implement constitutionally owned execution surfaces.
```

This document does not create atomic task directories, task `PLAN.md` files,
task `EXEC_LOG.md` files, migrations, verifier scripts, or evidence artifacts.

## Execution Envelope Caveat

This plan remains a planning artifact, but the current execution posture is now
governed by the active Phase 3 envelope and opening approval set. The activation
sequence is complete, so broader Phase 3 runtime task creation may proceed
through the repo's task-pack workflow and DAG dependencies.

## Planning Hierarchy

Phase 3 planning must flow in this order:

```text
Phase source pack
  -> capability boundary
  -> execution surface map
  -> replay-aware task DAG
  -> master implementation plan
  -> surface-specific implementation plans
  -> CREATE-TASK atomic task packs
```

The master plan may cite doctrines and phase artifacts. It must not define new
doctrine, interpret sovereign law, or absorb future-phase runtime behavior.

## Source-Pack Authority Summary

`docs/PHASE3/PHASE3_SOURCE_PACK.md` is the source-pack index for this plan. A
single source document may satisfy multiple source-pack categories.

| Source-Pack Category | Governing Source |
|---|---|
| Phase purpose, build scope, exit criteria | `docs/architecture/Symphony-Phase-Specification-Document_v1.md`, sections 3.1 through 3.8; `docs/architecture/PHASE_SPECIFICATION_AI_CAPABILITY_AUGMENTATION.md`, sections 3.9 through 3.10; `docs/PHASE3/phase3_contract.yml` |
| Legality status and phase routing | `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`; `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` |
| Authorized and prohibited capability domains | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` |
| Governing doctrines | Phase 3 doctrine inventory in `docs/constitutional/**`, including uncertainty, authority-transfer, and AI governance doctrine additions |
| Contract rows | `docs/PHASE3/phase3_contract.yml` rows P3-001 through P3-011 |
| Invariant register | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` rows INV-301 through INV-313 |
| Verifier, evidence, and negative-test expectations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`; `docs/PHASE3/phase3_contract.yml` rows P3-009 through P3-011 |
| Replay and authority obligations | replay, authority, policy-lineage, contradiction, failure, spatial, sovereignty, evidentiary, uncertainty, and AI admissibility doctrines |
| Carry-forward obligations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` INV-310 through INV-313 and referenced Phase 2 carry-forward material |
| Excluded non-canonical sources | `docs/PHASE3/archive/**`; draft, assessment, and review files marked `DO-NOT-INGEST` |
| Execution envelope constraints | `docs/operations/PHASE_EXECUTION_ENVELOPE.md`; `docs/PHASE3/PHASE3_OPENING_ACT.md` after reconciliation |
| Unresolved blockers | Wave 0 cleanup nodes in this plan and `docs/PHASE3/phase3_task_dag.yml` |

## Execution Surface Universe

Every implementation-plan node in Phase 3 must map to at least one execution
surface in `docs/PHASE3/PHASE3_EXECUTION_SURFACE_MAP.md`.

| Surface | Title | Authority Class | Replay Criticality | State Mutability | Ontology | Determinism | Doctrine Outcome |
|---|---|---|---|---|---|---|---|
| P3-SURF-000 | Governance Planning Control Surface | operational | operational-exhaust | derived-cache | projection | deterministic | IMPLEMENT |
| P3-SURF-001 | Typed Dependency Graph Lineage Surface | authoritative | replay-authoritative | immutable-lineage | lineage-truth | deterministic | IMPLEMENT |
| P3-SURF-002 | Policy And Authority Lineage Surface | authoritative | replay-authoritative | revocable-authority | authority-projection | deterministic | IMPLEMENT |
| P3-SURF-003 | Replay Projection And Recursive Legitimacy Surface | projection-only | projection-state | supersedable-projection | admissibility-projection | deterministic | IMPLEMENT |
| P3-SURF-004 | Contradiction Detection And Quarantine Surface | authoritative | projection-state | quarantined-state | quarantine | deterministic | IMPLEMENT |
| P3-SURF-005 | Failure Composition And Evidence Continuity Surface | authoritative | replay-derived | compensating-lineage | compensating-reconstruction | deterministic | IMPLEMENT |
| P3-SURF-006 | Authority Scope And Delegation Enforcement Surface | authoritative | replay-authoritative | revocable-authority | authority-projection | deterministic | IMPLEMENT |
| P3-SURF-007 | Regulator Partition And Arbitration Surface | authoritative | replay-derived | quarantined-state | projection | deterministic | IMPLEMENT |
| P3-SURF-008 | Conflict-Of-Interest Enforcement Surface | authoritative | replay-derived | immutable-lineage | lineage-truth | deterministic | IMPLEMENT |
| P3-SURF-009 | Spatial Constraint And DNSH Surface | authoritative | replay-derived | supersedable-projection | admissibility-projection | bounded-nondeterministic | IMPLEMENT |
| P3-SURF-010 | Dwell-Time Forensic Surface | projection-only | projection-state | supersedable-projection | admissibility-projection | deterministic | IMPLEMENT |
| P3-SURF-011 | Verifier And CI Closure Surface | verifier-only | operational-exhaust | derived-cache | projection | deterministic | IMPLEMENT |
| P3-SURF-012 | Runtime And Verifier Segregation Surface | verifier-only | operational-exhaust | derived-cache | projection | deterministic | IMPLEMENT |
| P3-SURF-013 | Uncertainty And Estimation Semantics Surface | authoritative | replay-derived | supersedable-projection | admissibility-projection | deterministic | IMPLEMENT |

## Full Task Universe

The following DAG nodes are the complete Phase 3 implementation-plan universe
currently generated from the source pack, boundary, and execution surface map.
They are planning nodes, not atomic task packs.

### Wave 0 - Governance Cleanup And Readiness

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-CLEAN-001 | P3-SURF-000 | complete | IMPLEMENT | Fix `docs/PHASE3/phase3_contract.yml` parse/indentation defect. |
| TSK-P3-CLEAN-002 | P3-SURF-000 | complete | IMPLEMENT | Rewrite `docs/PHASE3/README.md` to match Phase 3 planning posture. |
| TSK-P3-CLEAN-003 | P3-SURF-000 | complete | IMPLEMENT | Add doctrine references to INV-301 through INV-310 in the invariant register. |
| TSK-P3-CLEAN-004 | P3-SURF-000 | complete | ESCALATE-DOCTRINE | Reconcile Phase 3 opening posture with the active execution envelope. |
| TSK-P3-CLEAN-005 | P3-SURF-000 | complete | IMPLEMENT | Resolve duplicate or non-canonical MADD/MAIN doctrine copy. |
| TSK-P3-CLEAN-006 | P3-SURF-000 | complete | IMPLEMENT | Verify archived Phase 3 files remain non-canonical and excluded. |
| TSK-P3-CLEAN-007 | P3-SURF-000 | complete | IMPLEMENT | Maintain Phase 3 DAG artifacts after cleanup. |
| TSK-P3-CLEAN-008 | P3-SURF-000 | complete | IMPLEMENT | Maintain implementation-plan registry and status index. |

### Wave 0A - Phase Activation Governance Alignment

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-ACT-001 | P3-SURF-000 | complete | IMPLEMENT | Build the missing Phase 3 lifecycle artifact set. |
| TSK-P3-ACT-002 | P3-SURF-000 | complete | IMPLEMENT | Create the formal Phase 3 opening approval artifact set. |
| TSK-P3-ACT-003 | P3-SURF-000 | complete | IMPLEMENT | Rewrite the root execution envelope for active Phase 3 status. |
| TSK-P3-ACT-004 | P3-SURF-000 | complete | IMPLEMENT | Reconcile the legality layer and dependent Phase 3 planning posture. |
| TSK-P3-ACT-005 | P3-SURF-000 | complete | IMPLEMENT | Normalize existing Phase 3 plans and evidence for opened-phase use. |

### Wave 1 - Lineage Foundations

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-001 | P3-SURF-001 | completed | IMPLEMENT | Typed dependency graph lineage and traversal substrate. |
| TSK-P3-WP-002 | P3-SURF-002 | completed | IMPLEMENT | Policy artifact and authority lineage foundation. |
| TSK-P3-SUPPORT-DB-001 | P3-SURF-001, P3-SURF-002 | completed | IMPLEMENT | Persistence model for dependency, policy, and authority lineage surfaces. |
| TSK-P3-SUPPORT-SEC-001 | P3-SURF-001, P3-SURF-002 | completed | IMPLEMENT | Access-control and privilege model for lineage surfaces. |
| TSK-P3-SUPPORT-CONTRACT-001 | P3-SURF-001, P3-SURF-002 | completed | IMPLEMENT | Deterministic internal serialization, proof contracts, and offline replay package schema contracts for lineage records. |

### Wave 2 - Projection And Authority Enforcement

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-003 | P3-SURF-003 | completed | IMPLEMENT | Projection universes and recursive legitimacy evaluation. |
| TSK-P3-WP-006 | P3-SURF-006 | completed | IMPLEMENT | Authority scope and delegation enforcement. |
| TSK-P3-SUPPORT-FIXTURE-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-006 | completed | IMPLEMENT | Canonical valid and invalid lineage, authority, and legitimacy fixtures. |
| TSK-P3-SUPPORT-VERSION-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003 | completed | IMPLEMENT | Schema, projection, proof, policy format compatibility, and replay hash regression planning. |

### Wave 3 - Contradiction And Failure Composition

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-004 | P3-SURF-004 | completed | IMPLEMENT | Contradiction detection, quarantine, supersession, and escalation mechanics. |
| TSK-P3-WP-005 | P3-SURF-005 | completed | IMPLEMENT | Failure composition and cross-system evidence continuity. |
| TSK-P3-SUPPORT-MIG-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-006 | completed | IMPLEMENT | Migration and backfill planning for replay-addressable lineage, findings, and pre-/post-Phase-3 fixture equality preservation. |

### Wave 4 - Regulator, COI, Spatial, And Temporal Gates

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-007 | P3-SURF-007 | completed | IMPLEMENT | Regulator-aware partitioning, precedence application, and non-collapse mechanics. |
| TSK-P3-WP-008 | P3-SURF-008 | completed | IMPLEMENT | Conflict-of-interest and verifier independence enforcement. |
| TSK-P3-WP-009 | P3-SURF-009 | completed | IMPLEMENT | Spatial constraint and DNSH gates. |
| TSK-P3-WP-010 | P3-SURF-010 | completed | IMPLEMENT | Dwell-time forensic findings under temporal replay doctrine. |
| TSK-P3-SUPPORT-PERF-001 | P3-SURF-001, P3-SURF-003, P3-SURF-009 | completed | IMPLEMENT | Deterministic traversal, spatial, and projection scale bounds. |
| TSK-P3-SUPPORT-OBS-001 | P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-007, P3-SURF-009 | completed | IMPLEMENT | Internal constitutional observability without UI or dashboard semantics. |

### Wave 5 - Verifier, Segregation, Uncertainty, AI, CI, And Closeout Planning

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-012 | P3-SURF-012 | completed | IMPLEMENT | Runtime/verifier trust-boundary segregation, artifact exchange contracts, and privilege-separated verification surfaces. |
| TSK-P3-WP-011 | P3-SURF-011 | completed | IMPLEMENT | Verifier suite, CI wiring, evidence expectations, negative tests, invariant-to-verifier registry, capability-boundary contamination tests, and invariant promotion protocol. |
| TSK-P3-WP-013 | P3-SURF-013 | completed | IMPLEMENT | Uncertainty classification, operator-governed propagation, and replay-admissible authority transfer semantics. |
| TSK-P3-GOV-005 | P3-SURF-000 | completed | IMPLEMENT | AI governance doctrine, model registry and inference log schemas, and confidence-to-uncertainty admissibility mappings. |
| TSK-P3-SUPPORT-DOC-001 | P3-SURF-000 through P3-SURF-013 | completed | IMPLEMENT | Implementation references, replay specifications, and operator-neutral documentation. |

### Post-Wave Follow-Up Governance And Baseline Repairs

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-GOV-004 | P3-SURF-000 | completed | IMPLEMENT | Repair DB task-pack generator and planning-to-task handoff scope so canonical DB baseline, migration-head, ADR, and human task-index closure surfaces are emitted without manual patching. |
| TSK-P3-SUPPORT-DB-002 | P3-SURF-000 | completed | IMPLEMENT | Make privilege-only migration effects visible to canonical baseline and drift governance. |
| TSK-P3-SUPPORT-DB-003 | P3-SURF-000 | completed | IMPLEMENT | Fail-closed DB verifier bootstrap and connection diagnostics for `scripts/db` verifiers so DB/bootstrap failure cannot be silently misreported as schema absence. |
| TSK-P3-GOV-006 | P3-SURF-000 | completed | IMPLEMENT | Fail-closed DB probe contract for audit-side DB-facing verifiers and implementation-process guidance. |
| TSK-P3-GOV-007 | P3-SURF-000 | completed | IMPLEMENT | Normalize proof-before-completion lifecycle semantics so task proof no longer depends on pre-set completed status. |
| TSK-P3-SUPPORT-DB-004 | P3-SURF-000 | completed | IMPLEMENT | Make `baseline_then_migrations` safe on fresh databases with the default `public` schema while preserving baseline-cutoff governance. |
| TSK-P3-GOV-008 | P3-SURF-000 | completed | IMPLEMENT | Reconcile Stage A approval semantics with wave-end `pre_ci` and final governance signoff timing. |

## Support-Domain Justification

Support domains are included only where required by replay legality, authority
reconstruction, admissibility evaluation, deterministic enforcement, verifier
closure, or constitutional persistence.

| Support Domain | DAG Node | Constitutional Justification | Prohibited Expansion |
|---|---|---|---|
| Persistence model | TSK-P3-SUPPORT-DB-001 | constitutional persistence and replay legality for lineage surfaces | runtime DDL, speculative schema work, future-phase persistence |
| Access control | TSK-P3-SUPPORT-SEC-001 | authority reconstruction and separation of lineage authority | broad privilege changes or product auth workflows |
| Serialization/proof contracts | TSK-P3-SUPPORT-CONTRACT-001 | deterministic enforcement, replay-stable proof interfaces, and offline replay package schema contracts | public product APIs or external integration contracts |
| Fixtures | TSK-P3-SUPPORT-FIXTURE-001 | verifier closure and negative-test coverage | scenario prose without mechanical validation value |
| Versioning | TSK-P3-SUPPORT-VERSION-001 | replay continuity across schemas, projections, proofs, policy formats, and replay hash regressions | speculative product versioning |
| Migration/backfill planning | TSK-P3-SUPPORT-MIG-001 | constitutional persistence, replay reconstruction, and pre-/post-Phase-3 fixture equality preservation | applied migration edits or unapproved runtime migration work |
| Performance bounds | TSK-P3-SUPPORT-PERF-001 | deterministic traversal, spatial, and projection scale limits | optimization work that changes replay truth |
| Observability | TSK-P3-SUPPORT-OBS-001 | internal detection of constitutional projection and failure states | dashboards, user-facing explanations, or disclosure UX |
| Runtime/verifier segregation | TSK-P3-WP-012 | verifier independence, artifact exchange trust boundaries, and privilege separation between runtime and verification paths | shared trust context, verifier mutation authority, or runtime-authored verifier proof |
| Uncertainty semantics | TSK-P3-WP-013 | uncertainty-class completeness, registered operator propagation, and replay-visible authority transfer records for estimation-bearing artifacts | methodology-specific execution, industrial ontology invention, or external disclosure semantics |
| AI governance | TSK-P3-GOV-005 | advisory-only AI admissibility doctrine, model provenance, inference log schema, and confidence-to-uncertainty mapping | AI execution runtime, model training pipelines, or constitutional truth delegation to AI outputs |
| Documentation | TSK-P3-SUPPORT-DOC-001 | operator-neutral references and handoff closure | doctrine invention or external marketing/workflow material |

## Coverage Matrix

| Scope Item | Covered By |
|---|---|
| Phase spec 3.1 | P3-SURF-001; TSK-P3-WP-001; TSK-P3-SUPPORT-DB-001; TSK-P3-SUPPORT-CONTRACT-001 |
| Phase spec 3.2 | P3-SURF-003; TSK-P3-WP-003; P3-SURF-010; TSK-P3-WP-010 |
| Phase spec 3.3 | P3-SURF-004; TSK-P3-WP-004 |
| Phase spec 3.4 | P3-SURF-005; TSK-P3-WP-005 |
| Phase spec 3.5 | P3-SURF-002; TSK-P3-WP-002; P3-SURF-006; TSK-P3-WP-006 |
| Phase spec 3.6 | P3-SURF-007; TSK-P3-WP-007 |
| Phase spec 3.7 | P3-SURF-008; TSK-P3-WP-008; P3-SURF-012; TSK-P3-WP-012 |
| Phase spec 3.8 | P3-SURF-009; TSK-P3-WP-009 |
| Phase spec 3.9 | P3-SURF-013; TSK-P3-WP-013 |
| Phase spec 3.10 | P3-SURF-000; TSK-P3-GOV-005 |
| P3-001 | P3-SURF-001; TSK-P3-WP-001 |
| P3-002 | P3-SURF-003; TSK-P3-WP-003; P3-SURF-010; TSK-P3-WP-010 |
| P3-003 | P3-SURF-004; TSK-P3-WP-004 |
| P3-004 | P3-SURF-005; TSK-P3-WP-005 |
| P3-005 | P3-SURF-002; TSK-P3-WP-002; P3-SURF-006; TSK-P3-WP-006 |
| P3-006 | P3-SURF-007; TSK-P3-WP-007 |
| P3-007 | P3-SURF-008; TSK-P3-WP-008 |
| P3-008 | P3-SURF-009; TSK-P3-WP-009 |
| P3-009 | P3-SURF-011; TSK-P3-WP-011; P3-SURF-012; TSK-P3-WP-012 |
| P3-010 | P3-SURF-013; TSK-P3-WP-013 |
| P3-011 | P3-SURF-000; TSK-P3-GOV-005 |
| INV-301 | P3-SURF-007; TSK-P3-WP-007 |
| INV-302 | P3-SURF-001; P3-SURF-002; TSK-P3-WP-001; TSK-P3-WP-002 |
| INV-303 | P3-SURF-003; TSK-P3-WP-003 |
| INV-304 | P3-SURF-004; TSK-P3-WP-004 |
| INV-305 | P3-SURF-005; TSK-P3-WP-005 |
| INV-306 | P3-SURF-005; TSK-P3-WP-005 |
| INV-307 | P3-SURF-006; TSK-P3-WP-006 |
| INV-308 | P3-SURF-008; TSK-P3-WP-008; P3-SURF-012; TSK-P3-WP-012 |
| INV-309 | P3-SURF-009; TSK-P3-WP-009 |
| INV-310 | P3-SURF-010; TSK-P3-WP-010 |
| INV-311 | P3-SURF-013; TSK-P3-WP-013 |
| INV-312 | P3-SURF-013; TSK-P3-WP-013 |
| INV-313 | P3-SURF-000; TSK-P3-GOV-005; P3-SURF-011; TSK-P3-WP-011 |

## Future-Phase Routing

These candidates are explicitly excluded from Phase 3 task absorption.

| Candidate | Outcome |
|---|---|
| PII erasure workflows | DEFER to Phase 6 |
| User-facing dashboards or explanation UX | DEFER to Phase 6 |
| Methodology adapter execution | DEFER to Phase 5 |
| Public disclosure APIs or buyer reporting | DEFER to Phase 8D |
| External registry integrations | DEFER to Phase 8B |
| MAIN/MADD authorization runtime | DEFER to Phase 8A |
| Settlement finality and statutory deductions | DEFER to Phase 4 |

## Surface-Specific Implementation Plan Registry

Surface-specific plans are expected under
`docs/PHASE3/implementation_plans/`. Each plan status must match disk state.

| Plan ID | Expected File | Surface | DAG Node | Status |
|---|---|---|---|---|
| TSK-P3-CAP-000 | `TSK-P3-CAP-000_governance_cleanup.md` | P3-SURF-000 | TSK-P3-CLEAN-001 through TSK-P3-CLEAN-008 | created-planning |
| TSK-P3-CAP-001 | `TSK-P3-CAP-001_dependency_graph.md` | P3-SURF-001 | TSK-P3-WP-001 | created-planning |
| TSK-P3-CAP-002 | `TSK-P3-CAP-002_policy_authority_lineage.md` | P3-SURF-002 | TSK-P3-WP-002 | created-planning |
| TSK-P3-CAP-003 | `TSK-P3-CAP-003_projection_legitimacy.md` | P3-SURF-003 | TSK-P3-WP-003 | created-planning |
| TSK-P3-CAP-004 | `TSK-P3-CAP-004_contradiction_detection.md` | P3-SURF-004 | TSK-P3-WP-004 | created-planning |
| TSK-P3-CAP-005 | `TSK-P3-CAP-005_failure_evidence_continuity.md` | P3-SURF-005 | TSK-P3-WP-005 | created-planning |
| TSK-P3-CAP-006 | `TSK-P3-CAP-006_authority_delegation.md` | P3-SURF-006 | TSK-P3-WP-006 | created-planning |
| TSK-P3-CAP-007 | `TSK-P3-CAP-007_regulator_partition.md` | P3-SURF-007 | TSK-P3-WP-007 | created-planning |
| TSK-P3-CAP-008 | `TSK-P3-CAP-008_conflict_of_interest.md` | P3-SURF-008 | TSK-P3-WP-008 | created-planning |
| TSK-P3-CAP-009 | `TSK-P3-CAP-009_spatial_dnsh.md` | P3-SURF-009 | TSK-P3-WP-009 | created-planning |
| TSK-P3-CAP-010 | `TSK-P3-CAP-010_dwell_time_forensics.md` | P3-SURF-010 | TSK-P3-WP-010 | created-planning |
| TSK-P3-CAP-011 | `TSK-P3-CAP-011_verifier_ci.md` | P3-SURF-011 | TSK-P3-WP-011 | created-planning |
| TSK-P3-CAP-012 | `TSK-P3-CAP-012_phase3_activation_alignment.md` | P3-SURF-000 | TSK-P3-ACT-001 through TSK-P3-ACT-005 | created-planning |
| TSK-P3-CAP-013 | `TSK-P3-CAP-013_runtime_verifier_segregation.md` | P3-SURF-012 | TSK-P3-WP-012 | created-planning |
| TSK-P3-CAP-014 | `TSK-P3-CAP-014_uncertainty_semantics.md` | P3-SURF-013 | TSK-P3-WP-013 | created-planning |
| TSK-P3-CAP-015 | `TSK-P3-CAP-015_ai_governance_doctrine.md` | P3-SURF-000 | TSK-P3-GOV-005 | created-planning |

## Broad Wave Plan Registry

| Plan ID | Expected File | Scope | Status |
|---|---|---|---|
| TSK-P3-PLAN-001 | `TSK-P3-PLAN-001_wave1_lineage_foundations.md` | Wave 1 (`TSK-P3-WP-001`, `TSK-P3-WP-002`, `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, `TSK-P3-SUPPORT-SEC-001`) | created-planning |
| TSK-P3-PLAN-002 | `TSK-P3-PLAN-002_wave2_projection_authority_enforcement.md` | Wave 2 (`TSK-P3-WP-003`, `TSK-P3-SUPPORT-VERSION-001`, `TSK-P3-WP-006`, `TSK-P3-SUPPORT-FIXTURE-001`) | created-planning |
| TSK-P3-PLAN-003 | `TSK-P3-PLAN-003_wave3_contradiction_failure_composition.md` | Wave 3 (`TSK-P3-WP-004`, `TSK-P3-WP-005`, `TSK-P3-SUPPORT-MIG-001`) | created-planning |
| TSK-P3-PLAN-004 | `TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md` | Wave 4 (`TSK-P3-WP-007`, `TSK-P3-WP-008`, `TSK-P3-WP-009`, `TSK-P3-WP-010`, `TSK-P3-SUPPORT-OBS-001`, `TSK-P3-SUPPORT-PERF-001`) | created-planning |
| TSK-P3-PLAN-005 | `TSK-P3-PLAN-005_wave5_verifier_segregation_closeout.md` | Wave 5 (`TSK-P3-WP-012`, `TSK-P3-WP-011`, `TSK-P3-WP-013`, `TSK-P3-GOV-005`, `TSK-P3-SUPPORT-DOC-001`) | created-planning |

## Atomic Task Creation Gate

Atomic task creation is not allowed by this plan. A DAG node may be handed to
`CREATE-TASK` only after all of the following are true:

- Wave 0 blockers are resolved or routed into their own earlier atomic cleanup
  tasks;
- source pack, boundary, execution surface map, master plan, and DAG agree;
- the DAG node maps to one or more execution surface IDs;
- every mapped surface has ownership, replay criticality, state mutability,
  ontology, determinism, and doctrine-gap classifications;
- doctrine-gap outcome is `IMPLEMENT` or `SPLIT`;
- future-phase isolation has no unresolved conflict;
- governing doctrine is cited;
- boundary row, execution surface ID, master plan work package, DAG node,
  surface-specific implementation plan, and doctrine references are all
  present in the proposed task;
- the active execution envelope permits the operation.

When `CREATE-TASK` succeeds, the node becomes task-packed. In Phase 3 planning
surfaces this may still be labeled `tasks-created`, but that state means only
that the atomic task pack exists and passes structural readiness. It does not
mean the node is implemented, `resume-ready`, or evidence-complete.

## Non-Goals

This plan does not:

- create atomic implementation tasks;
- create migrations, scripts, CI gates, or evidence artifacts;
- authorize Phase 3 implementation execution while the execution envelope blocks
  it;
- promote any invariant from roadmap to implemented;
- define legitimacy, replay, authority, contradiction, spatial, or failure
  doctrine locally;
- absorb future-phase methodology, settlement, disclosure, registry, MAIN/MADD,
  dashboard, or PII-erasure work.

## Immediate Next Planning Actions

1. Treat this corrected master plan as the authoritative full Phase-3 task
   universe before extracting additional implementation plans or task packs.
2. Ensure future extraction preserves the added runtime/verifier segregation
   surface and the expanded verifier-closure obligations in `TSK-P3-WP-011`.
3. Create surface-specific implementation plans from the registry only after
   dependency grouping and batching are reviewed against the full corrected node set.
4. Begin `CREATE-TASK` only from a blocker-free DAG node with a completed
   surface-specific implementation plan, required lifecycle artifacts, and all
   required citations.
