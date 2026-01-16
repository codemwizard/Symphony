# Security and Code Design Best-Practice Audit Report (V2)

Project: Symphony
Date: 2026-01-15
Scope: /home/mwiza/workspaces/Symphony

## 1) Scope and methodology
- Static review of application code, configuration, and security documentation.
- Focus on ISO-27001:2022, ISO-27002, ISO-20022, PCI DSS 4.0, and OWASP Top 10 alignment.
- Test suite review with emphasis on authenticity (no faked/self-asserted passes).
- ESLint strictness review based on repository configuration and package metadata.
- No dynamic testing, penetration testing, or dependency CVE scanning executed in this pass.

## 2) Executive summary
Security architecture intent is strong and several critical gaps from the prior review are now resolved (request context isolation, JWT verification, signature comparison, policy parity enforcement, log redaction). Remaining material risks center on trust fabric governance, configuration consistency, transport security guarantees, and test rigor for key runtime controls. ESLint is now present but coverage and rule strictness are incomplete for compliance-grade assurance.

## 3) Resolved since prior review
- Request context is now AsyncLocalStorage-backed for isolation (`libs/context/requestContext.ts:1`).
- JWT bridge performs ES256 verification using jose (`libs/bridge/jwtToMtlsBridge.ts:5`).
- Identity verification enforces token freshness and policy parity (`libs/context/verifyIdentity.ts:18`, `libs/context/verifyIdentity.ts:81`).
- Signature comparison uses timing-safe comparison with canonical JSON (`libs/context/verifyIdentity.ts:49`, `libs/context/verifyIdentity.ts:75`).
- Log redaction is configured (`libs/logging/logger.ts:7`, `libs/logging/redactionConfig.ts:5`).
- Audit chain verifier no longer uses eval (`libs/audit/integrity.ts` has no eval usage).

## 4) Findings (ordered by severity)

### High
1) mTLS TrustFabric relies on hardcoded registry and in-memory revocation
- Impact: No revocation propagation, auditability, or centralized trust management; not production-grade mTLS governance.
- Evidence: `libs/auth/trustFabric.ts:14`
- Standards: ISO-27001 A.8/A.9, ISO-27002 key management, PCI DSS Req 4

2) Crypto config guard expects KMS_KEY_ARN while KeyManager uses KMS_KEY_ID
- Impact: Configuration enforcement can pass while key derivation uses a different, potentially missing variable.
- Evidence: `libs/bootstrap/config-guard.ts:15`, `libs/crypto/keyManager.ts:43`
- Standards: ISO-27001 A.8, PCI DSS Req 3, OWASP A05 (Security Misconfiguration)

3) Database TLS is optional at runtime despite mandatory CA config
- Impact: Connections can run without TLS if DB_SSL_QUERY is unset, conflicting with PCI transport protection requirements.
- Evidence: `libs/db/index.ts:28`
- Standards: PCI DSS Req 4, ISO-27002 network security

4) Policy parity is enforced via local file without integrity verification
- Impact: Active policy version is sourced from `.symphony/policies/active-policy.json` without authenticity guarantees; a tampered file could downgrade enforcement.
- Evidence: `libs/db/policy.ts:19`, `libs/db/policy.ts:44`
- Standards: ISO-27001 A.8, ISO-27002 change control, PCI DSS Req 6

### Medium
5) Identity schema allows subjectType = user, but verification logic does not handle this type
- Impact: Inconsistent trust checks; potential bypass or undefined behavior in authorization paths.
- Evidence: `libs/validation/schema.ts:15`, `libs/context/verifyIdentity.ts:87`
- Standards: OWASP A01, ISO-27002 access control

6) ESLint strictness and coverage are incomplete
- Impact: Linting skips `**/*.spec.ts` and all `**/*.js`, and does not enable type-aware or security plugin rules. Compliance evidence for secure coding checks is weaker than required by PCI DSS Req 6 / ISO-27001 A.14.
- Evidence: `eslint.config.mjs:20`, `.eslintrc.json:16`, `package.json` has no lint script.
- Standards: PCI DSS Req 6, ISO-27001 A.14, OWASP testing practices

### Low
7) Logging still attaches subject identifiers by default in context logger
- Impact: Potentially sensitive identifiers are logged routinely; risk depends on data classification and retention controls.
- Evidence: `libs/logging/logger.ts:19`
- Standards: ISO-27001 A.8, PCI DSS Req 3/10

8) Ingress attestation accepts missing signature and auto-generates request IDs
- Impact: Weakens assurance of provenance for ingress evidence; acceptable for dev but not production-grade.
- Evidence: `libs/attestation/IngressAttestationMiddleware.ts:151`
- Standards: ISO-27001 A.8, ISO-20022 auditability expectations

## 5) Test integrity review (faked or weak tests)

High-concern examples where tests do not execute production logic or assert behavior purely by local data construction:
- `tests/safety.test.js:65` explicitly states verification by inspection and only checks that `executeTransaction` exists. This does not test rollback behavior.
- `tests/unit/IngressAttestationMiddleware.spec.ts:36` validates mock objects without invoking the actual middleware or service logic.
- `tests/unit/OutboxRelayer.spec.ts:47` asserts string fragments and simulated state machines rather than running `OutboxRelayer` methods.
- `tests/unit/OutboxDispatchService.spec.ts:35` uses ad-hoc query calls and synthetic records rather than instantiating `OutboxDispatchService` and verifying its behavior.

Positive improvements:
- `tests/unit/RequestContext.spec.ts` exercises AsyncLocalStorage isolation.
- `tests/unit/JwtBridge.spec.ts` validates ES256 signature rejection.
- `tests/unit/VerifyIdentity.spec.ts` validates policy mismatch and token freshness.

Implication: Some core controls still lack evidence-grade tests for failure modes and integration behavior; this weakens PCI DSS Req 6 and ISO-27001 A.14 assurance.

## 6) Compliance alignment summary

### ISO-27001:2022 / ISO-27002
- Strengths: Strong documentation, audit logging framework, policy parity enforcement, and identity verification improvements.
- Gaps:
  - Trust fabric governance and revocation not production-grade (`libs/auth/trustFabric.ts:14`).
  - Policy file integrity is not protected (`libs/db/policy.ts:44`).
  - Logging still emits identifiers without explicit classification controls (`libs/logging/logger.ts:19`).

### ISO-20022
- Strengths: Schema validation and semantic checks for pacs.008/pacs.002/camt.053.
- Gaps:
  - No end-to-end ISO-20022 conformance or transport handling verification.

### PCI DSS 4.0
- Strengths: Secure SDLC procedures documented; identity verification and policy parity checks improved.
- Gaps:
  - TLS for database connections is optional (`libs/db/index.ts:28`).
  - Trust fabric and revocation controls are not aligned with Req 4/8 expectations.
  - Test evidence for runtime controls is still weak for Req 6.
  - ESLint coverage excludes tests and JS files; no lint script in CI (`eslint.config.mjs:20`, `package.json`).

### OWASP Top 10 (2021)
- A01 Broken Access Control: subjectType mismatch handling.
- A05 Security Misconfiguration: KMS config mismatch, optional TLS, partial lint enforcement.
- A07 Identification and Authentication Failures: mTLS trust fabric governance gap.
- A09 Security Logging and Monitoring Failures: identifier logging without explicit redaction/classification policy.

## 7) Recommendations (prioritized)
1) Replace TrustFabric hardcoded registry with a signed or database-backed registry; implement revocation propagation (OCSP/CRL or short-lived certs).
2) Align KMS config guards with actual key usage (KMS_KEY_ID vs KMS_KEY_ARN) and fail-closed on missing values.
3) Require DB TLS in production unconditionally and enforce certificate validation.
4) Protect policy file integrity (signed policy manifest, WORM storage, or DB-backed version with integrity checks).
5) Enforce linting on all TS/JS sources including tests, and add type-aware + security rules (e.g., @typescript-eslint/recommended-requiring-type-checking, eslint-plugin-security).
6) Strengthen tests for outbox, attestation, and transaction safety with real service invocation and failure-path assertions.

## 8) Residual risks and limitations
- Static review only; no runtime or integration testing performed.
- Dependency vulnerability status was not assessed in this pass.
- External systems (KMS, database, rails) were not validated.

