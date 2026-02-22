# Symphony Authentication and Identity Boundary Standard

**Document ID:** SEC-AUTH-IDENTITY-BOUNDARY-0001  
**Status:** Canonical (BoZ Submission Supporting Standard)  
**Owner:** CTO (final sign-off), with Security + Compliance review  
**Applies to:** Symphony ingress, service runtime, evidence generation, key management  
**Related:** 
- `docs/security/ZERO_TRUST_POSTURE.md`
- `docs/security/CLIENT_AUTH_TIERS.md`
- `docs/security/CLIENT_AUTH_TIER_MATRIX.md`

---

## 1. Purpose

This document defines and separates the three identity domains used in Symphony:

1. **Client Authentication Identity** (who is calling Symphony)
2. **Service/Mesh Identity** (which Symphony workload is talking to which workload)
3. **Evidence Signing Identity** (which key signs evidence artifacts / proofs)

These identities **must not be conflated**.

This separation exists to prevent architectural and operational errors, especially:
- conflating mTLS mesh certificates with client certificates,
- reusing transport identity as signing identity,
- coupling certificate rotation to evidence signing key rotation,
- creating audit ambiguity about who authenticated a request vs who signed evidence.

---

## 2. Canonical Identity Domains

## 2.1 Client Authentication Identity (External Caller Identity)

### What it is
The identity used to authenticate **external participants/clients** connecting to Symphony ingress APIs.

Examples:
- Bank
- MMO
- PSP
- MFI
- Authorized enterprise client

### What it proves
It proves the caller’s right (subject to authorization checks) to submit or query within a defined participant/tenant scope.

### How it is established
Per `CLIENT_AUTH_TIERS.md`, Symphony supports three client auth tiers:

- **Tier 1:** mTLS client certificate (+ revocation enforcement)
- **Tier 2:** API key + signed JWT claims
- **Tier 3:** API key + trusted headers with strict validation and compensating controls

### Outputs it produces (authoritative identity attributes)
At minimum:
- `participant_id`
- `tenant_id`
- auth tier used
- auth method metadata (certificate serial, JWT kid, or API key identifier/fingerprint)

### What it does NOT do
- It does not identify internal workloads.
- It does not sign evidence artifacts.
- It does not replace mesh identity.
- It does not imply transport encryption posture for internal services.

---

## 2.2 Service / Mesh Identity (Internal Workload Identity)

### What it is
The identity used for **service-to-service** communication inside Symphony runtime infrastructure.

Examples:
- `ledger-api` calling `executor-worker`
- services calling Postgres (depending on deployment mode)
- internal service calls in Kubernetes via service mesh

### What it proves
It proves that one Symphony workload is an authorized internal service communicating with another, according to infrastructure/network policy.

### Typical implementation
- Service mesh mTLS identities (e.g., Istio SPIFFE IDs / service accounts)
- Kubernetes service account bound identities
- Mesh-issued workload certificates with rotation

### Key characteristics
- Short-lived certificates
- Infrastructure-managed rotation
- Used for transport authentication and encryption
- Policy-driven (who can talk to whom)

### What it does NOT do
- It does not authenticate external participants.
- It does not assign `tenant_id` for client requests.
- It does not sign evidence artifacts.
- It must not be treated as the same identity as OpenBao signing keys.

---

## 2.3 Evidence Signing Identity (Artifact Trust Identity)

### What it is
The cryptographic identity used to sign evidence artifacts, reports, and proof packs.

Examples:
- signing deterministic regulator reports
- signing evidence pack manifests
- signing compliance outputs

### What it proves
It proves that a given evidence artifact was signed by an authorized Symphony evidence-signing process/key under a controlled key management regime.

### Where it lives
- OpenBao (or equivalent HSM/KMS-backed secure key management)
- Strict access control and audit logging
- Rotation policy independent from mesh certificate rotation

### Key characteristics
- Controlled key lifecycle
- Signing permissions are tightly scoped
- Rotation schedules driven by crypto policy and evidence assurance requirements
- Audit trail of signing operations

### What it does NOT do
- It does not authenticate API callers.
- It does not replace mTLS for services or clients.
- It does not establish tenant scope in application sessions.
- It must not be reused as a transport TLS certificate.

---

## 3. Boundary Rules (Non-Negotiable)

### Rule 1 — Identity separation is mandatory
Client auth identity, mesh identity, and evidence signing identity are three separate identity domains with separate trust anchors and separate rotation lifecycles.

### Rule 2 — Mesh mTLS identity is not evidence signing identity
Service mesh certificates are for transport authentication/encryption only. They must not be used to sign evidence artifacts or reports.

### Rule 3 — Client mTLS certificate is not evidence signing identity
Even when a client authenticates using mTLS, the client certificate is only for caller authentication. It must not be used to sign Symphony-generated evidence.

### Rule 4 — Client auth tier determines request identity quality, not evidence signing trust
The tier used by a client (Tier 1/2/3) affects confidence in caller identity and authorization posture, but evidence artifact signatures are produced by Symphony’s signing identity regardless of client tier.

### Rule 5 — Rotation policies are independent
- Client cert revocation/rotation ≠ mesh cert rotation ≠ evidence signing key rotation
- A rotation event in one domain must not force ad hoc rotation in another domain unless a broader incident policy explicitly requires it.

### Rule 6 — Auditable provenance must record identity domain used
Evidence and logs should identify which identity domain was involved:
- request authenticated by [client auth tier/method]
- internal transport via [mesh identity]
- artifact signed by [evidence signing key ref/version]

---

## 4. Request Processing Identity Flow (Canonical Model)

## 4.1 External request ingress
1. Client connects to Symphony ingress.
2. Client is authenticated via Tier 1 / Tier 2 / Tier 3 method.
3. Symphony derives authoritative request identity attributes (`tenant_id`, `participant_id`) from the authenticated source.
4. Authorization checks validate scope and request consistency.
5. Application proceeds to DB work using validated identity context.

> Note: For lower tiers, compensating controls and tighter monitoring are required because identity assurance is weaker.

## 4.2 Internal service calls
1. Symphony services communicate over internal channels.
2. Service mesh / workload identity enforces service-to-service authentication and encryption.
3. Mesh identity authorizes workload communication paths.
4. Internal transport identity does not alter external caller identity already established at ingress.

## 4.3 Evidence generation/signing
1. Runtime generates deterministic evidence artifact content.
2. Signing component requests signature operation from OpenBao-managed key.
3. Evidence artifact is signed and stored with provenance metadata.
4. Signing provenance includes key reference/version and timestamp.
5. Signing identity remains independent of both client and mesh identity.

---

## 5. Why This Separation Matters (Regulatory + Engineering)

### 5.1 Regulatory clarity (BoZ / audit context)
This separation allows Symphony to answer distinct audit questions cleanly:
- **Who called the system?** → client auth identity
- **Which internal services handled the request?** → mesh identity
- **Who signed the evidence/report?** → evidence signing identity

Without this separation, audit reconstruction becomes ambiguous and weak.

### 5.2 Engineering safety
This prevents common implementation errors:
- tying evidence signing keys to service mesh cert rotation
- assuming mesh mTLS means client identity is cryptographically proven
- accidentally using a transport cert as a signing cert
- mixing operational controls and crypto domains in incident response

---

## 6. Task Boundary Guidance (INF-004 vs INF-006)

This section exists specifically to prevent prompt ambiguity and implementation drift.

### 6.1 TSK-P1-INF-004 (service-to-service mTLS)
This task covers:
- internal workload identity
- mesh/service-to-service mTLS posture
- transport encryption between Symphony services
- mesh certificate rotation verification (if applicable)

This task does **not** cover:
- evidence signing keys
- signing key storage
- report/evidence signatures
- client authentication tier policy (except documenting interaction points)

### 6.2 TSK-P1-INF-006 (evidence signing via OpenBao)
This task covers:
- evidence signing keys in OpenBao
- signing key lifecycle/rotation policy
- signing verifier and signature proof outputs
- deterministic evidence signature posture

This task does **not** cover:
- mesh mTLS certificates
- service mesh identity policy
- client certificate authentication at ingress

### 6.3 Integration point (allowed boundary)
The only valid integration is metadata/provenance:
- INF-004 may expose mesh identity posture evidence
- INF-006 may reference that signing occurred within an internally authenticated runtime
- but keys/certs/rotation are managed independently

---

## 7. CI / Documentation Verification Expectations

CI should verify (at minimum):
1. This document exists and is non-empty.
2. It explicitly contains the three identity domains:
   - client auth identity
   - service/mesh identity
   - evidence signing identity
3. It states separation/non-conflation rule.
4. It references INF-004 and INF-006 task boundary guidance.

Evidence may be emitted by:
- `scripts/audit/verify_client_auth_tiers_docs.sh` (basic presence)
- a future dedicated verifier:
  - `scripts/audit/verify_auth_identity_boundary_doc.sh`

---

## 8. Open Items / Placeholders (if needed)

> Replace or remove before final BoZ submission if all decisions are settled.

- **[PLACEHOLDER]** Exact ingress TLS termination architecture (ingress controller vs pod-level termination) by environment
- **[PLACEHOLDER]** Final service mesh product choice (if not yet fixed)
- **[PLACEHOLDER]** Evidence signing key rotation cadence (policy-specific)
- **[PLACEHOLDER]** Client certificate issuance/revocation operational workflow owner(s)

---

## 9. Approval

- **Final sign-off:** CTO
- **Security review:** [NAME / ROLE]
- **Compliance review input:** [NAME / ROLE]
- **Version effective date:** [YYYY-MM-DD]