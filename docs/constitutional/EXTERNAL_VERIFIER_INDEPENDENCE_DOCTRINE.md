# EXTERNAL VERIFIER INDEPENDENCE DOCTRINE

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 9
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/contracts/ED25519_SIGNING_CONTRACT.md
  - docs/contracts/TRANSITION_HASH_CONTRACT.md
  - docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md
  - docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md
  - docs/architecture/SIGNATURE_METADATA_STANDARD.md
  - docs/security/KEY_MANAGEMENT_POLICY.md

---

## 1. Purpose

This doctrine establishes the constitutional principles governing the independence
of external verifiers from Symphony's runtime infrastructure. It defines verifier
sovereignty as a first-order constitutional property, not a design convenience or
audit accommodation.

External verifier independence is the guarantee that any entity possessing
persisted evidence artifacts — including regulators, counterparties, auditors,
judicial bodies, and foreign jurisdiction authorities — may independently
reconstruct, verify, and adjudicate the authenticity and authority provenance of
any signed event without access to Symphony's runtime, key custody infrastructure,
signer resolution services, or operational trust hierarchy.

This doctrine is binding on all phases, all waves, all signer classes, all
evidence systems, and all admissibility surfaces within Symphony.

---

## 2. Constitutional Scope

This doctrine governs:

- the completeness obligations of all persisted evidence artifacts
- the independence requirements for cryptographic verification
- the offline verification legal standing of all signed transitions and asset batches
- the replay survivability obligations across key rotation, key revocation, and
  signer decommission events
- the regulator-side replay capability as a sovereignty-preserving right
- the cross-jurisdiction admissibility of persisted evidence
- the obligations of evidence artifact designers to anticipate external verifier
  needs at artifact creation time

This doctrine does not govern:

- the internal key custody architecture of Symphony's operational runtime
- the choice of HSM vendor or KMS provider
- the internal trigger ordering of runtime enforcement functions
- the internal RLS posture of operational tables
- the wave-by-wave delivery sequence of runtime enforcement surfaces

---

## 3. Verifier Sovereignty

### 3.1 Definition

A verifier is externally sovereign when it possesses the constitutional right and
the practical means to verify the authenticity and authority provenance of a
signed evidence artifact using only:

1. the persisted evidence artifact itself,
2. the declared public verification key associated with the signing key identifier
   and key version recorded in that artifact,
3. the canonicalization procedure identified in the artifact's metadata, and
4. the signing contract version identified in the artifact's metadata.

External verifier sovereignty is violated when any of the following conditions
holds:

- the verification requires a live query to Symphony's signer resolution surface,
- the verification requires access to Symphony's operational database,
- the verification requires a trust relationship with Symphony's certificate
  authority or key management infrastructure,
- the verification requires knowledge of internal Symphony system state that is
  not persisted in the evidence artifact, or
- the verification requires execution of Symphony's runtime code paths.

### 3.2 Sovereignty as Constitutional Constraint

Verifier sovereignty is not a post-hoc audit feature. It is a design constraint
on every evidence artifact produced by Symphony. Artifact designers MUST treat
the following question as a first-class requirement at design time:

> Can an entity possessing only this artifact and the declared public key
> independently verify the artifact's authenticity and authority provenance
> without any runtime dependency on Symphony?

If the answer is no, the artifact design is constitutionally non-compliant
regardless of its runtime enforcement properties.

### 3.3 Sovereignty Scope Boundaries

Verifier sovereignty applies independently within each of the following domains:

- **State transition signatures** (governed by ED25519_SIGNING_CONTRACT.md):
  sovereignty requires that every required field of the signed payload is
  persisted in recoverable form, that the canonicalization version is explicitly
  identified, and that the key identifier and key version are persisted with
  sufficient resolution to retrieve the public key from an archive key store.

- **Asset batch signatures** (Wave 8 boundary): sovereignty requires that the
  canonical payload bytes are persisted, that the signer key identifier and key
  version are persisted, and that the signing algorithm is explicitly identified.

- **Evidence packs** (future activation): sovereignty requires that each evidence
  pack carries its own signing metadata sufficient for independent verification
  without reference to the evidence pack's parent session context.

- **Batch and Merkle artifacts**: sovereignty requires that `merkle_root`,
  `leaf_index`, and `merkle_proof` are persisted as part of the artifact, enabling
  membership verification without access to the full batch.

---

## 4. Replay Without Runtime Trust

### 4.1 Constitutional Replay Obligation

Replay verification is the act of reconstructing the verification result for a
past signed event from persisted evidence alone. Symphony's constitutional
obligation is that every accepted signed artifact MUST be replayable to its
original verification outcome without runtime trust.

This obligation is mechanically grounded in ED25519_SIGNING_CONTRACT.md §13,
which states:

> Replay verification MUST be possible from persisted artifacts alone. The system
> MUST persist or be able to deterministically reconstruct every field in the
> signed payload, algorithm, key_id, key_version, canonicalization_version,
> signing_contract_version, the encoded signature bytes, and the exact persisted
> occurred_at used at signing time.

The phrase "persisted artifacts alone" is a sovereignty declaration. It means the
replay does not depend on Symphony's runtime state at the time of replay.

### 4.2 Replay Completeness Requirements

For replay to succeed without runtime trust, the following MUST be persistently
available for every signed artifact:

**From the evidence artifact itself:**
- `algorithm` — the signing algorithm; MUST be `Ed25519` for signing contract v1
- `key_id` — the identifier of the signing key
- `key_version` — the version of the signing key
- `canonicalization_version` — the canonicalization procedure used; MUST be
  `JCS-RFC8785-V1` for signing contract v1
- `signing_contract_version` — the version of the signing contract; MUST be `1`
- `signature` — the base64url-encoded signature bytes
- `occurred_at` — the exact persisted UTC timestamp used at signing time; MUST be
  immutable after first persistence

**Reconstructible from persisted authoritative inputs:**
- `project_id`, `entity_type`, `entity_id`, `from_state`, `to_state`,
  `execution_id`, `interpretation_version_id`, `policy_decision_id`,
  `transition_hash` — all fields of the signed payload, reconstructible from
  the authoritative transition record without runtime service calls

**From the archive key store (not the live operational key store):**
- the public key bytes corresponding to `key_id` and `key_version`
- the key authorization scope for `project_id`
- the key activation and deactivation timestamps sufficient to establish that the
  key was active at `occurred_at`

### 4.3 Replay Independence From Key Lifecycle State

Replay verification MUST succeed for artifacts signed by keys that have
subsequently been rotated, superseded, or deactivated, provided that the key
was active at the time of signing.

The following constraints MUST NOT be applied during replay verification of
historical artifacts:

- the requirement that the key currently be `is_active = true`
- the requirement that the key not currently be `superseded`
- the requirement that `valid_until` be in the future at the time of replay

Replay verification MUST apply only the key lifecycle state that was valid at
the time of the artifact's `occurred_at` timestamp, not the key lifecycle state
at the time of replay.

This principle is the historical key lifecycle independence guarantee. Its
constitutional basis is the recognition that key rotation and revocation are
operational events that MUST NOT retroactively invalidate lawfully signed
historical evidence.

### 4.4 The Archive Key Store Obligation

Because replay independence from key lifecycle state requires access to public
keys for keys that may no longer be active in the operational key store,
Symphony MUST maintain an archive key store that:

- retains the public key bytes for every key that has ever been used to produce
  an accepted signed artifact,
- retains the key authorization scope (project binding) for each such key,
- retains the validity window (`valid_from`, `valid_until` or deactivation
  timestamp) for each such key,
- is queryable by `key_id` and `key_version`,
- is append-only with respect to key records (no deletion of historically active
  key records), and
- is accessible to authorized verifiers without requiring access to Symphony's
  live operational signer resolution surface.

The `historical_verification_runs` and `archive_verification_runs` tables
(migration 0065, migration 0066) represent the scaffolded schema reservation for
this obligation. Their current dormant status is a deferred activation, not an
indication that this obligation does not exist. The obligation exists at doctrine
level from Phase-0 forward.

The KEY_MANAGEMENT_POLICY.md explicitly states:
> Evidence already produced must remain verifiable: evidence should include key
> identifiers so verifiers can determine which key was used; verification material
> for historical evidence must be retained per retention policy.

This policy statement is the operational instantiation of the archive key store
obligation. It is binding regardless of the current implementation status of the
archive verification tables.

---

## 5. Offline Verification Legal Standing

### 5.1 Definition of Offline Verification

Offline verification is verification performed without any network connection to
Symphony's runtime infrastructure, without access to Symphony's operational
database, and without any trust relationship with Symphony's key management
services.

An offline verifier possesses:

- one or more evidence artifacts in their persisted form,
- the public key material corresponding to the `key_id` and `key_version`
  declared in each artifact (obtained from the archive key store prior to going
  offline, or obtained from a regulator-maintained key registry), and
- a standard Ed25519 verification implementation conforming to RFC 8032.

### 5.2 Legality of Offline Verification

Offline verification is constitutionally legal for all signed artifacts in
Symphony. It is not a degraded or exception mode. It is a primary verification
path with equal constitutional standing to online verification against Symphony's
live signer resolution surface.

The constitutional basis for this standing is the determinism requirement of the
signing contract. ED25519_SIGNING_CONTRACT.md §3 states:

> verification is independent of whitespace, key ordering, and serializer choice
> replay verification is possible from persisted artifacts alone

These properties are not implementation conveniences. They are the mechanism by
which offline verification achieves legal standing: a verifier who follows the
published canonicalization procedure and uses the declared public key will reach
the same verification outcome as Symphony's own runtime, without any dependency
on that runtime.

### 5.3 Offline Verification Procedure

An offline verifier MUST perform the following steps:

1. Assert all required metadata fields are present in the artifact:
   `algorithm`, `key_id`, `key_version`, `canonicalization_version`,
   `signing_contract_version`, `signature`.

2. Assert `algorithm = Ed25519` and `signing_contract_version = 1`.

3. Obtain the public key bytes for `key_id` and `key_version` from the archive
   key store or a regulator-maintained key registry.

4. Assert that the public key's authorization scope includes the `project_id`
   declared in the signed payload.

5. Assert that the key was active at the `occurred_at` timestamp declared in the
   artifact, using the archived key validity window.

6. Reconstruct the signed payload from the persisted field values in their
   authoritative persisted form. The reconstructed payload MUST contain exactly
   the fields declared in ED25519_SIGNING_CONTRACT.md §5, with `occurred_at` taken
   from its persisted value and not regenerated.

7. Canonicalize the reconstructed payload using RFC 8785 (JCS) and encode as
   UTF-8 bytes.

8. Decode the `signature` field from base64url without padding.

9. Verify the Ed25519 signature over the canonical UTF-8 bytes using the public
   key obtained in step 3.

10. Return success only if all preceding steps succeed.

An offline verifier following this procedure is constitutionally entitled to treat
a successful verification result as equivalent to an authoritative verification
by Symphony's own runtime.

### 5.4 Offline Verification of transition_hash

Because `transition_hash` is a required field in the signed payload, and because
it is deterministically derived from authoritative inputs per
TRANSITION_HASH_CONTRACT.md, an offline verifier MAY independently recompute
`transition_hash` from the persisted authority tuple fields and verify that it
matches the value in the signed payload.

Recomputation of `transition_hash` by an offline verifier is a secondary
verification layer beyond signature verification. Its constitutional value is that
it proves the signed hash was derived from the declared authority inputs and was
not injected.

---

## 6. External Trust-Root Reconstruction

### 6.1 The Trust-Root Reconstruction Problem

A Symphony evidence artifact carries `key_id` and `key_version` but does not
carry the public key bytes inline. This is by design: inline public keys are
mutable by the artifact producer and cannot be independently verified without a
trust anchor.

The external trust-root reconstruction problem is: given only an evidence
artifact, how does an external verifier establish a trust anchor for the public
key corresponding to `key_id` and `key_version`?

### 6.2 Reconstruction Paths

Symphony recognizes three constitutionally valid reconstruction paths:

**Path 1 — Archive Key Store Access:**
The verifier obtains the public key from Symphony's archive key store by
presenting `key_id` and `key_version`. This path requires a one-time online
interaction with Symphony's archive service to retrieve public key material but
does not require any ongoing trust relationship. Once the public key is obtained
and independently stored by the verifier, all subsequent verifications against
that key are offline.

**Path 2 — Regulator Key Registry:**
The verifier obtains the public key from a regulator-maintained key registry into
which Symphony has published its active and historical public keys. This path
requires no trust relationship with Symphony at verification time. The trust
anchor is the regulator's publication act, not Symphony's runtime assertion.

This path represents the regulator-partitioned trust architecture in which
Symphony's public key material is a regulated publication obligation, not a
runtime service dependency.

**Path 3 — Prior-Authenticated Key Delivery:**
The verifier obtained the public key directly from Symphony through a prior
authenticated channel (e.g., bilateral agreement, onboarding protocol) and has
independently stored it. Verification against this independently stored key
requires no runtime interaction with Symphony.

### 6.3 Trust-Root Reconstruction Obligations

Symphony MUST support trust-root reconstruction through at least Path 1 for all
signing key classes. Symphony SHOULD support Path 2 for all key classes used to
sign evidence with regulatory admissibility obligations (EASK and PCSK class keys
as defined in the key class taxonomy).

The `public_keys_registry` table (migration 0165) is the scaffolded schema
reservation for the publication surface that enables Paths 1 and 2. Its current
dormant status does not relieve Symphony of the underlying constitutional
obligation. The obligation exists from the moment the first signed artifact is
accepted by the runtime.

### 6.4 Trust Chain Reference

The `trust_chain_ref` field in the SIGNATURE_METADATA_STANDARD is the mechanism
by which an artifact declares which of the above reconstruction paths is
applicable and where the relevant trust anchor material may be retrieved.

An evidence artifact that carries a `trust_chain_ref` is providing a
verifier-navigable path to its trust root. This field MUST be populated for all
artifacts with regulatory admissibility obligations.

An evidence artifact whose `trust_chain_ref` is absent or null is constitutionally
non-compliant with the external verifier independence requirement for regulatory
admissibility contexts.

---

## 7. Independent Provenance Validation

### 7.1 Provenance Independence as a Sovereignty Property

Provenance validation is the act of establishing that a signed event was
produced by the declared authority under the declared conditions. Independent
provenance validation means that this establishment is achievable without trusting
Symphony's runtime assertions about what occurred.

The constitutional basis for provenance independence in Symphony is the
data-authority derivation architecture defined in DATA_AUTHORITY_DERIVATION_SPEC.md.
The `data_authority` fingerprint is a deterministic SHA-256 digest over the
canonicalized authority tuple including `execution_id`, `interpretation_version_id`,
`policy_decision_id`, `transition_hash`, and `signature_verification_result`.

An external verifier can independently validate provenance by:

1. Recomputing `transition_hash` from the declared authority tuple fields.
2. Recomputing `data_authority` from the full authority tuple including the
   recomputed `transition_hash` and the stated `signature_verification_result`.
3. Comparing the recomputed `data_authority` against the persisted value.
4. Verifying the Ed25519 signature as defined in §5.3 above.

Successful completion of all four steps establishes independent provenance
validation without any trust in Symphony's runtime assertions.

### 7.2 The Non-Collapse of Provenance and Runtime Authority

Independent provenance validation does not depend on establishing trust in
Symphony's runtime authority surfaces (signer resolution function, authorization
matrix, execution records table). An external verifier who successfully completes
the independent provenance validation procedure has established:

- that the signed payload was canonicalized correctly,
- that the signature was produced by the holder of the private key corresponding
  to the declared public key,
- that the authority tuple was internally consistent (transition hash matches
  declared fields), and
- that the data_authority fingerprint matches the authority tuple.

The external verifier does NOT thereby establish:

- that Symphony's internal policy controls were correctly followed at the time of
  signing,
- that the actor who caused the signing was the actor entitled to cause it, or
- that the delegated signing grant (if any) was validly issued.

These latter properties require access to Symphony's internal authority surfaces
and are constitutionally within Symphony's operational sovereignty, not within the
external verifier's independent domain. This is the correct constitutional
boundary: external verifiers can prove what was signed and by whom (cryptographic
provenance), but not why the platform was authorized to execute the signing
(operational authority provenance).

---

## 8. Regulator-Side Replay Capability

### 8.1 Regulatory Replay as Sovereign Right

A regulator with jurisdiction over any of Symphony's operational domains possesses
the sovereign right to independently replay verification of any signed artifact
within its jurisdiction without cooperation from Symphony's runtime.

This right is a consequence of verifier sovereignty (§3) and is not conditional
on:

- Symphony's cooperation,
- Symphony's operational status,
- the current lifecycle state of the signing key,
- the current operational state of Symphony's signer resolution surface, or
- the jurisdiction in which the verification is conducted.

### 8.2 Regulator Replay Obligations on Symphony

Symphony's constitutional obligations toward regulator-side replay capability are:

**Obligation R-1 — Artifact Completeness:**
Every signed artifact produced by Symphony MUST contain, or be accompanied by, all
fields necessary for an offline verifier to reconstruct the signed payload and
verify the signature per §5.3 above. Artifacts that require a live Symphony query
to reconstruct signed payload fields are constitutionally non-compliant.

**Obligation R-2 — Key Publication:**
Symphony MUST maintain a mechanism by which regulators may obtain the public key
bytes for any `key_id` and `key_version` referenced in any evidence artifact
within the regulator's jurisdiction. This mechanism MUST remain operational
throughout the regulatory retention period applicable to the jurisdiction, which
is no less than the period declared in the AUDIT_LOGGING_RETENTION_POLICY.md.

**Obligation R-3 — Canonicalization Stability:**
The canonicalization procedure identified by `canonicalization_version` in a
signed artifact MUST remain publicly documented and independently implementable
throughout the regulatory retention period. Symphony MUST NOT deprecate or
withdraw the specification of any canonicalization version referenced in any
artifact still within its regulatory retention window.

The `canonicalization_registry` table (migration 0065) with its `immutable` flag
and `deprecated_at` timestamp is the scaffolded reservation for enforcement of
Obligation R-3. Its dormant status does not relieve Symphony of this obligation.

**Obligation R-4 — Cross-Jurisdiction Portability:**
Signed artifacts produced by Symphony MUST be verifiable under the legal
evidentiary standards of any jurisdiction in which they may be presented. The
choice of Ed25519 as the sole accepted signature algorithm satisfies this
obligation because Ed25519 (RFC 8032) is a published, royalty-free, independently
implementable standard with no jurisdiction-specific dependencies.

**Obligation R-5 — Replay Evidence Retention:**
Symphony MUST retain, for the applicable regulatory retention period:
- the persisted value of `occurred_at` for every signed transition,
- the full authority tuple for every signed transition,
- the `data_authority` fingerprint for every signed transition,
- all signature metadata fields declared in SIGNATURE_METADATA_STANDARD.md,
- the archive key store records sufficient to verify signatures produced by any
  key used during the retention period.

### 8.3 Regulator Partitioning and Replay

Regulators are orthogonal sovereign domains. A regulator with jurisdiction over
Green Finance instruments is not the same regulator as one with jurisdiction over
payment settlement finality, and neither has jurisdiction over the other's
domain.

This orthogonality has a direct implication for replay: a Green Finance regulator
MAY replay evidence from Green Finance-domain asset batches without access to the
payment settlement finality evidence store, and vice versa. Symphony's evidence
architecture MUST not structurally couple these domains in a way that makes
independent domain-scoped replay impossible.

The Wave 8 authority boundary at `asset_batches` (defined in
DATA_AUTHORITY_SYSTEM_DESIGN.md §17) is consistent with this principle: the
Green Finance sovereign domain has its own authoritative write boundary, its own
signing surface, and its own attestation gate, structurally independent of the
payment outbox and settlement finality surfaces.

---

## 9. Verifier Independence Guarantees

The following guarantees are constitutionally binding on Symphony's evidence
architecture:

**VIG-1 — Payload Reconstructibility:**
The complete signed payload for any accepted transition or asset batch MUST be
reconstructible from persisted authoritative records without runtime service
calls.

**VIG-2 — Key Archive Permanence:**
Public key bytes for any signing key that has produced an accepted artifact MUST
be retained in archive storage for the full applicable regulatory retention period.
Operational key deactivation, rotation, or revocation MUST NOT cause deletion of
the corresponding public key archive record.

**VIG-3 — Algorithm Stability:**
The signing algorithm declared in any accepted artifact MUST remain independently
implementable and publicly documented for the full applicable regulatory retention
period.

**VIG-4 — Canonicalization Reproducibility:**
The canonicalization procedure declared in any accepted artifact MUST produce
identical byte output for identical inputs, independent of runtime environment,
serializer implementation choice, and locale, for the full applicable regulatory
retention period.

**VIG-5 — Historical Key Lifecycle Independence:**
A signed artifact whose key was active at `occurred_at` MUST be verifiable as
valid regardless of the current operational lifecycle state of that key.

**VIG-6 — Failure Class Transparency:**
An external verifier who encounters a verification failure MUST be able to
determine which of the declared failure classes (§10 below) applies from
information present in the artifact and the verification procedure, without
requiring Symphony to explain the failure.

**VIG-7 — Cross-Jurisdiction Portability:**
No guarantee in this list is jurisdiction-specific. All guarantees apply equally
in all jurisdictions in which Symphony evidence may be presented.

---

## 10. Failure Classes Under External Verification

An external verifier performing independent verification MUST distinguish the
following failure classes, each of which is independently diagnosable from
artifact content without runtime access:

| Failure Class | Diagnosis Source |
|---|---|
| `ARTIFACT_PAYLOAD_INCOMPLETE` | Required metadata fields absent from artifact |
| `ALGORITHM_NOT_SUPPORTED` | `algorithm` field value is not `Ed25519` |
| `SIGNING_CONTRACT_UNKNOWN` | `signing_contract_version` field value is unrecognized |
| `CANONICALIZATION_VERSION_UNKNOWN` | `canonicalization_version` field value is unrecognized |
| `PUBLIC_KEY_NOT_RETRIEVABLE` | Archive key store does not contain record for `key_id`/`key_version` |
| `KEY_NOT_ACTIVE_AT_OCCURRED_AT` | Archived key validity window excludes `occurred_at` |
| `KEY_SCOPE_MISMATCH` | Archived key authorization scope excludes `project_id` |
| `PAYLOAD_RECONSTRUCTION_FAILURE` | Required payload fields cannot be reconstructed from persisted records |
| `CANONICALIZATION_FAILURE` | Reconstructed payload cannot be canonicalized per declared procedure |
| `SIGNATURE_DECODE_FAILURE` | `signature` field is not valid base64url |
| `SIGNATURE_LENGTH_INVALID` | Decoded signature is not 64 bytes |
| `SIGNATURE_VERIFICATION_FAILED` | Ed25519 verification of canonical bytes against public key fails |
| `TRANSITION_HASH_MISMATCH` | Recomputed `transition_hash` does not match declared value |
| `DATA_AUTHORITY_MISMATCH` | Recomputed `data_authority` does not match persisted value |

Each failure class MUST be distinguishable from the others without access to
Symphony's runtime. This is the practical expression of failure class transparency
(VIG-6).

---

## 11. Phase Interaction Rules

### Phase-0 and Phase-1
The external verifier independence obligations established by this doctrine apply
from the moment the first signed artifact is accepted by any runtime path,
regardless of the development phase.

In Phase-0 and Phase-1, where the `state_transitions` signing path carries a
`PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix in `transition_hash`, the absence
of real cryptographic signatures means that the external verifier independence
guarantees (VIG-1 through VIG-7) apply as obligations against any real signed
artifact accepted by any path that does not carry the placeholder prefix.
Placeholder-prefixed artifacts are constitutionally not signed artifacts and are
excluded from the verifier independence guarantee scope.

Wave 8 asset batch artifacts that pass the attestation gate and cryptographic
enforcement function (migration 0190) ARE within the verifier independence
guarantee scope from the moment they are conditionally accepted, subject to the
activation of the `ed25519_verify()` extension.

### Phase-2 and Beyond
As the `state_transitions` signing path transitions from placeholder to real
cryptographic enforcement, every artifact newly accepted under real signing
immediately and retroactively comes within the full scope of all verifier
independence guarantees from its `occurred_at` timestamp.

There is no phase-limited grace window for verifier independence. The obligation
attaches at the moment of signing, not at some later phase gate.

---

## 12. Constitutional Self-Validation

**Sovereignty domains governed by this doctrine:**
- External verifier sovereignty over all signed evidence artifacts
- Regulator replay sovereignty within each regulator's jurisdictional domain
- Archive key store sovereignty (obligation to maintain, not to operate as Symphony runtime)

**Sovereignty domains this doctrine MUST NOT redefine:**
- Symphony's internal key custody architecture (governed by KEY_MANAGEMENT_POLICY.md)
- Symphony's internal signer resolution authority (governed by wave8_signer_resolution)
- The operational trigger ordering of Wave 4 and Wave 8 runtime enforcement
- The internal RLS posture of operational tables
- The authority boundary between actor-rooted grants and platform-mediated execution

**Replay obligations preserved by this doctrine:**
- Every accepted signed artifact must be replayable to its original verification
  outcome from persisted evidence alone
- Replay must succeed for artifacts signed by keys that have been subsequently
  rotated, superseded, or deactivated
- Archive key material must be retained for the full applicable regulatory
  retention period
- Canonicalization procedure specifications must remain publicly documented for
  the full applicable regulatory retention period

**Regulator boundaries that constrain this doctrine:**
- Green Finance regulatory domain: governed by applicable EU taxonomy regulations;
  evidence from asset_batches boundary
- Payment settlement finality domain: governed by applicable settlement finality
  statutes; evidence from instruction_settlement_finality and state_transitions
- Cross-jurisdiction replay: no jurisdiction may claim exclusive rights over
  verification procedure; Ed25519 is a jurisdiction-neutral algorithm

**Phases to which this doctrine applies:**
- GLOBAL — all phases from Phase-0 forward, applied to all artifacts that are
  constitutionally signed (not placeholder-prefixed)

**Constitutional layers with override authority over this doctrine:**
- No lower-authority layer may override this doctrine
- A future ROOT-authority constitutional amendment may supersede this doctrine
  only if it preserves or strengthens the verifier independence guarantees VIG-1
  through VIG-7
- No PHASE, REGULATORY, or ENFORCEMENT interpretation authority may override
  this doctrine

**Lower-layer documents prohibited from reinterpretation:**
- ED25519_SIGNING_CONTRACT.md may not be reinterpreted to permit runtime-dependent
  verification paths
- TRANSITION_HASH_CONTRACT.md may not be reinterpreted to include mutable or
  runtime-derived fields in the hash input
- DATA_AUTHORITY_DERIVATION_SPEC.md may not be reinterpreted to permit
  caller-supplied data_authority values
- SIGNATURE_METADATA_STANDARD.md may not be reinterpreted to make `key_id`,
  `key_version`, or `algorithm` fields optional
- KEY_MANAGEMENT_POLICY.md may not be reinterpreted to permit deletion of archive
  key records for keys with outstanding signed artifacts within their retention
  period

---

## 13. Prohibited Misinterpretations

**PM-1 — Runtime-Exclusive Verification Dependency (PROHIBITED)**
It is prohibited to interpret this doctrine, or any document it governs, as
permitting a verification architecture in which external verification requires a
live connection to Symphony's signer resolution service, operational database,
or key management infrastructure. External verifier independence is not satisfied
by a system that merely permits external callers to invoke Symphony's internal
verification function.

**PM-2 — Centralized Provenance Trust (PROHIBITED)**
It is prohibited to treat Symphony as the sole authoritative source of truth for
whether any given artifact is valid. External verifiers are constitutionally
entitled to reach their own verification conclusions from artifact content and
archived key material. A Symphony assertion that an artifact is valid does not
override an external verifier's independent conclusion to the contrary.

**PM-3 — Unverifiable Historical Evidence (PROHIBITED)**
It is prohibited to treat the current operational lifecycle state of a signing key
as determinative of the validity of historical evidence signed by that key. A
rotated key is not a revoked key. Evidence signed by a subsequently rotated key
is not retroactively invalid. This prohibition is absolute and applies regardless
of the reason for rotation.

**PM-4 — Regulator Equivalence Collapse (PROHIBITED)**
It is prohibited to treat all regulators as equivalent or to treat one regulator's
replay of evidence from another's domain as legally valid. Regulators are
orthogonal sovereign domains. Evidence admissible before one regulator is not
thereby made admissible before another, and one regulator's key registry does not
serve as a trust anchor for another's verification.

**PM-5 — Phase-Limited Verifier Independence (PROHIBITED)**
It is prohibited to treat verifier independence as a Phase-2 or Phase-N feature
that applies only after some phase gate. The obligation attaches from the moment
of signing. A signed artifact that is accepted in Phase-1 carries full verifier
independence obligations from its `occurred_at` timestamp regardless of the phase
in which it was produced.

**PM-6 — Dormant Substrate as Absent Obligation (PROHIBITED)**
It is prohibited to interpret the dormant status of the archive verification
tables (`historical_verification_runs`, `archive_verification_runs`,
`canonicalization_registry`, `public_keys_registry`) as evidence that the
corresponding obligations do not exist. These tables are deferred activation
reservations for obligations that exist at doctrine level from Phase-0 forward.
Their dormancy reflects implementation scheduling, not constitutional absence.

**PM-7 — Placeholder Prefix as Signed Evidence (PROHIBITED)**
It is prohibited to treat any `transition_hash` value prefixed with
`PLACEHOLDER_PENDING_SIGNING_CONTRACT:` as a cryptographically signed artifact
subject to external verifier independence guarantees. Such artifacts are
explicitly excluded from this doctrine's guarantee scope and MUST NOT be presented
to regulators or external auditors as signed evidence.

**PM-8 — Provenance/Runtime Collapse (PROHIBITED)**
It is prohibited to collapse the distinction between cryptographic provenance
(what was signed by whom) and operational authority provenance (why the platform
was authorized to sign). External verifiers can establish the former
independently; the latter is within Symphony's operational sovereignty. No
document may be interpreted to require external verifiers to establish operational
authority provenance as a condition of successful verification.

**PM-9 — Replay Irrelevance (PROHIBITED)**
It is prohibited to treat replay capability as an optional audit accommodation
rather than a constitutional permanence infrastructure. Replay survivability is
a first-order design constraint on every evidence artifact. An artifact design
that cannot survive key rotation and still be replayed to its original
verification outcome is constitutionally non-compliant at design time, not merely
deficient at audit time.

**PM-10 — Universal Admissibility Assumption (PROHIBITED)**
It is prohibited to assume that a successfully verified artifact is admissible
in all jurisdictions and before all regulators. External verifier independence
guarantees that verification is technically possible; it does not guarantee legal
admissibility. Admissibility is a jurisdiction-specific determination governed
by applicable law and the regulatory framework of the jurisdiction concerned.
