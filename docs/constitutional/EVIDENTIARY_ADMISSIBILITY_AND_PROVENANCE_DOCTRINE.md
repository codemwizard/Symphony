# EVIDENTIARY ADMISSIBILITY AND PROVENANCE DOCTRINE

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 9
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/contracts/ED25519_SIGNING_CONTRACT.md
  - docs/contracts/TRANSITION_HASH_CONTRACT.md
  - docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md
  - docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md
  - docs/architecture/SIGNATURE_METADATA_STANDARD.md
  - docs/architecture/ARTIFACT_CLASS_TAXONOMY.md
  - docs/architecture/EVIDENCE_EVENT_CLASSES.md
  - docs/security/AUDIT_LOGGING_RETENTION_POLICY.md
  - docs/security/KEY_MANAGEMENT_POLICY.md
  - docs/security/ZDPA_COMPLIANCE_MAP.md

---

## 1. Purpose

This doctrine defines Symphony as a constitutional evidentiary admissibility
system. It establishes the legal and constitutional standing of all evidence
classes produced, preserved, and replayed by Symphony's runtime, and defines the
obligations governing provenance continuity, temporal evidence validity,
historical reconstruction, and regulator-grade audit survivability across all
phases and all sovereign domains.

Evidence in Symphony is not auxiliary application metadata. Evidence is
constitutional state-bearing substrate. Every accepted transition, every
settlement finality record, every signed asset batch, and every policy decision
carries an evidentiary identity from the moment of its acceptance. That identity
is permanent, provenance-linked, temporally bounded, and independently verifiable.

This doctrine governs the admissibility conditions under which evidence may be
presented to regulators, adjudicators, counterparties, and auditors; the
continuity obligations that ensure admissibility survives key rotation,
supersession, and phase progression; and the prohibitions that prevent
operational optimizations from destroying evidentiary standing.

---

## 2. Constitutional Scope

This doctrine governs:

- the definition and classification of all evidence classes produced by Symphony
- the admissibility conditions applicable to each evidence class
- the provenance continuity requirements binding on the evidence lifecycle
- the replay obligations ensuring historical reconstruction without runtime trust
- the temporal validity rules governing evidence produced at specific phases
- the cross-jurisdiction portability standards for evidence presented to multiple
  regulator domains
- the historical reconstruction obligations that persist across key lifecycle
  events, phase transitions, and policy supersession events
- the prohibition on evidence-destructive operational practices

This doctrine does not govern:

- the internal implementation of runtime enforcement triggers
- the specific regulatory text of any applicable statutory framework
- the wire format of evidence transmission to external parties
- the internal key custody architecture
- the choice of archive storage vendor or technology
- the internal routing of payment instructions

---

## 3. Symphony as a Constitutional Evidentiary Admissibility System

Symphony's constitution treats every accepted, persisted, authoritative event
as an evidence-bearing object from the moment of acceptance. The evidentiary
identity of an accepted event cannot be revoked, expired, or administratively
withdrawn by any operational act performed after acceptance.

This doctrine expresses three foundational constitutional commitments:

**Commitment E-1 — Admissibility at Time of Execution:**
The evidentiary admissibility of an accepted event is determined by the
constitutional state of Symphony at the moment of acceptance, not by the
operational state at the moment of audit or verification. An event accepted
under a signing contract version, key, and canonicalization procedure in effect
at its `occurred_at` timestamp remains admissible under those parameters for the
full applicable retention period, regardless of subsequent changes to the signing
contract, the active key, or the canonicalization registry.

**Commitment E-2 — Evidence Permanence:**
No administrative act, key rotation, policy supersession, phase transition,
or operational optimization may retroactively destroy, invalidate, or render
inaccessible any accepted evidence artifact within its applicable retention
period, except as required by a lawful erasure obligation that has been
explicitly accommodated by the evidence architecture per the PII decoupling
design (ZDPA_COMPLIANCE_MAP.md, INV-107). Even in that case, the evidence
artifact's cryptographic binding to non-PII identifiers must remain verifiable.

**Commitment E-3 — Provenance Continuity:**
Every accepted evidence artifact must carry sufficient provenance material that
its origin, authority chain, and constitutional validity can be independently
established at any point within its retention period. Provenance continuity is
not satisfied by runtime availability of Symphony's signer resolution service.
It is satisfied by the persistent availability of the archive key store records,
the canonicalization registry entries, and the authority tuple fields sufficient
for independent verification per the External Verifier Independence Doctrine.

---

## 4. Evidence Classes

Symphony recognizes eight constitutionally distinct evidence classes. Each class
has distinct admissibility conditions, provenance obligations, and retention
semantics. These classes are not hierarchically ordered. They are
constitutionally orthogonal, and evidence from one class does not substitute for
evidence in another.

### 4.1 Operational Evidence

**Definition:** Records produced by the execution of payment instructions,
state transitions, and outbox dispatch operations, constituting the authoritative
account of what the system did during normal operation.

**Constitutional substrate:**
- `state_transitions` (append-only, migration 0137, BEFORE UPDATE/DELETE blocked)
- `payment_outbox_attempts` (append-only, migration 0001, trigger-enforced)
- `execution_records` (append-only after migration 0133, GF056 trigger)
- `state_current` (projection surface; not independently admissible — derived from
  `state_transitions` only)

**Admissibility conditions:**
- The record is admitted from `state_transitions` or `payment_outbox_attempts`
  directly; `state_current` is not independently admissible as evidence because
  it is a projection and does not carry its own authority tuple.
- For `state_transitions` records produced in Phase-1 or later under real
  cryptographic signing, all fields of the signed payload must be present and
  verifiable per ED25519_SIGNING_CONTRACT.md §11.
- For `state_transitions` records carrying the `PLACEHOLDER_PENDING_SIGNING_CONTRACT:`
  prefix (migration 0153), these records are Phase-boundary-delimited operational
  evidence with indicator-only evidentiary status. They are not cryptographically
  admissible as signed evidence.

**Retention obligation:** Full applicable regulatory retention period, not less
than 7 years per AUDIT_LOGGING_RETENTION_POLICY.md for regulated environments.

**Replay obligation:** Every `state_transitions` record must be replayable to its
acceptance or rejection outcome from persisted fields alone. The authority tuple
(`project_id`, `entity_type`, `entity_id`, `from_state`, `to_state`,
`execution_id`, `interpretation_version_id`, `policy_decision_id`,
`transition_hash`) must be reconstructible and its internal consistency
independently verifiable.

### 4.2 Provenance Evidence

**Definition:** Records that establish the authority lineage of an accepted
event: which execution record authorized it, which interpretation version bound
it, which policy decision governed it, and which signer attested to it.

**Constitutional substrate:**
- `execution_records` (migration 0118, FK-bound to `interpretation_packs`)
- `policy_decisions` (migration 0134, append-only GF061, decision_hash and
  signature CHECK constraints)
- `interpretation_packs` (migration 0116, FK reference from `execution_records`)
- `signing_authorization_matrix` (migration 0065, declarative — no runtime
  enforcement reader currently active)
- `wave8_signer_resolution` (migration 0176, active enforcement surface for
  asset_batches path)

**Admissibility conditions:**
- `execution_records` is admissible as provenance evidence for any transition
  that carries its `execution_id`.
- `policy_decisions` is admissible as provenance evidence for any transition
  that carries its `policy_decision_id`. The `decision_hash` must match
  `sha256(canonical_json(decision_payload))` and the `signature` must be a
  valid 64-byte hex-encoded Ed25519 signature over `decision_hash`.
- `signing_authorization_matrix` is currently declarative only (migration 0065);
  it is admissible as governance evidence of authorization intent but not as
  runtime-enforced provenance evidence until an enforcement reader is wired.

**Retention obligation:** Provenance evidence must be retained for the same
period as the operational evidence it provisions. The deletion of `execution_records`
or `policy_decisions` rows is unconstitutionally forbidden by their append-only
trigger enforcement (GF056, GF061) and by this doctrine independently.

**Replay obligation:** Provenance evidence must allow an external verifier to
trace any accepted transition through its full authority chain: from the
transition to its execution record, from the execution record to its
interpretation pack, and from the transition to its policy decision. This chain
must be traversable from persisted records without runtime service calls.

### 4.3 Regulator Evidence

**Definition:** Evidence specifically composed and formatted to satisfy the
admissibility standards of a specific regulatory domain. Regulator evidence is
domain-specific and is not universally transferable across regulator domains.

**Constitutional substrate:**
- Green Finance domain: `asset_batches` with Wave 8 attestation and cryptographic
  signing (migrations 0168–0190); `statutory_levy_registry` (migration 0123);
  `jurisdictional_regulations` and `jurisdictional_regulations_registrants`
  (migration 0126); `protected_areas` and `project_boundaries` with PostGIS
  geometry (migration 0126); DNSH enforcement log (GF057 trigger); K13 taxonomy
  alignment log (GF060 trigger)
- Payment settlement domain: `instruction_settlement_finality` (migration 0028);
  `finality_conflict_record` event class (EVIDENCE_EVENT_CLASSES.md)
- General regulatory: `evidence_packs` with signing columns (migration 0023,
  currently scaffolded)

**Admissibility conditions:**
- Regulator evidence is admissible only within the jurisdictional scope of the
  regulating authority for which it was composed.
- Green Finance regulator evidence requires the attestation gate to have passed
  (`validate_attestation_gate`, migration 0171) and, once the `wave8_crypto`
  extension is active, the cryptographic enforcement function to have produced a
  PASS outcome.
- Settlement finality evidence requires `is_final = TRUE` and the shape
  constraint (`pacs.008` for SETTLED, `camt.056` for REVERSED) to have been
  satisfied at the time of insertion.
- Evidence carrying the `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix is NOT
  admissible as regulator evidence for any domain that requires cryptographic
  signing.

**Regulator coexistence rule:** Green Finance regulator evidence and payment
settlement regulator evidence are orthogonal. A Green Finance regulator has no
jurisdiction over payment settlement evidence, and a payment settlement authority
has no jurisdiction over Green Finance taxonomy compliance evidence. No evidence
from one domain satisfies admissibility requirements in the other.

**Retention obligation:** Domain-specific. For Green Finance: applicable EU
taxonomy regulation retention periods. For payment settlement: applicable
settlement finality statute retention periods. When domain-specific statutes
require retention longer than the general 7-year default, the longer period
governs.

### 4.4 Replay Evidence

**Definition:** Records that are specifically produced to support independent
replay and historical verification of signed artifacts, including verification
run logs, archive snapshots, and Merkle proof structures.

**Constitutional substrate:**
- `historical_verification_runs` (migration 0065, `operational_store_excluded = true`
  default — archive-only verification posture; currently dormant)
- `archive_verification_runs` (migration 0066, `archive_only boolean NOT NULL
  DEFAULT true`, `key_versions_covered`, `canonicalization_versions_covered`;
  currently dormant)
- `proof_pack_batches` and `proof_pack_batch_leaves` (migration 0066, Merkle
  batch structure with `merkle_root`, `leaf_index`, `leaf_hash`, `merkle_proof`)
- `canonicalization_archive_snapshots` (migration 0066, immutable snapshots of
  canonicalization spec and test vectors)
- `anchor_backfill_jobs` (migration 0066, replay day tracking)

**Constitutional status of dormant substrate:** The dormant status of
`historical_verification_runs` and `archive_verification_runs` represents a
deferred activation, not an absent obligation. The obligation to preserve replay
capability exists at doctrine level from the moment the first signed artifact
is accepted. The schema reservations at migrations 0065 and 0066 constitute
constitutional reservations of this capability domain.

**Admissibility conditions:**
- A completed `archive_verification_runs` record with `outcome = 'PASS'` and
  `archive_only = true` is admissible as evidence that historical artifacts were
  independently verified against archive-only key material.
- `proof_pack_batch_leaves` records are admissible to prove membership of an
  artifact in a Merkle-anchored batch without requiring access to the full batch.
- `canonicalization_archive_snapshots` records are admissible to prove that the
  canonicalization procedure used at signing time was the procedure specified in
  the `canonicalization_registry` entry referenced by the artifact.

**Replay obligation:** Replay evidence records must themselves be append-only
and tamper-evident. A replay verification run that updates or deletes prior
verification run records is constitutionally invalid. Replay evidence
accumulates; it does not supersede.

### 4.5 Settlement Evidence

**Definition:** Records that establish the final, irrevocable outcome of a
payment instruction: whether it settled or was reversed, under which rail
message type, and with what lineage to any prior settled instruction.

**Constitutional substrate:**
- `instruction_settlement_finality` (migration 0028, `is_final = TRUE` enforced
  by CHECK constraint, BEFORE UPDATE/DELETE trigger P7003, shape constraint,
  self-reversal prohibition, one-reversal-per-original unique index)
- `payment_outbox_attempts` (migration 0001, append-only outbox ledger)
- `instruction_finality_conflicts` (migration 0062, FINALITY_CONFLICT state,
  HOLD_RELEASE containment action, `apply_finality_signals` SECURITY DEFINER
  function)
- `effect_seal_mismatch_events` (migration 0062, dispatch integrity evidence)

**Admissibility conditions:**
- `instruction_settlement_finality` rows are admissible as settlement evidence
  only when `is_final = TRUE` and the shape constraint has been satisfied at
  insertion time. Rows that were inserted with a later UPDATE to `is_final`
  cannot exist by constitutional enforcement; the trigger blocks updates to
  final rows.
- A `FINALITY_CONFLICT` record in `instruction_finality_conflicts` is admissible
  as evidence that a contradiction existed between rail responses and that
  HOLD_RELEASE containment was applied. It is not evidence of settlement outcome;
  it is evidence of a contested finality determination.
- `effect_seal_mismatch_events` are admissible as evidence that a dispatch
  integrity failure was detected and logged. Their existence constitutes evidence
  that the system did not silently pass a mismatched payload.

**Immutability guarantee:** Settlement evidence is constitutionally immutable
from insertion. The `deny_final_instruction_mutation` trigger (SQLSTATE P7003)
is an ABSOLUTE enforcement surface. No role, no session, and no administrative
act may mutate a final instruction record. This guarantee is not overridable by
any operational authority layer.

**Retention obligation:** Full applicable payment statute retention period, not
less than 7 years for regulated environments.

### 4.6 Methodological Evidence

**Definition:** Records that establish the methods, policies, and interpretation
frameworks under which operational decisions were made, enabling historical
reconstruction of why an event was accepted in addition to that it was accepted.

**Constitutional substrate:**
- `interpretation_packs` (migration 0116, FK from `execution_records`)
- `policy_versions` (migration 0005, foundational policy registry)
- `policy_bundles` (migration 0065, signed policy bundles with
  `activate_policy_bundle` enforcement)
- `state_rules` (migration 0135, entity-type-scoped state movement rules)
- `canonicalization_registry` (migration 0066, immutable canonicalization
  specifications with `immutable = true` flag)

**Admissibility conditions:**
- An `interpretation_packs` record is admissible as methodological evidence when
  it is referenced by an `execution_records` row whose `interpretation_version_id`
  was bound at the time of the execution. The temporal binding trigger
  (`enforce_execution_interpretation_temporal_binding`, GF058) ensures that the
  referenced interpretation pack was active at `execution_timestamp`.
- A `policy_bundles` record is admissible as methodological evidence when
  `state = 'active'`, `signature_valid = true`, and `activation_timestamp` is
  not null. Unsigned policy bundles are constitutionally inadmissible as
  methodological evidence (POLICY_BUNDLE_UNSIGNED, ERRCODE P8201).
- `canonicalization_registry` entries with `immutable = true` are admissible as
  evidence of the exact canonicalization procedure in effect at a given point in
  time. The `deprecated_at` field, when populated, bounds the window during which
  the procedure was in canonical use but does not render historical evidence
  produced under that version inadmissible.

**Replay-safe supersession rule:** When an interpretation pack, policy version,
or canonicalization procedure is superseded by a newer version, the superseded
version's methodological evidence remains fully admissible for all events that
referenced it. Supersession is forward-only: it governs new events; it does not
retroactively alter the methodological evidence record of past events.

### 4.7 Attestation Evidence

**Definition:** Records that establish the outcome of an invariant evaluation
or attestation gate, proving that a specific set of invariant conditions was
satisfied at the time of the attested operation.

**Constitutional substrate:**
- `invariant_registry` (migration 0163, append-only, `is_blocking` flag,
  `checksum` format enforced, `superseded_by` chain)
- `asset_batches.invariant_attestation_hash` (migration 0168, SHA-256 hex,
  freshness-constrained, anti-replay, `registry_snapshot_hash`)
- `validate_attestation_gate` trigger (migration 0171, live snapshot hash
  matching — reads blocking invariants from `invariant_registry` at INSERT time)
- `wave8_attestation_nonces` (migration 0183, nonce uniqueness for replay
  prevention on wave8 path)
- `adjustment_approval_event` and `verification_continuity_event` event classes
  (EVIDENCE_EVENT_CLASSES.md)

**Admissibility conditions:**
- An attestation record on `asset_batches` is admissible as attestation evidence
  when:
  1. `invariant_attestation_hash` is non-null and matches the expected hex format,
  2. `registry_snapshot_hash` matched the live `invariant_registry` snapshot at
     the time of INSERT (enforced by `validate_attestation_gate`),
  3. `invariant_attested_at` was within 300 seconds of the INSERT time (freshness
     gate, GF073/GF075),
  4. `attestation_nonce` was not previously used (anti-replay constraint
     `unique_attestation_hash`).
- An `invariant_registry` entry is admissible as attestation framework evidence
  when it carries a valid `checksum` and has not been superseded. Superseded
  entries remain admissible for the period during which they were the current
  non-superseded entry.

**Constitutional significance of registry_snapshot_hash:** The live snapshot hash
computed by `validate_attestation_gate` over the blocking invariants in
`invariant_registry` is the mechanism by which each attestation record is bound
to the specific invariant set in force at the moment of attestation. This binding
is constitutionally necessary: an attestation record that is not bound to a
specific invariant set is methodologically indeterminate and is not admissible
as attestation evidence.

**Replay obligation:** Because the `invariant_registry` is append-only and
supersession-preserved, the blocking invariant set at any historical moment can
be reconstructed by querying the registry for entries whose `created_at`
precedes the attested event and which had not been superseded at that time. This
reconstruction must yield the same `registry_snapshot_hash` as was computed at
attestation time.

### 4.8 Retention Evidence

**Definition:** Records that prove that evidence has been preserved, that
retention obligations have been fulfilled, and that archive systems have been
verified to be operative.

**Constitutional substrate:**
- `archive_verification_runs` (migration 0066, `archive_only = true`, outcome,
  `key_versions_covered`, `canonicalization_versions_covered`, `years_covered`)
- `canonicalization_archive_snapshots` (migration 0066, snapshot SHA-256,
  unique per version/hash pair)
- `key_rotation_drills` (migration 0065, `archival_confirmed` boolean,
  `rotation_type`, `old_key_deactivation_timestamp`, `new_key_activation_timestamp`)
- CI evidence artifacts (`evidence/phase0/`, `evidence/phase1/`, `evidence/phase2/`)
- `signing_audit_log` (migration 0065, dormant — currently no active writer)

**Admissibility conditions:**
- An `archive_verification_runs` record with `outcome = 'PASS'`, `archive_only = true`,
  and `years_covered >= 1` is admissible as retention evidence that archive key
  material covering the declared key versions was verified against historical
  artifacts over the declared period.
- A `key_rotation_drills` record with `archival_confirmed = true` is admissible
  as evidence that the key rotation event preserved archive-only verification
  capability for artifacts signed by the old key.
- CI evidence artifacts are admissible within the limits of their 30-day
  retention window (green_finance_contract_gate.yml). After that window expires,
  they are not independently available for external verification. This creates a
  retention gap: CI evidence artifacts must be copied to a durable store before
  expiry if they are to form part of the long-term retention evidence corpus.

**Retention gap declaration:** The `signing_audit_log` (migration 0065) is
currently dormant (no active writer in migration evidence). Until this table is
activated, there is no queryable, persistent, tamper-evident record at the
database layer of which signing operations were executed, under which keys, with
which outcomes. This gap does not affect the admissibility of evidence artifacts
produced through the signing path, but it does affect the completeness of the
retention evidence corpus. This gap is declared, not concealed.

---

## 5. Admissibility-at-Time-of-Execution

### 5.1 The Temporal Admissibility Rule

The admissibility conditions applicable to any evidence artifact are the
conditions that were in constitutional force at the artifact's `occurred_at`
timestamp or, for artifacts without an `occurred_at` field, at their `created_at`
timestamp. Future changes to signing contracts, key classes, canonicalization
procedures, or invariant sets do not retroactively alter the admissibility
determination for historical artifacts.

This rule is the constitutional expression of Commitment E-1. Its operational
consequence is that a version-1 signed transition artifact is admissible as a
signed evidence artifact forever, even after the signing contract advances to
version 2, because its admissibility is determined by version 1's conditions,
which it satisfied at the time of acceptance.

### 5.2 Phase Boundary Admissibility

Phase boundaries constitute constitutional capability thresholds. Evidence
produced before a phase transition carries the admissibility classification
appropriate to the phase in which it was produced.

**Phase-1 indicative evidence:** Evidence from records with
`data_authority = 'phase1_indicative_only'` (migration 0121) carries
indicator-only evidentiary status. It is admissible to prove what was recorded
but not to prove cryptographic authority over what was recorded. The
`audit_grade = false` constraint enforced by `enforce_phase1_boundary` (migration
0169, GF072) makes this evidentiary limitation machine-readable.

**Signed evidence:** Evidence from records with `data_authority = 'authoritative_signed'`
carries full cryptographic admissibility status, subject to the signing contract
conditions in effect at the time of signing.

**The data_authority transition machine:** The `data_authority_level` enum
(migration 0121) defines a seven-state authority progression:
`phase1_indicative_only` → `derived_unverified` → `policy_bound_unsigned` →
`authoritative_signed`, with terminal states `superseded` and `invalidated`.
The transition machine enforced by `enforce_monitoring_authority` and
`enforce_asset_batch_authority` triggers (migration 0122, GF037) is
constitutionally unidirectional: authority may be upgraded but not downgraded
except to `superseded` or `invalidated`.

The `invalidated` terminal state is constitutionally significant: it is the
state into which evidence transitions when a determination has been made that
it cannot be relied upon. An `invalidated` record is not deleted — the
append-only constraints prevent deletion — but it is no longer admissible as
positive evidence of the event it records. It is admissible as evidence that
the record was invalidated and when.

### 5.3 Placeholder-Prefixed Evidence Classification

Evidence artifacts whose `transition_hash` carries the
`PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix (migration 0153) are classified
as Phase-transition-delimited operational evidence. They are admissible to prove
that the system accepted a state transition at the recorded time, but they are
not admissible as cryptographically signed evidence because no cryptographic
operation was performed. Any presentation of placeholder-prefixed evidence to
a regulator as signed evidence is constitutionally prohibited.

---

## 6. Historical Proof-of-State

### 6.1 Definition

Historical proof-of-state is the evidentiary capability to establish, at any
point within an applicable retention period, what the authoritative state of any
entity was at any historical moment, tracing that determination to the sequence
of accepted state transitions that produced it.

### 6.2 Constitutional Mechanism

Historical proof-of-state is grounded in the append-only architecture of
`state_transitions`. Because no row in `state_transitions` may be updated or
deleted after acceptance (BEFORE UPDATE/DELETE trigger, ABSOLUTE enforcement),
the full sequence of state transitions for any entity is permanently retrievable
from the table ordered by `occurred_at` and `transition_id`.

`state_current` is explicitly excluded from historical proof-of-state evidence:
it is a mutable projection surface that reflects the latest accepted transition
only. It is admissible as a convenience query surface but not as independent
evidence of historical state.

### 6.3 Replay Determinism Requirement

Historical proof-of-state requires that replaying the `state_transitions` sequence
for an entity from any historical starting point produces the same sequence of
state values as was produced during original execution. This determinism is
guaranteed by the trigger ordering contract (migration 0149, `bi_01_` through
`bi_06_` prefix ordering) and by the state rule enforcement that uses
`state_rules` as an authoritative lookup rather than embedded logic.

### 6.4 Cross-Entity Replay Isolation

Historical proof-of-state for one entity is constitutionally isolated from
that for another. The `enforce_policy_decisions_entity_coherence` trigger (GF062)
ensures that policy decisions bound to one entity cannot be applied to another.
This isolation guarantee means that replaying an entity's state history does not
depend on the state of any other entity's records.

---

## 7. Evidence Permanence Guarantees

The following guarantees are constitutionally binding. No operational act,
administrative decision, or runtime configuration change may override them.

**EPG-1 — Append-Only State Transitions:**
`state_transitions` rows are permanently immutable from insertion. The
`deny_state_transitions_mutation` trigger (ABSOLUTE enforcement, BEFORE
UPDATE/DELETE) is constitutionally non-bypassable for any role that does not
possess a PostgreSQL superuser bypass. Administrative operations that require
superuser access to mutate this table are constitutionally prohibited regardless
of technical feasibility.

**EPG-2 — Append-Only Settlement Finality:**
`instruction_settlement_finality` rows with `is_final = TRUE` are permanently
immutable. The `deny_final_instruction_mutation` trigger (SQLSTATE P7003) is
an ABSOLUTE enforcement surface.

**EPG-3 — Append-Only Execution Records:**
`execution_records` rows are permanently immutable after the append-only trigger
(GF056) is active. Deletion of execution records is constitutionally forbidden.

**EPG-4 — Append-Only Policy Decisions:**
`policy_decisions` rows are permanently immutable (GF061). Deletion of policy
decisions is constitutionally forbidden.

**EPG-5 — Append-Only Revocation Records:**
`revoked_client_certs` and `revoked_tokens` rows are permanently immutable
(migration 0012, ERRCODE P0001). A revocation act cannot be undone by deleting
the revocation record; it can only be superseded by a subsequent restoration
decision recorded as a separate event.

**EPG-6 — Append-Only Invariant Registry:**
`invariant_registry` rows are permanently immutable (migration 0163). Invariants
may be superseded by reference (via `superseded_by` FK) but never deleted.

**EPG-7 — Canonicalization Version Permanence:**
`canonicalization_registry` entries with `immutable = true` may never be deleted
(ON DELETE RESTRICT FK from `canonicalization_archive_snapshots`). Their
`spec_json` and `test_vectors` are the permanent specification for the
canonicalization procedure identified by that version string. The `deprecated_at`
field records the date on which the procedure was retired for new use but does
not authorize deletion or modification of the specification.

---

## 8. Replay-Safe Supersession

### 8.1 Definition

Replay-safe supersession is the property by which a new version of a policy,
interpretation pack, canonicalization procedure, key, or invariant may supersede
the prior version for new events without invalidating the evidentiary standing of
historical events that were governed by the prior version.

### 8.2 Supersession Semantics by Evidence Class

**Key supersession (wave8_signer_resolution):** When a signing key is superseded
via `wave8_signer_resolution.superseded_by`, the superseded key is rejected for
new signing operations (P7813, migration 0179). However, the archive key store
record for the superseded key must be preserved, and all artifacts signed by
that key while it was active remain verifiable against its archived public key.
Supersession in the live signer resolution surface does not affect archive-side
verification.

**Interpretation pack supersession:** When a new interpretation pack version is
activated, prior pack versions referenced by `execution_records` remain fully
admissible as methodological evidence. The temporal binding trigger (GF058)
ensures that `execution_records` rows are bound to the pack version that was
active at `execution_timestamp`, not the version current at verification time.

**Canonicalization version supersession:** When a new `canonicalization_version`
is added to `canonicalization_registry`, prior versions are deprecated via
`deprecated_at` but their `spec_json` and `test_vectors` remain permanently
accessible. Evidence produced under the deprecated version remains admissible
under its original canonicalization contract.

**Policy bundle supersession:** When a new policy bundle version is activated,
prior policy decisions that reference prior bundle versions remain admissible
as provenance evidence. The `policy_bundle_state_enum` transition from `active`
to `inactive` (migration 0072) does not alter the admissibility of policy
decisions made while the bundle was active.

**Invariant supersession:** When an invariant is superseded in `invariant_registry`
via the `superseded_by` FK chain, attestation records that were produced against
the superseded invariant set remain admissible for the period in which they were
produced. The live snapshot hash computed by `validate_attestation_gate` reflects
the blocking invariant set at insertion time; that hash is the durable binding
of the attestation to the specific invariant framework in force at attestation time.

### 8.3 The Non-Retroactivity Rule

Supersession events are forward-only constitutional acts. They govern the
treatment of new events from the supersession date. They do not retroactively
alter:

- the authority tuple of any accepted transition,
- the methodological evidence applicable to any accepted execution record,
- the admissibility classification of any evidence artifact accepted under the
  prior version, or
- the archival obligations applicable to any evidence produced under the prior
  version.

Any interpretation that treats a supersession event as retroactively invalidating
prior evidence is constitutionally prohibited.

---

## 9. Provenance Continuity Requirements

### 9.1 The Provenance Chain

For every accepted `state_transitions` record, the following provenance chain
must be traversable from persisted records:

```
state_transitions.transition_id
  → state_transitions.execution_id → execution_records.execution_id
      → execution_records.interpretation_version_id → interpretation_packs
  → state_transitions.policy_decision_id → policy_decisions.policy_decision_id
      → policy_decisions.execution_id (must equal state_transitions.execution_id)
      → policy_decisions.entity_type/entity_id (must match transition)
  → state_transitions.transition_hash (verifiable from authority tuple fields)
  → state_transitions.signature (verifiable against archived public key)
  → state_transitions.data_authority (verifiable from DATA_AUTHORITY_DERIVATION_SPEC.md)
```

### 9.2 Provenance Completeness Obligation

No accepted transition may exist in `state_transitions` whose provenance chain
is incomplete. The FK constraints added in migration 0147 (execution_id and
policy_decision_id FKs with SQLSTATE 23503 on violation) are the primary
enforcement surface for provenance completeness.

An evidence artifact whose provenance chain cannot be fully traversed from
persisted records is constitutionally inadmissible as provenance evidence,
regardless of its runtime origin.

### 9.3 PII Decoupling and Provenance Continuity

Where PII erasure obligations apply (ZDPA_COMPLIANCE_MAP.md, INV-107), the PII
decoupling architecture must ensure that erasure of raw PII does not break the
provenance chain. The architecture achieves this by binding evidence artifacts
to `identity_hash` (a non-PII derived identifier) rather than to raw PII fields.
After PII erasure, the provenance chain from transition to execution to policy
to signer remains intact through the non-PII identifiers. The erased PII fields
are outside the signed payload and outside the provenance chain.

This is a constitutional design requirement: any evidence schema that places
PII fields inside the signed payload creates an irresolvable conflict between
PII erasure obligations and evidence permanence guarantees. Such schema designs
are constitutionally prohibited.

---

## 10. Regulator-Grade Audit Survivability

### 10.1 Definition

Regulator-grade audit survivability is the property that Symphony's complete
evidence corpus for any regulatory domain remains fully auditable by the
applicable regulatory authority for the full applicable retention period,
including through:

- complete key rotation cycles,
- complete phase transitions,
- loss of the operational runtime,
- loss of the signer resolution service,
- migration of evidence to archive storage, and
- activation of PII erasure procedures.

### 10.2 Survivability Matrix

| Survival Event | Evidence Classes Affected | Survivability Mechanism | Constitutional Status |
|---|---|---|---|
| Key rotation | Operational, Provenance, Settlement, Regulator | Archive key store retention (KEY_MANAGEMENT_POLICY.md) + `key_rotation_drills.archival_confirmed` | Obligatory |
| Key revocation for compromise | Operational, Provenance | Historical key lifecycle independence (External Verifier Independence Doctrine §4.3) — pre-revocation artifacts remain verifiable | Obligatory |
| Phase transition (Phase-1 → Phase-2) | All classes | Admissibility-at-time-of-execution rule (§5.1) — phase-1 evidence retains its phase-1 admissibility classification | Absolute |
| Loss of operational runtime | All classes | Offline verification procedure (External Verifier Independence Doctrine §5.3) — no runtime dependency | Obligatory |
| Canonicalization version deprecation | All signed evidence | `canonicalization_registry` permanence (EPG-7) + `canonicalization_archive_snapshots` | Obligatory |
| PII erasure | Operational, Provenance | PII decoupling to `identity_hash` (ZDPA INV-107) — signed payload excludes raw PII | Design obligation |
| Signing contract version upgrade | Operational, Settlement, Regulator | Version-scoped admissibility — v1 artifacts remain admissible under v1 conditions permanently | Absolute |
| Invariant set supersession | Attestation | `registry_snapshot_hash` binding — attestation bound to invariant set at attestation time | Enforced |
| CI artifact expiry (30 days) | Retention | Durable store copy obligation — CI artifacts must be promoted to durable retention before expiry | Gap (declared) |

### 10.3 The CI Artifact Retention Gap

CI evidence artifacts (30-day retention per green_finance_contract_gate.yml)
are not durably retained at the database layer. This is a declared constitutional
gap. It does not affect the admissibility of database-layer evidence but it does
affect the completeness of the retention evidence corpus for the CI gate
verification record. This gap requires resolution before the platform claims
regulator-grade audit survivability for its CI evidence layer.

---

## 11. Cryptographic Lineage

### 11.1 Definition

Cryptographic lineage is the chain of cryptographic commitments connecting an
accepted evidence artifact to its authority inputs. For a signed state transition,
the cryptographic lineage is:

```
authority tuple fields
  → SHA-256(JCS(authority_tuple)) = transition_hash
  → Ed25519_sign(JCS({...transition_hash...})) = signature
  → SHA-256(JCS({...signature_verification_result...})) = data_authority
```

Each step in this chain is deterministic, independently reproducible, and
constitutionally binding. The chain cannot be partially verified: all steps must
succeed for the artifact to carry full cryptographic lineage.

### 11.2 Lineage Completeness by Artifact Class

**INDIVIDUAL_SIGNED artifacts** (ARTIFACT_CLASS_TAXONOMY.md): Carry a complete
cryptographic lineage from authority tuple through signature to `data_authority`.
Each artifact is independently verifiable.

**BATCH_MERKLE_SIGNED artifacts** (ARTIFACT_CLASS_TAXONOMY.md): Carry a Merkle
lineage from individual leaf hashes through `merkle_root` to the batch signature.
The `merkle_proof` for each leaf enables membership verification without access
to the full batch. The batch signature provides a single cryptographic commitment
over all leaves.

### 11.3 Key Class Authority Lineage

The `key_class_enum` values (EASK, PCSK, AAK, TRANSPORT_IDENTITY, migration 0065)
define the authority domain of each key class. The cryptographic lineage of an
evidence artifact carries the key class of the signing key, which determines
which authority domain the signature attests to. An EASK signature attests to
evidence artifact signing authority. A PCSK signature attests to policy contract
authority. These are constitutionally distinct attestations and are not
substitutable.

---

## 12. Temporal Evidence Validity

### 12.1 The Occurred_At Invariant

The `occurred_at` timestamp is the constitutional temporal anchor of a signed
evidence artifact. It MUST:

- be persisted on the authoritative record before signature payload construction
  begins (ED25519_SIGNING_CONTRACT.md §6),
- be used verbatim in the signed payload during original signing,
- be replayed verbatim from its persisted value during verification,
- never be regenerated at verification time, and
- never be mutated after its initial persistence.

Violation of any of these requirements invalidates the temporal validity of the
artifact. A signature over a regenerated `occurred_at` is constitutionally
invalid even if the regenerated timestamp is numerically close to the original.

### 12.2 Attestation Freshness Window

Attestation evidence (§4.7) carries an additional temporal constraint: the
`invariant_attested_at` timestamp must be within 300 seconds of the INSERT time
at the time of INSERT (GF073, GF075). This freshness window is a constitutional
gate on attestation admissibility — it prevents stale attestation tokens from
being presented as evidence of current invariant compliance.

The freshness window is enforced at INSERT time and does not retroactively
invalidate attestation evidence after acceptance. An attestation record that
passes the freshness gate at INSERT time is permanently admissible as
attestation evidence regardless of subsequent time passage.

### 12.3 Key Validity Window Temporal Binding

A signed artifact is temporally valid only if the signing key was within its
declared validity window (`valid_from` to `valid_until`) at the artifact's
`occurred_at` timestamp. This temporal binding is enforced at signing time by
the wave8 key lifecycle enforcement (migration 0179, P7813 for expired keys).
For historical verification, the archived key validity window is used to
establish temporal validity per the External Verifier Independence Doctrine §4.3.

---

## 13. Cross-Jurisdiction Evidence Portability

### 13.1 Portability Foundation

Evidence portability across jurisdictions rests on three constitutional properties:

1. **Algorithm universality:** Ed25519 (RFC 8032) is a published, royalty-free,
   independently implementable standard. No jurisdiction-specific cryptographic
   library is required for verification.

2. **Canonicalization universality:** RFC 8785 (JCS) is a published IETF standard
   for JSON canonicalization. No vendor-specific serializer is required for
   payload reconstruction.

3. **Artifact self-containment:** Every signed artifact carries its own algorithm
   identifier, canonicalization version, signing contract version, key identifier,
   and key version. A verifier in any jurisdiction can determine the complete
   verification procedure from the artifact itself.

### 13.2 Jurisdiction-Specific Admissibility

Portability guarantees technical verifiability across jurisdictions. It does not
guarantee legal admissibility. Each jurisdiction's courts, regulatory bodies,
and evidentiary standards determine what constitutes legally admissible evidence.

The constitutional obligation of Symphony is to ensure that technical
verifiability is achievable in all jurisdictions. The legal admissibility
determination is outside Symphony's constitutional scope.

### 13.3 Regulator Domain Non-Transference

Evidence admissible before the Green Finance regulatory authority does not become
admissible before the payment settlement authority by virtue of being technically
verifiable. Admissibility is domain-scoped. Technical verifiability is universal.
These are distinct properties that must not be conflated.

---

## 14. Historical Reconstruction Obligations

### 14.1 Definition

Historical reconstruction is the act of re-deriving the complete evidentiary
record of a past event — its acceptance, authority, provenance, and cryptographic
validity — from persisted artifacts, without reliance on runtime system state.

### 14.2 Reconstruction Flow: State Transition

Given a `state_transitions.transition_id`, historical reconstruction proceeds:

1. Retrieve the `state_transitions` row from the append-only table.
2. Verify the `transition_hash` by reconstructing it from the authority tuple
   fields per TRANSITION_HASH_CONTRACT.md §8.
3. Reconstruct the signed payload per ED25519_SIGNING_CONTRACT.md §5–§7.
4. Retrieve the public key from the archive key store using `key_id` and
   `key_version`.
5. Assert key was active at `occurred_at` using archived validity window.
6. Verify the Ed25519 signature over the canonical payload.
7. Recompute `data_authority` per DATA_AUTHORITY_DERIVATION_SPEC.md §6.
8. Assert `data_authority` matches the persisted value.
9. Traverse the provenance chain: resolve `execution_records` and
   `policy_decisions` from their FK references.
10. Verify entity coherence: `policy_decisions.entity_type/entity_id` must
    match `execution_records.entity_type/entity_id` (GF062).
11. Resolve the `interpretation_packs` record and verify it was active at
    `execution_records.execution_timestamp` (temporal binding GF058).

Successful completion of all eleven steps constitutes complete historical
reconstruction of the transition's evidentiary record.

### 14.3 Reconstruction Flow: Asset Batch (Wave 8)

Given an `asset_batches` record:

1. Retrieve the `asset_batches` row.
2. Verify `invariant_attestation_hash` against the reconstructed blocking
   invariant set from `invariant_registry` at the attested date.
3. Verify `registry_snapshot_hash` against the same reconstructed snapshot.
4. Retrieve the public key from the archive key store using `signer_key_id`
   and `signer_key_version`.
5. Assert key was active at the batch's `occurred_at` equivalent.
6. Verify the Ed25519 signature over `canonical_payload_bytes`.

### 14.4 Reconstruction Flow: Settlement Finality

Given an `instruction_settlement_finality.instruction_id`:

1. Retrieve the `instruction_settlement_finality` row.
2. Assert `is_final = TRUE` (CHECK constraint ensures this is immutable).
3. Assert shape constraint: `pacs.008` for SETTLED, `camt.056` for REVERSED.
4. If `final_state = 'REVERSED'`, traverse `reversal_of_instruction_id` to
   the original settled instruction and assert it was SETTLED and final.
5. Retrieve the corresponding `payment_outbox_attempts` rows for the
   complete dispatch history.

### 14.5 Reconstruction Failure Protocol

If any step in a reconstruction flow fails, the failure MUST be classified using
the failure classes defined in §4 (Evidence Classes) and the signing contract
failure classes. Reconstruction failure is not admissible as evidence of event
invalidity unless the failure class is specifically `SIGNATURE_VERIFICATION_FAILED`,
`DATA_AUTHORITY_MISMATCH`, or `TRANSITION_HASH_MISMATCH`. All other failure
classes indicate an incomplete evidence corpus, not an invalid event.

---

## 15. Admissibility Matrix

| Evidence Class | Admissible for Cryptographic Proof | Admissible for State Proof | Admissible for Authority Proof | Admissible before Green Finance Regulator | Admissible before Payment Regulator | Admissible Across Jurisdictions (Technical) |
|---|---|---|---|---|---|---|
| Operational (signed) | ✓ | ✓ | ✓ | ✓ (wave8 path) | ✓ | ✓ |
| Operational (placeholder) | ✗ | ✓ (indicator only) | ✗ | ✗ | ✗ | N/A |
| Provenance | ✗ (indirect) | ✗ | ✓ | ✓ | ✓ | ✓ |
| Regulator (GF domain) | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ (technical) |
| Regulator (settlement domain) | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ (technical) |
| Replay | ✗ (meta) | ✗ | ✗ | ✓ (for verification runs) | ✓ (for verification runs) | ✓ |
| Settlement finality | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ |
| Methodological | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ |
| Attestation (wave8 gate passed) | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ |
| Attestation (gate not yet passed) | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Retention | ✗ (meta) | ✗ | ✗ | ✓ | ✓ | ✓ |

---

## 16. Constitutional Self-Validation

**Sovereignty domains governed by this doctrine:**
- Evidentiary admissibility sovereignty over all evidence classes produced by
  Symphony
- Provenance continuity sovereignty over the authority chains of all accepted
  events
- Temporal admissibility sovereignty over the classification of evidence by
  phase and time of execution
- Historical reconstruction sovereignty over the obligations binding on all
  evidence-bearing surfaces

**Sovereignty domains this doctrine MUST NOT redefine:**
- External verifier sovereignty (governed by EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md)
- Key custody architecture (governed by KEY_MANAGEMENT_POLICY.md)
- Runtime trigger ordering (governed by DATA_AUTHORITY_SYSTEM_DESIGN.md §10)
- Internal RLS and role privilege model (governed by migration sequence)
- Wave-by-wave delivery scheduling (governed by task planning documents)

**Replay obligations preserved by this doctrine:**
- Every signed evidence artifact must be replayable to its original verification
  outcome from persisted artifacts alone (Commitment E-3)
- Replay evidence accumulates; it does not supersede (§4.4 Replay Evidence)
- Historical reconstruction must be achievable without runtime service dependency
  (§14 Historical Reconstruction Obligations)
- Supersession events are forward-only and do not retroactively invalidate
  replay capability for prior artifacts (§8.3 Non-Retroactivity Rule)

**Regulator boundaries that constrain this doctrine:**
- Green Finance regulatory domain: EU taxonomy regulation retention and
  admissibility standards; evidence from `asset_batches` Wave 8 boundary
- Payment settlement domain: applicable settlement finality statutes; evidence
  from `instruction_settlement_finality`
- ZDPA / data protection domain: PII erasure obligations constrain the design
  of signed payload schemas (§9.3)
- These domains are orthogonal; this doctrine governs all of them without
  collapsing their boundaries

**Phases to which this doctrine applies:**
- GLOBAL — all phases; temporal admissibility rules apply phase-specific
  classifications to evidence produced in each phase

**Constitutional layers with override authority over this doctrine:**
- No lower-authority surface may override this doctrine
- A future ROOT-authority constitutional amendment may supersede this doctrine
  only if it preserves or strengthens the evidence permanence guarantees
  EPG-1 through EPG-7 and the admissibility continuity obligations
- No PHASE, REGULATORY, or ENFORCEMENT authority layer may override this doctrine

**Lower-layer documents prohibited from reinterpretation:**
- DATA_AUTHORITY_DERIVATION_SPEC.md may not be reinterpreted to permit
  `non_reproducible` placeholders as admissible evidence
- ED25519_SIGNING_CONTRACT.md may not be reinterpreted to permit `occurred_at`
  regeneration
- TRANSITION_HASH_CONTRACT.md may not be reinterpreted to include mutable
  fields in the hash input
- AUDIT_LOGGING_RETENTION_POLICY.md may not be reinterpreted to reduce the
  7-year default retention target for regulated environments
- Migration 0028 (settlement finality) may not be reinterpreted to permit
  mutation of final instruction records

---

## 17. Prohibited Misinterpretations

**PM-1 — Evidence as Auxiliary Metadata (PROHIBITED)**
It is prohibited to treat evidence artifacts as secondary application logs or
debugging metadata. Evidence is constitutional state-bearing substrate. Every
accepted evidence artifact carries constitutional obligations from the moment of
its acceptance that survive the operational lifetime of the system that produced
it.

**PM-2 — Runtime-Only Evidence Trust (PROHIBITED)**
It is prohibited to architect any system under the assumption that evidence
validity is determined by whether Symphony's runtime is operational at the time
of verification. Evidence validity is determined by the cryptographic and
provenance properties of the artifact itself. Runtime availability is irrelevant
to evidentiary admissibility.

**PM-3 — Replay-Destructive Optimization (PROHIBITED)**
It is prohibited to optimize any evidence schema, migration, or data lifecycle
policy in a manner that prevents historical replay. Specifically:
- compaction or archival operations that destroy the `transition_hash` preimage
  fields are prohibited,
- deletion of `execution_records` or `policy_decisions` rows to reclaim storage
  is prohibited,
- modification of `occurred_at` for any reason is prohibited,
- deletion of `canonicalization_registry` entries for any reason is prohibited.

**PM-4 — Provenance-Detached Operational State (PROHIBITED)**
It is prohibited to accept any state transition into `state_transitions` whose
provenance chain is incomplete. The FK constraints on `execution_id` and
`policy_decision_id` (migration 0147) are the enforcement surface of this
prohibition. Circumventing these constraints by any technical means is
constitutionally prohibited regardless of operational justification.

**PM-5 — Historical Evidence Invalidation by Future Policy (PROHIBITED)**
It is prohibited to treat the supersession, deprecation, or replacement of any
policy version, interpretation pack, signing contract version, or canonicalization
procedure as retroactively invalidating evidence produced under the prior version.
Supersession is forward-only. Historical evidence produced under the prior version
retains its admissibility classification.

**PM-6 — Phase-Boundary Admissibility Collapse (PROHIBITED)**
It is prohibited to treat Phase-1 indicative evidence as equivalent to Phase-2
signed evidence, or to treat placeholder-prefixed transition hashes as
cryptographically signed artifacts. The `data_authority_level` enum and the
`audit_grade` boolean are the machine-readable embodiment of phase admissibility
classification. These classifications may not be collapsed.

**PM-7 — Regulator Domain Transference (PROHIBITED)**
It is prohibited to present Green Finance domain evidence to a payment settlement
regulator, or payment settlement domain evidence to a Green Finance regulator,
as evidence of compliance within the other regulator's domain. Regulatory domains
are orthogonal sovereign jurisdictions. Evidence admissibility is domain-scoped.

**PM-8 — Invalidation as Deletion (PROHIBITED)**
It is prohibited to treat the `invalidated` state in `data_authority_level` as
equivalent to deletion or absence of evidence. An invalidated record is admissible
evidence that the record was invalidated and when. It remains in the append-only
table permanently and is a constitutional record of the invalidation act.

**PM-9 — Dormant Substrate as Absent Obligation (PROHIBITED)**
It is prohibited to interpret the dormant status of `signing_audit_log`,
`historical_verification_runs`, `archive_verification_runs`, or `evidence_packs`
signing columns as evidence that the corresponding evidentiary obligations do not
exist. These substrates are deferred activation reservations for obligations
that exist at doctrine level from Phase-0 forward.

**PM-10 — Single-Regulator Evidence Design (PROHIBITED)**
It is prohibited to design evidence artifacts under the assumption that they will
be presented to only one regulatory domain. Evidence artifacts must preserve
cross-jurisdiction technical verifiability even when their admissibility is
domain-specific.
