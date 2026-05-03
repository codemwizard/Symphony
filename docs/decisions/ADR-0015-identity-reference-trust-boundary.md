# ADR-0015: Identity Reference and PII Trust Boundary

## Status
Proposed (Phase-1 Authority). Supersedes [ADR-0013](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/docs/decisions/ADR-0013-zdpa-pii-decoupling-strategy.md) passive model.

## User Review Required

> [!IMPORTANT]
> **Normative Protocol**: This ADR mandates the **12-field signed binary tuple** as the ONLY valid wire contract for identity references. Compact variants and ad hoc expansion are strictly PROHIBITED.

> [!WARNING]
> **Evidence Standard**: All implementation evidence MUST be anchored to **Runtime Invocation Trust** (hardware-rooted attestation, signed execution receipts), not merely passive custody proof.

> [!CAUTION]
> **Technical Forensic Isolation**: Forensic re-derivation is restricted to a dedicated, technically isolated execution plane with NO shared service principals and NO synchronous response channel.

## Context
Symphony requires a defensible ZDPA-safe (Zambia Data Protection Act) architecture for KYC and PII. The previous model (ADR-0013) introduced PII decoupling but treated the trust boundary as a passive storage problem. This ADR corrects that position by establishing a cryptographic control plane.

## Decision
Symphony will decouple raw PII from the ledger using OpenBao not merely as a secret store, but as the **Identity Derivation and Controlled Disclosure Authority**.

### 1. Cryptographic Control Plane
OpenBao is the only authority permitted to:
- Own identity derivation keys and attestation signing keys.
- Perform deterministic pseudonym derivation via **Keyed HMAC-SHA-256**.
- **HMAC Input Contract**: MUST use length-prefixed framing. Payload gets `u32be` because it is the only unbounded field (may exceed 64 KiB); all other fields are bounded protocol metadata and MUST use `u16be`. 
    - Contract: `u16be(len(canon_v)) | canon_v | u16be(len(domain)) | domain | u32be(len(payload)) | payload`. Delimiter-based framing is strictly PROHIBITED.
- **Signature Input Contract**: Signature input MUST NOT use JSON. It MUST use binary length-prefixed framing of fields 1–11: `u16be(len(f1)) | f1 | u16be(len(f2)) | f2 | ... | u16be(len(f11)) | f11`.
- **Output Contract**: Full 32-byte raw digest encoded as **base64url** (no padding). Canonical textual form for SHA-256 is exactly **43 base64url characters**, case-sensitive, no padding, no whitespace, and MUST round-trip to exactly 32 bytes. Padded input or non-canonical alphabet variants MUST be rejected on ingest.
- **Hard Invariant**: HMAC and attestation keys MUST be API non-exportable and policy-restricted. Extraction resistance is enforced at the API/policy layer; however, extraction is NOT extraction-impossible under full host compromise. 
- **Hard Invariant**: "No plaintext backup" mandated. Implementation MUST use seal-wrap and Shamir quorum; unmanaged key imports and unsealed dev-mode mounts in production are PROHIBITED. Infrastructure-level snapshot leakage (plaintext raft snapshots, debug snapshots, or volume-level VM snapshots of unsealed instances) is strictly PROHIBITED.
- **Leakage Control Set**: The following are explicitly PROHIBITED on regulated nodes:
    - Plaintext raft/debug snapshots.
    - Host-level VM snapshots of unsealed instances.
    - Memory/Heap snapshots and Crash dumps with heap pages.
    - Support bundles containing transit request bodies.
    - Sidecar/Agent trace captures of request payloads.
- **Observability & Leakage Control**: Regulated PII boundary workloads MUST prohibit:
    - Memory/Heap/Crash dump generation.
    - Tracing or log export of request bodies/PII payloads.
    - Support bundle generation without automated redaction.
    - Debug endpoints and sidecar/agent payload capture.
    - **Remote Exfiltration**: Prohibit crash uploader agents, external APM sinks, and OTel exporters carrying request attributes from regulated workloads.
- **Signing Semantics**: PII boundary submits canonical binary material to OpenBao transit for Ed25519 signing; signing occurs exclusively inside OpenBao.
- **Signature Verification**: Verifiers MUST reconstruct signature input binary material from parsed tuple fields and MUST NOT verify over any caller-supplied pre-serialized blob.
- **Fail-Closed Verification**: Verifiers MUST fail closed on unknown fields, cardinality mismatches, unknown versions, or un-pinned domains.
- **Normative Vectors**: Golden protocol vectors are **normative and binding**. TSK-P1-SEC-014 is the explicit protocol authority; all implementations MUST be proven against 014 fixtures. Verifiers verify binary tuples ONLY; transcripts MUST be independently regeneratable from declared inputs and pinned state (Reproducible Determinism).
- **Clock Authority Hierarchy**: 
    - **Tier 1 (Strict)**: Maximum drift tolerance of **1500ms** (default).
    - **Tier 2 (Degraded Mode)**: Explicit incident posture for multi-region or high-load conditions; requires calibration evidence and incident classification. Maximum drift **5000ms**.
    - **Hard Reject**: Discrepancies above **5000ms** MUST trigger a verifier hard-reject.

### 1.1 OpenBao as Cryptographic Enforcement Boundary
OpenBao is a cryptographic enforcement boundary, **not a semantic trust oracle**. 
- It proves custody, policy mediation, and signing authority. 
- It does **not** independently prove operator legitimacy, human identity uniqueness, approval independence, or business authorization correctness. 
- **Composite Trust Boundary**: OpenBao is the enforcement boundary ONLY while host integrity, token integrity, and seal integrity assumptions hold.
Auditors and engineers MUST NOT over-credit OpenBao with semantic authority.

### 2. Derivation Prohibitions
- **App-layer derivation is PROHIBITED**: The application may never own derivation keys or compute `identity_ref`.
- **DB-layer derivation is PROHIBITED**: The database may never compute identity derivation; it only stores the resulting tuples.

### 3. Identity Reference (`identity_ref`)
A valid `identity_ref` is a metadata-rich **12-field tuple** emitted by the PII boundary, signed by the **PII-Attestation-Key** (Ed25519).
- **Normative Tuple Ordering (12 Fields)**:
    1. `identity_ref` (the HMAC digest)
    2. `derivation_algorithm` (e.g., `hmac-sha256-v1`)
    3. `identity_ref_policy_alias` (Audit correlation metadata)
    4. `identity_ref_key_id` (Concrete derivation key identity)
    5. `identity_ref_key_version` (Provenance anchor)
    6. `attestation_policy_alias` (Audit correlation metadata)
    7. `attestation_key_id` (Concrete signer key identity)
    8. `attestation_key_version` (Signer provenance anchor)
    9. `canonicalization_version` (e.g., `v1`)
    10. `derivation_domain` (e.g., `symphony-kyc`)
    11. `schema_version` (e.g., `1.1.0`)
    12. `attestation_signature` (Ed25519 signature)
- **Hard Protocol Standard**: All identity references MUST be emitted as a **12-field signed binary tuple**. No alternate tuple cardinality is valid.
- **Signature Input**: The signature input MUST be the binary length-prefixed serialization of **fields 1–11**. Reordering is invalid and MUST fail verification.
- **Algorithm Agility Denial**: Ed25519 is the sole permitted signature algorithm. Implementations MUST NOT support algorithm fallbacks or silent downgrade to weaker primitives.
- **Key-Version Monotonicity**: Verifiers MUST enforce key-version monotonicity:
    - Verifier MUST maintain a per-`key_id` observed max version.
    - Reject if tuple version `<` observed max version for the same `key_id`.
- **Historical Validation Mode (Privileged)**: 
    - MUST be treated as a privileged forensic mode with explicit capability segregation.
    - Mandatory case binding, reason code, and separate audit class required.
    - PROHIBITED in live transactional paths; non-user-facing ONLY.
- **Verifier Trust Chain**:
    - The verifier MUST resolve the attestation public key from a **pinned trust bundle** or a **signed registry**.
    - Verifiers verify reconstructed binary tuples only; verifiers DO NOT verify JSON.
    - `attestation_key_id` and `attestation_key_version` binding is mandatory.
- **Provenance**: Verification MUST bind both `key_id` and `key_version`. Any observer projection (SIEM/Dashboards) that drops `key_version` is non-compliant.
- **Key Rotation & Governance**:
    - **Re-derivation Policy**: Historical identity references MUST NOT be re-derived by application or business workflows. 
    - **Forensic Technical Isolation**: Controlled re-derivation is permitted ONLY within forensic paths with:
        1. **Technical Isolation**: MUST use a dedicated non-transactional execution plane with a separate auth domain and NO shared service principals.
        2. **Technical Denial**: Forensic outputs MUST be envelope-encrypted to case-bound recipient keys before persistence.
        3. **Cardinality Limits**: NO bulk re-derivation; per-case authorization ONLY.
        4. **Case TTL**: Authorization is valid for maximum 4 hours; single case ID binding.
        5. **Output Sink Restrictions**: Results MUST be emitted to restricted write-only write-once buckets; NO synchronous caller response channel; NO interactive human retrieval path.
        6. **Escrow Response Channel**: Response MUST return only escrow handles and audit receipts; derived material is NEVER returned through the broker response channel.
        7. **Replay Determinism**: Forensic reconstruction MUST produce byte-for-byte identical results to production derivation under identical inputs and domains.
    - **Anti-Correlation Governance**: `derivation_domain` values MUST be selected from a **centrally governed registry**. Issuance requires uniqueness, non-overlap, anti-correlation review, purpose binding, and revocation semantics. Ad hoc domains are PROHIBITED.

### 4. KYC Trust Boundary
The `kyc_hold` gate on payment instructions is cleared ONLY when the PII boundary issues a sealed, attested identity tuple. The flow must be:
1. **Ingest**: Raw identity docs enter ONLY through the PII boundary.
2. **Validate**: Provider checked against `kyc_provider_registry`.
3. **Seal**: Raw KYC package sealed into vault storage (never in the general app DB).
4. **Derive**: PII boundary derives `identity_ref` via OpenBao.
5. **Emit**: Only the compliance tuple leaves the boundary.
6. **Release**: `kyc_hold` is cleared based on the presence of the signed tuple.

### 5. Controlled Disclosure (Dual-Principal Brokered)
- **Independence Constraints**: Rejection mandated if approvals share the same `subject_id`, `auth_session`, or `principal_domain`.
- **Independence Matrix**: Broker MUST enforce an **Independence Matrix**: human root, device root, authenticator root, IdP lineage, and organizational reporting chains.
- **Graph Enforcement Math**:
    - **Nodes**: Principal identities.
    - **Edges**: Approval participation within a rolling 30-day window.
    - **Edge Weight**: Recency-weighted joint approvals.
    - **Hard Reject**: Reciprocal edges (Approver A and B swap roles within window).
    - **Hard Reject**: Artifact replay (reused artifacts, tokens, or `case_id`).
    - **Review Trigger**: Pair reuse above threshold **K**. K MUST be organization-size normalized and policy-derived; baseline 3 applies where no calibrated model exists.
    - **Review Trigger**: Local weighted clustering coefficient threshold (default 0.4); triggers mandatory compliance review with calibration evidence.
- **Disaster Recovery (DR) Invariants**:
    - **Seal Parity**: DR cluster MUST enforce seal parity with primary (HSM/KMS wrapping).
    - **Quorum Independence**: Recovery quorum holders MUST satisfy organizational independence constraints.
    - **Witnessed Restore**: Restore ceremonies MUST be witnessed, transcripted, and anchored to verifiable evidence.
    - **Activation Audit**: DR activation MUST emit a distinct, non-maskable audit class.
- **Temporal Separation**: Minimum 300s separation between approval legs for high-risk disclosures.
- **Replay Protection**: Rejection mandated for reused approval artifacts, reused wrapped tokens, or reused `case_id`. 
- **Uniqueness Key**: Replay uniqueness MUST include: `(subject_ref, requester, purpose, scope, case_id, approver_set_hash, approval_artifact_hash)`.
- **Token Lineage**: Disclosure token issuance MUST bind lineage to the specific disclosure edge.
- **Introspection Authorization**: Permitted ONLY to broker service principals; returns control metadata only. Caller principals MUST NOT possess `read` or `introspect` capabilities.
- **Audit**: Every disclosure event captures both approvers, device_ids, authenticator_assurance_levels, purpose_code, and case_id.

## Rationale
Treating OpenBao as a passive secret store keeps the liability in the application. By moving derivation and disclosure policy into OpenBao, we reduce the trust surface and ensure that raw PII is isolated from both the application logic and the database persistence layer. This provides a technically and legally defensible position for ZDPA compliance.

## Migration Contract (Supersedes ADR-0013)
- **Legacy Identity References**: Existing `identity_hash` values are grandfathered for historical lookups but MUST be flagged as `legacy-unattested`.
- **Dual-Read Transition**: The PII client MUST support a dual-read period where it resolves both legacy hashes and normative attested tuples.
- **Downgrade Resistance**: 
    - **No Trust Equivalence**: Legacy-unattested identities MUST NEVER satisfy controls requiring attested provenance.
    - **Lookup Compatibility Only**: Dual-read is for lookup compatibility only, never trust equivalence.
    - **Domination**: If both legacy and attested versions exist for a subject, the attested version MUST dominate.
    - **Closed Resolution**: Ambiguity resolution MUST fail closed; no automatic legacy-to-attested equivalence projection is permitted without explicit re-attestation.
- **Attestation Upgrade**: Future KYC re-verification MUST trigger an upgrade to the normative 12-field attested tuple.

### 4. Key Custody and Operation Confinement
Derivation and signing keys are hosted in the **OpenBao Transit Engine**.
- **Invariants**:
    - The trust primitive is the full chain: **non-exportable key material + operation-constrained policy + verifier-proven deny graph**.
    - Keys are **API non-exportable under trusted host and seal assumptions** (`exportable=false`).
    - **Operation Confinement**: ACL policies MUST explicitly `deny` `read`, `export`, `backup`, and `rewrap` on the **derivation/attestation key hierarchy** and descendant policy aliases. Inherited wildcard grants are prohibited.
    - **Seal Integrity**: Seal-wrap MUST be enabled; unmanaged imports are PROHIBITED.
- **Custody Evidence**: Verifiers MUST prove active custody at the claimed time.

## [ADDED] Canonical JSON Specification (Normalization Only)
- **Status**: Canonical JSON is a pre-processing normalization grammar ONLY. It is NOT part of the verification primitive.
- **Hard Rules**:
    - **UTF-8**: Enforce strict UTF-8; reject overlong encodings.
    - **Unicode Scalar Validity**: Reject surrogate code points (`U+D800`–`U+DFFF`), noncharacters, and control characters except allowed escaped forms.
    - **Unicode Normalization**: MUST be **NFC**.
    - **Duplicates**: Uniqueness collision domain is the **normalized Unicode scalar sequence**; MUST be evaluated after JSON string unescaping and NFC normalization, and BEFORE ordering.
    - **Ordering**: Lexicographic key ordering by raw **UTF-8 octet compare**.
    - **Numbers**: Integer-only; magnitude bounded to `2^53 - 1`. No leading `+`, no leading zeros (except literal `0`), no `-0`. ASCII digits ONLY. No whitespace around tokens.
- **Limits**: Maximum field sizes MUST be enforced before normalization.

## [ADDED] Evidence Standard (Runtime Invocation Trust)
Implementation evidence for high-trust operations MUST be anchored to **Runtime Invocation Trust**, not merely passive custody proof. 
- **Anchor Independence**: Anchors MUST NOT share cloud accounts/tenants, IAM roots, HSM tenancy, or signing lineage. At least one anchor MUST be external to the primary execution trust domain.
- **Runtime Trust Requirements**:
    - **Caller Identity Attestation**: Evidence MUST include a cryptographic proof of the caller's identity (e.g., OIDC identity token, SPIFFE SVID) bound to the operation.
    - **Environment Integrity**: Evidence MUST include hardware-rooted environment attestation (vTPM, AWS Nitro Enclave, Azure SNP) proving the execution environment was uncompromised at the time of invocation.
    - **Policy Enforcement Context**: Evidence MUST capture the exact policy version and resolved alias applied at runtime, bound to the execution receipt.
    - **Signed Execution Receipts**: OpenBao MUST return a signed receipt of the transit operation, including the request hash, timestamp, and key version.
- **State-Coupled Mandatory Proof Artifacts**:
    - `runtime_invocation_attestation`: Cryptographic proof of trusted environment and caller identity.
    - `derived_state_fingerprint`: Hash of effective verifier state.
    - `policy_eval_transcript_sha256`: Deterministic capture of policy evaluation.
    - `negative_test_failure_proof`: Capture of rejected unauthorized inputs.
    - `binary_fixture_digest_set`: SHA-256 of normative golden vectors tested.
    - `tuple_contract_version`: Normative contract version (e.g., `v1.12`).
    - `canonicalization_rule_digest`: Hash of the normalization grammar used.
    - `verifier_nonce`: Bound to the current session.
    - `environment_attestation`: OpenBao build fingerprint, seal type, and host integrity digest.
