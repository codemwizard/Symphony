# PHASE3_TASK_DAG.md

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3

## Purpose

This document is the human-readable Phase 3 planning DAG. It sequences the
Phase 3 task universe by constitutional, replay, authority, persistence,
determinism, verifier, and operational dependency order.

This is not an atomic task pack and does not authorize implementation.

## DAG Status Rules

- `blocked`: unresolved cleanup, doctrine, legality, or source-pack issue.
- `planned`: valid planning node, not yet converted to atomic task packs.
- `ready-for-surface-plan`: execution surface exists but surface-specific plan is not created.
- `ready-for-task-creation`: may enter `CREATE-TASK` after all blockers are closed.
- `tasks-created`: atomic task packs exist and pass structural readiness checks.
  This means `task-packed`, not `resume-ready`, implemented, or completed.
- `complete`: downstream atomic tasks are complete with verification evidence.

## Sequencing Fields

- `depends_on` defines structural DAG order: the listed predecessor must be
  completed before the current node can start.
- `blocked_by` defines active impediments: root wave gates, governance
  conflicts, missing doctrine, failed readiness checks, remediation blockers, or
  execution-envelope conflicts.
- `blocked_by` must not duplicate normal predecessors already listed in
  `depends_on`.
- A wave/root gate may block otherwise independent nodes even when their
  `depends_on` field is empty.

## Wave 0 - Governance Cleanup And Readiness

| DAG Node | Surface | Depends On | Blocked By | Status | Purpose |
|---|---|---|---|---|---|
| TSK-P3-CLEAN-001 | P3-SURF-000 | None | None | complete | Fix `docs/PHASE3/phase3_contract.yml` parse/indentation defect. |
| TSK-P3-CLEAN-002 | P3-SURF-000 | None | None | complete | Rewrite `docs/PHASE3/README.md` to match Phase 3 planning posture. |
| TSK-P3-CLEAN-003 | P3-SURF-000 | None | None | complete | Add doctrine references to INV-301 through INV-310 in the invariant register. |
| TSK-P3-CLEAN-004 | P3-SURF-000 | None | None | complete | Reconcile Phase 3 opening posture with the active execution envelope. |
| TSK-P3-CLEAN-005 | P3-SURF-000 | None | None | complete | Resolve duplicate/non-canonical MADD/MAIN doctrine copy. |
| TSK-P3-CLEAN-006 | P3-SURF-000 | None | None | complete | Verify archived Phase 3 files remain non-canonical and excluded. |
| TSK-P3-CLEAN-007 | P3-SURF-000 | TSK-P3-CLEAN-001, TSK-P3-CLEAN-003 | None | complete | Maintain Phase 3 DAG artifacts. |
| TSK-P3-CLEAN-008 | P3-SURF-000 | TSK-P3-CLEAN-007 | None | complete | Maintain implementation-plan registry/status index. |

## Wave 0A - Phase Activation Governance Alignment

| DAG Node | Surface | Depends On | Blocked By | Status | Purpose |
|---|---|---|---|---|---|
| TSK-P3-ACT-001 | P3-SURF-000 | TSK-P3-CLEAN-001, TSK-P3-CLEAN-002, TSK-P3-CLEAN-003, TSK-P3-CLEAN-004, TSK-P3-CLEAN-005, TSK-P3-CLEAN-006, TSK-P3-CLEAN-007, TSK-P3-CLEAN-008 | None | complete | Build the missing Phase 3 lifecycle artifact set. |
| TSK-P3-ACT-002 | P3-SURF-000 | TSK-P3-ACT-001 | None | complete | Create the formal Phase 3 opening approval artifact set and constitutional opening attestation outputs. |
| TSK-P3-ACT-003 | P3-SURF-000 | TSK-P3-ACT-001, TSK-P3-ACT-002 | None | complete | Rewrite the root execution envelope for active Phase 3 status. |
| TSK-P3-ACT-004 | P3-SURF-000 | TSK-P3-ACT-003 | None | complete | Reconcile the legality layer and dependent Phase 3 planning posture. |
| TSK-P3-ACT-005 | P3-SURF-000 | TSK-P3-ACT-004 | None | complete | Normalize existing Phase 3 plans and evidence for opened-phase use, including activation-close attestation outputs. |

## Wave 1 - Lineage Foundations

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-001 | P3-SURF-001 | TSK-P3-ACT-005 | completed | Typed dependency graph lineage and traversal substrate. |
| TSK-P3-WP-002 | P3-SURF-002 | TSK-P3-WP-001 | completed | Policy artifact and authority lineage foundation. |
| TSK-P3-SUPPORT-DB-001 | P3-SURF-001, P3-SURF-002 | TSK-P3-WP-001, TSK-P3-WP-002 | completed | Persistence model for dependency, policy, and authority lineage surfaces. |
| TSK-P3-SUPPORT-SEC-001 | P3-SURF-001, P3-SURF-002 | TSK-P3-SUPPORT-DB-001 | completed | Access-control and privilege model for lineage surfaces. |
| TSK-P3-SUPPORT-CONTRACT-001 | P3-SURF-001, P3-SURF-002 | TSK-P3-WP-001, TSK-P3-WP-002 | completed | Deterministic internal serialization, proof contracts, and offline replay package schema contracts for lineage records. |

## Wave 2 - Projection And Authority Enforcement

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-003 | P3-SURF-003 | TSK-P3-WP-001, TSK-P3-WP-002, TSK-P3-SUPPORT-CONTRACT-001 | completed | Projection universes and recursive legitimacy evaluation. |
| TSK-P3-WP-006 | P3-SURF-006 | TSK-P3-WP-002, TSK-P3-SUPPORT-SEC-001 | completed | Authority scope and delegation enforcement. |
| TSK-P3-SUPPORT-FIXTURE-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-006 | TSK-P3-WP-003, TSK-P3-WP-006 | completed | Canonical valid/invalid lineage, authority, and legitimacy fixtures. |
| TSK-P3-SUPPORT-VERSION-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003 | TSK-P3-WP-003 | completed | Schema, projection, proof, policy format compatibility, and replay hash regression planning. |

## Wave 3 - Contradiction And Failure Composition

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-004 | P3-SURF-004 | TSK-P3-WP-003, TSK-P3-WP-006 | completed | Contradiction detection, quarantine, supersession, and escalation mechanics. |
| TSK-P3-WP-005 | P3-SURF-005 | TSK-P3-WP-003, TSK-P3-WP-004 | completed | Failure composition and cross-system evidence continuity. |
| TSK-P3-SUPPORT-MIG-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-006 | TSK-P3-SUPPORT-DB-001, TSK-P3-WP-005 | completed | Migration and backfill planning for replay-addressable lineage, findings, and pre-/post-Phase-3 fixture equality preservation. |

## Wave 4 - Regulator, COI, Spatial, And Temporal Gates

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-007 | P3-SURF-007 | TSK-P3-WP-002, TSK-P3-WP-004 | completed | Regulator-aware partitioning, precedence application, and non-collapse mechanics. |
| TSK-P3-WP-008 | P3-SURF-008 | TSK-P3-WP-006 | completed | Conflict-of-interest and verifier independence enforcement. |
| TSK-P3-WP-009 | P3-SURF-009 | TSK-P3-WP-002, TSK-P3-WP-005 | completed | Spatial constraint and DNSH gates. |
| TSK-P3-WP-010 | P3-SURF-010 | TSK-P3-WP-003, TSK-P3-WP-004, TSK-P3-WP-005 | completed | Dwell-time forensic findings under temporal replay doctrine. |
| TSK-P3-SUPPORT-PERF-001 | P3-SURF-001, P3-SURF-003, P3-SURF-009 | TSK-P3-WP-009, TSK-P3-WP-010 | completed | Deterministic traversal, spatial, and projection scale bounds. |
| TSK-P3-SUPPORT-OBS-001 | P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-007, P3-SURF-009 | TSK-P3-WP-007, TSK-P3-WP-009, TSK-P3-WP-010 | completed | Internal constitutional observability without UI/dashboard semantics. |

## Wave 5 - Verifier, Segregation, Uncertainty, AI, CI, And Closeout Planning

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-012 | P3-SURF-012 | TSK-P3-WP-005, TSK-P3-WP-006, TSK-P3-WP-008 | completed | Runtime/verifier trust-boundary segregation, artifact exchange contracts, and privilege-separated verification surfaces. |
| TSK-P3-WP-011 | P3-SURF-011 | TSK-P3-WP-001 through TSK-P3-WP-010, TSK-P3-WP-012 | completed | Verifier suite, CI wiring, evidence expectations, negative tests, invariant-to-verifier registry, capability-boundary contamination tests, and invariant promotion protocol. |
| TSK-P3-WP-013 | P3-SURF-013 | TSK-P3-WP-011, TSK-P3-WP-012 | completed | Uncertainty classification, operator-governed propagation, and replay-admissible authority transfer semantics. |
| TSK-P3-GOV-005 | P3-SURF-000 | TSK-P3-WP-013 | completed | AI governance doctrine, model registry and inference log schemas, and confidence-to-uncertainty admissibility mappings. |
| TSK-P3-SUPPORT-DOC-001 | P3-SURF-000 through P3-SURF-013 | TSK-P3-WP-011, TSK-P3-WP-012, TSK-P3-WP-013, TSK-P3-GOV-005 | completed | Implementation references, replay specifications, and operator-neutral documentation. |

## Post-Wave Follow-Up Governance And Baseline Repairs

| DAG Node | Surface | Depends On | Status | Purpose |
|---|---|---|---|---|
| TSK-P3-GOV-004 | P3-SURF-000 | None | completed | Repair DB task-pack generator and planning-to-task handoff scope so canonical DB baseline, migration-head, ADR, and human task-index closure surfaces are emitted without manual patching. |
| TSK-P3-SUPPORT-DB-002 | P3-SURF-000 | TSK-P3-SUPPORT-SEC-001 | completed | Make privilege-only migration effects visible to canonical baseline and drift governance. |
| TSK-P3-SUPPORT-DB-003 | P3-SURF-000 | None | completed | Fail-closed DB verifier bootstrap and connection diagnostics for `scripts/db` verifiers so DB/bootstrap failure cannot be silently misreported as schema absence. |
| TSK-P3-GOV-006 | P3-SURF-000 | None | completed | Fail-closed DB probe contract for audit-side DB-facing verifiers and implementation-process guidance. |
| TSK-P3-GOV-007 | P3-SURF-000 | TSK-P3-GOV-004 | completed | Normalize proof-before-completion lifecycle semantics so task proof no longer depends on pre-set completed status. |
| TSK-P3-SUPPORT-DB-004 | P3-SURF-000 | TSK-P3-SUPPORT-DB-002 | completed | Make `baseline_then_migrations` safe on fresh databases with the default `public` schema while preserving baseline-cutoff governance. |
| TSK-P3-GOV-008 | P3-SURF-000 | None | completed | Reconcile Stage A approval semantics with wave-end `pre_ci` and final governance signoff timing. |

## Explicit Future-Phase Routing

| Candidate | DAG Outcome |
|---|---|
| PII erasure workflows | DEFER to Phase 6 |
| User-facing dashboards or explanation UX | DEFER to Phase 6 |
| Methodology adapter execution | DEFER to Phase 5 |
| Public disclosure APIs or buyer reporting | DEFER to Phase 8D |
| External registry integrations | DEFER to Phase 8B |
| MAIN/MADD authorization runtime | DEFER to Phase 8A |
| Settlement finality and statutory deductions | DEFER to Phase 4 |

## Coverage Check

| Scope | Covered By |
|---|---|
| Phase spec 3.1 | P3-SURF-001; TSK-P3-WP-001 |
| Phase spec 3.2 | P3-SURF-003; TSK-P3-WP-003; P3-SURF-010; TSK-P3-WP-010 |
| Phase spec 3.3 | P3-SURF-004; TSK-P3-WP-004 |
| Phase spec 3.4 | P3-SURF-005; TSK-P3-WP-005 |
| Phase spec 3.5 | P3-SURF-002; TSK-P3-WP-002; P3-SURF-006; TSK-P3-WP-006 |
| Phase spec 3.6 | P3-SURF-007; TSK-P3-WP-007 |
| Phase spec 3.7 | P3-SURF-008; TSK-P3-WP-008; P3-SURF-012; TSK-P3-WP-012 |
| Phase spec 3.8 | P3-SURF-009; TSK-P3-WP-009 |
| Phase spec 3.9 | P3-SURF-013; TSK-P3-WP-013 |
| Phase spec 3.10 | P3-SURF-000; TSK-P3-GOV-005 |
| Contract rows P3-001 through P3-011 | P3-SURF-000 through P3-SURF-013 |
| Invariants INV-301 through INV-313 | P3-SURF-000 through P3-SURF-013 |

## Atomic Task Creation Gate

No DAG node may be converted to atomic tasks until:

- Wave 0 blockers are resolved;
- source pack, boundary, surface map, and DAG agree;
- the node maps to an execution surface;
- the surface has ownership, replay, mutability, ontology, determinism, and
  doctrine-gap classifications;
- the node has a doctrine-gap outcome of `IMPLEMENT` or `SPLIT`;
- no future-phase routing conflict remains;
- the Phase 3 activation nodes are complete when the node depends on the
  opened-phase governance posture.
