# CRYPTOGRAPHIC AND RUNTIME AUTHORITY DOCTRINE

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md

---

## Purpose

This document defines the constitutional architecture governing the relationship between Wave 4 operational/runtime sovereignty and Wave 8 provenance/cryptographic sovereignty within Symphony. It establishes the boundary conditions, veto semantics, compositional validation rules, HSM separation requirements, execution token semantics, attestation signature semantics, signer lineage doctrine, replay trust roots, and external verification survivability obligations that together constitute Symphony's dual-sovereignty enforcement model.

The architecture defined herein is coexistence-through-boundary-definition. Wave 4 and Wave 8 are constitutionally orthogonal sovereign surfaces that coexist by maintaining explicit, non-overlapping authority boundaries. They do not converge toward a unified authority. They do not derive their authority from each other. They do not validate each other's determinations. They coexist through the constitutional definition of their respective domains and the veto semantics that govern records crossing both domains.

No lower-rank artifact may reframe this architecture as convergence-through-collapse, runtime-derivation of provenance authority, or provenance-subordination to operational consensus.

---

## Constitutional Scope

This document governs:

1. The definition of Wave 4 operational sovereignty and its authority boundary.
2. The definition of Wave 8 provenance/cryptographic sovereignty and its authority boundary.
3. The mutual veto semantics applicable when a record must satisfy both Wave 4 and Wave 8 determinations.
4. The compositional payload doctrine governing how records are structured to carry both operational and provenance authority.
5. The HSM boundary rules separating hardware signing authority from software runtime authority.
6. The execution token semantics governing the authority of runtime execution attestation.
7. The attestation signature semantics governing the authority of cryptographic provenance attestation.
8. The signer lineage doctrine governing the chain of signing authority.
9. The replay trust roots from which replay verification derives its authority.
10. The external verification survivability obligations ensuring replay validity independent of runtime state.
11. The arbitration semantics for PASS/PASS, PASS/FAIL, and FAIL/PASS determination combinations.

This document does NOT govern:

- The specific migration implementation of Wave 4 or Wave 8 enforcement surfaces (governed by enforcement doctrine and migration records).
- The priority ordering when Wave 4 and Wave 8 obligations conflict with obligations from other priority classes (governed by CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md).
- The amendment procedures for this doctrine (governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md).

---

## Authority Boundaries

This document operates at Authority-Rank 10 (ROOT). Its definitions of Wave 4 and Wave 8 sovereignty, their boundary conditions, and their veto semantics are constitutionally binding on all lower-rank artifacts. No enforcement doctrine, migration record, operational artifact, or synthesis product may redefine, narrow, expand, or collapse the sovereignty boundaries defined herein.

---

## Part I: Wave 4 Operational Sovereignty

### 1.1 Definition

Wave 4 operational sovereignty is the constitutional authority surface governing whether a record is legally processable within Symphony's operational enforcement model at runtime. Wave 4 authority determines:

- Whether the record's data structure conforms to the schema enforced by active migration-tip tables.
- Whether the record's values satisfy the invariants enforced by active SECURITY DEFINER triggers and RESTRICTIVE RLS policies.
- Whether the record's state transition conforms to the valid transition graph enforced by active phase-boundary and state-machine triggers.
- Whether the record's entry point satisfies merge-path CI gate requirements.

Wave 4 operational sovereignty does NOT determine:

- Whether the record's provenance chain is cryptographically valid.
- Whether the record's signing key is authorized by the Wave 8 signer resolution mechanism.
- Whether the record's historical hash chain is cryptographically continuous.
- Whether the record is replay-verifiable against the Wave 8 trust root.

### 1.2 Wave 4 Authority Boundary

Wave 4 authority is bounded by the enforcement surfaces active at the current migration tip. Its determinations are authoritative within the operational domain. They do not extend into the cryptographic provenance domain. Specifically:

**W4-B1.** Wave 4 authority extends to: schema conformance, invariant satisfaction, state transition legality, phase-boundary compliance, and CI gate passage.

**W4-B2.** Wave 4 authority does not extend to: cryptographic signature validity, signing key authorization, hash chain continuity, or replay trust root verification.

**W4-B3.** A Wave 4 PASS determination on a record establishes that the record satisfies all current operational enforcement constraints. It does not establish that the record satisfies Wave 8 provenance obligations.

**W4-B4.** Wave 4 authority surfaces include: `enforce_transition_signature` (presence check), `enforce_phase1_boundary`, `enforce_batch_status_transitions`, `enforce_assignment_limits`, and all RESTRICTIVE RLS policies. These surfaces enforce operational constraints; they do not perform cryptographic provenance validation.

### 1.3 Wave 4 Self-Authorization Prohibition

Wave 4 operational sovereignty may not self-authorize. The following are constitutionally prohibited:

**W4-P1. Runtime self-signing:** A runtime process may not generate, apply, or validate a cryptographic signature using keys that are managed and attested by the same runtime process. Runtime signing authority must be externally attested and HSM-separated.

**W4-P2. Operational consensus as provenance:** Wave 4 operational acceptance of a record by multiple nodes, services, or enforcement surfaces does not constitute cryptographic provenance validation. Consensus at the operational layer is not a provenance mechanism.

**W4-P3. Trigger self-validation:** A SECURITY DEFINER trigger may not validate its own enforcement logic as the basis for declaring a record constitutionally admitted. Trigger enforcement expresses a constitutional obligation; it does not validate that the obligation has been constitutionally satisfied.

---

## Part II: Wave 8 Provenance Sovereignty

### 2.1 Definition

Wave 8 provenance sovereignty is the constitutional authority surface governing whether a record's cryptographic provenance chain is valid and whether the record is attributable to an authorized signer within the signer lineage. Wave 8 authority determines:

- Whether the record's signing hash was produced by a valid `ed25519_verify()`-verifiable signing operation.
- Whether the signing key used is registered in `wave8_signer_resolution` as an authorized signer for the record class.
- Whether the signer's authorization is traceable through the signer lineage to a trust root.
- Whether the record's hash chain is cryptographically continuous and has not been interrupted or forked.
- Whether the record is reconstructable through replay from the trust root.

Wave 8 provenance sovereignty does NOT determine:

- Whether the record's data values satisfy operational invariants.
- Whether the record's state transition is operationally permitted.
- Whether the record's schema conforms to Wave 4 enforcement surfaces.
- Whether the record passes CI gate merge-path requirements.

### 2.2 Wave 8 Authority Boundary

Wave 8 authority is bounded by the cryptographic provenance chain and the signer lineage. Its determinations are authoritative within the provenance domain. They do not extend into the operational enforcement domain. Specifically:

**W8-B1.** Wave 8 authority extends to: cryptographic signature validity, signing key authorization, hash chain continuity, signer lineage traceability, and replay trust root anchoring.

**W8-B2.** Wave 8 authority does not extend to: schema conformance enforcement, state transition legality, operational invariant satisfaction, or CI gate passage.

**W8-B3.** A Wave 8 PASS determination on a record establishes that the record's cryptographic provenance chain is valid and the signer is authorized within the signer lineage. It does not establish that the record satisfies Wave 4 operational enforcement constraints.

**W8-B4.** Wave 8 authority surfaces include: `wave8_cryptographic_enforcement`, `wave8_signer_resolution`, `resolve_authoritative_signer`, `verify_ed25519_signature` (when constitutionally operative, not stub-implemented), `public_keys_registry` (upon constitutional activation), `delegated_signing_grants` (upon constitutional activation), `signing_audit_log` (upon constitutional activation), and `canonicalization_registry`.

### 2.3 Wave 8 Shadow Authority Surface: Constitutional Classification

`verify_ed25519_signature` in its current stub implementation — returning `true` unconditionally regardless of the signature bytes provided — is constitutionally classified as a **shadow authority surface**: it occupies the Wave 8 enforcement position without performing the Wave 8 enforcement function.

**W8-S1.** A shadow authority surface does not satisfy Wave 8 provenance integrity obligations.

**W8-S2.** Records that have passed through the stub `verify_ed25519_signature` are Wave 4 operationally admitted but Wave 8 provenance-defective.

**W8-S3.** The shadow authority surface must be remediated by the installation of a constitutionally operative `ed25519_verify()` extension and the replacement of the stub with actual cryptographic verification logic. This remediation is a constitutional obligation, not an implementation preference.

**W8-S4.** The existence of the shadow authority surface is a documented constitutional defect, not an accepted architectural state.

### 2.4 Wave 8 Provenance Bypass Prohibition

Wave 8 provenance sovereignty may not be bypassed through the following:

**W8-P1. Operational legality bypass:** A record's satisfaction of all Wave 4 operational constraints does not authorize the bypass of Wave 8 provenance verification. Wave 4 PASS does not constitute Wave 8 PASS.

**W8-P2. Stub satisfaction:** A stub implementation of a Wave 8 enforcement surface that returns unconditional positive results does not satisfy Wave 8 obligations. Stub results carry the constitutional weight of no verification.

**W8-P3. Performance exception:** No runtime performance constraint, latency requirement, or throughput objective constitutes grounds for bypassing Wave 8 cryptographic verification. Wave 8 verification is not an optional performance trade-off.

**W8-P4. Phase-conditional bypass:** No phase doctrine may establish that Wave 8 provenance obligations are conditionally suspended during any phase. Wave 8 obligations may be in a constitutionally deferred activation state during early phases; they may not be waived or bypassed by phase doctrine once the Wave 8 enforcement path is activated.

---

## Part III: Mutual Veto Semantics

### 3.1 Constitutional Principle

Wave 4 and Wave 8 exercise mutual veto authority over records. A record that must satisfy both Wave 4 operational constraints and Wave 8 provenance constraints is admitted only when both determinations are PASS. Either determination being FAIL is sufficient to block the record. Neither determination being PASS is sufficient alone. This is mutual veto by sovereign orthogonality.

### 3.2 PASS/PASS: Execute

**Definition:** A record receives a Wave 4 PASS determination (all operational enforcement constraints satisfied) AND a Wave 8 PASS determination (cryptographic provenance chain valid, signer authorized).

**Constitutional outcome:** The record is constitutionally admitted in both the operational domain and the provenance domain. It is operationally processable and cryptographically provenance-traceable. It satisfies the constitutional requirements of both sovereignty surfaces and may proceed to the designated operational endpoint.

**Admissibility status:** Fully admitted — operationally and provenancially.

**Replay status:** Replay-eligible. The record is replayable against the Wave 8 trust root and reconstructable from the operational record.

**Regulator status:** Subject to independent evaluation by each applicable regulator domain. PASS/PASS does not constitute universal regulatory admissibility; it constitutes the necessary constitutional precondition for regulatory admissibility evaluation.

### 3.3 PASS/FAIL: Block

**Definition:** A record receives a Wave 4 PASS determination (all operational enforcement constraints satisfied) AND a Wave 8 FAIL determination (cryptographic provenance chain invalid, signer unauthorized, hash chain broken, or stub verification insufficient).

**Constitutional outcome:** The record is constitutionally blocked. Wave 4 PASS does not override Wave 8 FAIL. Wave 8 veto is unconditional. The record may not proceed to the designated operational endpoint. It may not be treated as partially admitted or conditionally processed pending Wave 8 remediation.

**Admissibility status:** Blocked — operationally capable but provenancially inadmissible.

**Replay status:** Not replay-eligible in the Wave 8 dimension. If the record entered the database despite the Wave 8 FAIL (e.g., due to the stub shadow authority surface accepting it), it carries a Wave 8 constitutional defect that persists regardless of its presence in the operational record.

**Enforcement obligation:** The enforcement surface must generate a Wave 8 FAIL event record in `signing_audit_log` (upon activation) or equivalent constitutional evidence store, documenting the failed provenance determination. This record is itself replay-obligated.

**Prohibited responses:**
- Retrying with relaxed provenance requirements.
- Treating the Wave 4 PASS as sufficient for processing while Wave 8 is "pending."
- Logging the failure and proceeding.
- Treating the FAIL as a warning rather than a block.

### 3.4 FAIL/PASS: Block

**Definition:** A record receives a Wave 4 FAIL determination (one or more operational enforcement constraints unsatisfied) AND a Wave 8 PASS determination (cryptographic provenance chain valid, signer authorized).

**Constitutional outcome:** The record is constitutionally blocked. Wave 8 PASS does not override Wave 4 FAIL. Wave 4 veto is unconditional. A cryptographically valid, properly signed record that fails operational enforcement constraints is not admitted. Cryptographic validity does not constitute operational legality.

**Admissibility status:** Blocked — provenancially valid but operationally inadmissible.

**Replay status:** The Wave 8 PASS determination is itself replayable — the cryptographic provenance chain is valid and reconstructable. The record's Wave 4 FAIL is also a replayable constitutional event, not a merely operational error.

**Enforcement obligation:** The enforcement surface must generate a Wave 4 FAIL event in the applicable audit trail, documenting which operational constraint was unsatisfied and the determination basis. This is constitutionally distinct from a Wave 8 FAIL event.

**Prohibited responses:**
- Treating Wave 8 PASS as overriding Wave 4 enforcement constraints.
- Admitting the record on the basis of cryptographic integrity alone.
- Deferring Wave 4 enforcement in deference to Wave 8 authority.
- Treating the record as constitutionally valid in the Wave 4 dimension "pending" operational correction.

### 3.5 FAIL/FAIL: Block

**Definition:** A record receives both a Wave 4 FAIL determination and a Wave 8 FAIL determination.

**Constitutional outcome:** The record is constitutionally blocked on both sovereignty surfaces. Both veto rights are exercised. Both failure events must be independently documented.

**Admissibility status:** Fully blocked — operationally inadmissible and provenancially inadmissible.

**Replay status:** Both FAIL events are replay-obligated constitutional records.

---

## Part IV: Arbitration Matrix

### Matrix A: Wave 4 / Wave 8 Determination Outcomes

| Wave 4 Determination | Wave 8 Determination | Constitutional Outcome | Operational Effect | Replay Obligation |
|---|---|---|---|---|
| PASS | PASS | EXECUTE — full admission | Record proceeds to endpoint | Replay-eligible; both surfaces reconstructable |
| PASS | FAIL | BLOCK — Wave 8 veto | Record blocked at Wave 8 surface | Wave 8 FAIL event replay-obligated |
| FAIL | PASS | BLOCK — Wave 4 veto | Record blocked at Wave 4 surface | Wave 4 FAIL event replay-obligated; Wave 8 PASS reconstructable |
| FAIL | FAIL | BLOCK — dual veto | Record blocked at earliest encountered surface | Both FAIL events independently replay-obligated |
| PASS | STUB (shadow) | OPERATIONALLY ADMITTED — constitutionally defective | Record in database; Wave 8 obligation unmet | Record present; Wave 8 defect is a separate replay-obligated constitutional event |
| FAIL | STUB (shadow) | BLOCKED at Wave 4 | Record blocked; Wave 8 stub result immaterial | Wave 4 FAIL replay-obligated |

### Matrix B: Write Path Sovereignty Applicability

| Write Path | Wave 4 Applicable | Wave 8 Applicable | Both Required | Notes |
|---|---|---|---|---|
| `state_transitions` (INSERT) | YES — `enforce_transition_signature` | YES — hash continuity, signing obligation | YES | Placeholder posture currently satisfies Wave 4 presence; Wave 8 cryptographic validation deferred (defect) |
| `asset_batches` (INSERT) | YES — batch status enforcement | YES — `wave8_cryptographic_enforcement` | YES | Wave 8 enforcement active on this path |
| `asset_batch_items` (INSERT) | YES — referential integrity | YES — parent batch Wave 8 status | YES | Inherits parent batch Wave 8 status |
| `monitoring_records` (INSERT) | YES — `enforce_phase1_boundary` | Conditional — per applicable wave doctrine | Per doctrine | Phase boundary enforced; Wave 8 applicability per wave doctrine |
| `evidence_packs` (INSERT) | YES — invariant enforcement | YES — evidence provenance chain | YES | Evidence provenance is Wave 8 domain |
| CI gate (merge path) | YES — all CI gates | YES — signature verification gate where applicable | YES | CI gate passage is Wave 4; provenance gate is Wave 8 |

---

## Part V: Compositional Payload Doctrine

### 5.1 Definition

Compositional payload doctrine governs the structure of records that must carry both Wave 4 operational authority and Wave 8 provenance authority. A compositional payload is a record that:

- Contains operational fields governed by Wave 4 enforcement surfaces.
- Contains provenance fields governed by Wave 8 enforcement surfaces.
- Is subject to mutual veto semantics under Part III of this document.

### 5.2 Compositional Payload Structure Requirements

**CP-1. Operational field separation:** Operational fields (schema-enforced values, state identifiers, foreign key references, status fields) must be structurally separable from provenance fields (signing hashes, signer identifiers, signature bytes, hash chain references). Structural commingling of operational and provenance fields in a manner that makes independent Wave 4 and Wave 8 evaluation impossible is constitutionally impermissible.

**CP-2. Provenance field completeness:** A compositional payload that contains operational fields without corresponding provenance fields is constitutionally incomplete at the Wave 8 level. Its Wave 8 determination is FAIL pending population of provenance fields.

**CP-3. Hash chain anchoring:** Provenance fields must include a hash chain reference that anchors the record to the prior record in the same hash chain. A record without a valid prior-record hash reference is not anchored in the Wave 8 trust chain and is Wave 8 inadmissible.

**CP-4. Canonicalization version reference:** Where `canonicalization_registry` is constitutionally active, provenance fields must include a reference to the canonicalization schema version used to produce the signing hash. Signing hash produced under an unregistered canonicalization schema is Wave 8 inadmissible.

**CP-5. Compositional validation sequencing:** Wave 4 enforcement must be applied before Wave 8 enforcement in the write path. A record that fails Wave 4 enforcement must not be submitted to Wave 8 signing; signed records that contain Wave 4-invalid data are Wave 8 PASS but Wave 4 FAIL (see FAIL/PASS semantics, Section 3.4). The correct sequencing avoids signing invalid records.

### 5.3 Compositional Validation Flow

```
Record submitted to write path
           │
           ▼
Wave 4 Enforcement
(schema, invariants, state transitions, phase boundary)
           │
      ┌────┴────┐
    FAIL       PASS
      │           │
      ▼           ▼
BLOCK (Wave 4)  Wave 8 Enforcement
Document FAIL   (canonicalization, signing hash, signer resolution,
event           ed25519_verify(), hash chain anchoring)
                   │
              ┌────┴────┐
            FAIL       PASS
              │           │
              ▼           ▼
        BLOCK (Wave 8)  EXECUTE
        Document FAIL   Document PASS/PASS
        event           event; record admitted
                        in both domains
```

**Note on stub path:** Where `verify_ed25519_signature` is stub-implemented, the Wave 8 path returns PASS unconditionally. This does not constitute a genuine PASS/PASS outcome. It constitutes a PASS (Wave 4) / STUB (Wave 8) outcome as defined in Matrix A, Row 5. The record is operationally admitted but Wave 8 provenancially defective.

---

## Part VI: HSM Boundary Rules

### 6.1 HSM Sovereignty Principle

Hardware Security Module (HSM) separation is a constitutional requirement for Wave 8 signing authority. Signing keys that establish Wave 8 provenance authority must be managed within a hardware boundary that is constitutionally and physically separate from the runtime software processes that request signing operations. This separation is not an implementation preference; it is a constitutional requirement for Wave 8 signing authority to be independent of Wave 4 operational sovereignty.

### 6.2 HSM Boundary Definitions

**HSM-1. Signing key custody boundary:** Ed25519 private signing keys authorized in `wave8_signer_resolution` must be held within an HSM. Private key material must not be present in: database memory, application process memory, environment variables, configuration files, or any software-accessible storage. Violation of this constraint renders the signer's Wave 8 authority constitutionally void.

**HSM-2. Signing operation boundary:** The signing operation (applying the private key to the canonicalized record bytes to produce a signature) must occur within the HSM boundary. The plaintext record bytes may be transmitted to the HSM for signing; the private key must not be transmitted out of the HSM for signing.

**HSM-3. Attestation boundary:** The HSM must produce a signing attestation that records: the signer identifier, the canonicalization schema version used, the hash of the record bytes signed, the signature produced, and the timestamp of the signing operation. This attestation is a Wave 8 constitutional record and must be stored in `signing_audit_log` upon that table's constitutional activation.

**HSM-4. HSM independence from Wave 4:** The HSM signing authority must not be administratively subordinate to the Wave 4 operational runtime. The HSM's authorized operators must be constitutionally distinct from the Wave 4 runtime administrators. Administrative subordination of the HSM to Wave 4 runtime operators constitutes a sovereignty boundary violation.

**HSM-5. Key rotation boundary:** Signing key rotation within the HSM must produce a signer lineage entry in `wave8_signer_resolution` and `delegated_signing_grants` (upon activation). Key rotation that does not update the signer lineage produces an unauthorized signer gap in the Wave 8 provenance chain.

### 6.3 HSM Separation Requirements Matrix

| Requirement | HSM Boundary Required | Software Runtime Permitted | Constitutional Basis |
|---|---|---|---|
| Ed25519 private key custody | YES | NO | W8 sovereignty independence |
| Signing operation execution | YES | NO | Provenance non-subordination |
| Signing attestation generation | YES | YES (attestation transmission only) | HSM-3 |
| Public key registration | NO | YES | `wave8_signer_resolution` is software-managed |
| Signature verification | NO | YES (via `ed25519_verify()` extension) | Verification is Wave 8 enforcement, not signing |
| Signer lineage management | NO | YES | `wave8_signer_resolution` and `delegated_signing_grants` |
| Canonicalization schema selection | NO | YES | `canonicalization_registry` |
| HSM administrative access | Separate authority | NOT Wave 4 runtime | HSM-4 |

---

## Part VII: Execution Token Semantics

### 7.1 Definition

An execution token is a constitutionally authorized runtime credential that establishes Wave 4 operational authority for a specific operation or sequence of operations within a defined time and scope boundary. Execution tokens govern which runtime actors may initiate operations on Wave 4 enforcement surfaces.

### 7.2 Execution Token Constitutional Requirements

**ET-1. Scope boundedness:** An execution token must define the specific operation class, table scope, and time window for which it confers Wave 4 operational authority. Unbounded execution tokens — tokens that confer Wave 4 authority for any operation, any table, or any duration — are constitutionally impermissible.

**ET-2. Non-self-issuance:** An execution token may not be issued by the same runtime process that will use it. Token issuance must be performed by a constitutionally distinct authority surface, not by the operational process requesting the authority.

**ET-3. Wave 8 independence:** An execution token confers Wave 4 operational authority only. It does not confer Wave 8 signing authority. A runtime process holding a valid execution token may initiate a record write; it may not apply a Wave 8 cryptographic signature using the token as a signing credential.

**ET-4. Non-transferability:** An execution token issued to a specific runtime actor may not be transferred to, reused by, or presented by a different runtime actor. Token validity is actor-bound.

**ET-5. Revocability:** Execution tokens must be revocable by the issuing authority prior to their expiry. Revocation must take effect immediately upon recording in the applicable token authority surface.

### 7.3 Prohibited Execution Token Uses

**ET-P1.** An execution token may not be used as a Wave 8 signing credential.

**ET-P2.** An execution token may not authorize a record to bypass Wave 4 enforcement constraints within its scope.

**ET-P3.** An execution token may not extend its own scope, duration, or authority class.

**ET-P4.** A self-authorizing execution model — where a runtime process issues itself an execution token and immediately uses it — is constitutionally prohibited as a form of Wave 4 self-authorization.

---

## Part VIII: Attestation Signature Semantics

### 8.1 Definition

An attestation signature is a cryptographic signature produced by an authorized signer within the Wave 8 signer lineage, applied to a canonicalized record, that establishes the record's Wave 8 provenance. Attestation signatures are the constitutional mechanism by which Wave 8 provenance authority is expressed on individual records.

### 8.2 Attestation Signature Requirements

**AS-1. Authorized signer requirement:** An attestation signature is constitutionally valid only if it was produced by a signer whose public key is registered in `wave8_signer_resolution` as authorized for the record class being signed.

**AS-2. Canonicalization requirement:** The signature must be applied to the canonicalized form of the record, as defined by the canonicalization schema version registered in `canonicalization_registry` for the applicable record class and constitutional moment. Signatures applied to non-canonical forms are Wave 8 inadmissible.

**AS-3. Algorithm requirement:** Attestation signatures must use Ed25519. Signatures produced under alternative algorithms are Wave 8 inadmissible regardless of the algorithm's cryptographic strength. Algorithm substitution requires Root constitutional amendment.

**AS-4. Verifiability requirement:** An attestation signature must be verifiable using the `ed25519_verify()` PostgreSQL extension with the signer's registered public key. A signature that cannot be so verified is Wave 8 inadmissible.

**AS-5. Non-repudiability requirement:** An attestation signature must be produced such that the signing event is recorded in `signing_audit_log` (upon activation). A signature produced without a corresponding audit log entry lacks constitutional non-repudiability and is Wave 8 defective.

**AS-6. Temporal anchoring requirement:** An attestation signature must include or be associated with a timestamp recorded within the HSM attestation and transmitted to `signing_audit_log`. Signatures without temporal anchoring cannot be ordered within the hash chain and are Wave 8 inadmissible.

### 8.3 Invalid Attestation Signature Patterns

| Pattern | Constitutional Status | Reason |
|---|---|---|
| Signature produced by unauthorized signer | Wave 8 FAIL | AS-1 violation |
| Signature applied to non-canonical record form | Wave 8 FAIL | AS-2 violation |
| HMAC-SHA256 signature (non-Ed25519) | Wave 8 FAIL | AS-3 violation |
| Signature verifiable only by runtime-managed key (not HSM-held) | Wave 8 FAIL | HSM-1 violation |
| Signature present but `ed25519_verify()` not installed | Wave 8 FAIL | AS-4 violation; shadow authority surface |
| Placeholder hash (`PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix) | Wave 8 FAIL | AS-4 violation; no verifiable signature |
| Stub `verify_ed25519_signature` returning `true` unconditionally | Constitutional defect | Shadow authority surface per W8-S1 |
| Signature with no corresponding audit log entry | Wave 8 defective | AS-5 violation |

---

## Part IX: Signer Lineage

### 9.1 Definition

Signer lineage is the constitutional chain of signing authority that traces the authorization of every record's signer from the record back to a trust root. Signer lineage is the Wave 8 analogue of legal title chains: just as title chains establish property ownership through a traceable sequence of authorized transfers, signer lineage establishes cryptographic provenance through a traceable sequence of authorized signing authorizations.

### 9.2 Signer Lineage Structure

**SL-1. Trust root:** Every signer lineage chain must terminate at a trust root — a constitutional authority that is defined in Wave 8 Sovereignty Doctrine as a self-authorizing signing root. The trust root's public key is the Wave 8 chain's constitutional anchor.

**SL-2. Lineage traceability requirement:** Every signer authorized in `wave8_signer_resolution` must be traceable to the trust root through a chain of `delegated_signing_grants` entries (upon activation). A signer whose authorization cannot be traced to the trust root is constitutionally unauthorized.

**SL-3. Delegation depth:** Delegation chains within the signer lineage must not exceed the depth defined in governing Wave 8 Sovereignty Doctrine. Deep delegation chains increase revocation complexity and are constitutionally bounded.

**SL-4. Revocation propagation:** Revocation of a signer's authorization propagates to all signers authorized by that signer through `delegated_signing_grants`. Records signed by a revoked signer after the revocation event are Wave 8 inadmissible from the revocation event forward. Records signed before the revocation event retain their Wave 8 admissibility status as of their signing time.

**SL-5. Key rotation continuity:** When a signer's signing key is rotated (old key retired, new key activated), the signer lineage entry in `wave8_signer_resolution` must be updated to reflect the new key while retaining the historical record of the old key for replay purposes. Old-key entries must not be deleted; they must be marked as retired with a retirement timestamp. Replay of records signed under the old key requires the old key's public key to remain in the lineage record.

**SL-6. Lineage completeness at replay time:** At the time of replay verification, the complete signer lineage from the signing event's signer to the trust root must be reconstructable from `wave8_signer_resolution` and `delegated_signing_grants` records as they existed at the time of the signing event, not as they exist at the time of replay.

### 9.3 Signer Lineage Diagram

```
Trust Root (self-authorizing, HSM-anchored)
    │
    │ (authorizes via delegated_signing_grants)
    ▼
Primary Signer (registered in wave8_signer_resolution)
    │
    │ (may authorize via delegated_signing_grants, bounded by SL-3)
    ▼
Delegate Signer (registered in wave8_signer_resolution)
    │
    ▼
Attestation Signature on Record
    │
    ▼
wave8_cryptographic_enforcement validates:
  - Signer registered for record class (wave8_signer_resolution)
  - Signature verifiable by ed25519_verify() (AS-4)
  - Signer traceable to trust root (SL-2)
  - Hash chain anchored to prior record (CP-3)
  - Canonicalization version registered (CP-4)
```

---

## Part X: Replay Trust Roots

### 10.1 Definition

A replay trust root is the constitutional anchor from which Wave 8 replay verification begins. It is the earliest point in the hash chain from which a complete, cryptographically continuous replay path can be constructed forward to the record under verification. The trust root is not simply the first record in the database; it is the constitutionally designated anchor point whose provenance is self-validating by constitutional definition.

### 10.2 Replay Trust Root Requirements

**RT-1. Constitutional designation:** A replay trust root must be constitutionally designated in Wave 8 Sovereignty Doctrine. It may not be arbitrarily selected by the replay process at replay time.

**RT-2. Self-validation:** The trust root's own cryptographic validity is established by its constitutional designation, not by verification against a prior record in the hash chain. The trust root is the chain's starting point; it has no prior record.

**RT-3. Immutability:** Once designated, a replay trust root's record may not be modified, deleted, or superseded without a Root constitutional amendment that explicitly addresses the transition from the prior trust root to the new trust root and provides a replay-safe migration path.

**RT-4. Multiplicity restriction:** A single hash chain may have only one active trust root at any point in constitutional time. Trust root transitions must be executed through constitutional amendment with explicit chain continuity provisions.

**RT-5. Trust root replay obligation:** The trust root record itself is subject to replay obligation. Its own cryptographic integrity must be verifiable at replay time without reference to any prior record in its own chain.

### 10.3 Replay Reconstruction Obligation

**RR-1. Forward reconstructability:** From any trust root, it must be possible to reconstruct the complete hash chain forward to any specified record in the chain. This requires that no hash chain link has been broken, no record has been deleted, and no record's hash value has been altered.

**RR-2. Historical signer availability:** Replay reconstruction requires that the public keys of all signers who signed records in the replay window be available in the `wave8_signer_resolution` historical record as it existed at the time of signing. Retired key entries must not be deleted.

**RR-3. Historical canonicalization availability:** Replay reconstruction requires that the canonicalization schema version used to produce each signing hash in the replay window be available in `canonicalization_registry` as it existed at the time of signing.

**RR-4. External verifier independence:** Replay reconstruction must be executable by a verifier who has access only to: the constitutional record (migration tip schema), the Wave 8 signer registry historical state, the canonicalization registry historical state, and the hash chain records. Replay must not require access to runtime secrets, runtime state, or runtime infrastructure. This is the external verification survivability obligation.

---

## Part XI: External Verification Survivability

### 11.1 Definition

External verification survivability is the constitutional requirement that Symphony's evidentiary record remains verifiable by a constitutionally authorized external verifier — independently of Symphony's runtime infrastructure — at any point in time, including after Symphony's operational runtime is unavailable, after system migrations, and after constitutional phase transitions.

### 11.2 External Verifier Independence Requirements

**EV-1. Runtime independence:** External verification must not require the runtime execution of Symphony's Wave 4 enforcement surfaces. Verification is a Wave 8 function performed against the constitutional record. Wave 4 runtime availability is not a precondition for Wave 8 external verification.

**EV-2. Credential independence:** External verification must not require access to any private key, HSM credential, or runtime secret. Verification requires only: the public keys registered in `wave8_signer_resolution` (historical), the canonicalization schemas registered in `canonicalization_registry` (historical), and the records in the hash chain.

**EV-3. Infrastructure independence:** External verification must be performable using only the `ed25519_verify()` algorithm applied to the available public keys and canonical record forms. It must not require Symphony-specific software, Symphony-specific network access, or Symphony-specific runtime services.

**EV-4. Temporal independence:** External verification must be performable at any time after the signing event. Signatures must not have embedded time-to-live constraints or runtime-dependent validity windows that make them unverifiable after a certain period.

**EV-5. Regulator domain independence:** External verification performed by a verifier designated by one regulator domain must not depend on infrastructure controlled by another regulator domain. Each regulator domain's external verification capability must be constitutionally self-sufficient.

### 11.3 External Verification Survivability Obligations

The following constitutional obligations ensure external verification survivability:

**EVS-1.** `wave8_signer_resolution` records must be retained in full historical form, including retired entries, in perpetuity. Deletion of any `wave8_signer_resolution` record breaks external verification survivability for all records signed by the deleted signer.

**EVS-2.** `canonicalization_registry` records must be retained in full historical form, including all historical schema versions, in perpetuity. Deletion of any canonicalization schema version breaks external verification survivability for all records signed under that version.

**EVS-3.** The `ed25519_verify()` algorithm must remain the constitutionally designated verification algorithm. Algorithm substitution requires Root constitutional amendment with explicit provisions for the survivability of records signed under the prior algorithm.

**EVS-4.** The hash chain records (`state_transitions.transition_hash`, `asset_batches` signing fields, and analogous fields in other constitutionally designated record classes) must be preserved without alteration in perpetuity.

**EVS-5.** `historical_verification_runs`, `archive_verification_runs`, and `resign_sweeps` constitute the infrastructure for periodic external verification. Their constitutional activation is a Wave 8 obligation. Prior to activation, external verification must be performable through direct hash chain traversal as defined in RR-1 through RR-4.

---

## Part XII: Prohibited Authority Architectures

The following authority architectures are constitutionally prohibited in Symphony's cryptographic and runtime design:

### 12.1 Runtime Self-Signing

**Definition:** A runtime self-signing architecture is one in which the Wave 4 operational runtime process generates, holds, and applies Ed25519 signing keys without HSM separation.

**Prohibition basis:** Runtime self-signing collapses Wave 4 and Wave 8 sovereignty into a single process. A process that both processes records (Wave 4) and signs them (Wave 8) without external boundary constitutes a single-sovereignty model, eliminating Wave 8's independence. The mutual veto semantics of Part III require that Wave 8 determinations be made by an authority independent of the Wave 4 runtime. Self-signing eliminates that independence.

### 12.2 Provenance Bypass of Operational Legality

**Definition:** An architecture in which Wave 8 cryptographic validity is treated as sufficient to admit a record that has failed Wave 4 operational enforcement constraints.

**Prohibition basis:** This is the FAIL/PASS scenario defined in Section 3.4. Wave 8 authority does not override Wave 4 authority. A cryptographically valid record that violates operational constraints is operationally inadmissible. Provenance does not authorize operational illegality.

### 12.3 Provenance/Runtime Collapse

**Definition:** An architecture that treats Wave 4 and Wave 8 as a single unified sovereignty layer, where a single determination covers both operational and provenance validity, or where one surface's determination is treated as implying the other's.

**Prohibition basis:** This is the foundational architectural prohibition of this document. Wave 4 and Wave 8 are constitutionally orthogonal. Their coexistence-through-boundary-definition model requires that each surface make independent determinations within its own domain. Collapse into a single layer destroys the constitutional architecture. See NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, Patterns PI-1, PI-7, PI-8.

### 12.4 Self-Authorizing Execution Model

**Definition:** An architecture in which a runtime process determines its own Wave 4 authority level, issues its own execution tokens, and applies its own Wave 8 signing authority, constituting a fully self-authorizing system.

**Prohibition basis:** Self-authorization eliminates the constitutional separations between issuing authority and using authority (ET-2), between operational authority and signing authority (ET-3), and between Wave 4 and Wave 8 sovereignty (Part III). A self-authorizing system cannot be externally verified; it cannot produce Wave 8 determinations that are independent of Wave 4 runtime state; and it cannot satisfy the external verifier independence requirement of Part XI.

---

## Part XIII: Admissibility Implications

The cryptographic and runtime authority doctrine has the following admissibility implications:

**ADM-1.** A record is fully constitutionally admissible only upon PASS/PASS determination by both Wave 4 and Wave 8 enforcement surfaces.

**ADM-2.** A record admitted under PASS/STUB determination is operationally present but constitutionally defective in the Wave 8 dimension. Its Wave 8 defect persists. Its operational admission does not cure its Wave 8 inadmissibility.

**ADM-3.** Records admitted before `wave8_cryptographic_enforcement` was constitutionally activated on a given write path are constitutionally assessed against the enforcement that was operative at their production time. They are not retroactively subjected to Wave 8 enforcement that was not constitutionally active when they were produced.

**ADM-4.** Regulator domain admissibility for a record requires, at minimum, that the record has a PASS/PASS determination. Regulator domains may impose additional admissibility requirements beyond PASS/PASS; they may not reduce admissibility below PASS/PASS as a floor.

---

## Part XIV: Replay Implications

**REP-1.** Replay of any record in the Wave 8 hash chain requires the PASS/PASS determination for that record to be verifiable from the trust root forward.

**REP-2.** Records bearing PASS/STUB (shadow authority surface) determinations are present in the operational record but are Wave 8 provenancially defective. Their replay in the Wave 8 dimension will fail until the Wave 8 defect is remediated. Remediation requires a constitutional resign operation documented in `resign_sweeps` and `historical_verification_runs`.

**REP-3.** The signer lineage state at the time of each signing event must be reconstructable from `wave8_signer_resolution` and `delegated_signing_grants` historical records. The replay verifier uses the historical state, not the current state.

**REP-4.** External verification survivability (Part XI) is a replay obligation. Replay must be possible without Symphony's runtime infrastructure.

**REP-5.** FAIL events (Wave 4 FAIL, Wave 8 FAIL) are themselves replay-obligated constitutional records. The constitutional record of what was blocked and why must be as reconstructable as the constitutional record of what was admitted.

---

## Part XV: Sovereignty Implications

**SOV-1.** Wave 4 and Wave 8 are constitutionally orthogonal. Their coexistence requires that each make determinations within its own domain without reference to the other's determination as a precondition.

**SOV-2.** Wave 4 operational sovereignty is bounded. It does not extend into the cryptographic provenance domain. Attempts by Wave 4 enforcement surfaces to constitute themselves as Wave 8 provenance validators (as `verify_ed25519_signature` stub does in posture) are constitutional defects, not legitimate Wave 4 boundary expansions.

**SOV-3.** Wave 8 provenance sovereignty is bounded. It does not extend into the operational enforcement domain. A Wave 8 PASS determination does not authorize operational admission; it satisfies one of the two required conditions for PASS/PASS admission.

**SOV-4.** The HSM boundary is the physical constitutional boundary of Wave 8 signing sovereignty. Signing key material held within the HSM boundary is under Wave 8 custody. Signing key material that has crossed the HSM boundary into software runtime is Wave 8 sovereignty-compromised.

**SOV-5.** External verifier independence is a sovereignty independence obligation. External verifiers must be constitutionally capable of operating outside both Wave 4 and Wave 8 runtime infrastructure while accessing only the constitutional record.

---

## Phase Interaction Rules

**PH-1.** In phases where Wave 8 cryptographic enforcement is constitutionally deferred (early phases before `wave8_cryptographic_enforcement` activation on a given write path), records produced on that write path are assessed against the enforcement operative at their production time. They are not retroactively subjected to Wave 8 enforcement that was not yet active.

**PH-2.** Phase transitions do not reduce Wave 8 signer lineage or trust root obligations. Signer lineage records produced during any phase must remain available for replay across all subsequent phases.

**PH-3.** The `wave8_cryptographic_enforcement` surface, once constitutionally activated on a write path, may not be deactivated by phase transition without Root constitutional amendment.

**PH-4.** The shadow authority surface classification of `verify_ed25519_signature` applies in all phases until the stub is replaced with actual `ed25519_verify()` invocation. No phase doctrine may classify the stub as constitutionally operative.

**PH-5.** Execution token scope must be phase-aware. Tokens issued within Phase N are bounded by Phase N's capability boundary. They may not authorize operations that are phase-inadmissible within Phase N.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the constitutional boundary between Wave 4 operational/runtime sovereignty and Wave 8 provenance/cryptographic sovereignty. It defines the authority surface of each, the veto semantics governing records subject to both, the HSM separation requirements, and the external verification survivability obligations.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine the substantive scope of individual regulator sovereignty domains or phase capability boundaries. It governs the Wave 4 / Wave 8 dual-sovereignty architecture; it does not define regulator domain admissibility standards or phase capability definitions.

**Replay obligations preserved by this document:**
This document preserves replay obligations through: the replay trust root requirements (Part X), the replay reconstruction obligation (Section 10.3), the external verification survivability obligations (Part XI, EVS-1 through EVS-5), the requirement that FAIL events are replay-obligated constitutional records (REP-5), and the prohibition on stub-based signing being treated as Wave 8 compliance (REP-2).

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator orthogonality. The PASS/PASS determination is a constitutional floor for regulator admissibility; each regulator domain independently determines whether additional requirements beyond PASS/PASS apply within its domain.

**Phases this document applies to:**
GLOBAL. This document applies across all phases. Phase-specific interaction rules (PH-1 through PH-5) define how this document's provisions operate within phase-specific contexts without creating phase-specific exceptions to the underlying doctrine.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10 (ROOT). Any lower-rank document that redefines Wave 4 or Wave 8 sovereignty, alters mutual veto semantics, or reclassifies the shadow authority surface constitutes a constitutional defect.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, CI gate definitions, operational artifacts, declarative substrate, repository observations, AI syntheses, and NotebookLM outputs are prohibited from reinterpreting the Wave 4 authority boundary, Wave 8 authority boundary, mutual veto semantics, PASS/PASS / PASS/FAIL / FAIL/PASS determination outcomes, HSM boundary rules, execution token semantics, attestation signature requirements, signer lineage doctrine, replay trust root requirements, external verification survivability obligations, and prohibited authority architectures defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Wave 4 and Wave 8 are the same layer with different names:**
Wave 4 and Wave 8 are constitutionally distinct sovereignty surfaces with non-overlapping authority boundaries, independent determination mechanisms, and mutual veto semantics. They are not two names for the same enforcement layer. Treating them as equivalent, redundant, or interchangeable constitutes a sovereignty collapse that is constitutionally prohibited.

**Invalid simplification — PASS/FAIL means "retry with better signing":**
A PASS/FAIL determination (Wave 4 PASS, Wave 8 FAIL) means the record is constitutionally blocked. It does not mean the record is held pending Wave 8 correction and will be admitted upon resubmission with a valid signature. The record in its blocked form is not admitted. A corrected record is a new record subject to fresh Wave 4 and Wave 8 enforcement.

**Invalid simplification — Stub verification is acceptable during development phases:**
The `verify_ed25519_signature` stub is a constitutional defect in all phases. It is not an acceptable transitional state for development, testing, or early phase operation. Its classification as a shadow authority surface applies immediately and unconditionally. No phase doctrine or enforcement doctrine may reclassify it as acceptable.

**Forbidden authority collapse — Wave 4 runtime accepts the record, therefore it is valid:**
Wave 4 runtime acceptance establishes Wave 4 operational admissibility only. It does not establish Wave 8 provenance validity. A record accepted by Wave 4 runtime that has not been validated by Wave 8 cryptographic enforcement is constitutionally defective in the Wave 8 dimension. The Wave 4 runtime's acceptance does not cure the Wave 8 defect.

**Forbidden authority collapse — HSM signs the record, therefore it passes Wave 4:**
Wave 8 HSM signing establishes Wave 8 provenance validity only. It does not establish Wave 4 operational admissibility. A record bearing a valid HSM signature that fails Wave 4 enforcement constraints is a FAIL/PASS determination and is constitutionally blocked. HSM signing does not override Wave 4 enforcement.

**Replay-destructive interpretation — Replay needs only the current signer registry:**
Replay reconstruction requires the signer lineage state as it existed at the time of each signing event, not the current state. Retired signer entries and retired public keys must remain in the historical record. Purging retired entries from `wave8_signer_resolution` destroys replay survivability for records signed under those entries.

**Replay-destructive interpretation — Placeholder records can be retroactively signed:**
Records bearing `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix values cannot be retroactively signed without a constitutional resign operation documented in `resign_sweeps`. The original placeholder record's Wave 8 defect cannot be cured by simply adding a signature field after the fact. The resign operation must produce a new, constitutionally documented re-signing event in the signer lineage and audit trail.

**Regulator-flattening interpretation — PASS/PASS means universally admissible:**
PASS/PASS is the constitutional floor for admissibility. It does not constitute universal admissibility across all regulator domains. Each regulator domain evaluates admissibility against its own requirements independently, using PASS/PASS as a minimum necessary condition, not as a sufficient condition.

**Provenance/runtime collapse — Operational consensus constitutes Wave 8 validation:**
Agreement among multiple Wave 4 runtime nodes that a record is valid does not constitute Wave 8 cryptographic provenance validation. Wave 8 validation requires cryptographic signature verification by `ed25519_verify()` against the signer's registered public key. Operational consensus is not a cryptographic mechanism and carries no Wave 8 authority.

**Convergence misreading — Wave 4 and Wave 8 will eventually merge into a single enforcement layer:**
Wave 4 and Wave 8 are constitutionally designed as permanently orthogonal sovereignty surfaces. Their coexistence-through-boundary-definition architecture is not a transitional state en route to a unified single layer. They are not converging. Their parallel, independent operation is the constitutionally correct steady state.
