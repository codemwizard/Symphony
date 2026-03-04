# Symphony Client Authentication Tiers
**Document ID:** SEC-AUTH-TIERS-0001  
**Status:** Canonical (BoZ Submission Support)  
**Owner:** CTO (final sign-off), with Compliance review input  
**Applies to:** Client-to-Symphony ingress authentication and tenant scope establishment  
**Last Updated:** {{YYYY-MM-DD}}

---

## 1. Purpose

This document formalizes Symphony’s **client authentication tier policy**.

Symphony operates in environments where client technical capability varies materially (e.g., banks, MMOs, cooperatives, merchants, aggregators). To avoid blocking adoption while preserving a credible security posture, Symphony uses a **tiered authentication model** with explicit trust guarantees, limitations, and upgrade paths.

This policy ensures:
- Trust boundaries are explicit
- Security trade-offs are documented
- Phase claims remain truthful
- BoZ can assess the posture by client class

---

## 2. Tier Ordering (Canonical)

> **Canonical order (strongest → weakest):**
1. **Tier-1: mTLS (client certificate)**
2. **Tier-2: Signed JWT**
3. **Tier-3: API Key + Trusted Headers**

This ordering is mandatory in all Symphony documents and implementations.

---

## 3. Common Rules Across All Tiers

These rules apply to **every** client regardless of tier:

1. **Tenant and participant scope must be explicit**
   - Requests must carry scoped identifiers required by the endpoint contract (e.g., tenant_id, participant_id).
2. **Application-level scope validation is mandatory**
   - Header/body consistency and endpoint-level authorization checks are required.
3. **Least privilege applies**
   - A client credential grants only the minimum scope required.
4. **Audit logging is mandatory**
   - Authentication method, client identifier, and outcome must be logged.
5. **Revocation/disable path must exist**
   - Every credential type must have a disable/revoke mechanism.
6. **Upgrade path must be documented**
   - Tier-3 and Tier-2 clients should have a path to Tier-1 where feasible.

---

## 4. Tier-1 (mTLS + Certificate Revocation) — Strongest

## 4.1 Definition
Client authenticates using a **client TLS certificate** issued by a trusted CA recognized by Symphony. The certificate is validated at connection/request time and checked against a revocation mechanism.

## 4.2 Trust guarantees
Tier-1 provides:
- Cryptographic client identity at transport layer
- Strong resistance to header spoofing
- Certificate-based revocation capability
- Strong basis for deriving participant identity from cert subject/SAN mapping
- Strong compatibility with RLS defense-in-depth when session context is set from validated cert identity

## 4.3 Minimum controls (Tier-1)
- Certificate chain validation against trusted CA
- Expiry validation
- Revocation check (CRL/OCSP and/or governed revocation registry, as implemented)
- Mapping from certificate identity → participant/tenant scope via governed registry
- Explicit logging of cert fingerprint/serial (or safe hash thereof) and auth outcome
- Deny on validation failure (fail-closed)

## 4.4 Limitations / operational realities
- Higher integration complexity for clients
- Certificate issuance/rotation operational overhead
- Some market participants may not be capable of rapid Tier-1 adoption

## 4.5 Phase alignment
- Structural hooks may exist before runtime enforcement (Phase-0)
- Runtime enforcement and verifiers begin in Phase-1 or later according to phase gates
- Production-grade posture expected by Phase-2 for capable participants

---

## 5. Tier-2 (API Key + Signed JWT) — Strong

## 5.1 Definition
Client uses an API key (or equivalent client credential) plus a **signed JWT** where the JWT carries claims used by Symphony for authorization and scope establishment.

## 5.2 Trust guarantees
Tier-2 provides:
- Cryptographically signed claims (tenant/participant/client scope) if Symphony validates signature and issuer
- Better integrity than headers-only scope establishment
- Revocability through key rotation and token expiry policy
- Strong intermediate step toward Tier-1 for clients unable to deploy mTLS immediately

## 5.3 Minimum controls (Tier-2)
- JWT signature validation using approved keys
- Issuer and audience validation
- Expiry (`exp`) enforcement
- Replay risk mitigation (short token TTL; optional `jti` tracking for sensitive flows)
- Claim validation (tenant_id / participant_id / permitted scopes)
- API key validation (if retained as secondary credential)
- Deny on any validation failure (fail-closed)

## 5.4 Limitations
- Security depends on token issuance and signing key protection
- Weaker than mTLS for transport identity binding
- Token leakage risk must be managed (TTL, rotation, logging discipline)

## 5.5 Phase alignment
- Can be used as a credible Phase-1 identity control where Tier-1 is not yet feasible for all participants
- Remains acceptable in Phase-2 for client classes explicitly approved by policy

---

## 6. Tier-3 (API Key + Trusted Headers) — Pragmatic Fallback

## 6.1 Definition
Client authenticates with an API key and supplies request scope (e.g., `x-tenant-id`, `x-participant-id`) via headers and/or body fields. Symphony validates:
- Credential presence/validity
- Internal consistency of declared scope
- Endpoint authorization rules

## 6.2 Trust guarantees
Tier-3 provides:
- Basic caller authentication (shared secret possession)
- Internal request consistency checks
- Operationally practical onboarding for lower-capability clients
- Compatibility with application-layer tenant isolation controls

## 6.3 Minimum controls (Tier-3)
- API key validation
- Header/body consistency validation for scoped fields
- Endpoint-level authorization checks
- Audit logging of client principal + declared scope + outcome
- Key rotation/disable path
- Rate limiting / abuse controls
- Explicit documentation that scope is **declared** and validated for consistency, not cryptographically bound to transport identity

## 6.4 Limitations (must be disclosed)
Tier-3 does **not** provide:
- Cryptographic binding of tenant scope to caller identity
- Strong non-repudiation of client identity at transport layer
- Equivalent assurance to Tier-1 mTLS

Tier-3 is therefore a **constrained-risk posture**, not the target end-state for high-capability institutions.

## 6.5 Phase alignment
- May be permitted in Phase-1 for market onboarding practicality
- Phase-2 policy should define which participant classes may remain on Tier-3 and under what compensating controls

---

## 7. Tier Assignment Policy

## 7.1 Assignment is based on client capability and risk
Tier assignment is not arbitrary. It is determined by:
- Client technical capability
- Transaction risk profile
- Regulatory expectations for the participant type
- Volume/criticality of operations
- Symphony operational ability to support the tier safely

## 7.2 Policy defaults (to be finalized)
- **[PLACEHOLDER]** Banks: default Tier-1 target (mTLS), temporary Tier-2 allowed under approved migration plan
- **[PLACEHOLDER]** MMOs: default Tier-1 target (mTLS), temporary Tier-2 allowed under approved migration plan
- **[PLACEHOLDER]** Cooperatives / smaller merchants / aggregators: Tier-2 or Tier-3 based on capability assessment
- **[PLACEHOLDER]** Internal sandbox/demo clients: controlled Tier-2 or Tier-3 only under explicit non-production labeling

> Note: User clarified MMO and Bank rails are compulsory in Zambia. This affects rail scope, not the authenticity of tier definitions. Tier choice remains capability/risk driven.

---

## 8. Upgrade Path Rules (Tier Progression)

## 8.1 Mandatory upgrade posture
Symphony must support controlled progression:
- Tier-3 → Tier-2
- Tier-2 → Tier-1

## 8.2 No hidden downgrades
Any downgrade (e.g., Tier-1 to Tier-3 due to client outage) requires:
- Explicit approval
- Time-bound exception
- Audit log
- Compensating controls
- Expiry/reversion plan

## 8.3 Exception registry (recommended)
Tier exceptions should be tracked in a governed registry (DB table or equivalent) with:
- client/tenant identifier
- approved tier
- justification
- approved_by
- approved_at
- expires_at
- compensating controls

---

## 9. Interaction with Tenant Isolation and RLS

## 9.1 Important truth
RLS is only as trustworthy as the source of the session tenant context.

- **Tier-1:** session tenant context can be derived from validated cert identity (strong)
- **Tier-2:** session tenant context can be derived from validated JWT claims (strong/intermediate)
- **Tier-3:** session tenant context is derived from declared scope + application validation (pragmatic, weaker)

## 9.2 Policy consequence
When Tier-3 is used, Symphony must not overstate RLS guarantees.  
RLS still provides valuable defense-in-depth against accidental leakage, but not the same cryptographic assurance as Tier-1/Tier-2-derived tenant context.

---

## 10. Evidence and CI Requirements

This document is canonical only if:
1. It exists at `docs/security/CLIENT_AUTH_TIERS.md`
2. `docs/security/ZERO_TRUST_POSTURE.md` exists and references this document
3. The posture docs verifier passes
4. Evidence artifact is emitted in the configured phase path

Recommended evidence fields:
- document_exists checks
- tier_order_verified (Tier-1 mTLS, Tier-2 JWT, Tier-3 API key + headers)
- common_rules_present
- limitations_disclosed_for_all_tiers
- cto_signoff_placeholder_present

---

## 11. Prohibited Ambiguity

The following are prohibited in code/docs:
- Inverting tier strength order
- Calling Tier-3 “zero trust equivalent” to Tier-1
- Omitting limitations for Tier-3
- Claiming mTLS-level assurance for JWT or header-derived scope
- Using undocumented ad hoc auth modes in production-facing flows

---

## 12. Approval and Sign-off

- **Compliance input:** advisory and high-priority review input
- **Final technical sign-off authority:** CTO

This document becomes effective only when the CTO signs off the current revision.
## Language Scope
This policy applies to all backend implementation languages in Symphony, including:
- C# (.NET)
- Python
