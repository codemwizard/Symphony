# PHASE3_SOURCE_PACK.md

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3

## Purpose

This document is the Phase 3 source-pack index for master implementation
planning. It maps required source-pack information categories to existing
canonical repository documents.

A source-pack category is not the same as a file. One canonical document may
satisfy multiple categories when this index declares the mapping explicitly.

This file does not define doctrine, create atomic tasks, claim phase execution
authority, or supersede the active execution envelope.

## Source-Pack Category Map

| Requirement | Canonical Phase 3 Source |
|---|---|
| Phase purpose | `docs/architecture/Symphony-Phase-Specification-Document_v1.md`; `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` |
| Phase build scope | `docs/architecture/Symphony-Phase-Specification-Document_v1.md` sections 3.1 through 3.8; `docs/PHASE3/phase3_contract.yml` rows P3-001 through P3-009 |
| Phase exit criteria | `docs/architecture/Symphony-Phase-Specification-Document_v1.md`; `docs/PHASE3/phase3_contract.yml` row P3-009; `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` verifier promotion protocol |
| Phase legality status | `docs/operations/PHASE_EXECUTION_ENVELOPE.md`; `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`; `docs/PHASE3/PHASE3_OPENING_ACT.md` |
| Authorized capability domains | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md`; `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`; `docs/PHASE3/phase3_contract.yml` |
| Prohibited capability domains | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md`; `docs/architecture/Symphony-Phase-Specification-Document_v1.md` cross-phase routing; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` |
| Governing doctrines | `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` Required Doctrine Inventory; Phase 3 doctrines under `docs/constitutional/` |
| Phase contract rows | `docs/PHASE3/phase3_contract.yml` |
| Invariant register | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` |
| Verifier expectations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`; `docs/PHASE3/phase3_contract.yml` row P3-009 |
| Evidence expectations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`; `docs/architecture/evidence_schema.json`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` |
| Negative-test expectations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` |
| Replay obligations | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md` |
| Authority obligations | `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md` |
| Carry-forward obligations | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` INV-310; referenced carry-forward CF-2 from Phase 2 closeout material |
| Existing completed or planned task packs | Existing `tasks/TSK-P3-*` and `docs/plans/phase3/TSK-P3-*` directories, when present and readiness-valid |
| Archived or non-canonical documents to exclude | `docs/PHASE3/archive/**`; `docs/constitutional/NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md` |
| Execution envelope constraints | `docs/operations/PHASE_EXECUTION_ENVELOPE.md` |
| Unresolved blockers | `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md` cleanup table; `docs/PHASE3/PHASE3_TASK_DAG.md` Wave 0 blockers |

## Current Blockers

| Blocker | Source | Effect |
|---|---|---|
| Contract parse defect | `docs/PHASE3/phase3_contract.yml` row P3-004 contains malformed indentation | Contract-dependent task planning must not consume the row until repaired |
| Historical runtime-adjacent artifacts | Classification is complete; artifacts marked `regenerate_required` still need opened-phase regeneration before implementation claims rely on them | Runtime-adjacent legacy artifacts remain non-admissible until regenerated under current task packs and verifiers |
| Invariant doctrine-reference gaps | `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` does not yet cite all new Phase 3 governing doctrines per invariant | Atomic task scoping requires cleanup before task packs are generated |
| Duplicate MADD/MAIN doctrine copy | `docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE-2.md` remains a non-canonical duplicate candidate | Citation hygiene must route to the canonical doctrine only |

## Planning Rule

This source pack may be used to create execution-surface maps, master
implementation plans, phase DAGs, and surface-specific implementation plans.
It may now be used to create atomic task packs when the task-creation gate in
`docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md` is satisfied and DAG
dependencies permit the node.
