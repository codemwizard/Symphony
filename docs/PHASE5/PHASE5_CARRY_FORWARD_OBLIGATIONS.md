# PHASE5_CARRY_FORWARD_OBLIGATIONS.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-5
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md

Effective-Date: 2026-05-10

---

## Purpose

This document registers the carry-forward obligations assigned to Phase 5
(Adapter Refactor and Methodology Runtime) as determined by the Phase 3
capability boundary rewrite (2026-05-10) and the canonical phase assignment
derived from Symphony-Phase-Specification-Document_v1.md.

---

## CF-1: Methodology Adapter Extraction

**Origin:** docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md, §1
**Assigned to Phase 5 by:** docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md §Carry-Forward Obligations
**Determination date:** 2026-05-10

### Description

The current architecture tightly couples the registry methodology to core
application logic. It must be extracted into a modular adapter abstraction.

### Phase Specification Basis

Symphony-Phase-Specification-Document_v1.md §Phase 5 — Adapter Refactor and
Methodology Runtime:

> "Shifts the platform from hardcoded methodology logic to an adapter-governed
> methodology runtime capable of simultaneous multi-format evidence exports."

Specifically §5.1–5.4 (Contract and Input Normalization: standardized descriptors,
typed I/O contracts, and explicit dependency declarations for methodologies) directly
addresses the CF-1 obligation.

### Escalation Trigger (unchanged from Phase 2 filing)

Becomes an immediate blocker if a new registry methodology is introduced into the
core without adapter abstraction before Phase 5 is constitutionally open for this
work.

### Phase 5 Entry Condition

CF-1 must be addressed as a formal Phase 5 task. Its Phase 5 entry condition is:
a methodology adapter extraction task must be scaffolded with full constitutional
declarations (TASK_GENERATION_CONSTITUTION.md Part II) and must reference this
document as the CF-1 source.

### Status

DEFERRED. Non-triggered. Non-blocking until escalation condition fires.
Phase 5 is not yet open. This obligation is registered for Phase 5 planning.

---

## Note on Phase 7

Phase 7 (Multi-Methodology Scale Proof) depends on Phase 5's adapter framework
being complete before a second methodology can be onboarded. The CF-1 resolution
in Phase 5 is therefore on the critical path to Phase 7 and all Phase 8 tracks.
