# Phase 3 Replay Migration And Backfill Contract

Task: `TSK-P3-SUPPORT-MIG-001`

This contract is the single canonical shared planning artifact for replay-addressable
migration and backfill obligations across:

- `P3-SURF-001`
- `P3-SURF-002`
- `P3-SURF-003`
- `P3-SURF-004`
- `P3-SURF-005`
- `P3-SURF-006`

It is planning-only. It does not authorize applied migration execution, runtime
backfill, or destructive historical rewrite semantics.

## Additive-Only Reconciliation Rule

All replay-addressable migration and backfill planning in Phase 3 is
additive-only.

- Wave 1 lineage meaning must remain preserved.
- Wave 2 projection and authority meaning must remain preserved.
- Wave 3 contradiction and failure meaning must remain preserved.
- No owning surface may unilaterally freeze, compress, or reinterpret another
  owning surface's replay substrate.

## Canonical Owning Surface Coverage

The shared artifact must preserve replay-addressable continuity for:

- dependency graph lineage (`P3-SURF-001`)
- policy and authority lineage (`P3-SURF-002`)
- projection legitimacy records (`P3-SURF-003`)
- contradiction findings, quarantine, supersession, and escalation (`P3-SURF-004`)
- failure trees and provenance continuity (`P3-SURF-005`)
- authority scope and delegation enforcement (`P3-SURF-006`)

Coverage is incomplete if any one of these six owning surfaces is omitted.

## Replay-Equality Declaration Rules

Migration and backfill planning must explicitly declare the replay-equality
floor for every touched artifact family:

- `replay_hash_continuity`
- `structural_lineage_equality`
- `semantic_admissibility_equivalence`
- `projection_equivalence`

No replay-equality layer may be silently assumed. If a touched layer is not
verified, the contract must say so explicitly.

## Ontology-Transition Guards

Cross-surface transition rules must remain replay-safe:

- lineage findings may flow into projection or authority surfaces only as
  replay-addressable inputs
- contradiction findings may flow into failure composition only as read-only
  immutable references
- authority scope findings may constrain contradiction or failure decisions but
  may not be reinterpreted as policy lineage truth
- no migration plan may collapse orthogonal ontologies into a single local
  surrogate representation

## Fixture-Equality Preservation

Pre- and post-migration fixture closure must preserve canonical replay fixtures:

- Wave 1 lineage fixtures
- Wave 2 legitimacy and authority fixtures
- Wave 3 contradiction fixtures
- Wave 3 failure continuity fixtures

Fixture equality must remain deterministic across:

- fixture identity keys
- negative_sqlstate expectations
- replay_context_hash anchors
- wave1_semantics_preserved / prior-wave semantics preservation flags

## Deterministic Ordering And Tie-Break Rules

Migration planning must not rely on undeclared ordering.

- canonical ordering inputs must be declared for replay-addressable rewrite or
  rebinding steps
- tie-break rules must be explicit where canonical ordering values can collide
- insertion order, engine order, cache order, and UUID lexical order are not
  allowed as undeclared tie-break authorities

## Prohibited Drift

This contract explicitly excludes:

- applied migration execution
- runtime backfill execution
- destructive historical rewrites
- unilateral scope freezing by one owning surface
- undeclared ordering assumptions
- undeclared authority-transfer ownership assumptions
- future-phase workflow semantics

## Runtime And Verifier Boundary

This contract is authoritative for planning obligations only.

- runtime migration code must be implemented in later atomic tasks
- verifier code may prove that the contract exists and covers all six owning
  surfaces
- verifier code may not claim that runtime backfill completion has occurred
