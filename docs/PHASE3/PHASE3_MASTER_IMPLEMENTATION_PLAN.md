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
| Phase purpose, build scope, exit criteria | `docs/architecture/Symphony-Phase-Specification-Document_v1.md`, sections 3.1 through 3.8; `docs/PHASE3/phase3_contract.yml` |
| Legality status and phase routing | `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`; `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` |
| Authorized and prohibited capability domains | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` |
| Governing doctrines | Phase 3 doctrine inventory in `docs/constitutional/**` |
| Contract rows | `docs/PHASE3/phase3_contract.yml` rows P3-001 through P3-009 |
| Invariant register | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` rows INV-301 through INV-310 |
| Verifier, evidence, and negative-test expectations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`; `docs/PHASE3/phase3_contract.yml` row P3-009 |
| Replay and authority obligations | replay, authority, policy-lineage, contradiction, failure, spatial, sovereignty, and evidentiary doctrines |
| Carry-forward obligations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` INV-310 and referenced Phase 2 carry-forward material |
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

## Full Task Universe

The following DAG nodes are the complete Phase 3 implementation-plan universe
currently generated from the source pack, boundary, and execution surface map.
They are planning nodes, not atomic task packs.

### Wave 0 - Governance Cleanup And Readiness

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-CLEAN-001 | P3-SURF-000 | blocked | IMPLEMENT | Fix `docs/PHASE3/phase3_contract.yml` parse/indentation defect. |
| TSK-P3-CLEAN-002 | P3-SURF-000 | planned | IMPLEMENT | Rewrite `docs/PHASE3/README.md` to match Phase 3 planning posture. |
| TSK-P3-CLEAN-003 | P3-SURF-000 | planned | IMPLEMENT | Add doctrine references to INV-301 through INV-310 in the invariant register. |
| TSK-P3-CLEAN-004 | P3-SURF-000 | blocked | ESCALATE-DOCTRINE | Reconcile Phase 3 opening posture with the active execution envelope. |
| TSK-P3-CLEAN-005 | P3-SURF-000 | planned | IMPLEMENT | Resolve duplicate or non-canonical MADD/MAIN doctrine copy. |
| TSK-P3-CLEAN-006 | P3-SURF-000 | planned | IMPLEMENT | Verify archived Phase 3 files remain non-canonical and excluded. |
| TSK-P3-CLEAN-007 | P3-SURF-000 | planned | IMPLEMENT | Maintain Phase 3 DAG artifacts after cleanup. |
| TSK-P3-CLEAN-008 | P3-SURF-000 | planned | IMPLEMENT | Maintain implementation-plan registry and status index. |

### Wave 0A - Phase Activation Governance Alignment

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-ACT-001 | P3-SURF-000 | planned | IMPLEMENT | Build the missing Phase 3 lifecycle artifact set. |
| TSK-P3-ACT-002 | P3-SURF-000 | planned | IMPLEMENT | Create the formal Phase 3 opening approval artifact set. |
| TSK-P3-ACT-003 | P3-SURF-000 | planned | IMPLEMENT | Rewrite the root execution envelope for active Phase 3 status. |
| TSK-P3-ACT-004 | P3-SURF-000 | planned | IMPLEMENT | Reconcile the legality layer and dependent Phase 3 planning posture. |
| TSK-P3-ACT-005 | P3-SURF-000 | planned | IMPLEMENT | Normalize existing Phase 3 plans and evidence for opened-phase use. |

### Wave 1 - Lineage Foundations

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-001 | P3-SURF-001 | planned | IMPLEMENT | Typed dependency graph lineage and traversal substrate. |
| TSK-P3-WP-002 | P3-SURF-002 | planned | IMPLEMENT | Policy artifact and authority lineage foundation. |
| TSK-P3-SUPPORT-DB-001 | P3-SURF-001, P3-SURF-002 | planned | IMPLEMENT | Persistence model for dependency, policy, and authority lineage surfaces. |
| TSK-P3-SUPPORT-SEC-001 | P3-SURF-001, P3-SURF-002 | planned | IMPLEMENT | Access-control and privilege model for lineage surfaces. |
| TSK-P3-SUPPORT-CONTRACT-001 | P3-SURF-001, P3-SURF-002 | planned | IMPLEMENT | Deterministic internal serialization and proof contracts for lineage records. |

### Wave 2 - Projection And Authority Enforcement

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-003 | P3-SURF-003 | planned | IMPLEMENT | Projection universes and recursive legitimacy evaluation. |
| TSK-P3-WP-006 | P3-SURF-006 | planned | IMPLEMENT | Authority scope and delegation enforcement. |
| TSK-P3-SUPPORT-FIXTURE-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-006 | planned | IMPLEMENT | Canonical valid and invalid lineage, authority, and legitimacy fixtures. |
| TSK-P3-SUPPORT-VERSION-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003 | planned | IMPLEMENT | Schema, projection, proof, and policy format compatibility planning. |

### Wave 3 - Contradiction And Failure Composition

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-004 | P3-SURF-004 | planned | IMPLEMENT | Contradiction detection, quarantine, supersession, and escalation mechanics. |
| TSK-P3-WP-005 | P3-SURF-005 | planned | IMPLEMENT | Failure composition and internal evidence continuity. |
| TSK-P3-SUPPORT-MIG-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-006 | planned | IMPLEMENT | Migration and backfill planning for replay-addressable lineage and findings. |

### Wave 4 - Regulator, COI, Spatial, And Temporal Gates

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-007 | P3-SURF-007 | planned | IMPLEMENT | Regulator-aware partitioning, precedence application, and non-collapse mechanics. |
| TSK-P3-WP-008 | P3-SURF-008 | planned | IMPLEMENT | Conflict-of-interest and verifier independence enforcement. |
| TSK-P3-WP-009 | P3-SURF-009 | planned | IMPLEMENT | Spatial constraint and DNSH gates. |
| TSK-P3-WP-010 | P3-SURF-010 | planned | IMPLEMENT | Dwell-time forensic findings under temporal replay doctrine. |
| TSK-P3-SUPPORT-PERF-001 | P3-SURF-001, P3-SURF-003, P3-SURF-009 | planned | IMPLEMENT | Deterministic traversal, spatial, and projection scale bounds. |
| TSK-P3-SUPPORT-OBS-001 | P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-007, P3-SURF-009 | planned | IMPLEMENT | Internal constitutional observability without UI or dashboard semantics. |

### Wave 5 - Verifier, CI, And Closeout Planning

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-011 | P3-SURF-011 | planned | IMPLEMENT | Verifier suite, CI wiring, evidence expectations, negative tests, and invariant promotion protocol. |
| TSK-P3-SUPPORT-DOC-001 | P3-SURF-000 through P3-SURF-011 | planned | IMPLEMENT | Implementation references, replay specifications, and operator-neutral documentation. |

## Support-Domain Justification

Support domains are included only where required by replay legality, authority
reconstruction, admissibility evaluation, deterministic enforcement, verifier
closure, or constitutional persistence.

| Support Domain | DAG Node | Constitutional Justification | Prohibited Expansion |
|---|---|---|---|
| Persistence model | TSK-P3-SUPPORT-DB-001 | constitutional persistence and replay legality for lineage surfaces | runtime DDL, speculative schema work, future-phase persistence |
| Access control | TSK-P3-SUPPORT-SEC-001 | authority reconstruction and separation of lineage authority | broad privilege changes or product auth workflows |
| Serialization/proof contracts | TSK-P3-SUPPORT-CONTRACT-001 | deterministic enforcement and replay-stable proof interfaces | public product APIs or external integration contracts |
| Fixtures | TSK-P3-SUPPORT-FIXTURE-001 | verifier closure and negative-test coverage | scenario prose without mechanical validation value |
| Versioning | TSK-P3-SUPPORT-VERSION-001 | replay continuity across schemas, projections, proofs, and policy formats | speculative product versioning |
| Migration/backfill planning | TSK-P3-SUPPORT-MIG-001 | constitutional persistence and replay reconstruction | applied migration edits or unapproved runtime migration work |
| Performance bounds | TSK-P3-SUPPORT-PERF-001 | deterministic traversal, spatial, and projection scale limits | optimization work that changes replay truth |
| Observability | TSK-P3-SUPPORT-OBS-001 | internal detection of constitutional projection and failure states | dashboards, user-facing explanations, or disclosure UX |
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
| Phase spec 3.7 | P3-SURF-008; TSK-P3-WP-008 |
| Phase spec 3.8 | P3-SURF-009; TSK-P3-WP-009 |
| P3-001 | P3-SURF-001; TSK-P3-WP-001 |
| P3-002 | P3-SURF-003; TSK-P3-WP-003; P3-SURF-010; TSK-P3-WP-010 |
| P3-003 | P3-SURF-004; TSK-P3-WP-004 |
| P3-004 | P3-SURF-005; TSK-P3-WP-005; blocked by TSK-P3-CLEAN-001 until contract row parses |
| P3-005 | P3-SURF-002; TSK-P3-WP-002; P3-SURF-006; TSK-P3-WP-006 |
| P3-006 | P3-SURF-007; TSK-P3-WP-007 |
| P3-007 | P3-SURF-008; TSK-P3-WP-008 |
| P3-008 | P3-SURF-009; TSK-P3-WP-009 |
| P3-009 | P3-SURF-011; TSK-P3-WP-011 |
| INV-301 | P3-SURF-007; TSK-P3-WP-007 |
| INV-302 | P3-SURF-001; P3-SURF-002; TSK-P3-WP-001; TSK-P3-WP-002 |
| INV-303 | P3-SURF-003; TSK-P3-WP-003 |
| INV-304 | P3-SURF-004; TSK-P3-WP-004 |
| INV-305 | P3-SURF-005; TSK-P3-WP-005 |
| INV-306 | P3-SURF-005; TSK-P3-WP-005 |
| INV-307 | P3-SURF-006; TSK-P3-WP-006 |
| INV-308 | P3-SURF-008; TSK-P3-WP-008 |
| INV-309 | P3-SURF-009; TSK-P3-WP-009 |
| INV-310 | P3-SURF-010; TSK-P3-WP-010 |

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
| TSK-P3-CAP-001 | `TSK-P3-CAP-001_dependency_graph.md` | P3-SURF-001 | TSK-P3-WP-001 | not-created |
| TSK-P3-CAP-002 | `TSK-P3-CAP-002_policy_authority_lineage.md` | P3-SURF-002 | TSK-P3-WP-002 | not-created |
| TSK-P3-CAP-003 | `TSK-P3-CAP-003_projection_legitimacy.md` | P3-SURF-003 | TSK-P3-WP-003 | not-created |
| TSK-P3-CAP-004 | `TSK-P3-CAP-004_contradiction_detection.md` | P3-SURF-004 | TSK-P3-WP-004 | not-created |
| TSK-P3-CAP-005 | `TSK-P3-CAP-005_failure_evidence_continuity.md` | P3-SURF-005 | TSK-P3-WP-005 | not-created |
| TSK-P3-CAP-006 | `TSK-P3-CAP-006_authority_delegation.md` | P3-SURF-006 | TSK-P3-WP-006 | not-created |
| TSK-P3-CAP-007 | `TSK-P3-CAP-007_regulator_partition.md` | P3-SURF-007 | TSK-P3-WP-007 | not-created |
| TSK-P3-CAP-008 | `TSK-P3-CAP-008_conflict_of_interest.md` | P3-SURF-008 | TSK-P3-WP-008 | not-created |
| TSK-P3-CAP-009 | `TSK-P3-CAP-009_spatial_dnsh.md` | P3-SURF-009 | TSK-P3-WP-009 | not-created |
| TSK-P3-CAP-010 | `TSK-P3-CAP-010_dwell_time_forensics.md` | P3-SURF-010 | TSK-P3-WP-010 | not-created |
| TSK-P3-CAP-011 | `TSK-P3-CAP-011_verifier_ci.md` | P3-SURF-011 | TSK-P3-WP-011 | not-created |
| TSK-P3-CAP-012 | `TSK-P3-CAP-012_phase3_activation_alignment.md` | P3-SURF-000 | TSK-P3-ACT-001 through TSK-P3-ACT-005 | created-planning |

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

1. Use `TSK-P3-CAP-012` to formalize the Phase 3 activation sweep and create
   the corresponding `TSK-P3-ACT-00*` planning nodes.
2. Create surface-specific implementation plans from the remaining registry
   entries once the activation posture is reconciled.
3. Update `docs/PHASE3/phase3_task_dag.yml` statuses only after blockers,
   activation posture, or surface plans change.
4. Begin `CREATE-TASK` only from a blocker-free DAG node with a completed
   surface-specific implementation plan, required lifecycle artifacts, and all
   required citations.
