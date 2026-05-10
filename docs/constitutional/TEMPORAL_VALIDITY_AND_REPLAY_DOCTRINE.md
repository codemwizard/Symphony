# TEMPORAL VALIDITY AND REPLAY DOCTRINE

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md, CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md

---

## Purpose

This document defines the constitutional doctrine governing the temporal dimension of Symphony's evidentiary architecture. It establishes the rules by which historical records remain constitutionally valid, verifiable, and admissible across time — across key rotations, schema supersessions, policy evolutions, runtime migrations, and constitutional amendments.

The temporal validity doctrine answers a single foundational constitutional question: when the present state of Symphony's constitutional architecture differs from its state at the moment a record was produced, which state governs the record's constitutional validity?

The answer is constitutionally absolute: **the constitutional state operative at the moment of production governs the record's validity, admissibility, and replayability**. Present-time policy, present-time schema, present-time key registries, and present-time constitutional doctrine do not retroactively govern historical records. A record that was constitutionally valid when produced remains constitutionally valid at the moment of that production regardless of all subsequent changes to Symphony's constitutional architecture.

This doctrine does not protect records from present-time enforcement in the present-time context. It protects the historical constitutional state of records produced in prior constitutional moments from retroactive invalidation by subsequent constitutional evolution.

---

## Constitutional Scope

This document governs:

1. The definition of historical replay survivability and its constitutional requirements.
2. The temporal proof-of-state doctrine establishing how the constitutional state at any prior constitutional moment is established for replay purposes.
3. The definition and requirements of historical admissibility.
4. The trust-root lineage doctrine governing the chain of trust across trust root transitions.
5. The canonicalization lineage doctrine governing the availability of historical canonicalization schemas.
6. The replay-version governance doctrine governing which version of constitutional doctrine applies to a replay event.
7. The historical verifier reconstruction requirements.
8. The policy-at-time-of-execution semantics defining which policy version governs any given record.
9. The survivability requirements for key rotation, schema supersession, policy evolution, and runtime evolution.

This document does NOT govern:

- The present-time enforcement of Wave 4 or Wave 8 obligations on current records (governed by CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md).
- The procedures for constitutional amendment (governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md).
- The priority ordering of competing constitutional obligations in present-time conflicts (governed by CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md).

---

## Authority Boundaries

This document operates at Authority-Rank 10 (ROOT). Its temporal validity rules are constitutionally binding on all lower-rank artifacts. No enforcement doctrine, migration record, operational artifact, or analytical synthesis may apply a temporal validity rule that contradicts the doctrine defined herein. Any artifact that asserts retroactive invalidity of a historically constitutionally valid record constitutes a constitutional defect.

---

## Part I: Historical Replay Survivability

### 1.1 Definition

Historical replay survivability is the constitutional requirement that every constitutionally admitted record in Symphony's evidentiary chain remains replayable — that is, its constitutional validity at the time of its production can be independently reconstructed and verified — regardless of all subsequent changes to Symphony's operational, cryptographic, or constitutional architecture.

Replay survivability is not a backup or archival obligation. It is a constitutional permanence obligation. It does not merely require that records be retained; it requires that the full evidentiary context necessary to verify their historical validity be retained alongside them.

### 1.2 Components of Historical Replay Survivability

Historical replay survivability requires the simultaneous preservation and availability of:

**HRS-1. The record itself:** The complete record as it existed at the time of production, without alteration, compression loss, or field deletion.

**HRS-2. The signing attestation:** The cryptographic signature applied to the record at the time of production, the signer identifier, and the HSM attestation metadata (per CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md, Part VIII).

**HRS-3. The historical signer lineage:** The state of `wave8_signer_resolution` and `delegated_signing_grants` as it existed at the time of the signing event, including the public key of the signing key used. Retired entries must remain in the historical record.

**HRS-4. The historical canonicalization schema:** The canonicalization schema version registered in `canonicalization_registry` that was used to produce the signing hash at the time of signing. Superseded schema versions must remain in the historical record.

**HRS-5. The hash chain context:** The prior record's hash value that was used as the chain anchor for the record being replayed, establishing hash chain continuity.

**HRS-6. The historical constitutional doctrine:** The constitutional doctrine that was operative at the time of the record's production, sufficient to evaluate the record's constitutional legality under the rules that applied when it was produced.

**HRS-7. The historical enforcement state:** The migration tip that was active at the time of the record's production, defining the Wave 4 enforcement constraints that governed the record's operational admissibility at that time.

### 1.3 Replay Survivability as Constitutional Permanence Infrastructure

Replay survivability is classified at Priority 1 in CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md. It is the supreme constitutional priority. No subsequent constitutional evolution — no amendment, no key rotation, no schema supersession, no policy change, no runtime migration — may reduce, compromise, or eliminate the replay survivability of any historically admitted record.

This classification is non-derogable. It cannot be overridden by wave doctrine, phase doctrine, regulator doctrine, enforcement doctrine, or operational necessity.

---

## Part II: Temporal Proof-of-State

### 2.1 Definition

Temporal proof-of-state is the constitutional mechanism by which the complete constitutional state of Symphony at any specified prior constitutional moment can be established with sufficient precision to evaluate the constitutional validity of any record produced at that moment.

Temporal proof-of-state is not a snapshot. It is a reconstructed evidentiary state derived from the constitutional history record. It answers the question: "What were the applicable constitutional rules, enforcement surfaces, key registries, canonicalization schemas, phase boundaries, and signer lineages at constitutional moment T?"

### 2.2 Temporal Proof-of-State Components

**TPS-1. Migration tip at moment T:** The highest-numbered migration that was committed to the constitutional record at or before moment T. This establishes the Wave 4 enforcement surface operative at T.

**TPS-2. Constitutional doctrine version at moment T:** The set of constitutional documents that were authoritative at moment T, determined by traversal of the constitutional version lineage records (per CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, Doctrine Version Lineage section).

**TPS-3. Wave 8 signer registry state at moment T:** The state of `wave8_signer_resolution` and `delegated_signing_grants` as of moment T, including all entries that were active at T and all entries that had been retired before T (with their retirement timestamps).

**TPS-4. Canonicalization registry state at moment T:** The state of `canonicalization_registry` as of moment T, including all schema versions that were registered at T.

**TPS-5. Phase activation state at moment T:** The constitutional phase that was active at moment T, determining the applicable phase capability boundaries.

**TPS-6. Regulator domain configuration at moment T:** The regulator domain admissibility requirements that were operative at moment T, as established by governing regulator partition doctrine at that time.

### 2.3 Temporal Proof-of-State Reconstruction Obligation

The constitutional record must be maintained in a form that permits temporal proof-of-state reconstruction at any prior constitutional moment without ambiguity. This requires:

**TPSR-1.** All migration records are retained in sequence and in full.

**TPSR-2.** All constitutional doctrine versions are retained in the version lineage record with their effective dates.

**TPSR-3.** All `wave8_signer_resolution` changes are recorded with timestamps, including activations, updates, retirements, and revocations.

**TPSR-4.** All `canonicalization_registry` entries are retained with their registration timestamps. Schema versions are never deleted.

**TPSR-5.** All phase transition events are recorded with their constitutional moment timestamps.

**TPSR-6.** All regulator domain configuration changes are recorded with their constitutional effective dates.

---

## Part III: Historical Admissibility

### 3.1 Definition

Historical admissibility is the constitutional status of a record as having been constitutionally admitted under the constitutional doctrine operative at the time of its production. A record is historically admissible if and only if it satisfied the constitutional requirements applicable to it at the time of its production — regardless of whether those requirements have since been amended, superseded, or made more stringent.

### 3.2 The Temporal Admissibility Principle

**TAP-1. Historical admissibility is constitutionally permanent.**
A record that was constitutionally admitted at the time of its production retains that admissibility permanently. Subsequent constitutional evolution does not retroactively alter the record's admissibility status as of its production time.

**TAP-2. Present-time policy does not retroactively invalidate historical admissibility.**
No present-time constitutional doctrine — no matter how recently amended, how authoritatively issued, or how operationally urgent — may declare historically admitted records inadmissible. The retroactive application of present-time policy to historical records is constitutionally prohibited.

**TAP-3. More stringent present-time requirements do not invalidate prior-admitted records.**
Where present-time constitutional doctrine imposes more stringent admissibility requirements than the doctrine operative at the time of a record's production, records produced under the prior, less stringent doctrine remain historically admissible under the rules applicable when they were produced.

**TAP-4. Historical admissibility does not confer present-time operational authority.**
Historical admissibility establishes that the record was constitutionally valid when produced. It does not authorize the record to be treated as constitutionally valid under present-time enforcement surfaces in present-time operational contexts. Historical admissibility and present-time operational admissibility are constitutionally distinct determinations.

### 3.3 Historical Admissibility in Regulator Domains

**HA-R1.** Historical admissibility within a regulator domain is evaluated against the admissibility requirements of that domain as they existed at the time of the record's production.

**HA-R2.** Regulator domain admissibility requirement evolution does not retroactively invalidate records admitted under prior domain requirements.

**HA-R3.** Where a regulator domain is newly introduced after a record's production, that record's historical admissibility is not evaluated against the new domain's requirements. The new domain may define its applicability to historical records; absent explicit applicability definition, the new domain's requirements apply only to records produced after the domain's constitutional establishment.

---

## Part IV: Trust-Root Lineage

### 4.1 Definition

Trust-root lineage is the chronological chain of trust roots that have been constitutionally designated as Wave 8 signing anchors across Symphony's constitutional history. Each trust root represents a constitutional moment at which the Wave 8 signing chain's anchor was established or transitioned.

Trust-root lineage is distinct from signer lineage (Part IX of CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md). Signer lineage is the chain of delegated signing authority within a trust root's authority. Trust-root lineage is the chain of trust root transitions across constitutional time.

### 4.2 Trust-Root Lineage Requirements

**TRL-1. Continuity:** The trust-root lineage must be continuous. Each trust root transition must document: the prior trust root, the new trust root, the transition constitutional moment, and the transition authorization (Root constitutional amendment reference).

**TRL-2. Retrospective verifiability:** The trust-root lineage must be maintained such that the trust root operative at any prior constitutional moment T can be determined from the lineage record.

**TRL-3. Prior root preservation:** A prior trust root's public key and the records it anchored must remain in the constitutional record after the trust root's transition. Records signed under a prior trust root's chain retain their Wave 8 admissibility under that root. The prior root's retirement does not invalidate records signed under its chain before the transition.

**TRL-4. Transition gap prohibition:** A trust root transition may not create a constitutional moment during which no trust root is designated. The new trust root must be constitutionally designated before the prior trust root is retired.

**TRL-5. Transition authentication:** Every trust root transition must be authenticated by a Root constitutional amendment (Authority-Rank 10). Trust root transitions are constitutional amendments, not operational configurations.

### 4.3 Trust-Root Transition Semantics

When a trust root transition occurs:

**TRT-1.** Records produced before the transition remain anchored to the prior trust root and are verified against that root's chain.

**TRT-2.** Records produced after the transition are anchored to the new trust root and are verified against the new root's chain.

**TRT-3.** The transition itself is recorded as a constitutional event in the constitutional history record, establishing the boundary between the two trust root chains.

**TRT-4.** A replay verifier presented with a record must determine, from the trust-root lineage record, which trust root chain governed the record at its production time, and apply that chain for verification.

**TRT-5.** It is constitutionally impermissible to verify a pre-transition record against the post-transition trust root's chain, or vice versa.

### 4.4 Temporal Trust-Root Recovery Semantics

Where a trust root's private key is compromised, lost, or rendered inaccessible:

**TTR-1.** The compromise event must be documented as a constitutional emergency in the constitutional history record with precise timestamp.

**TTR-2.** A new trust root must be designated by Root constitutional amendment immediately following the compromise event.

**TTR-3.** Records produced before the compromise event, under the prior trust root's chain, retain their historical Wave 8 admissibility status as of their production time. The compromise event does not retroactively invalidate records produced before it.

**TTR-4.** Records produced after the compromise event but before the new trust root designation — during the compromise gap — are constitutionally defective in the Wave 8 dimension for the duration of the gap. Their historical Wave 8 admissibility status is: provenancially unverifiable for the gap period.

**TTR-5.** The constitutional amendment establishing the new trust root must explicitly define the gap period, its constitutional implications, and the replay treatment of records produced during the gap.

**TTR-6.** A resign operation (executed through `resign_sweeps` upon its constitutional activation) may be applied to gap-period records to re-establish their Wave 8 provenance chain under the new trust root. The resign operation creates a new Wave 8 attestation for gap-period records; it does not alter the original record. Both the original record (with its gap-period status) and the re-signed attestation are retained in the constitutional record.

---

## Part V: Canonicalization Lineage

### 5.1 Definition

Canonicalization lineage is the chronological record of all canonicalization schema versions registered in `canonicalization_registry`. It establishes, for any record produced at any constitutional moment, the exact canonicalization procedure that was used to produce the signing hash submitted for Wave 8 attestation.

Canonicalization lineage is a prerequisite for historical replay survivability. A record cannot be replayed — its signature cannot be verified — without the canonicalization schema used to produce the signing hash. Schema versions must therefore be retained permanently.

### 5.2 Canonicalization Lineage Requirements

**CL-1. Version permanence:** Every canonicalization schema version registered in `canonicalization_registry` must be retained permanently. No schema version may be deleted or rendered inaccessible. Schema version retirement is a status change (marking the version as no longer applicable to new records); it is not deletion.

**CL-2. Version identification:** Every canonicalized record must carry a reference to the specific canonicalization schema version used to produce its signing hash. Records without a schema version reference are canonicalization-lineage-defective.

**CL-3. Schema evolution traceability:** Canonicalization schema versions must form a traceable lineage, where each version is related to its predecessor. The lineage must be traversable from any version to the initial version.

**CL-4. Replay schema resolution:** For any record produced at constitutional moment T, the canonicalization schema version applicable at T must be resolvable from `canonicalization_registry` using the record's schema version reference and the historical state of the registry at T.

**CL-5. Cross-version incompatibility documentation:** Where a new canonicalization schema version is not backward-compatible with a prior version (i.e., canonicalizing the same record data under both versions produces different byte sequences), this incompatibility must be documented in `canonicalization_registry` with the version registration. A record signed under version N cannot be verified using version N+1 if the two versions are not backward-compatible.

### 5.3 Schema Supersession Survivability

When a canonicalization schema version is superseded by a newer version:

**SSS-1.** The prior schema version remains in `canonicalization_registry` as a retired version with a retirement timestamp.

**SSS-2.** All records signed under the prior schema version retain their historical Wave 8 admissibility. Their signatures are verifiable using the retired schema version and the signer's public key from the historical signer registry.

**SSS-3.** New records are signed under the current schema version. Prior records are not retroactively re-canonicalized or re-signed merely because a new schema version has been established.

**SSS-4.** Where a schema supersession corrects a cryptographic vulnerability in the canonicalization procedure, a constitutional resign obligation may be established by Root constitutional amendment. The resign obligation defines which record classes must be re-signed under the new schema, the timeline for re-signing, and the replay treatment of records during the re-signing period. Re-signing is a distinct constitutional event; it does not erase the original signing event.

---

## Part VI: Replay-Version Governance

### 6.1 Definition

Replay-version governance defines which version of every relevant constitutional element — trust root, signer lineage, canonicalization schema, phase doctrine, constitutional doctrine, enforcement surface — governs the evaluation of a replay event.

The governing principle is: **the version operative at the time of the original event governs the replay evaluation of that event**. Replay is not re-evaluation under present-time doctrine; it is reconstruction and verification of the historical event under the constitutional state that governed the event when it occurred.

### 6.2 Replay Governing Version Determination Rules

For any replay event involving a record produced at constitutional moment T:

**RVG-1. Trust root version:** The trust root operative at T governs. Determined from the trust-root lineage record.

**RVG-2. Signer lineage version:** The state of `wave8_signer_resolution` and `delegated_signing_grants` at T governs. Includes the public key of the signing key as it existed at T.

**RVG-3. Canonicalization schema version:** The canonicalization schema version referenced in the record's provenance fields governs. This version must be available in `canonicalization_registry` historical state.

**RVG-4. Constitutional doctrine version:** The constitutional doctrine version authoritative at T governs the evaluation of the record's constitutional legality. Determined from the doctrine version lineage record.

**RVG-5. Phase doctrine version:** The phase that was active at T and the capability boundaries defined by that phase's doctrine at T govern the evaluation of the record's phase legality.

**RVG-6. Enforcement state version:** The migration tip active at T governs the Wave 4 enforcement constraints applicable to the record's operational admissibility evaluation.

**RVG-7. Regulator domain version:** The admissibility requirements of the applicable regulator domain as they existed at T govern the evaluation of the record's regulator admissibility.

### 6.3 Replay Governing Version Determination Flow

```
Replay event initiated for record R produced at moment T
              │
              ▼
Determine T from record's constitutional timestamp
              │
              ▼
Resolve trust root operative at T (trust-root lineage)
              │
              ▼
Resolve signer lineage state at T
(wave8_signer_resolution historical state)
              │
              ▼
Resolve canonicalization schema (record's schema version reference
+ canonicalization_registry historical state at T)
              │
              ▼
Resolve constitutional doctrine version at T
(doctrine version lineage)
              │
              ▼
Resolve phase active at T (phase transition records)
              │
              ▼
Resolve migration tip at T (migration sequence records)
              │
              ▼
Reconstruct Wave 8 verification:
  - Canonicalize record using T-version schema
  - Verify signature using T-version signer public key
  - Verify signer authorization in T-version signer registry
  - Verify hash chain continuity using T-version prior record hash
              │
              ▼
Reconstruct Wave 4 verification:
  - Evaluate record against T-version migration tip enforcement
  - Evaluate record against T-version phase capability boundary
              │
              ▼
Produce replay determination:
  - Wave 4 PASS/FAIL at T
  - Wave 8 PASS/FAIL at T
  - Historical admissibility status at T
  - Historical regulator domain status at T
```

### 6.4 Replay Version Conflict Resolution

Where two elements of the replay governing version set produce contradictory determinations for the same record:

**RVC-1.** The constitutional priority ordering (CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md) governs. Replay survivability (Priority 1) takes precedence. The version determination that preserves replay verifiability is controlling.

**RVC-2.** Where the constitutional history record is ambiguous about the exact state of a governing element at moment T (e.g., a signer registry entry's exact timestamp is uncertain), the conservative determination applies: the version that produces the more restrictive historical admissibility conclusion is the governing version.

**RVC-3.** Where replay version conflict cannot be resolved from the constitutional history record, the conflict must be escalated to Root constitutional doctrine for interpretation (per CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md escalation rules). It may not be resolved by operational assumption.

---

## Part VII: Historical Verifier Reconstruction

### 7.1 Definition

Historical verifier reconstruction is the process by which a constitutionally authorized external verifier, operating at any point in time after the production of a record, assembles the complete evidentiary context necessary to verify that record's historical constitutional validity without access to Symphony's present-time runtime infrastructure.

### 7.2 Historical Verifier Reconstruction Requirements

A historical verifier must be able to reconstruct the following from the constitutional record:

**HVR-1. The record's text:** The complete record as produced, available from Symphony's evidentiary store.

**HVR-2. The record's signing attestation:** The signature bytes, signer identifier, canonicalization schema version reference, and timestamp, available from the signing attestation record (in `signing_audit_log` upon activation, or from the record's provenance fields directly).

**HVR-3. The signer's historical public key:** The public key registered in `wave8_signer_resolution` for the signing key used, as it existed at the time of signing. Available from the historical `wave8_signer_resolution` record.

**HVR-4. The historical canonicalization schema:** The complete canonicalization procedure defined by the schema version referenced in the signing attestation. Available from `canonicalization_registry`.

**HVR-5. The hash chain context:** The prior record's hash value used as the chain anchor, available from the prior record's provenance fields.

**HVR-6. The trust root public key:** The public key of the trust root operative at the time of signing, available from the trust-root lineage record.

**HVR-7. The signer authorization chain:** The complete `delegated_signing_grants` chain from the signing signer to the trust root, as it existed at the time of signing. Available from the historical `delegated_signing_grants` records.

### 7.3 Historical Verification Flow

```
External verifier initiates historical verification of record R
              │
              ▼
HVR-1: Retrieve record R from constitutional evidentiary store
              │
              ▼
HVR-2: Retrieve signing attestation for R
  (signature bytes, signer ID, schema version, timestamp)
              │
              ▼
HVR-3: Retrieve signer's public key from wave8_signer_resolution
  historical state at signing timestamp
              │
              ▼
HVR-4: Retrieve canonicalization schema from canonicalization_registry
  at schema version referenced in attestation
              │
              ▼
Apply schema to record R bytes to produce canonical form
              │
              ▼
Verify: ed25519_verify(
  public_key = signer's historical public key (HVR-3),
  message = canonical form (HVR-4 applied to HVR-1),
  signature = signature bytes (HVR-2)
)
              │
         ┌────┴────┐
       FAIL       PASS
         │           │
         ▼           ▼
WAVE 8 FAIL      HVR-5: Retrieve prior record hash
at production    and verify hash chain continuity
time                  │
                      ▼
               HVR-6: Verify trust root chain
               (signer authorization via HVR-7
               traces to trust root at production time)
                      │
                 ┌────┴────┐
               FAIL       PASS
                 │           │
                 ▼           ▼
           WAVE 8 FAIL  HISTORICAL WAVE 8 PASS
           (chain broken  CONFIRMED
           or signer
           unauthorized)
```

### 7.4 External Verifier Independence Obligation

The historical verification flow defined in Section 7.3 must be executable:

**EVI-1.** Without access to Symphony's Wave 4 runtime infrastructure.
**EVI-2.** Without access to any private key material.
**EVI-3.** Without access to Symphony-specific network services.
**EVI-4.** Using only the `ed25519_verify()` algorithm and the public data in the constitutional evidentiary record.
**EVI-5.** At any point in time after the record's production, including years or decades later.

These requirements are the historical dimension of the external verification survivability obligations defined in CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md, Part XI.

---

## Part VIII: Policy-at-Time-of-Execution Semantics

### 8.1 Definition

Policy-at-time-of-execution semantics define the rule that the constitutional policy governing a record is the policy that was operative at the time the record was produced — the time of execution — not the policy operative at the time the record is subsequently reviewed, replayed, audited, or enforced in a different context.

This doctrine is the constitutional foundation of historical admissibility. Without policy-at-time-of-execution semantics, every record would be subject to retroactive re-evaluation under constantly evolving constitutional doctrine, destroying historical admissibility continuity.

### 8.2 Policy-at-Time-of-Execution Rules

**PTE-1. Governing policy is time-bound:** The constitutional policy governing a record's validity, admissibility, and provenance is the policy operative at the record's production timestamp.

**PTE-2. Policy evolution is prospective:** Constitutional policy evolution — amendments, supersessions, new enforcement surfaces, new regulator requirements — applies to records produced after the evolution's constitutional effective date. It does not apply retroactively to prior records.

**PTE-3. More stringent policy is not retroactive:** Where evolved constitutional policy imposes more stringent requirements than the policy operative at a record's production time, the record is evaluated against the less stringent prior policy for historical admissibility purposes. The more stringent present-time policy governs only records produced after its constitutional effective date.

**PTE-4. Relaxed policy does not retroactively cure prior defects:** Where evolved constitutional policy relaxes a requirement that was operative at a record's production time, and the record was constitutionally defective under the prior, more stringent policy, the policy relaxation does not retroactively cure the record's historical defect. The record was constitutionally defective when produced; it remains historically defective. The relaxed policy governs future records, not the historical status of past records.

**PTE-5. Policy-at-execution is the replay governing standard:** When a record is replayed, the replay evaluation uses the policy-at-execution standard. The replay verifier does not evaluate the record against present-time policy; it evaluates the record against the policy operative at production time (per Replay-Version Governance, Part VI).

### 8.3 Policy-at-Execution Application to Specific Policy Classes

**PTE-A. Wave 8 signing policy:** A record signed under the signing policy operative at its production time is historically Wave 8 valid if it satisfied that policy's requirements, even if present-time Wave 8 signing policy requires additional or different signing procedures.

**PTE-B. Key authorization policy:** A record signed by a signer who was authorized in `wave8_signer_resolution` at the time of signing retains its historical Wave 8 admissibility even if that signer's authorization was subsequently revoked. Revocation is prospective; it does not retroactively invalidate records signed before the revocation event.

**PTE-C. Canonicalization policy:** A record canonicalized and signed under a canonicalization schema version that was current at the time of signing retains its historical Wave 8 admissibility even if that schema version has since been superseded. The historical signing hash was produced under the then-current schema; it is verified under that same schema at replay time.

**PTE-D. Phase legality policy:** A record produced within a constitutionally active phase's capability boundary retains its historical phase legality even if a subsequent phase transition has retired the producing phase. The record was phase-legal when produced.

**PTE-E. Regulator admissibility policy:** A record admitted under the regulator domain requirements operative at its production time retains its historical regulator admissibility within that domain even if the domain's requirements have subsequently been made more stringent.

---

## Part IX: Key Rotation Survivability

### 9.1 Definition

Key rotation survivability is the constitutional requirement that the rotation of signing keys — the retirement of one Ed25519 signing key and the activation of a new one within a signer's authority — does not destroy the historical Wave 8 admissibility of records signed under the retired key.

### 9.2 Key Rotation Constitutional Requirements

**KRS-1. Retired key preservation:** The public key of every retired Ed25519 signing key must be retained in `wave8_signer_resolution` with a retirement timestamp. The retired key entry may not be deleted.

**KRS-2. Signing event temporal anchoring:** Every signing event must be recorded with a timestamp that can be compared with the signing key's active period (activation timestamp to retirement timestamp) to establish that the signing event occurred during the key's authorized active period.

**KRS-3. Historical key authorization:** For replay purposes, a signing key is considered authorized at any time T if: (a) the key was registered in `wave8_signer_resolution` with an activation timestamp at or before T, and (b) the key's retirement timestamp, if any, is after T.

**KRS-4. Key rotation is not key compromise:** A constitutionally executed key rotation (retirement of one key, activation of its successor) does not create a Wave 8 defect in records signed under the retired key during its authorized active period. Rotation and compromise are distinct events with distinct constitutional consequences.

**KRS-5. Successor key lineage continuity:** The successor key activated in a rotation must be traceable to the same trust root as the retired key through the signer lineage. Key rotation may not constitute a signer lineage gap.

### 9.3 Key Rotation Survivability Matrix

| Event | Records Signed Before Event | Records Signed After Event | Constitutional Basis |
|---|---|---|---|
| Key rotation (authorized) | Historically Wave 8 valid under retired key | Valid under new key; must satisfy new key's authorization | KRS-1, KRS-2, KRS-3 |
| Key compromise (unauthorized access) | Historical Wave 8 validity preserved for pre-compromise records | Post-compromise records are Wave 8 defective | TTR-3, TTR-4 |
| Key revocation (authorized cancellation) | Historical Wave 8 validity preserved for pre-revocation records | Post-revocation records blocked | PTE-B |
| Signer authorization revocation | Historical Wave 8 validity preserved for pre-revocation records | Post-revocation records blocked | PTE-B |
| Trust root transition | Records under prior root: verified against prior root chain | Records under new root: verified against new root chain | TRT-1, TRT-2 |

---

## Part X: Schema Supersession Survivability

### 10.1 Definition

Schema supersession survivability is the constitutional requirement that the introduction of a new canonicalization schema version does not destroy the historical Wave 8 admissibility of records canonicalized and signed under prior schema versions.

### 10.2 Schema Supersession Constitutional Requirements

**SSS-A. Prior schema version retention:** All canonicalization schema versions registered in `canonicalization_registry` are retained permanently. No version is deleted upon supersession.

**SSS-B. Cross-version verification protocol:** The verification protocol for a record canonicalized under version N uses version N's schema, not the current version. Version N must remain available in `canonicalization_registry` to support this.

**SSS-C. Supersession does not require re-signing:** A schema supersession event does not create a constitutional obligation to re-sign all existing records under the new schema. Re-signing is a distinct constitutional obligation established only by Root constitutional amendment, and only where a cryptographic vulnerability in the prior schema warrants it (per SSS-4 of Part V).

**SSS-D. Version reference completeness:** Every signed record must carry a complete canonicalization schema version reference sufficient to identify the exact schema used to produce the signing hash. A record with an incomplete or ambiguous schema version reference is canonicalization-lineage-defective and Wave 8 provenancially impaired.

---

## Part XI: Policy Evolution Survivability

### 11.1 Definition

Policy evolution survivability is the constitutional requirement that the evolution of any constitutional policy — including wave sovereignty doctrine amendments, phase doctrine amendments, regulator domain requirement changes, and root constitutional doctrine amendments — does not retroactively invalidate the historical admissibility of records produced under prior policy.

### 11.2 Policy Evolution Survivability Rules

**PES-1. Policy evolution is prospective only:** All constitutional policy amendments take effect from their constitutional effective date. They govern records produced after that date. They do not alter the constitutional status of records produced before that date.

**PES-2. Admissibility continuity across policy evolution:** The admissibility of a record produced under prior policy is evaluated against the policy operative at production time. Policy evolution does not trigger re-evaluation of historically admitted records under evolved standards.

**PES-3. The constitutional history record is the policy-at-execution authority:** The constitutional history record (version lineage, doctrine history, migration sequence) constitutes the authoritative record of which policy was operative at any given constitutional moment. It is the source of policy-at-execution determinations.

**PES-4. Policy evolution survivability for regulator domains:** Regulator domain admissibility requirement evolution is prospective. Records admitted under prior domain requirements retain their historical domain admissibility.

**PES-5. Policy evolution survivability for phases:** Phase doctrine amendments — including redefinition of phase capability boundaries — do not retroactively alter the constitutional status of records produced within the phase's prior capability boundary.

**PES-6. Constitutional amendment survivability:** Root constitutional amendments — including amendments to wave sovereignty doctrine, replay obligation doctrine, and authority hierarchy doctrine — do not retroactively alter the constitutional status of records produced under prior constitutional doctrine. Prior constitutional states remain constitutionally valid for records produced in those states.

---

## Part XII: Runtime Evolution Survivability

### 12.1 Definition

Runtime evolution survivability is the constitutional requirement that the evolution of Symphony's operational runtime — including schema migrations, enforcement trigger additions, RLS policy changes, CI gate additions, and operational infrastructure changes — does not destroy the historical replay survivability or historical admissibility of records produced under prior runtime states.

### 12.2 Runtime Evolution Survivability Rules

**RES-1. Migration continuity:** The migration sequence is the constitutional record of runtime evolution. Every migration must be retained in sequence. No migration may be deleted, reordered, or retroactively amended.

**RES-2. Schema field retention:** No migration may delete or rename a schema field that appears in historically admitted records without: (a) a formal constitutional amendment authorizing the change, and (b) explicit provisions for the historical admissibility continuity of records that used the prior field definition.

**RES-3. Enforcement surface addition is prospective:** The addition of a new enforcement trigger or RLS policy to a write path applies to records produced after the enforcement surface's migration activation. Records produced before the surface's activation are not retroactively subject to the new enforcement.

**RES-4. Enforcement surface removal is constitutionally regulated:** The removal of an existing enforcement trigger or RLS policy requires Root constitutional amendment where the surface was constitutionally designated as an invariant enforcement mechanism. Removal without amendment constitutes a constitutional defect.

**RES-5. Runtime infrastructure change does not affect historical replay:** Changes to Symphony's operational runtime infrastructure — server migrations, database engine upgrades, application framework changes — do not affect the historical replay survivability of records in the constitutional evidentiary store. Historical replay is a function of the constitutional record; it is not a function of the present-time runtime infrastructure.

**RES-6. Operational discontinuity is not replay suspension:** If Symphony's operational runtime becomes temporarily unavailable, that unavailability does not suspend or toll replay obligations. Records in the constitutional evidentiary store remain replay-obligated regardless of operational availability.

---

## Part XIII: Replay Reconstruction Models

### 13.1 Full Hash Chain Replay

Full hash chain replay is the reconstruction of the complete sequence of records in a hash chain, from the trust root forward to a specified record, verifying cryptographic continuity at each step.

**FHC-1. Sequential verification:** Each record in the chain is verified against its predecessor's hash value and the signer's historical public key.

**FHC-2. Trust root anchoring:** The chain terminates at the trust root designated for the chain's constitutional moment.

**FHC-3. Gap detection:** A full hash chain replay that encounters a missing record, a broken hash link, or a signature that does not verify constitutes a gap finding — a constitutional record of provenance chain interruption. Gap findings are themselves replay-obligated constitutional records.

**FHC-4. PASS/STUB identification:** Full hash chain replay that encounters records bearing `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix values identifies those records as PASS/STUB (Wave 4 admitted, Wave 8 provenancially defective). Their chain positions are noted; they do not terminate the replay unless the defect prevents hash chain continuity.

### 13.2 Point-in-Time State Reconstruction

Point-in-time state reconstruction is the reconstruction of Symphony's complete constitutional state at a specified constitutional moment T, without traversing the complete hash chain.

**PIT-1.** The reconstruction identifies the migration tip, signer registry state, canonicalization registry state, phase activation state, and constitutional doctrine version operative at T.

**PIT-2.** Point-in-time state reconstruction is the foundation for temporal proof-of-state (Part II) and replay-version governance (Part VI).

**PIT-3.** Point-in-time state reconstruction does not verify individual record signatures; it establishes the constitutional context against which individual records can be verified.

### 13.3 Selective Record Replay

Selective record replay is the verification of a specific record's historical constitutional validity without full hash chain traversal.

**SR-1.** Selective replay is appropriate where the question is the constitutional status of a specific record, not the integrity of the complete chain.

**SR-2.** Selective replay verifies: the record's signature against the historical signer public key, the canonicalization schema, the signer authorization at production time, and the hash chain anchoring (the prior record's hash value as included in the record's provenance fields).

**SR-3.** Selective replay does not verify the constitutional status of records preceding the selected record. It verifies one link in the chain, not the complete chain.

**SR-4.** A selective replay PASS establishes that the selected record is individually Wave 8 valid. It does not establish that the complete chain leading to the record is intact.

### 13.4 Resign Sweep Replay

Resign sweep replay is the replay model applicable to records that have undergone a constitutional resign operation.

**RSR-1.** A resigned record has two Wave 8 attestations: the original attestation (which may be a PASS/STUB defective attestation) and the resign attestation produced by the `resign_sweeps` operation.

**RSR-2.** Replay of a resigned record must account for both attestations. The original attestation establishes the record's historical Wave 8 status at production time. The resign attestation establishes the record's Wave 8 status after the resign operation.

**RSR-3.** The resign attestation does not retroactively alter the record's historical Wave 8 status at production time. A record that was PASS/STUB at production time retains that historical status; the resign operation creates a new, constitutionally documented Wave 8 determination that applies from the resign event forward.

**RSR-4.** For replay purposes within the historical window pre-dating the resign operation, the original attestation governs. For replay purposes from the resign event forward, the resign attestation governs.

---

## Part XIV: Admissibility Implications

**ADM-T1.** Historical admissibility is evaluated against the constitutional doctrine operative at the time of production. No present-time doctrine retroactively governs historical admissibility.

**ADM-T2.** A record that was Wave 8 provenancially defective at production time (PASS/STUB) retains that historical defect. The defect is a constitutionally documented historical fact, not an alterable status.

**ADM-T3.** Key rotation, schema supersession, policy evolution, and runtime evolution do not retroactively alter the historical admissibility status of records produced before those events.

**ADM-T4.** Regulator domain admissibility for historical records is evaluated against the domain requirements operative at the record's production time.

**ADM-T5.** A resigned record's historical admissibility from the resign event forward is governed by the resign attestation. Its historical admissibility before the resign event is governed by the original attestation.

---

## Part XV: Replay Implications

**REP-T1.** All replay events use the policy-at-time-of-execution standard. Replay is historical verification, not present-time re-evaluation.

**REP-T2.** The constitutional history record — migration sequence, doctrine version lineage, signer registry history, canonicalization registry history, trust-root lineage record, phase transition records — constitutes the complete evidentiary basis for replay governing version determination.

**REP-T3.** Replay of gap-period records (records produced during a trust root compromise gap) must document the gap-period status as a constitutional finding, not as a verification failure requiring operational remediation.

**REP-T4.** Full hash chain replay, point-in-time state reconstruction, selective record replay, and resign sweep replay are each constitutionally authorized replay models. Their selection is governed by the scope of the replay inquiry.

**REP-T5.** External verifier independence (Part VII, EVI-1 through EVI-5) is a replay obligation. Replay must be performable without Symphony's present-time runtime infrastructure.

---

## Part XVI: Sovereignty Implications

**SOV-T1.** Wave 4 and Wave 8 historical determinations are temporally governed independently. Historical Wave 4 admissibility is evaluated against the migration tip operative at production time. Historical Wave 8 admissibility is evaluated against the signer registry, canonicalization registry, and trust root operative at production time. These are independent temporal evaluations on orthogonal sovereignty surfaces.

**SOV-T2.** Trust-root lineage is a Wave 8 sovereignty construct. Trust root transitions are Wave 8 sovereignty events and require Root constitutional amendment.

**SOV-T3.** Canonicalization lineage is a Wave 8 sovereignty construct. Canonicalization schema versions define the boundary of Wave 8's canonicalization authority at any given constitutional moment.

**SOV-T4.** Regulator domain temporal admissibility is governed per-domain. Domain A's historical admissibility determination for a record does not govern Domain B's historical admissibility determination for the same record.

**SOV-T5.** Phase temporal legality is evaluated against the phase active at the record's production time. Records produced in Phase N retain their Phase N capability boundary evaluations regardless of subsequent phase transitions.

---

## Phase Interaction Rules

**PH-T1.** Phase transitions are constitutional events with timestamps in the constitutional history record. The timestamp of a phase transition determines which phase's doctrine governs records produced at any given constitutional moment.

**PH-T2.** Records produced during a phase's active period are evaluated for phase legality against that phase's capability boundaries as they existed during the active period, not as subsequently amended.

**PH-T3.** A phase's retirement does not retroactively alter the phase legality of records produced during its active period.

**PH-T4.** Where a phase is constitutionally exited without formal closure documentation, the phase transition timestamp must be established from the constitutional history record. If the timestamp is ambiguous, the conservative determination applies: the more restrictive phase boundary applies to records in the ambiguous period.

**PH-T5.** Phase interaction with trust root transitions: where a phase transition and a trust root transition occur in close constitutional proximity, the constitutional history record must establish the precise temporal ordering. The trust root operative at any given constitutional moment is determined from the trust-root lineage record, independent of phase transition sequencing.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the temporal dimension of Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, regulator domain sovereignty, and phase capability sovereignty. It defines how the historical states of these sovereignty domains govern records produced at prior constitutional moments.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine the substantive present-time scope of Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator sovereignty domains, or present-time phase capability boundaries. It governs the temporal application of those domains' definitions; it does not alter their present-time definitions.

**Replay obligations preserved by this document:**
This document constitutes a comprehensive articulation and preservation of Symphony's replay obligations across time. It establishes replay survivability requirements (Part I), temporal proof-of-state obligations (Part II), replay-version governance (Part VI), historical verifier reconstruction requirements (Part VII), key rotation survivability (Part IX), schema supersession survivability (Part X), policy evolution survivability (Part XI), runtime evolution survivability (Part XII), and replay reconstruction models (Part XIII). Every component of this document is oriented toward preserving replay survivability as the supreme constitutional priority.

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator orthogonality. Its temporal admissibility rules must be applied per-domain. Regulator domain historical admissibility is evaluated independently per domain; this document does not flatten regulator domains into a unified temporal admissibility standard.

**Phases this document applies to:**
GLOBAL. This document applies across all phases and across all constitutional time. Its doctrines are the temporal framework within which every phase's doctrine operates.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10. Any artifact asserting retroactive policy application, retroactive admissibility invalidation, or retroactive replay invalidity constitutes a constitutional defect governed by this document.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, CI gate definitions, operational enforcement artifacts, declarative substrate, repository observations, AI syntheses, and NotebookLM outputs are prohibited from reinterpreting the historical replay survivability requirements, temporal proof-of-state doctrine, historical admissibility rules, trust-root lineage doctrine, canonicalization lineage doctrine, replay-version governance rules, historical verifier reconstruction requirements, policy-at-time-of-execution semantics, key rotation survivability rules, schema supersession survivability rules, policy evolution survivability rules, and runtime evolution survivability rules defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Historical validity is a backup concern:**
Historical replay survivability is Priority 1 in Symphony's constitutional priority ordering. It is not a backup concern, an archival preference, or an operational nice-to-have. It is the supreme constitutional obligation to which all other obligations yield. Treating it as a secondary operational concern constitutes a constitutional priority inversion.

**Invalid simplification — Present-time policy governs all records:**
Present-time constitutional policy governs present-time records. It does not govern historical records. The policy operative at the time of a record's production governs that record's historical constitutional status. This is the policy-at-time-of-execution principle. Applying present-time policy to historical records is constitutionally prohibited.

**Invalid simplification — Key rotation invalidates prior signatures:**
An authorized key rotation retires one signing key and activates its successor. It does not invalidate records signed under the retired key during its authorized active period. Those records retain their historical Wave 8 admissibility. Key rotation survivability is constitutionally required.

**Invalid simplification — Schema supersession invalidates prior hashes:**
A canonicalization schema supersession introduces a new schema version. It does not invalidate signing hashes produced under the prior schema version. Prior-version hashes are verifiable against the prior schema version, which is retained permanently in `canonicalization_registry`. Schema supersession survivability is constitutionally required.

**Forbidden authority collapse — Current enforcement determines historical validity:**
The enforcement surfaces active at the present constitutional moment do not determine the historical validity of records produced before those surfaces were activated. Historical validity is determined by the enforcement state operative at production time. Applying present-time enforcement retroactively is constitutionally prohibited.

**Forbidden authority collapse — Operational acceptance constitutes historical admissibility:**
A record's present-time operational acceptance by Wave 4 runtime surfaces does not constitute a determination of its historical constitutional admissibility. Historical admissibility is a temporal determination made against the constitutional state operative at production time. It is not determined by present-time operational acceptance.

**Replay-destructive interpretation — Resigned records replace original records:**
A resign operation creates a new Wave 8 attestation for a record that had a Wave 8 defect. It does not replace or erase the original record or its original constitutional status. The original record's historical Wave 8 defect is a constitutionally documented fact. The resign attestation creates a new, documented Wave 8 determination from the resign event forward. Both attestations must be retained.

**Replay-destructive interpretation — Gap-period records are simply invalid:**
Records produced during a trust root compromise gap are Wave 8 provenancially unverifiable for the gap period. This is a specific constitutional status, not a generic invalidity. Gap-period records may be subsequently re-established through a constitutional resign operation. Their gap-period status is a documented constitutional finding, not grounds for deletion.

**Regulator-flattening interpretation — Domain requirement evolution invalidates prior records across all domains:**
Evolution of admissibility requirements in one regulator domain does not alter the historical admissibility of records in any other domain. Each domain's historical admissibility is evaluated independently against its own requirements as they existed at the time of the record's production.

**Phase-illegality misreading — Phase retirement retroactively alters phase-legal records:**
The retirement of a constitutional phase — the constitutional transition from Phase N to Phase N+1 — does not retroactively alter the phase legality of records produced during Phase N's active period. Records that were phase-legal when produced retain that status permanently.

**Provenance/runtime collapse — Wave 4 migration tip governs Wave 8 historical evaluation:**
The Wave 4 migration tip operative at a record's production time governs the historical Wave 4 operational admissibility evaluation of that record. It does not govern the historical Wave 8 provenance evaluation. Wave 8 historical evaluation is governed by the Wave 8 signer registry, canonicalization registry, and trust root operative at production time. These are independent temporal evaluations on orthogonal sovereignty surfaces.

**Convergence misreading — All historical records must eventually be re-verified under current doctrine:**
Historical records do not require re-verification under current constitutional doctrine. They were constitutionally verified under the doctrine operative at their production time; that verification is historically permanent. Present-time doctrine applies to present-time records. The only constitutionally authorized basis for re-verification of historical records is a resign operation established by Root constitutional amendment to address a specific identified cryptographic vulnerability.
