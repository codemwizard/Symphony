# CONSTITUTIONAL_GLOSSARY.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 10
Phase-Scope: GLOBAL
Supersedes: all informal terminology conventions, all undeclared semantic usages applied to Symphony concepts
Depends-On: NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md, SYMPHONY_CANONICAL_CAPABILITY_AND_ENFORCEMENT_REPORT.md
```

---

## Purpose

This document establishes the canonical constitutional meanings of all major Symphony concepts. Definitions contained herein are not descriptive glosses of conventional software terms as applied to Symphony. They are constitutional definitions: authoritative, precise, sovereignty-preserving, and binding on all downstream documents, analytical outputs, agent reasoning, and NotebookLM retrieval synthesis.

Where a term has a conventional software or legal meaning that differs from its Symphony constitutional meaning, the Symphony constitutional meaning governs without qualification. The conventional meaning is explicitly excluded where necessary to prevent semantic drift.

No document, agent, or analytical process operating within Symphony's constitutional framework may assign meanings to these terms that contradict the definitions contained herein.

---

## Constitutional Scope

This document governs the semantic meaning of foundational Symphony concepts across all phases, all sovereignty planes, all regulatory jurisdictions, and all evidentiary contexts. It is the semantic root from which all constitutional doctrine, enforcement logic, and analytical framing derives its terminological precision.

Definitions in this document DO NOT govern: the specific technical implementation of any mechanism (governed by source migrations and the Canonical Capability Report), the specific content of any jurisdiction interpretation pack (governed by regulator-partitioned instruments), or the specific invariant assignments (governed by INVARIANTS_MANIFEST.yml).

---

## Definitions

---

### Sovereignty

**Constitutional Definition:**
In Symphony, sovereignty denotes the condition of a trust domain, authority plane, or enforcement layer that: (a) governs a constitutionally distinct set of questions, (b) derives its authority from a source that is not subordinate to any other Symphony trust domain, and (c) cannot have its findings overridden by another domain without an explicitly defined cross-domain arbitration protocol.

Sovereignty in Symphony is **plural and orthogonal**. Multiple sovereignty domains coexist simultaneously over the same substrate, each sovereign within its own plane. No single domain is universally supreme.

**What sovereignty is NOT in Symphony:**
Sovereignty is not administrative control over a system. It is not the right of a party to modify data. It is not determined by which layer executes last in a processing chain. It is not determined by which layer was implemented first.

**Constitutional implication:**
When two sovereignty domains produce findings about the same artifact, neither finding is automatically subordinate. The constitutionally correct response is to identify which plane each finding governs and apply each within its plane.

**Substrate references:** `data_authority_level` enforcement (Wave 4 operational sovereignty); `wave8_cryptographic_enforcement` (Wave 8 provenance sovereignty); `rls_jurisdiction_isolation_interpretation_packs` (regulatory sovereignty).

---

### Authority

**Constitutional Definition:**
In Symphony, authority denotes the constitutionally assigned power of a specific mechanism, declaration, or institution to produce findings that are binding within a defined sovereignty plane and for a defined class of constitutional questions.

Authority is **plane-specific and question-specific**. A mechanism possesses authority over the constitutional questions within its plane. It does not possess authority over constitutional questions in other planes, even when those questions arise from the same data object.

**Authority is not universal.** No single mechanism, table, function, or actor in Symphony possesses authority over all constitutional questions simultaneously.

**Authority is not hierarchical by default.** Two authority mechanisms in different planes are coequal within their respective planes. Neither is senior to the other. A hierarchy between planes exists only when an explicit cross-plane arbitration protocol defines one.

**Types of authority in Symphony:**
- *Decision authority:* The power to produce a cryptographically attested governance decision (`policy_decisions`).
- *Transition authority:* The power to determine which state transitions are constitutionally permissible (`state_rules`, `enforce_authority_transition_binding()`).
- *Interpretive authority:* The power to define the active regulatory interpretation rules for a project within a jurisdiction (`resolve_interpretation_pack()`).
- *Signer authority:* The power to cryptographically attest to the origin of an evidentiary artifact (`resolve_authoritative_signer()`).
- *Phase authority:* The power to declare that a given capability is constitutionally permissible within a phase (phase lifecycle constitutional documents).

---

### Operational Sovereignty

**Constitutional Definition:**
Operational sovereignty is the sovereignty domain governing the correctness, integrity, and legality of Symphony's runtime execution state. It answers the constitutional question: *Is this operational event — transaction, state transition, evidence record, asset batch — constitutionally valid at the time it occurs?*

Operational sovereignty is embodied in **Wave 4** mechanisms. Its primary enforcement surfaces are: `data_authority_level` transition enforcement, `enforce_phase1_boundary()`, `state_rules` permissibility gating, `enforce_confidence_before_issuance()`, `verify_internal_ledger_journal_balance()`, and all DB-layer trigger chains governing runtime state.

**What operational sovereignty governs:**
- Whether a state transition is permitted.
- Whether evidence meets the required authority threshold for an operational action.
- Whether a ledger entry is balanced.
- Whether a phase boundary constraint is observed.
- Whether an issuance event is authorized by the required confidence threshold and governance decisions.

**What operational sovereignty does NOT govern:**
- Whether an artifact's cryptographic origin is authentic (governed by provenance sovereignty).
- Whether a historical artifact remains admissible under a changed regulatory framework (governed by historical admissibility continuity doctrine).
- Whether an artifact satisfies the requirements of a specific regulatory jurisdiction (governed by regulatory sovereignty).

**Substrate references:** `0121`, `0122`, `0113`, `0135`, `0136`, `0137`–`0154`, `0169`.

---

### Provenance Sovereignty

**Constitutional Definition:**
Provenance sovereignty is the sovereignty domain governing the cryptographic authenticity, origin integrity, and non-repudiation of evidentiary artifacts produced within Symphony. It answers the constitutional question: *Can the origin of this artifact be cryptographically verified as having been produced by an authorized signer with an authorized key at the declared time?*

Provenance sovereignty is embodied in **Wave 8** mechanisms. Its primary enforcement surfaces are: `wave8_cryptographic_enforcement()`, `resolve_authoritative_signer()`, `public_keys_registry`, `ed25519_verify()`, canonical payload binding, timestamp integrity enforcement, and context binding enforcement.

**What provenance sovereignty governs:**
- Whether a signature on an artifact is cryptographically valid.
- Whether the signing key was authorized at the time of signing.
- Whether the canonical payload matches the persisted artifact fields.
- Whether the claimed timestamp is consistent with the canonical payload.

**What provenance sovereignty does NOT govern:**
- Whether an operationally valid state transition was made (governed by operational sovereignty).
- Whether a regulatory jurisdiction accepts the artifact as admissible (governed by regulatory sovereignty).
- Whether the artifact satisfies confidence thresholds for issuance (governed by operational sovereignty).

**Coexistence doctrine:**
Operational sovereignty and provenance sovereignty are coequal constitutional layers. An artifact that satisfies operational sovereignty requirements but fails provenance sovereignty requirements is operationally valid and cryptographically inadmissible simultaneously. These are not contradictory findings; they are sovereign findings in different planes.

**Substrate references:** `0165`, `0168`, `0170`, `0176`, `0183`, `0187`.

---

### Replay Authority

**Constitutional Definition:**
Replay authority is the constitutional power to reconstruct, verify, and assert the historical admissibility of evidentiary artifacts produced at a prior time, under the conditions (canonicalization version, signing key, interpretation pack) that were active at the time of original production. It answers the constitutional question: *Does this historical artifact remain constitutionally valid when subjected to forensic reconstitution under its original production conditions?*

Replay authority is not runtime authority. It does not govern whether current operations are valid. It governs whether past operations remain constitutionally legitimate after time has passed and conditions have changed.

**Replay authority obligations:**
Every evidentiary output produced by Symphony carries a constitutional obligation to remain subject to replay authority. This obligation is permanent and does not expire with phase transitions, key rotations, or canonicalization version changes.

**What replay authority requires:**
- Preservation of the canonicalization version under which an artifact was produced (`canonicalization_registry`).
- Preservation of the signing key version active at the time of signing (via `wave8_signer_resolution.superseded_by` chain, not invalidation).
- Preservation of the Merkle proof path for the artifact (`proof_pack_batch_leaves`, `verify_merkle_leaf()`).
- Preservation of the interpretation pack version active at the time of production (`interpretation_packs` temporal records).

**Substrate references:** `0066`, `0165`, `0176`, `0183`.

---

### Admissibility

**Constitutional Definition:**
In Symphony, admissibility is the constitutional status of an evidentiary artifact as legally valid for use in a specific constitutional proceeding, regulatory submission, or downstream trust operation. Admissibility is **multi-dimensional, plane-specific, and context-dependent**. An artifact is not admissible or inadmissible in the abstract; it is admissible for a specific purpose under specific conditions.

**Admissibility dimensions:**
- *Operational admissibility:* The artifact satisfies the operational sovereignty requirements of Wave 4 enforcement (correct data_authority_level, required confidence, authorized state transition).
- *Cryptographic admissibility:* The artifact satisfies the provenance sovereignty requirements of Wave 8 enforcement (valid signature, authorized signer, canonical payload integrity).
- *Regulatory admissibility:* The artifact satisfies the requirements of a specific regulatory jurisdiction as defined in the active interpretation pack for that jurisdiction.
- *Historical admissibility:* The artifact remains constitutionally valid when reconstituted under its original production conditions via replay authority.

**Non-universal admissibility doctrine:**
An artifact may be operationally admissible but not cryptographically admissible. It may be cryptographically admissible but not regulatorily admissible in a specific jurisdiction. It may be admissible for one downstream use and not another. No single admissibility determination covers all uses.

**Prohibited interpretation:**
"This artifact has been verified" does not constitute a universal admissibility declaration. The form of verification and the sovereignty plane of the verifying mechanism determine which admissibility dimension has been satisfied.

---

### Cryptographic Admissibility

**Constitutional Definition:**
Cryptographic admissibility is the admissibility dimension satisfied when an evidentiary artifact's provenance sovereignty requirements have been fully verified: the signature is cryptographically valid, the signing key was authorized at the time of signing, the canonical payload matches persisted fields, and the signing timestamp is internally consistent.

Cryptographic admissibility is a binary determination within its plane: an artifact either satisfies all provenance sovereignty requirements or it does not. There are no partial cryptographic admissibility states.

**Constitutional enforcement:** `wave8_cryptographic_enforcement()` with SQLSTATEs `P7807`–`P7814`. Failure in any component of this function produces a constitutionally inadmissible artifact in the cryptographic plane.

**Relationship to other admissibility dimensions:**
Cryptographic admissibility is independent of operational admissibility. An artifact may achieve cryptographic admissibility without operational admissibility (e.g., a validly signed artifact for which no APPROVED governance decision exists). The reverse is also true.

---

### Regulatory Admissibility

**Constitutional Definition:**
Regulatory admissibility is the admissibility dimension satisfied when an evidentiary artifact meets the requirements defined in the active interpretation pack for a specific regulatory jurisdiction, as determined by `resolve_interpretation_pack()` under the applicable `app.jurisdiction_code`.

Regulatory admissibility is **jurisdiction-specific** and **interpretation-pack-version-specific**. An artifact that is regulatorily admissible under interpretation pack version V1 for jurisdiction J is not automatically admissible under pack version V2 for the same jurisdiction, nor under any interpretation pack for a different jurisdiction.

**Constitutional enforcement:** `rls_jurisdiction_isolation_interpretation_packs`; `resolve_interpretation_pack()` SECURITY DEFINER; `check_reg26_separation()` (`GF001`); `enforce_dns_harm_trigger`; K13 taxonomy alignment (`trg_k13_taxonomy_alignment`).

**Regulator orthogonality implication:**
Regulatory admissibility determinations from different jurisdictions are constitutionally non-comparable. Satisfaction of regulatory admissibility in jurisdiction A does not address, imply, or approximate regulatory admissibility in jurisdiction B.

---

### Attestation

**Constitutional Definition:**
In Symphony, attestation is the act of producing a cryptographically bound declaration that a specific evidentiary event — an invariant evaluation, a state transition authorization, an issuance decision — occurred at a specific time, was performed by an identified and authorized actor, and produced a specific output whose integrity can be independently verified.

Attestation in Symphony is **not a self-asserted declaration**. It requires: (a) a canonical payload binding the declaration to specific artifact fields, (b) a cryptographic signature by an authorized signer using a key valid at the time of attestation, (c) a timestamp that is internally consistent with the canonical payload, and (d) a freshness constraint ensuring the attestation is temporally proximate to the event it attests to (300-second TTL, `GF073`).

**Attestation is not verification.** Attestation asserts that an event occurred. Verification confirms that an assertion is cryptographically valid. The `verify_audit_precedence.sh` principle encodes the constitutional ordering: attestation MUST precede dispatch. An operation that is dispatched without prior attestation is constitutionally unauthorized.

**Substrate references:** `0168`, `0170`, `0183`, `0187`; `attestation_source_type` ENUM; `invariant_attestation_hash`; `verify_audit_precedence.sh`.

---

### Verification

**Constitutional Definition:**
In Symphony, verification is the act of confirming, through a defined and repeatable process, that a declared assertion — an attestation, an invariant compliance claim, an evidence completeness claim — is accurate. Verification is an independent act that does not derive its authority from the entity whose assertion it confirms.

**Verification dimensions in Symphony:**
- *Cryptographic verification:* Confirmation that a signature is mathematically valid using the claimed key (`ed25519_verify()`).
- *Merkle verification:* Confirmation that an artifact is a valid leaf of a declared Merkle tree (`verify_merkle_leaf()`).
- *Invariant verification:* Confirmation that a system state satisfies a declared invariant (CI verifier scripts in `scripts/db/verify_*.sh`).
- *Confidence verification:* Confirmation that an asset batch satisfies the required evidence confidence threshold (`validate_confidence_score()`).
- *Archive verification:* Confirmation that historical evidence remains intact and correctly structured across a defined time range (`archive_verification_runs`).

**Verifier independence doctrine:**
Verification MUST be performed by a mechanism or party that is independent of the mechanism or party that produced the assertion being verified. `check_reg26_separation()` (`GF001`) enforces this at the project level: the entity that validates a project cannot also verify it. This principle extends to all verification activities.

---

### Execution Legality

**Constitutional Definition:**
Execution legality is the constitutional status of an operation — task execution, state transition, data insertion, issuance event — as permitted within the current constitutional phase, by a constitutionally authorized actor, through a constitutionally valid entrypoint, under a constitutionally current interpretation pack.

An operation may be technically executable (no system error prevents it) while being constitutionally illegal (it violates phase legality, authority binding, or entrypoint requirements). Technical executability does not confer execution legality.

**Execution legality requirements:**
1. *Phase legality:* The operation is constitutionally permitted in the current phase.
2. *Authority binding:* The operation is authorized by a valid policy decision (`policy_decisions`).
3. *Entrypoint legality:* The operation was initiated through the canonical entrypoint (`SYMPHONY_CANONICAL_ENTRYPOINT`).
4. *State rule permissibility:* The transition is permitted under `state_rules` for the current state.
5. *Interpretation currency:* The operation is bound to a currently active interpretation pack version.

**Constitutional enforcement:** `task_execution_authority_gate.py` (entrypoint legality); `state_rules` + transition trigger chain (state rule permissibility); `enforce_authority_transition_binding()` (authority binding); `enforce_phase1_boundary()` (phase legality).

---

### Historical Validity

**Constitutional Definition:**
Historical validity is the constitutional status of an evidentiary artifact produced at a prior time as remaining legally legitimate, admissible, and accurately representative of the conditions that existed at the time of its production, regardless of subsequent changes to the system's enforcement mechanisms, key infrastructure, canonicalization standards, or regulatory interpretation.

Historical validity is preserved by **replay authority**. An artifact retains historical validity so long as it can be successfully reconstituted under its original production conditions. It does not lose historical validity because:
- The signing key that produced it has been superseded.
- The canonicalization version under which it was produced has been deprecated.
- The interpretation pack version active at its production has been replaced.
- The phase in which it was produced has ended.

**Historical validity is not conditional on current validity.** A Phase 1 `phase1_indicative_only` evidence record has full historical validity as Phase 1 evidence. It is not invalid because Phase 2 evidence carries higher authority. It answers a different constitutional question under a different constitutional authority.

**Substrate references:** `canonicalization_registry`; `wave8_signer_resolution.superseded_by`; `archive_verification_runs`; `anchor_backfill_jobs`; `verify_merkle_leaf()`.

---

### Compositional Validation Semantics

**Constitutional Definition:**
Compositional validation semantics is the doctrine that Symphony's validation of an operation or artifact is composed of multiple independent validation acts, each contributing a distinct constitutional certification, such that the complete constitutional status of the operation or artifact is the conjunction of all individual certifications — no single certification subsumes or replaces the others.

An asset batch insertion, for example, is subject to compositional validation across: operational authority (confidence gate), state transition permissibility (state rules), cryptographic provenance (Wave 8 trigger chain), attestation freshness (anti-replay TTL), and interpretation binding (interpretation_version_id FK). The failure of any single component produces a constitutionally invalid insertion, regardless of the others passing.

**Compositional implication:**
The passage of any single validation component DOES NOT certify the artifact as constitutionally complete. Only the conjunction of all applicable validation components produces a constitutionally complete artifact. Downstream consumers of Symphony artifacts MUST verify which validation components have been satisfied for their specific use case.

**Non-collapse doctrine implication:**
Compositional validation semantics prohibits collapsing multiple validation components into a single "validity" flag. A boolean `is_valid` field does not constitute constitutionally adequate compositional validation record.

---

### Orthogonal Trust Domains

**Constitutional Definition:**
Orthogonal trust domains are sovereignty planes that: (a) govern constitutionally distinct questions, (b) derive their authority from independent sources, (c) produce findings that are non-comparable across domains without an explicit cross-domain protocol, and (d) whose coexistence is constitutionally mandated rather than architecturally incidental.

In Symphony, the primary orthogonal trust domains are:
- *Operational sovereignty (Wave 4):* Governs runtime execution validity.
- *Provenance sovereignty (Wave 8):* Governs cryptographic origin integrity.
- *Regulatory sovereignty (per-jurisdiction):* Governs jurisdiction-specific admissibility.
- *Phase sovereignty:* Governs constitutional capability boundaries.
- *Historical sovereignty (replay):* Governs the permanent validity of past evidentiary records.

**Orthogonality is not independence in the sense of non-interaction.** Orthogonal domains interact at defined interfaces (e.g., the `interpretation_version_id` FK binding an execution record to its interpretation context). Orthogonality means that interaction at these interfaces does not produce authority collapse — each domain remains sovereign within its plane at the point of interaction.

**Prohibited interpretation:**
Orthogonality does not mean that findings from different domains cannot be combined to assess a complete artifact status. It means that combination does not eliminate or subordinate any domain's independent finding.

---

### Replay Reconstruction

**Constitutional Definition:**
Replay reconstruction is the process of reconstituting the constitutional status of a historical evidentiary artifact using the exact production conditions — canonicalization version, signing key version, interpretation pack version, and Merkle proof path — that were active at the time of its original production.

Replay reconstruction is NOT the same as re-execution of the original operation. It is a forensic verification act that confirms the historical artifact remains valid under its original constitutional conditions, without requiring the original operation to be re-performed.

**Replay reconstruction obligations:**
Symphony's replay substrate MUST preserve all elements required for replay reconstruction: (a) the canonicalization version (`canonicalization_registry`), (b) the signing key version (`wave8_signer_resolution` with supersession chain, NOT deletion), (c) the Merkle proof path (`proof_pack_batch_leaves`), and (d) the interpretation pack version (`interpretation_packs` temporal records).

**Backfill reconstruction:** When a replay gap is identified (a period for which replay substrate was not populated), `anchor_backfill_jobs` tracks the backfill operation. Backfill reconstruction is constitutionally valid only when it uses the production conditions that were active during the original gap period, not the current production conditions.

**Substrate references:** `0066`; `verify_merkle_leaf()`; `archive_verification_runs`; `anchor_backfill_jobs`; `canonicalization_registry`.

---

### Trust Root

**Constitutional Definition:**
A trust root in Symphony is a constitutional anchor — a mechanism, declaration, or substrate element — from which a chain of constitutional validity can be derived for a class of operations or artifacts, such that validity of the root is sufficient to establish the constitutional provenance of all downstream operations or artifacts in the chain.

Symphony operates with **multiple, domain-specific trust roots**, not a single universal trust root. Each sovereignty plane maintains its own trust root:
- *Wave 4 operational trust root:* The `policy_decisions` append-only cryptographic ledger, from which the authority of every state transition is derived.
- *Wave 8 provenance trust root:* The `wave8_signer_resolution` table combined with the `public_keys_registry`, from which the cryptographic validity of every signature is derived.
- *Interpretation trust root:* The `canonicalization_registry` seed entry `canon-v1` and the `interpretation_packs` temporal history, from which the interpretive validity of every operation is derived.
- *Phase trust root:* The constitutional ratification documents (GOV-CONV series), from which the phase legality of every operation is derived.

**Prohibited interpretation:**
Symphony does not have a single trust root in the sense of a unified root of trust for all domains simultaneously. Assertions of the form "X is the trust root for Symphony" are constitutionally invalid unless qualified by the specific sovereignty plane for which X serves as root.

---

### Canonicalization Lineage

**Constitutional Definition:**
Canonicalization lineage is the complete, ordered record of canonicalization algorithm versions that have been ratified, activated, and potentially deprecated in Symphony, together with the time periods during which each was the active standard for producing canonical evidentiary artifacts.

Canonicalization lineage is a constitutional archive, not a migration history. It is the substrate that makes replay reconstruction possible: by preserving the `spec_json` and `test_vectors` for each canonicalization version in `canonicalization_registry`, Symphony preserves the ability to reconstitute the canonical form of any historical artifact under the exact algorithm that produced it.

**Deprecation in canonicalization lineage:**
When a canonicalization version is deprecated (`deprecated_at` field populated in `canonicalization_registry`), it is removed from the set of versions that MAY be used for new evidentiary production. It is NOT removed from the registry. Its `spec_json` and `test_vectors` remain permanently available for replay reconstruction.

**Parallel admissibility planes:**
Each canonicalization version in the lineage defines a parallel admissibility plane. Evidence produced under `canon-v1` is admissible under `canon-v1`. Evidence produced under `canon-v2` is admissible under `canon-v2`. These planes do not merge; they coexist.

**Substrate references:** `0066`; `canonicalization_registry`; `assert_canonicalization_version_exists()` (`P8301`).

---

### Evidence Survivability

**Constitutional Definition:**
Evidence survivability is the constitutional property of an evidentiary artifact whereby it retains its historical validity, cryptographic admissibility, and replay reconstructability across: system upgrades, key rotations, canonicalization version changes, phase transitions, regulatory framework changes, and the passage of time — without requiring reprocessing, re-signing, or re-collection.

Evidence survivability is not a feature of specific artifacts; it is a constitutional obligation of the system that produces them. Symphony is constitutionally required to produce evidence-survivable artifacts. An artifact that cannot survive replay reconstruction under its original production conditions is constitutionally deficient from the moment of its production.

**Evidence survivability requirements:**
1. The artifact must be bound to a specific canonicalization version that is permanently preserved in `canonicalization_registry`.
2. The artifact must carry or be associated with a Merkle proof path in `proof_pack_batches` / `proof_pack_batch_leaves`.
3. The signing key used to produce the artifact must be preserved in `wave8_signer_resolution` with a supersession chain (not deletion) if later rotated.
4. The interpretation context under which the artifact was produced must be preserved in `interpretation_packs` temporal history.

**Phase 3 implication:**
Every Phase 3 task that produces an evidentiary output MUST include evidence survivability as a Definition of Done criterion. Evidence produced without evidence survivability infrastructure is constitutionally incomplete from its first production.

---

### Regulator Partitioning

**Constitutional Definition:**
Regulator partitioning is the constitutional architectural principle whereby each regulatory jurisdiction that interacts with Symphony's substrate occupies a constitutionally isolated sovereignty domain, enforced through jurisdiction-scoped row-level security, jurisdiction-specific interpretation packs, and explicit jurisdiction context requirements on all operations that produce jurisdiction-regulated outputs.

Regulator partitioning means that: (a) data and findings from one jurisdiction are constitutionally isolated from data and findings in other jurisdictions by default, (b) operations that cross jurisdiction boundaries require explicit authorization via the cross-boundary protocol, and (c) the satisfaction of regulatory requirements in one jurisdiction does not create any constitutional presumption of satisfaction in another.

**Enforcement mechanism:**
`current_jurisdiction_code_or_null()` SECURITY DEFINER function; `rls_jurisdiction_isolation_interpretation_packs` RESTRICTIVE policy; `rls_jurisdiction_isolation_regulatory_authorities` RESTRICTIVE policy. Operations executed without a valid `app.jurisdiction_code` session variable are constitutionally unscoped and produce jurisdiction-inadmissible outputs.

**Regulator partitioning is not regulatory isolation in the sense of preventing multi-jurisdiction operation.** A project may produce outputs relevant to multiple jurisdictions. Regulator partitioning requires that outputs for each jurisdiction be produced under that jurisdiction's RLS context, not that multi-jurisdiction projects are prohibited.

**Substrate references:** `0102`; `rls_tables.yml` entry for `interpretation_packs` (isolation_type: JURISDICTION).

---

### Verifier Independence

**Constitutional Definition:**
Verifier independence is the constitutional requirement that any entity, mechanism, or process that performs verification of a Symphony evidentiary claim must be structurally incapable of having produced, authorized, or benefited from the original claim it verifies.

Verifier independence is a sovereignty-preserving principle. When the verifier and the claim producer share identity, authority plane, or organizational affiliation without structural separation, the verification is constitutionally invalid regardless of its technical correctness.

**Structural enforcement in Symphony:**
`check_reg26_separation()` (`GF001`) enforces verifier independence at the project level by prohibiting the same entity from holding both the VALIDATOR and VERIFIER roles on a single project. This is not a business rule; it is a constitutional boundary declaration.

**Extended implication:**
Verifier independence extends beyond the `check_reg26_separation()` constraint to all verification activities. CI verifier scripts (`verify_*.sh`) achieve verifier independence by being separate from the implementation scripts they verify. The `AGENTS.md` agent authority model achieves verifier independence by separating the agent roles that implement from those that verify.

**What verifier independence prohibits:**
- An entity verifying its own signatures.
- A mechanism that produced a state transition being the mechanism that determines whether that transition was valid.
- An agent that implemented a task being the sole verifier of that task's completion.

---

### Phase Legality

**Constitutional Definition:**
Phase legality is the constitutional status of an operation, data population event, substrate wiring change, or capability deployment as constitutionally permitted within the current declared phase of Symphony's capability development.

Phase legality is not equivalent to technical feasibility. An operation may be technically possible — the schema exists, the functions are defined, the CI gates would pass — while being phase-illegal because the current phase has not constitutionally authorized that operation.

**Phase legality sources:**
Phase legality is established by: (a) the phase lifecycle constitutional documents, (b) the explicit deferral declarations in migration comments and column comments, (c) the `enforce_phase1_boundary()` DB trigger (`GF071`/`GF072`), and (d) the `verify_phase_claim_admissibility.sh` CI gate.

**Phase legality is not permanent.** An operation that is phase-illegal in Phase N becomes phase-legal in Phase N+1 when the Phase N+1 constitutional boundary has been formally declared through the GOV-CONV ratification sequence. Phase illegality expires at the phase boundary; it does not prohibit the operation permanently.

**Phase legality is not discretionary.** An operation that is phase-illegal cannot be made phase-legal by team consensus, sprint planning, or technical readiness assessment alone. Constitutional ratification is required.

---

### Constitutional Reservation

**Constitutional Definition:**
Constitutional reservation is the deliberate, declared withholding of a capability, authority, or power from the current constitutional phase, for the purpose of preserving its integrity, preventing premature activation, and ensuring that it enters operation only under constitutionally defined conditions.

A constitutionally reserved capability is: (a) present in substrate form (schema declared, triggers defined, functions written), (b) absent in population or operational form (columns null, tables empty, wiring absent), and (c) assigned to a defined future phase or activation condition.

**Constitutional reservation is not incompleteness.** A reserved capability is constitutionally complete in its current state. Its emptiness is the correct expression of its reservation. The obligation to populate it is deferred to the authorizing phase or condition.

**Constitutional reservation examples in Symphony:**
- Attestation seam columns (`invariant_attestation_hash`, `invariant_attested_at`) — reserved for Wave 8 population.
- `archive_verification_runs` — reserved for activation by archive verification trigger conditions.
- `anchor_backfill_jobs` — reserved for activation when a replay gap is identified.
- `delegated_signing_grants` — reserved for population when delegation authority is constitutionally authorized.

**What constitutional reservation requires:**
Every constitutionally reserved capability MUST carry: (a) an explicit deferral declaration (migration comment, column comment, or governance document entry), (b) an identified authorizing phase or condition, and (c) a defined activation criterion that is independent of team preference.

**Substrate reference:** `attestation_source_type` ENUM value `'deferred'`; column comments with "Population deferred to Wave N" declarations.

---

### Dormant Substrate

**Constitutional Definition:**
Dormant substrate is substrate — tables, columns, functions, triggers, indexes — that is constitutionally active (deployed, enforced, available) but not currently receiving data, being called by application logic, or wired to a CI gate, because its activation condition has not yet been triggered.

Dormant substrate is categorically distinct from constitutional reservation. Constitutional reservation is a deliberate withholding. Dormant substrate is correct operational quiescence: the substrate is ready to activate; the activating condition has simply not occurred.

**The constitutional status of dormant substrate is ACTIVE, not INACTIVE.** Its current data state (empty tables, zero function calls) reflects the absence of activating events, not the absence of constitutional validity or operational relevance.

**Dormant substrate is NOT:**
- Technical debt awaiting removal.
- Accidental scope creep awaiting cleanup.
- A candidate for consolidation with other substrate.
- Evidence of architectural incompleteness.

**Dormant substrate IS:**
- Infrastructure awaiting its constitutional activation event.
- Part of Symphony's replay survivability posture (most replay substrate is correctly dormant during normal operation).
- Part of Symphony's forensic readiness posture (forensic quarantine infrastructure, when implemented, will be dormant except during investigations).

**Examples of correctly dormant substrate in Symphony:**
- `anchor_backfill_jobs` — dormant until a backfill is required.
- `archive_verification_runs` — dormant until a scheduled or triggered archive verification run occurs.
- `canonicalization_registry` entries beyond `canon-v1` — dormant until a second canonicalization version is ratified.
- `data_authority_level` values above `phase1_indicative_only` — dormant in Phase 1 (not dormant substrate in the technical sense; correctly non-populated due to phase legality constraints).

---

## Part II: Derived Constitutional Concepts

The following concepts are derived from the primary definitions above and are included to prevent semantic drift in their application.

---

### Evidence Continuity

The constitutional property whereby the chain of evidence from an original event to its final settlement record remains unbroken, with each link in the chain carrying a constitutionally valid attestation and an unambiguous reference to the preceding link. Evidence continuity is required for historical admissibility.

---

### Phase Capability Boundary

The constitutional threshold that separates the set of capabilities constitutionally permissible in Phase N from those permissible in Phase N+1. A phase capability boundary is established by constitutional ratification (GOV-CONV series), not by technical completion or team agreement.

---

### Interpretation Currency

The constitutional property of an operation whereby it is bound to the currently active interpretation pack version for its jurisdiction at the time of execution. Operations performed under an expired or superseded interpretation pack version are interpretation-stale and carry regulatory admissibility risks.

---

### Authority Binding

The constitutional act of linking an execution record, state transition, or operational event to the specific policy decision that authorized it, via cryptographic reference (`policy_decision_id` FK). Without authority binding, an operation is constitutionally unauthorized regardless of its technical correctness.

---

### Supersession Chain

The linear, non-forking sequence of `superseded_by` references by which a superseded invariant, signer key, or governance instrument is linked to its authorized successor. The supersession chain preserves the historical validity of superseded artifacts (they remain valid through their supersession point) while establishing the constitutional priority of successor artifacts.

A supersession chain must be linear (enforced by `idx_unique_superseded_by` unique constraint). A forked supersession chain — two successors claiming the same predecessor — is constitutionally impermissible as it creates an unresolvable authority ambiguity.

---

### Non-Collapse Doctrine

The constitutional principle that the coexistence of multiple sovereignty domains, authority mechanisms, or enforcement layers governing the same substrate MUST NOT be resolved by collapsing any domain into another or declaring one domain's findings to be universally subordinate to another's. Non-collapse doctrine requires that each domain's findings be preserved and evaluated within their respective planes.

Non-collapse doctrine is the constitutional basis for: sovereign orthogonality, compositional validation semantics, verifier independence, and regulator partitioning.

---

## Phase 3 Boundary Doctrine Definitions

The following definitions are added to support Phase 3 boundary and doctrine
readiness. They are canonical terms for task-plan scoping and must not be
redefined by Phase 3 task plans.

### Projection Universe

A bounded interpretive context used to derive a legitimacy, admissibility,
contradiction, or failure view from historical truth under declared policy,
authority, temporal, jurisdictional, regulator, and replay inputs. A projection
universe is a derived context. It is not historical truth and does not mutate
historical truth.

### Historical Truth

The append-only canonical record of what Symphony knew, accepted, rejected,
signed, referenced, and persisted at the time an event or decision occurred.
Historical truth is evaluated by replay and projection, but it is not rewritten
by later replay or projection results.

### Replay Reconstruction

The deterministic recomputation of a historical decision, admissibility view, or
legitimacy view from persisted canonical artifacts under declared replay rules
and declared projection context.

### Operational Exhaust

Runtime memory, mutable caches, telemetry, transient queue state, dashboard
state, temporary files, non-evidence logs, and ephemeral service responses.
Operational exhaust has no constitutional authority unless separately promoted
into an admissible evidence artifact under governing doctrine.

### Authority Lineage

The replayable chain from an asserted authority claim back to the constitutional,
regulator, policy, or delegated source that grants authority for the specific
act, resource, time, and context being evaluated.

### Policy Artifact

A versioned, replay-addressable constitutional, regulator, jurisdictional,
methodology, or governance input that defines a rule used by Phase 3 evaluation.
Runtime configuration, AI synthesis, task prose, and dashboard state are not
policy artifacts unless they are separately versioned, authority-linked, and
admitted by governing doctrine.

### Contradiction Quarantine

The append-only preservation state applied when records, findings, or policy
artifacts cannot safely be relied on pending contradiction resolution. Quarantine
prevents reliance; it does not delete, rewrite, or erase the quarantined record.

### Derived Legitimacy State

The output of replay reconstruction or projection evaluation within a declared
projection universe. A derived legitimacy state may affect future reliance or
future operations, but it does not retroactively mutate the historical record
that was evaluated.

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
The semantic definition space for all Symphony constitutional concepts across all sovereignty planes, all phases, all regulatory jurisdictions, and all evidentiary contexts.

**Sovereignty domains this document MUST NOT redefine:**
- The specific technical implementation of any enforcement mechanism (governed by source migrations and the Canonical Capability Report).
- The specific content of any jurisdiction interpretation pack (governed by regulator-partitioned instruments).
- The specific assignment of invariant identifiers or GF-prefix SQLSTATEs (governed by INVARIANTS_MANIFEST.yml and the SQLSTATE canonical map).
- The specific phase transition authorization criteria (governed by phase lifecycle constitutional documents).

**Replay obligations preserved:**
- The definitions of Replay Authority, Replay Reconstruction, Evidence Survivability, and Historical Validity collectively establish that replay is a constitutional permanence obligation, not a disaster recovery feature, and that this obligation attaches to every evidentiary output from the moment of its first production.
- The Canonicalization Lineage definition preserves the parallel admissibility plane doctrine: deprecated canonicalization versions remain permanently available for replay reconstruction.
- The definition of Historical Validity explicitly prohibits retroactive invalidation of historical artifacts through changes to current production conditions.

**Regulator boundaries constraining this document:**
This document defines the constitutional meaning of regulator-related concepts (Regulator Partitioning, Regulatory Admissibility). It does not govern the substantive requirements of any specific regulatory jurisdiction. Jurisdiction-specific requirements are governed by regulator-partitioned instruments operating within the framework this document defines.

**Phases this document applies to:**
GLOBAL — these definitions apply across all phases from Phase 1 onward. Definitions that are phase-qualified (e.g., Phase Legality, Constitutional Reservation, Dormant Substrate) identify their phase-specific dimensions explicitly within the definition.

**Constitutional layers possessing override authority:**
No document with Authority-Rank below 10 possesses override authority over this glossary. Override requires a ROOT-level constitutional instrument that explicitly supersedes this document by name and provides replacement definitions for each term superseded.

**Lower-layer documents prohibited from reinterpretation:**
- Phase-specific execution envelopes
- Wave-specific implementation guides
- Task-level Definitions of Done
- Governance convergence documents (GOV-CONV series)
- Agent authority documents (AGENTS.md, AGENT_ENTRYPOINT.md)
- Evidence schema documents
- Migration metadata (`.meta.yml` files)
- Any document with Authority-Rank < 10

These documents apply the definitions contained herein. They may employ these terms. They may not redefine, narrow, expand, or qualify them.

---

## Prohibited Misinterpretations

**PMI-001 — Sovereignty as Administrative Control:**
Sovereignty MUST NOT be interpreted as the right of an actor or system component to modify, delete, or override data. Sovereignty is a constitutional authority domain over a class of questions, not an access control concept.

**PMI-002 — Admissibility as Binary:**
Admissibility MUST NOT be treated as a single boolean property. It is multi-dimensional (operational, cryptographic, regulatory, historical). An artifact that is admissible in one dimension is not thereby admissible in all dimensions.

**PMI-003 — Dormant Substrate as Technical Debt:**
The definition of Dormant Substrate explicitly prohibits its characterization as technical debt, dead schema, or cleanup candidate. This definition is constitutionally authoritative and takes precedence over any audit or refactoring analysis that concludes otherwise.

**PMI-004 — Constitutional Reservation as Missing Implementation:**
Constitutional reservation is the deliberate, constitutionally declared withholding of a capability. It is constitutionally complete in its reserved state. Describing reserved capabilities as "missing" or "not yet implemented" without including the reservation declaration and authorizing condition is constitutionally inaccurate.

**PMI-005 — Replay Reconstruction as Disaster Recovery:**
Replay reconstruction is a constitutional permanence obligation, not a disaster recovery procedure. It applies to normal evidentiary operations, not only to system failure scenarios. Its infrastructure must be present and populated from the first production of evidentiary outputs.

**PMI-006 — Orthogonal Trust Domains as Independent Systems:**
Orthogonal trust domains coexist over the same substrate and interact at defined interfaces. Orthogonality means their findings are non-comparable across domain boundaries without a defined protocol — it does not mean they operate in isolation on separate data.

**PMI-007 — Verifier Independence as Organizational Separation Only:**
Verifier independence is a structural constitutional requirement. Organizational separation (different teams, different companies) is one form of structural separation but not the only form. Structural independence achieved through role separation (`check_reg26_separation()`), entrypoint separation, and CI-level separation is constitutionally equivalent to organizational separation.

**PMI-008 — Phase Legality as Technical Gating Only:**
Phase legality is a constitutional status, not a technical constraint. The `enforce_phase1_boundary()` DB trigger enforces one dimension of phase legality technically. But phase legality also governs actions that no trigger prevents — such as documentation claims, agent reasoning outputs, and task generation — and these are governed by `verify_phase_claim_admissibility.sh` and the GOV-CONV ratification sequence. Phase legality is not satisfied by passing technical gates alone.

**PMI-009 — Trust Root as Singular:**
Symphony operates with multiple domain-specific trust roots. The assertion that Symphony has "a trust root" is constitutionally imprecise and must always be qualified by the sovereignty plane for which the root serves.

**PMI-010 — Non-Collapse Doctrine as Prohibition on Integration:**
Non-collapse doctrine prohibits the unconstitutional elimination of sovereignty planes. It does not prohibit integration of mechanisms that serve the same plane, nor does it prohibit defined cross-plane interaction protocols. What it prohibits is interaction that results in one plane's findings becoming constitutionally subordinate to another's without explicit authorization.
