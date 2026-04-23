# Green Finance Wave 1 — Task DAG (v5)
# Corrected Phase Sequence and Dependency Architecture

## Core Architectural Principle
A task metadata graph is NOT the schema domain graph. 
- Governance operations enforce global constraints anchored securely to state transitions.
- Schema migrations execute chronologically following rigid, explicit completion maps.

---

## Phase A — REMEDIATION (Verified State Transition Gate)
Before arbitrary task sequences execute, the local state MUST be proven secure and properly mapped.
This is a strict verified state transition, not just a topological step.

**REMEDIATION_ROOT**
Must mechanically guarantee:
1. Rollback completion / validation
2. Removal of invalid tasks & migrations
3. Zero ownerless references exist
4. `MIGRATION_HEAD` recomputed and verified accurately

---

## Governance Layer (GLOBAL_VERIFIER_GATE)
Orthogonal but firmly anchored to prevent bypasses.

**GLOBAL_VERIFIER_GATE**
- *Depends on: [REMEDIATION_ROOT]*
- *Runs: GF-W1-GOV-005A (ownership/reference-order fail-closed verifier)*
- Ensures static DDL only compliance locally.

---

## Phase B — DOMAIN DAG ONLY (Explicit Ownership Edges)
The correct schema sequence relies intrinsically upon origin tracking explicitly separated from application layer functions. Adhering to explicit completeness, dependencies are redundantly mapped bridging the parent anchor accurately avoiding implicit graph gaps.

1. **GF-W1-SCH-002A** (root — establishes foundation: projects + methodologies)
   *Depends on: [GLOBAL_VERIFIER_GATE]*
2. **GF-W1-SCH-003** (monitoring_records)
   *Depends on: [GF-W1-SCH-002A]*
3. **GF-W1-SCH-004** (evidence_nodes + edges)
   *Depends on: [GF-W1-SCH-003, GF-W1-SCH-002A (ownership completeness)]*
4. **GF-W1-SCH-005** (asset_batches + lifecycle + retirement)
   *Depends on: [GF-W1-SCH-004, GF-W1-SCH-002A]*
5. **GF-W1-SCH-008** (verifier_registry + project assignments)
   *Depends on: [GF-W1-SCH-002A]*
6. **GF-W1-PLT-001** (adapter registration logic layer)
   *Depends on: [GF-W1-SCH-002A]*

---

## Secondary Systems Layers (FNC, FRZ, DSN)
Tasks belonging to structural, freeze, or design logic evaluate explicitly relative to schema dependencies above (Domain DAG). They must never be sorted blindly into a flat array structure.

*End of structural governance mapping.*
