# Symphony Tenant-Anchored User Model Report

## Findings (ordered by severity)
- Critical: `subjectType === 'user'` bypasses OU issuer checks and never fails closed, so any user envelope can pass even when the issuer is not allowed. `libs/context/verifyIdentity.ts`
- High: Tenant anchor for users is not enforced at type or schema level (participantId/role/status are optional), so a user can be created without a tenant anchor. `libs/context/identity.ts`, `libs/validation/schema.ts`
- High: User-related fields are not bound into the HMAC signature, so `participantId` can be altered without invalidating the envelope. `libs/context/verifyIdentity.ts`
- High: JWT bridge creates only `subjectType: 'client'` with `tenant_default`; no user issuance path exists, and `issuerService: 'ingress-gateway'` is not allowed by schema. `libs/bridge/jwtToMtlsBridge.ts`, `libs/validation/schema.ts`
- Medium: Authorization model does not distinguish user capabilities from client/service; policy only defines `service`/`client` capability maps. `libs/auth/authorize.ts`, `libs/auth/capabilities.ts`
- Medium: `trustTier` allows `internal` for users; no explicit enforcement or policy for user trust tier. `libs/context/identity.ts`, `libs/context/verifyIdentity.ts`
- Medium: JWT claims (e.g., `tenant_id`) are not mapped into tenant-anchored user identity; no replay/`jti` handling in identity layer. `libs/bridge/jwtToMtlsBridge.ts`

## Status of Tenant-Anchored User Model (current codebase)
- Implemented only as a permissive schema/type: `subjectType: 'user'` exists, but tenant anchoring is optional and not enforced.
- No issuance path or bridge for `subjectType: 'user'` exists; inbound JWTs are mapped to `subjectType: 'client'` only.
- No user-specific authorization path or capability scoping exists.
- User claims are not bound to identity signatures, so the tenant anchor is not integrity-protected.

Overall: the tenant-anchored user model is not implemented in a secure or enforceable way today; it is a stub with gaps that allow ambiguity and bypass.

## Banking-grade compliance gaps (requirements to reach industry standard)
- Strong identity verification at ingress (OIDC/JWKS, issuer/audience allowlists, token lifetime, `jti` replay control).
- Enforced tenant anchoring and explicit trust tier separation (user cannot be treated as participant/system).
- Capability-based authorization specific to users (least privilege, explicit mapping, no role strings without mapping).
- Cryptographic binding of tenant anchor fields into signed identity envelope.
- Audit trails with immutable, non-repudiable logs capturing user actions (subject type/id + tenant).
- Key management controls: rotation, HSM/KMS for signing keys, separation of duties, non-exportable keys.
- Secure SDLC artifacts: threat model for user flows, tests for authZ/authN boundary, and formal policy enforcement evidence.
- Data governance: PII classification, retention, access reviews, break-glass procedures, incident response logs.

## Improvements to the document (clarifications and risks)
- Align terminology: `tenantId` vs `participantId` must be explicit (tenant anchor for users must be `participantId`; if `tenantId` remains, define its role).
- Clarify policy binding: code currently uses DB policy version checks (`validatePolicyVersion`); document should explicitly state whether PaC commit pinning replaces it or not. `libs/context/verifyIdentity.ts`
- Require user-specific capabilities and forbid “user == client” semantics; add concrete capability map.
- Explicitly state trust tier allowed value for users and enforce it.
- Add issuer allowlist and JWKS requirements with rotation and caching; avoid HMAC/shared secret for user tokens.
- Add attestation log requirements for subjectType/user (subject id hash, participantId) for regulator auditability.

## Guidance answers
- Issuer allowlist: use explicit OIDC issuer URLs for each environment (e.g., `https://idp.symphony.bank/`), configured via env and validated strictly; default to the single corporate IdP. Avoid free-form strings.
- User trust tier value: recommend `trustTier: 'external'` for all user identities until a dedicated `'user'` tier is introduced end-to-end (schema, policy, logging, and checks). If you add `'user'`, it must be enforced in verify/authorize/logging.
- JWKS vs pre-shared key: for banking compliance, use full JWKS (OIDC) with rotation and caching. Pre-shared HMAC is not appropriate for external user identities.

## Secure implementation plan (tenant-anchored user pattern)
1) Type + schema hardening
- Replace `IdentityEnvelopeV1` with a discriminated union so user fields are required only for `subjectType: 'user'` and forbidden elsewhere. `libs/context/identity.ts`
- Add `zod` refinement so `participantId/Role/Status` are required when `subjectType === 'user'`. `libs/validation/schema.ts`

2) Signature integrity
- Bind `participantId/Role/Status` into `dataToSign` for user envelopes. `libs/context/verifyIdentity.ts`
- Update all signing sites to use the same canonical payload (bridge or issuer code).

3) Ingress boundary enforcement
- Enforce “user allowed only at ingress boundary” (e.g., only `ingest-api` accepts `subjectType: 'user'`). `libs/context/verifyIdentity.ts`
- Add issuer allowlist for users and fail closed.

4) User issuance path (JWT to user envelope)
- Extend `jwtToMtlsBridge` (or a new bridge) to create `subjectType: 'user'` using verified JWT claims:
  - `subjectId = sub`, `participantId = tenant_id`, `trustTier = external`, `roles/capabilities` from JWT or lookup.
- Include `jti`, `aud`, `iss`, `iat`, `exp` in validation and bind relevant claims into the envelope.

5) Authorization model for users
- Add user-capability map in policy and enforce user-specific capability checks. `libs/auth/authorize.ts`
- Enforce tenant boundary checks where resources are tenant-scoped.

6) Audit + attestation coverage
- Ensure ingress attestation includes `subjectType`, `subjectId` (redacted), and `participantId`.
- Log explicit allow/deny for user actions with capability + tenant scope.

7) Tests and evidence
- Unit tests: schema refinement, verifyIdentity (boundary, issuer allowlist, trust tier), and authorization checks for users.
- Evidence: show user-specific authZ tests and audit log outputs; include in evidence bundle.

8) Compliance hardening
- Key rotation/JWKS cache controls; add alerts on issuer changes.
- Document role/capability mapping and access review cadence.
