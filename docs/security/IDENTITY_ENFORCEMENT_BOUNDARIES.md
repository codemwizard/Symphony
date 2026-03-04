# Symphony Identity Enforcement Boundaries Standard

**Document ID:** SEC-IDBOUND-0003  
**Status:** Canonical Engineering Standard (BoZ-supporting)  
**Owner:** CTO  
**Contributors:** Security, Platform, Ledger, Integrations  
**Applies to:** Authentication, authorization, RLS, mTLS, service mesh, evidence signing implementations  
**Related:** `ZERO_TRUST_POSTURE.md`, `CLIENT_AUTH_TIERS.md`, `PHASE_BOUNDARIES.md`

---

## 1. Purpose

This document defines the boundaries between identity systems in Symphony so teams do not conflate:

- service mesh/workload identity,
- client authentication identity,
- application authorization scope,
- database session scope,
- and evidence signing identity.

This is the document that prevents INF-004 (mTLS), INF-006 (evidence signing), TEN-002 (RLS), and API auth tasks from drifting into incompatible implementations.

---

## 2. The Five Identity Domains (Canonical)

Symphony recognizes five distinct identity domains.

### 2.1 Client Identity (External Caller)
Who is calling Symphony (bank, MMO, merchant, auditor client app)?

Examples:
- mTLS client certificate identity
- signed JWT subject/client
- API key identity

Used for:
- client authentication
- deriving tenant/participant scope
- request audit trail

### 2.2 Workload Identity (Service-to-Service / Infrastructure)
Which Symphony workload is talking to which other workload?

Examples:
- mesh-issued workload cert
- Kubernetes service account identity
- internal mTLS identities

Used for:
- service-to-service authentication
- internal transport encryption
- lateral movement reduction

### 2.3 Application Authorization Identity (Effective Request Scope)
What tenant/participant/role scope is in effect for this request after authentication and authorization?

Examples:
- `effective_tenant_id`
- `effective_participant_id`
- `effective_permissions`

Used for:
- authorization decisions
- audit logging
- policy checks
- DB session scope derivation

### 2.4 Database Session Identity / Scope
What the DB uses to enforce row access and permissions for the current operation.

Examples:
- DB role (`symphony_app`, `symphony_executor`, `symphony_auditor_boz`)
- session variables (`app.current_tenant_id`, `app.current_participant_id`)
- RLS policy context

Used for:
- SQL privilege enforcement
- row-level isolation
- safety-net containment

### 2.5 Evidence Signing Identity
Which cryptographic key signs evidence artifacts/reports?

Examples:
- OpenBao-managed signing key
- KMS/HSM-backed signing identity

Used for:
- artifact integrity
- non-repudiation
- external verification

**Hard Rule:** Evidence signing identity is not the same thing as client identity or mesh identity.

---

## 3. Canonical Flow: From Client Request to DB Session Scope

This section defines the mandatory chain of custody for request identity.

### 3.1 Step 1 — Authenticate Client (Tier-aware)
Authenticate using the client’s assigned tier:
- Tier 1 mTLS
- Tier 2 JWT
- Tier 3 API key + trusted headers

### 3.2 Step 2 — Derive Claimed Scope
Extract claimed tenant/participant scope from the tier-appropriate source:
- Tier 1: certificate mapping
- Tier 2: JWT claims
- Tier 3: authorized headers + request consistency checks

### 3.3 Step 3 — Authorize Scope
Verify the client is allowed to act for the claimed scope.
This may include:
- tenant ownership checks
- participant checks
- API operation scope checks
- cross-tenant grant checks (if any)

### 3.4 Step 4 — Create Effective Scope
Produce canonical request scope:
- `effective_tenant_id`
- `effective_participant_id`
- `effective_auth_tier`
- `effective_permissions`

This is the only scope the application may use for downstream decisions.

### 3.5 Step 5 — Set DB Session Context (If Applicable)
Set DB session variables from **effective scope**, not raw request input.

Examples:
- `SET LOCAL app.current_tenant_id = ...`
- `SET LOCAL app.current_participant_id = ...`

### 3.6 Step 6 — Execute Data Access
Application queries must still include explicit tenant filters.
RLS is defense-in-depth, not a substitute for application authorization.

---

## 4. Boundary Rules (Non-Negotiable)

## 4.1 Mesh Identity vs Client Identity
Service mesh mTLS (INF-004) proves **workload identity**, not external client identity.

- Mesh identity cannot be used as a substitute for client auth tier.
- Client auth tier must still be evaluated per request.

## 4.2 Client Identity vs Evidence Signing Identity
Evidence signing keys (INF-006) sign artifacts produced by Symphony.
They do **not** represent client identity and must not rotate on the same policy as client certs or mesh certs unless explicitly designed to do so.

## 4.3 Authorization Scope vs Request Body Fields
Request body fields may be cross-checked but are not authoritative identity sources.

Effective scope must come from authenticated sources and authorization logic.

## 4.4 RLS Session Context Source Rule
RLS session variables must be set from **effective authorized scope**, never directly from raw headers/body.

---

## 5. RLS Positioning and Limits (Truthful Statement)

RLS provides real value, but only when described honestly.

### 5.1 What RLS Protects Against
- accidental missing tenant filters in SQL
- some classes of application query bugs
- blast-radius reduction when app logic is imperfect

### 5.2 What RLS Does Not Automatically Solve
- weak client authentication
- forged claims if session scope is derived from untrusted input
- complex hierarchy authorization by itself
- cross-tenant exceptions without explicit policy design

### 5.3 Hybrid Model Requirement
Symphony uses:
- application authorization and query scoping first
- RLS as defense-in-depth for designated sensitive tables

This is the canonical model.

---

## 6. Table Classification Guidance for RLS (Phase-2+)

This section exists so engineers stop enabling/disabling RLS ad hoc.

### 6.1 Force-RLS Candidates (high sensitivity)
Generally includes tables containing:
- instruction-level transaction data
- finality records
- pending/attempt queues
- PII vault data
- member/device/fraud event records
- escrow financial position records

### 6.2 App-Filtered-Only Candidates (governance/config/system-wide)
Generally includes:
- tenant registry
- participant registry
- rail/profile config
- formula registries
- revocation tables queried prior to session context
- engineering governance tables

### 6.3 Auditor Access
Where regulator roles require cross-tenant read access:
- use explicit policy exceptions or separate read surfaces,
- verify both:
  - auditor can read what it should
  - runtime app role cannot read cross-tenant

---

## 7. INF-004 and INF-006 Boundary (Explicit Resolution)

This section addresses a known implementation ambiguity.

### 7.1 INF-004 (Service-to-service mTLS)
Scope:
- workload/workload identity
- transport encryption between services
- mesh or infrastructure mTLS posture
- certificate rotation and posture verification for service identities

### 7.2 INF-006 (Evidence signing via OpenBao)
Scope:
- application-controlled evidence signing keys
- signing/verification of reports and evidence artifacts
- key rotation and signer provenance verification
- no dependency on mesh-issued certificates

### 7.3 Canonical Boundary Decision
**These identities are separate and must remain separate.**

- Mesh identity is **not** the evidence signing identity.
- Evidence signing key rotation is **not** tied to mesh certificate rotation.
- A verifier for INF-004 cannot be used to claim INF-006 completion, and vice versa.

---

## 8. CI Gate Expectations (Phase-Aligned)

### 8.1 Phase-0
- posture docs exist and are verified
- least privilege posture verified
- structural hooks may exist (e.g., revocation tables)
- no false claim of runtime cryptographic client enforcement

### 8.2 Phase-1
- credible identity controls for primary jurisdiction implemented and tested
- tier behavior is documented and exercised
- limitations are explicit in evidence and reporting
- BoZ-facing statements align with measured truth

### 8.3 Phase-2+
- RLS policy verification + leakage probes
- cross-tenant exception policy tests
- tier-specific runtime enforcement coverage
- evidence signing verification and rotation proofs

---

## 9. Implementation Checklist (Use in Task Prompts)

Any task touching auth, mTLS, JWT, RLS, or evidence signing must state:

1. Which identity domain(s) it modifies (from Section 2)
2. What it derives from what (source of truth)
3. What it must not be conflated with
4. Verifier script path
5. Evidence artifact path
6. `measurement_truth` language for evidence

If a task prompt omits these, it is underspecified.

---

## 10. Placeholders / Clarifications Needed

1. Canonical DB session variable names (`app.current_tenant_id` vs `app.current_tenant`)
   - Placeholder: `[Ledger/Platform to standardize]`
2. Auditor role exact name (`boz_auditor` vs `symphony_auditor_boz`)
   - Placeholder: `[DB role naming canonicalization]`
3. Phase at which Force-RLS becomes mandatory for each table class
   - Placeholder: `[Phase governance + CTO]`

---

## 11. Revision History

- v1.0.0 — Initial canonical identity-boundary standard
## Language Scope
This policy applies to all backend implementation languages in Symphony, including:
- C# (.NET)
- Python
