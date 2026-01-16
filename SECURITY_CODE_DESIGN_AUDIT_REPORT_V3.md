# Security and Code Design Best-Practice Audit Report (V3)

Project: Symphony
Date: 2026-01-15
Scope: /home/mwiza/workspaces/Symphony
Excluded: `_Legacy_V1` (explicitly excluded from all analysis)

## 1) Scope and methodology
- Static review of application code, configuration, and security documentation.
- Focus on ISO-27001:2022, ISO-27002, ISO-20022, PCI DSS 4.0, and OWASP Top 10 alignment.
- Test suite review with emphasis on authenticity (tests must import production implementations and exercise success + failure paths).
- ESLint enforcement review based on running the project’s configured ESLint.
- No dynamic penetration testing or dependency CVE scanning executed in this pass.

## 2) Executive summary
The codebase shows notable security hardening updates since prior reports (AsyncLocalStorage request context, JWT verification, timing-safe signature checks, policy parity enforcement, log redaction). However, compliance readiness is still blocked by (a) trust fabric governance, (b) configuration inconsistencies and optional transport security, (c) incomplete unit-test coverage against production implementations (especially in the .NET Core services), and (d) **existing ESLint errors/warnings** (7 errors, 54 warnings) which violate the “no lint errors or warnings” requirement.

## 3) Current lint status (blocking)
ESLint run (excluding `_Legacy_V1`): **7 errors, 54 warnings** remain. The project is not currently in a lint-clean state.
- Representative failures: `scripts/validation/invariant-scanner.ts` (no-console), `scripts/ci/*.cjs` (no-undef/no-require-imports), and multiple `@typescript-eslint/no-explicit-any` / unused-vars warnings across libs and services.

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
- Impact: Linting skips `**/*.spec.ts` and all `**/*.js`, and does not enable type-aware or security plugin rules in all configs; compliance evidence for secure coding checks is weaker than required by PCI DSS Req 6 / ISO-27001 A.14.
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

## 5) Unit test coverage audit (production implementation + success/failure paths)

### Node.js
Findings:
- Several tests do not exercise production implementations directly and/or do not test both success and failure paths (see examples below).
- This does not meet the stated requirement for compliance-grade testing.

Examples (insufficient):
- `tests/unit/OutboxRelayer.spec.ts`: simulates state machine and mocks without running actual relayer methods.
- `tests/unit/OutboxDispatchService.spec.ts`: uses ad-hoc query mocks; does not instantiate and invoke production service methods.
- `tests/unit/IngressAttestationMiddleware.spec.ts`: validates local object shapes without invoking the middleware/service.

Examples (improving):
- `tests/unit/VerifyIdentity.spec.ts` exercises success and failure paths on the production `verifyIdentity` function.
- `tests/unit/JwtBridge.spec.ts` validates signature failure against the production `jwtToMtlsBridge` implementation.
- `tests/unit/RequestContext.spec.ts` validates AsyncLocalStorage isolation.

### .NET Core (special emphasis)
Coverage is **insufficient** relative to the requirement that all components that should have tests must include success and failure paths using production implementations.

- Domain layer:
  - `FinancialCore/tests/FinancialCore.Tests/DomainInvariantTests.cs` validates failure paths (invalid transitions) but does **not** include a success-path transition test.

- Application services:
  - `FinancialCore/tests/FinancialCore.Tests/AtomicityTests.cs` validates a failure path in `InstructionService.TransitionInstructionAsync` but does **not** test a success path (ledger entries + commit) against the real service implementation.
  - No unit tests found for `InstructionService.CreateInstructionAsync` success/failure (duplicate idempotency vs new instruction).
  - No unit tests found for `LedgerService.ValidatePostingAsync` success/failure.

- Infrastructure / repositories:
  - No unit tests found for `InstructionRepository`, `LedgerRepository`, `UnitOfWork`, or `FinancialCoreDbContext` configuration and constraints.

- API layer:
  - No unit tests found for `LedgerController` or `InstructionsController` routes (success + failure). This leaves request validation and error handling unverified.

Conclusion: The .NET Core components do **not** meet the stated unit-test requirements at this time.

## 6) Compliance alignment summary

### ISO-27001:2022 / ISO-27002
- Strengths: Identity verification improvements, policy parity checks, and logging redaction.
- Gaps:
  - Trust fabric governance and revocation not production-grade.
  - Policy file integrity not protected.
  - Test coverage gaps for critical components (especially .NET Core services).

### ISO-20022
- Strengths: Schema validation and semantic checks exist in Node libs.
- Gaps:
  - No end-to-end ISO-20022 conformance or transport handling verification.

### PCI DSS 4.0
- Strengths: Secure SDLC procedures documented; identity verification and policy parity checks improved.
- Gaps:
  - TLS for database connections is optional.
  - Trust fabric governance gaps persist.
  - Unit tests do not fully validate production code paths (success + failure) in both Node and .NET.
  - Lint is not clean (errors/warnings present).

### OWASP Top 10 (2021)
- A01 Broken Access Control: subjectType mismatch handling and incomplete test validation.
- A05 Security Misconfiguration: KMS config mismatch, optional TLS, incomplete lint enforcement.
- A07 Identification and Authentication Failures: trust fabric governance gap.
- A09 Security Logging and Monitoring Failures: identifier logging without explicit classification policy.

## 7) Recommendations (prioritized)
1) Replace TrustFabric hardcoded registry with a signed or database-backed registry; implement revocation propagation (OCSP/CRL or short-lived certs).
2) Align KMS config guards with actual key usage (KMS_KEY_ID vs KMS_KEY_ARN) and fail-closed on missing values.
3) Require DB TLS in production unconditionally and enforce certificate validation.
4) Protect policy file integrity (signed policy manifest, WORM storage, or DB-backed version with integrity checks).
5) Make ESLint clean: add a lint script, apply overrides for scripts/CI files, and address all remaining errors/warnings.
6) Expand .NET unit tests to cover production implementations with both success and failure paths:
   - InstructionService (Create + Transition)
   - LedgerService (ValidatePosting)
   - Repositories and UnitOfWork
   - API controllers (success/failure/validation)
7) Refactor Node tests for outbox, attestation, and transaction safety to execute production methods and verify success/failure paths.

## 8) Residual risks and limitations
- Static review only; no runtime or integration testing performed.
- Dependency vulnerability status not assessed.
- External systems (KMS, database, rails) not validated.

