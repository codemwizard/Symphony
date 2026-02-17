# AI Secure Coding Standard (Policy-Locked)

**STRICT MODE — PRODUCTION ENFORCEMENT**

## 1. Document Control (MANDATORY)

| Field | Value |
|-------|-------|
| Document Title | AI Secure Coding Standard |
| Version | 1.0.0 |
| Status | ENFORCEABLE INTERNAL POLICY |
| Owner | Security & Architecture Authority |
| Approval Authority | Founder |
| Effective Date | 2026-01-01 |
| Review Cycle | Annual or upon material security incident |

This document is a mandatory internal standard.
Compliance is required.
Non-compliance blocks merge, release, and deployment.

## 2. Scope and Applicability

This standard applies to:

- All production and non-production environments
- All backend systems written in JavaScript or TypeScript
- All APIs, background workers, jobs, and internal services
- All code written or modified by AI systems without exception

AI systems are treated as non-trusted junior engineers.
All AI output is subject to this standard.

## 3. Normative References (AUTHORITATIVE)

All references below are normative.
Where conflicts exist, the strictest requirement SHALL apply.

| Standard | Authority |
|----------|-----------|
| ISO/IEC 27001:2022 | Information Security Management Systems |
| ISO/IEC 27002:2022 | Control 8.28 — Secure Coding |
| OWASP Top 10:2021 | Application Security Risks |
| OWASP ASVS 4.0 | Security Verification Standard |
| CWE/SANS Top 25 | Dangerous Software Weaknesses |
| Node.js Security Best Practices | Runtime security guidance |
| TypeScript Strict Mode | Language-level safety |

## 4. Mandatory Secure Coding Principles

(ISO/IEC 27002:2022 — Control 8.28)

All code SHALL adhere to the following principles:

- **Defense in Depth** — No single control is sufficient
- **Least Privilege** — Minimal access, always
- **Fail Securely** — Errors SHALL NOT degrade security
- **Explicit Validation** — All external input is untrusted
- **Deterministic Behavior** — No undefined or implicit behavior
- **Auditability by Design** — Actions must be traceable
- **Immutability for Financial Data** — No destructive updates

Violation of any principle constitutes a policy breach.

## 5. Absolute Prohibitions

The following are **STRICTLY FORBIDDEN**:

- Hardcoded secrets, credentials, tokens, or passwords
- Default or fallback secrets
- `any` type usage in TypeScript
- `SELECT *` queries
- Dynamic SQL string construction
- Silent error swallowing
- Unbounded database queries
- Console logging (`console.log`, `warn`, `error`)
- Custom cryptography or authentication
- Implicit type coercion
- Debug mode in production

Any occurrence SHALL fail CI/CD immediately.

## 6. AI-Specific Enforcement Rules (HARD LOCK)

### 6.1 Mandatory Verification Requirement

Before AI-generated output is considered valid, the AI system MUST explicitly confirm the existence of all items below:

- Input validation (schema-based)
- Parameterized database queries
- Explicit transaction boundaries
- Typed and classified errors
- Structured logging
- Type safety (no `any`)
- Resource limits (query LIMITs, memory safety)

### 6.2 Failure Obligation

If any required control is missing, the AI system MUST:

- Explicitly state the deficiency
- Raise an error in its output
- Refuse to silently proceed

Silent assumptions are not permitted.

## 7. TypeScript Enforcement (STRICT MODE)

### 7.1 Compiler Configuration (MANDATORY)

Code SHALL compile with the following settings enabled:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "exactOptionalPropertyTypes": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true
  }
}
```

### 7.2 Enforcement

Code that does not compile under strict mode SHALL NOT be merged or deployed.

## 8. Input Validation (NON-NEGOTIABLE)

### 8.1 Required Validation Points

All external input MUST be validated:

- HTTP bodies
- Query parameters
- Headers
- WebSocket messages
- File uploads
- Environment variables

### 8.2 Approved Pattern

Schema-based validation is mandatory (e.g., Zod).

Failure to validate input is a critical security violation.

## 9. Database Security & Transactions

### 9.1 Query Rules

All database queries MUST:

- Use parameterized queries
- Explicitly list columns (no `SELECT *`)
- Include `LIMIT` clauses on reads
- Enforce tenant isolation where applicable

### 9.2 Transactions

Any multi-step operation SHALL:

- Execute inside `BEGIN` / `COMMIT` / `ROLLBACK`
- Roll back fully on failure
- Never partially succeed

Financial writes are immutable. Corrections are additive only.

## 10. Error Handling

### 10.1 Error Discipline

- Generic `Error` is prohibited
- Errors SHALL be typed and classified
- Correlation IDs are mandatory
- Internal details SHALL NOT be exposed externally

### 10.2 Prohibited Behavior

- Silent catch blocks
- Logging without rethrowing or handling
- Returning stack traces to clients

## 11. Logging Standard (LOCKED)

### 11.1 Approved Libraries

- **Primary**: `pino`
- **Fallback** (only if pino is unavailable): `winston`

No other logging libraries are permitted.

### 11.2 Requirements

Logs SHALL be structured (JSON) and include:

- Timestamp
- Severity
- Service name
- Correlation ID

Logs SHALL NOT contain secrets, credentials, tokens, or PII.

## 12. Dependency Management

### 12.1 Security Auditing

The following is MANDATORY in CI/CD:

```bash
npm audit --audit-level=high
```

Builds SHALL fail on high or critical vulnerabilities.

### 12.2 Lockfiles

- `package-lock.json` SHALL be committed
- CI SHALL use `npm ci`
- Deprecated or unmaintained packages are prohibited

## 13. ESLint Enforcement (POLICY-BOUND)

ESLint rules are mandatory enforcement mechanisms of this policy.

Violations SHALL fail CI/CD.

Required rule categories include:

- `no-explicit-any`
- `no-console`
- `no-eval`
- security plugin rules
- unused variables
- unsafe object injection

Overrides require formal exception approval.

## 14. Compliance Checklist (AI MUST CONFIRM OR FAIL)

AI systems MUST explicitly confirm all items below.
If any item cannot be confirmed, output MUST fail.

- [ ] No hardcoded secrets
- [ ] Parameterized queries only
- [ ] Input validated everywhere
- [ ] Transactions for multi-step DB ops
- [ ] Connections released safely
- [ ] No `any` usage
- [ ] Structured logging only
- [ ] No sensitive data in logs
- [ ] `LIMIT` clauses present
- [ ] `npm audit` clean (high+)

## 15. Exceptions (STRICTLY CONTROLLED)

Exceptions require:

- Written justification
- Risk assessment
- Explicit approval
- Expiry date

Maximum exception duration: 90 days
Expired exceptions are invalid automatically.

## 16. Enforcement Statement (FINAL)

This standard is mandatory.
Violations SHALL block merge, release, and deployment.
There are no implied permissions.
Silence is non-compliance.

---

## Final Note

This document is now:

- **Policy-locked**
- **AI-enforceable**
- **Audit-defensible**
- **Financial-system appropriate**
