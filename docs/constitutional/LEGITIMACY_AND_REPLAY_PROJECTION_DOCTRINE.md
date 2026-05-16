# LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal projection-universe, replay-view, and legitimacy-view terminology
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_GLOSSARY.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This doctrine defines the Phase 3 meaning of projection universes, replay
reconstruction, derived legitimacy states, replay acceleration artifacts, and
operational exhaust.

Phase 3 may compute legitimacy and admissibility views from historical records.
It may not mutate historical truth, redefine sovereign policy meaning, or convert
runtime materializations into constitutional authority.

---

## 1. Historical Truth

Historical truth is the append-only canonical record of what Symphony knew,
accepted, rejected, signed, referenced, and persisted at the time an event or
decision occurred.

Historical truth includes:

- canonical payload bytes and canonicalization version references;
- transition hashes, execution identifiers, policy decision identifiers, and
  interpretation version identifiers;
- signatures, signer resolution lineage, authority references, and key lifecycle
  references;
- append-only decision, contradiction, failure, quarantine, supersession, and
  compensating-lineage records;
- timestamps and effective-time windows persisted as part of the constitutional
  record.

Historical truth excludes runtime memory, mutable caches, transient service
responses, operational telemetry, dashboard state, derived read models, and
task-generation commentary.

No Phase 3 task may replace, delete, rewrite, or retroactively reclassify
historical truth. Later findings must be appended as new replay-visible records.

---

## 2. Replay Reconstruction

Replay reconstruction is the deterministic recomputation of a historical
decision, admissibility view, or legitimacy view from persisted canonical
artifacts under the policy, authority, interpretation, and temporal context
declared for the replay.

Replay reconstruction must:

1. consume only persisted canonical lineage and declared projection context;
2. identify the policy, authority, regulator, jurisdiction, and temporal inputs
   used for the replay;
3. produce the same result when recomputed from the same inputs;
4. fail closed when required historical inputs are missing or ambiguous;
5. append any new finding instead of mutating the historical record being
   replayed.

Replay reconstruction is not disaster recovery. It is a constitutional
permanence obligation for Phase 3 legitimacy and admissibility evaluation.

---

## 3. Projection Universe

A projection universe is a bounded interpretive context used to derive a
legitimacy, admissibility, contradiction, or failure view from the same
historical truth record.

Every projection universe must declare:

- projection universe identifier;
- projection purpose;
- policy artifact set and versions;
- authority lineage inputs;
- regulator or jurisdiction context, if any;
- temporal evaluation point or interval;
- contradiction lineage included or excluded;
- replay rules and projection algorithm version;
- source historical record set.

A projection universe is a derived view. It is not historical truth, not a
sovereign policy source, and not a mutable substitute for canonical lineage.

Different projection universes may produce different derived views only when
their declared policy, authority, temporal, jurisdictional, or replay inputs
differ. The difference is a property of the declared projection context, not a
license to choose the preferred outcome.

---

## 4. Projection Isolation

Projection universes must be isolated from each other. A projection universe may
read historical truth and its declared policy inputs, but it may not import a
derived result from another projection universe as if that result were canonical
truth.

The following cross-universe contamination patterns are prohibited:

- using one regulator's admissibility finding as evidence of another regulator's
  admissibility finding;
- applying a current policy projection to mutate or erase a prior historical
  admissibility state;
- using a derived cache or snapshot as the source of legitimacy without its
  canonical source lineage;
- collapsing authority-lineage differences between projection contexts;
- treating a quarantine, contradiction, or supersession result in one universe
  as universal across all universes.

Where cross-universe comparison is required, Phase 3 must produce an explicit
comparison record that names both projection universes and preserves each result
without collapse.

---

## 5. Derived Legitimacy and Admissibility States

A derived legitimacy state is the output of replay reconstruction or projection
evaluation. It may state that a decision is legitimate, illegitimate, blocked,
quarantined, superseded, contradicted, or requires escalation within the declared
projection universe.

Derived states must be:

- source-linked to historical truth;
- projection-context-linked;
- deterministic under replay;
- append-only when persisted;
- explicit about proof limitations.

A derived state may cause future operations to fail closed. It may not rewrite
what was historically accepted, rejected, or signed. If a later replay finds that
a historical decision should not be relied on under a later projection universe,
the result is an appended finding, not a retroactive mutation.

---

## 6. Replay Acceleration and Operational Exhaust

Replay acceleration artifacts include snapshots, checkpoints, indexes, cached
read models, materialized views, compiled traversals, and projection caches.
They are permitted only as performance aids.

Replay acceleration artifacts must be:

- derivable from canonical historical truth and declared projection context;
- discardable without loss of constitutional record;
- reproducible from source lineage;
- source-hash-linked where persisted;
- algorithm-version-linked where replay behavior depends on code or rules.

Operational exhaust includes runtime memory, logs not registered as evidence,
telemetry, queue state, dashboard state, local temporary files, and ephemeral
service responses. Operational exhaust has no constitutional authority for Phase
3 legitimacy evaluation unless separately promoted into an admissible evidence
artifact by a governing doctrine.

---

## 7. Task-Generation Rule

Phase 3 tasks may implement projection storage, replay reconstruction, projection
isolation, deterministic evaluation, and verifier mechanics.

Phase 3 tasks must not define:

- sovereign policy meaning;
- regulator-specific admissibility standards;
- authority semantics not established by governing doctrine;
- contradiction categories not established by governing doctrine;
- historical truth mutation rules.

If a task requires projection semantics not defined here or in a referenced
doctrine, the task is blocked and must become a doctrine-gap task.

---

## Constitutional Self-Validation

**Sovereignty domains governed:** Phase 3 replay projection and derived
legitimacy/admissibility evaluation.

**Sovereignty domains this document must not redefine:** Root replay doctrine,
temporal validity doctrine, regulator sovereignty doctrine, evidentiary
admissibility doctrine, or jurisdiction-specific law.

**Replay obligations preserved:** Historical truth remains append-only. Later
projection results are appended and replay-visible; they do not mutate prior
records.

**Regulator boundaries:** Regulator-specific projection universes remain
orthogonal unless an explicit cross-domain protocol is declared by regulator
doctrine.

**Phases this document applies to:** Phase 3 task scoping and implementation.

**Override authority:** Root constitutional doctrine and superior replay,
temporal, evidentiary, and regulator doctrines override this document within
their domains.

---

## Prohibited Misinterpretations

**PM-LRP-01 - Projection as Truth:** A projection universe must not be treated as
historical truth.

**PM-LRP-02 - Replay as Mutation:** Replay reconstruction must not be used to
rewrite historical records.

**PM-LRP-03 - Cache as Authority:** A replay cache, snapshot, checkpoint, or read
model must not be treated as constitutional authority.

**PM-LRP-04 - Cross-Universe Collapse:** A derived finding in one projection
universe must not be treated as universal across all projection universes.

