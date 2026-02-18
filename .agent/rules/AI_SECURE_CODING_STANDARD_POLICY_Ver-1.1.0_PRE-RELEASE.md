# AI Secure Coding Standard (Policy-Locked)

**STRICT MODE — PRODUCTION ENFORCEMENT**

> [!IMPORTANT]
> **PRE-RELEASE VERSION** — This document contains finalized enhancements pending formal approval to Version 1.0.0. Changes are marked with `[ADDED]`, `[FIX]`, or `[HARDENED]` tags.

## 1. Document Control (MANDATORY)

| Field | Value |
|-------|-------|
| Document Title | AI Secure Coding Standard |
| Version | 1.1.0-PRE-RELEASE |
| Status | PRE-RELEASE — ENFORCEMENT-READY |
| Owner | Security & Architecture Authority |
| Approval Authority | Founder |
| Effective Date | Upon formal approval |
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
- **[ADDED]** All financial ledger and transaction processing systems
- **[ADDED]** All Stellar anchor and SEP protocol implementations

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
| Node.js Security Best Practices (Node.js LTS documentation) | Runtime security guidance |
| TypeScript Strict Mode | Language-level safety |
| **[ADDED]** SEP-1, SEP-6, SEP-10, SEP-12, SEP-24 | Stellar Ecosystem Proposals |
| **[ADDED]** PCI-DSS v4.0 | Payment Card Industry Data Security (where applicable) |

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
- **[ADDED] Idempotency** — All state-changing operations MUST be safely re-executable
- **[ADDED] Double-Entry Integrity** — All ledger operations MUST maintain balanced debits and credits
- **[HARDENED] Ledger Derivability** — All ledger balances SHALL be derivable from transaction history; stored balances are cached values and MUST NOT be authoritative

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
- **[ADDED]** Floating-point arithmetic for currency (use Decimal/BigNumber libraries)
- **[ADDED]** Mutable transaction records after confirmation
- **[ADDED]** Non-atomic idempotency implementations (INSERT + catch pattern)
- **[ADDED]** Unsafe type casting (`as any`, `as unknown as T`)

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
- **[ADDED]** Idempotency keys for all POST/PUT/PATCH operations
- **[ADDED]** Correlation ID propagation across all service boundaries
- **[ADDED]** Connection pool release in `finally` blocks

**[FIX] Confirmation Format Requirement:**

AI confirmation MUST be explicit, enumerated, and structured.
Free-form or implicit confirmation is non-compliant.

AI systems SHOULD emit a compliance block listing each verified control.

### 6.2 Failure Obligation

If any required control is missing, the AI system MUST:

- Explicitly state the deficiency
- Raise an error in its output
- Refuse to silently proceed

Silent assumptions are not permitted.

### 6.3 [ADDED] Domain Error Requirement

All errors thrown by AI-generated code MUST:

- Extend the project's `DomainError` base class
- Include a unique error `code` for client identification
- Include an HTTP `statusCode` for API responses
- Include a `correlationId` for distributed tracing
- Never expose internal stack traces to clients

```typescript
// REQUIRED: All errors must follow this pattern
export class TransactionNotFoundError extends DomainError {
    readonly code: string = 'TRANSACTION_NOT_FOUND';
    readonly statusCode: number = 404;
}
```

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

### 7.3 [ADDED] Typed Request Interfaces

All Express route handlers MUST use typed request interfaces:

```typescript
// REQUIRED pattern
interface AuthenticatedRequest extends Request {
    tenantId: string;
    userId: string;
    correlationId: string;
}

// PROHIBITED: (req as any).tenantId
```

## 8. Input Validation (NON-NEGOTIABLE)

### 8.1 Required Validation Points

All external input MUST be validated:

- HTTP bodies
- Query parameters
- Headers
- WebSocket messages
- File uploads
- Environment variables
- **[ADDED]** Webhook payloads from external services
- **[ADDED]** Stellar transaction callback data

### 8.2 Approved Pattern

Schema-based validation is mandatory. Approved libraries:

- **Primary**: Zod
- **Fallback**: Joi (only if Zod is unavailable)

Failure to validate input is a critical security violation.

### 8.3 [ADDED] Environment Variable Validation

All required environment variables MUST be validated at startup.

Logging during startup SHALL use the approved logging library.

```typescript
// REQUIRED pattern - fail fast on missing config
const requiredEnvVars = ['DATABASE_URL', 'API_KEY', 'JWT_SECRET'];
for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
        logger.fatal({ envVar }, 'Required environment variable missing');
        process.exit(1);
    }
}
```

## 9. Database Security & Transactions

### 9.1 Query Rules

All database queries MUST:

- Use parameterized queries
- Explicitly list columns (no `SELECT *`)
- Include `LIMIT` clauses on reads
- Enforce tenant isolation where applicable
- **[ADDED]** Use `FOR UPDATE` locks when reading data for modification
- **[ADDED]** Include explicit column ordering for consistent results

### 9.2 Transactions

Any multi-step operation SHALL:

- Execute inside `BEGIN` / `COMMIT` / `ROLLBACK`
- Roll back fully on failure
- Never partially succeed

Financial writes are immutable. Corrections are additive only.

### 9.3 [ADDED] Connection Management

All database connections MUST:

- Be released in `finally` blocks
- Use connection pooling with bounded limits
- Have explicit timeout configurations

```typescript
// REQUIRED pattern
const client = await pool.connect();
try {
    await client.query('BEGIN');
    // ... operations ...
    await client.query('COMMIT');
} catch (e) {
    await client.query('ROLLBACK');
    throw e;
} finally {
    client.release(); // MANDATORY
}
```

### 9.4 [ADDED] Idempotency Implementation

All state-changing API operations MUST implement idempotency:

```typescript
// REQUIRED: Atomic UPSERT pattern
INSERT INTO idempotency_keys (key, status)
VALUES ($1, 'PROCESSING')
ON CONFLICT (key) DO NOTHING
RETURNING *;

// PROHIBITED: Non-atomic INSERT + catch(23505) pattern
```

Idempotency records MUST include terminal failure states:

```sql
-- REQUIRED status values
status IN ('PROCESSING', 'COMPLETED', 'FAILED')
```

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

### 10.3 [ADDED] Error Hierarchy

The following error classification hierarchy SHALL be used:

| Error Type | HTTP Status | Use Case |
|------------|-------------|----------|
| `ValidationError` | 400 | Invalid input data |
| `AuthenticationError` | 401 | Missing/invalid credentials |
| `AuthorizationError` | 403 | Insufficient permissions |
| `NotFoundError` | 404 | Resource not found |
| `ConflictError` | 409 | State conflicts, idempotency violations |
| `BusinessRuleError` | 422 | Business logic violations |
| `ExternalServiceError` | 502 | Third-party service failures |
| `ServiceUnavailableError` | 503 | Temporary unavailability |
| `InternalError` | 500 | Unexpected internal failures |

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
- **[ADDED]** Tenant ID (for multi-tenant systems)
- **[ADDED]** Request ID

Logs SHALL NOT contain secrets, credentials, tokens, or PII.

### 11.3 [ADDED] Audit Logging for Financial Operations

All financial operations MUST produce audit logs containing:

- Operation type (CREDIT, DEBIT, TRANSFER)
- Transaction ID
- Account ID(s) involved
- Amount and currency
- Timestamp (ISO 8601)
- Correlation ID
- User/system initiator
- Result (SUCCESS, FAILURE with reason)

Audit logs MUST be immutable and retained per regulatory requirements.

In the absence of stricter regulatory requirements, audit logs MUST be retained for a minimum of 7 years.

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

### 12.3 [REFINED] Approved Default Dependencies

The following are approved **default** dependencies:

| Category | Default Package(s) |
|----------|--------------------|
| HTTP Framework | Express |
| Validation | Zod, Joi |
| Database | pg (node-postgres) |
| Logging | pino, winston |
| Decimal Arithmetic | decimal.js, bignumber.js |
| UUID Generation | uuid |
| Environment Config | dotenv |

**Alternatives are permitted** with architectural justification.

Alternative dependencies require:
- Written justification describing capability gap or technical constraint
- Security audit demonstrating no regression
- Approval by Security & Architecture Authority

## 13. ESLint Enforcement (POLICY-BOUND)

ESLint rules are mandatory enforcement mechanisms of this policy.

Violations SHALL fail CI/CD.

**[FIX]** ESLint SHALL be configured with `--max-warnings=0`.
Warnings are treated as errors in all environments.

Required rule categories include:

- `no-explicit-any`
- `no-console`
- `no-eval`
- security plugin rules
- unused variables
- unsafe object injection
- **[ADDED]** `@typescript-eslint/strict-boolean-expressions`
- **[ADDED]** `@typescript-eslint/no-unsafe-assignment`

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
- [ ] **[ADDED]** Idempotency implemented for state-changing operations
- [ ] **[ADDED]** Domain errors used (not generic `Error`)
- [ ] **[ADDED]** Correlation IDs propagated
- [ ] **[ADDED]** Typed request interfaces used (no `as any` casting)
- [ ] **[ADDED]** Decimal types used for currency (no floating-point)

## 15. Exceptions (STRICTLY CONTROLLED)

Exceptions require:

- Written justification
- Risk assessment
- Explicit approval
- Expiry date

Maximum exception duration: 90 days
Expired exceptions are invalid automatically.

## 16. [ADDED] API Response Standards

### 16.1 Error Response Format

All API error responses SHALL follow this format:

```typescript
interface ApiErrorResponse {
    error: string;       // Error class name
    code: string;        // Machine-readable error code
    message: string;     // Human-readable message (sanitized)
    correlationId?: string;
}
```

### 16.2 Success Response Format

All successful responses SHALL include:

- Appropriate HTTP status code (200, 201, 204)
- Consistent JSON structure
- No internal metadata exposure

## 17. [REFINED] Health and Readiness Checks

All services MUST expose:

- `/health` — Liveness probe (service is running)
- `/ready` — Readiness probe (service can accept traffic)

### 17.1 Critical Dependencies (Required for Readiness)

Readiness checks MUST verify these **critical** dependencies:

- Database connectivity
- Configuration validity
- Internal authentication services

Failure of any critical dependency SHALL mark the service as NOT READY.

### 17.2 Non-Critical Dependencies (Degraded Mode Allowed)

The following external integrations MAY operate in **degraded mode**:

- Stellar network connectivity
- Third-party webhook receivers
- Optional analytics/metrics endpoints

Degraded mode MUST:
- Log the degradation at WARNING level
- Expose degradation status via `/ready` response body
- NOT block pod readiness in Kubernetes

Services MUST gracefully handle unavailability of non-critical dependencies.

## 18. [REFINED] Timeout and Retry Policies

### 18.1 Timeouts

All external calls MUST have explicit timeouts.

Timeouts MUST NOT exceed the following **upper bounds** unless an approved exception exists:

| Operation Type | Maximum Timeout |
|----------------|----------------|
| Database queries | 30 seconds |
| External API calls | 15 seconds |
| Stellar network operations | 60 seconds |

**Environment-specific tuning** (e.g., shorter timeouts in production vs staging) is permitted within these bounds.

### 18.2 Retry Policies

Retries MUST use exponential backoff with jitter.
Maximum retry attempts: 3

Retries are PROHIBITED for:
- Non-idempotent operations without idempotency keys
- Client errors (4xx responses)
- Operations that have already mutated state

## 19. Enforcement Statement (FINAL)

This standard is mandatory.
Violations SHALL block merge, release, and deployment.
There are no implied permissions.
Silence is non-compliance.

---

## 20. [NEW] Governance, Enforcement & Traceability (MANDATORY)

### 20.1 Policy Authority and Precedence

This document is the authoritative source of truth for secure coding requirements.

In the event of conflict, the following order of precedence SHALL apply:

1. **This Secure Coding Standard**
2. CI/CD enforcement rules
3. Linting and static analysis rules
4. Code-level comments or documentation

Lower-precedence artifacts SHALL NOT weaken or override higher-precedence requirements.

### 20.2 Mandatory Enforcement Mechanisms

Compliance with this standard SHALL be enforced through automated controls.

The following enforcement mechanisms are mandatory:

- CI/CD pipeline checks
- ESLint and static analysis
- TypeScript compiler strict mode
- Pull Request (PR) templates with explicit attestations

**Manual review alone is insufficient and non-compliant.**

**[FIX] Branch Protection Requirement:**

All production branches (including `main`, `release/*`, and `hotfix/*`) SHALL be protected.

Branch protection rules MUST enforce:

- Required CI checks
- Required PR review
- Required PR attestation completion
- No direct pushes

Absence of branch protection constitutes a policy violation.

### 20.3 Policy-to-Code Traceability Requirement

Each production repository MUST demonstrate traceability between this policy and its enforcement mechanisms.

At minimum, each repository SHALL include:

- A CI configuration enforcing policy-aligned checks
- An ESLint configuration enforcing policy-aligned rules
- A PR template requiring explicit compliance attestation

Failure to demonstrate traceability constitutes policy non-compliance, regardless of code correctness.

**[FIX] Policy Version Binding:**

Each repository MUST declare the applicable policy version (e.g., `AI_SECURE_CODING_STANDARD_VERSION=1.1.0`) in documentation or configuration.

Undeclared versions default to the latest approved version.

### 20.4 Exception Governance (NON-NEGOTIABLE)

No exceptions to this policy are permitted unless **all** of the following are satisfied:

1. Written justification describing:
   - The violated requirement
   - Business necessity
   - Security risk
2. Explicit approval by the Approval Authority
3. A defined expiry date (maximum 90 days)

Expired exceptions are automatically invalid and SHALL be treated as policy violations.

### 20.5 Controlled Prototype and Spike Exception

Exploratory or prototype code MAY temporarily bypass selected requirements of this standard **ONLY IF** all conditions below are met:

1. Code is clearly labeled as `PROTOTYPE` or `SPIKE`
2. Code is isolated from production paths
3. Code is not merged into `main` or production branches
4. Code is time-boxed and removed or remediated before production use

Prototype code SHALL NOT process real customer data, real funds, or real credentials.

This exception **DOES NOT APPLY** to:

- Financial ledger logic
- Transaction processing
- Authentication or authorization code

### 20.6 AI Accountability Clause

AI systems generating or modifying code MUST:

- Explicitly confirm compliance with this standard, **OR**
- Explicitly identify missing controls and fail output

AI-generated code that bypasses or weakens enforcement mechanisms is automatically non-compliant.

---

## 21. [NEW] Policy Enforcement Mapping (AUTHORITATIVE)

The table below defines mandatory enforcement points for this standard.

**This mapping is normative.**

### 21.1 Enforcement Mapping Table

| Policy Section | Requirement Summary | CI/CD | ESLint/Static | PR Attestation |
|----------------|---------------------|-------|---------------|----------------|
| §5 Absolute Prohibitions | No secrets, no `any`, no console, no floating point | ✅ build fail | ✅ rules | ✅ |
| §6 AI Enforcement Rules | AI must confirm or fail | ✅ required output | ⛔ | ✅ |
| §7 TypeScript Strict Mode | Strict compiler settings | ✅ `tsc --noEmit` | ⛔ | ⛔ |
| §7.3 Typed Requests | No `as any` request mutation | ⛔ | ✅ | ✅ |
| §8 Input Validation | Schema validation everywhere | ⛔ | ⛔ | ✅ |
| §9 DB Security | Parameterized queries, LIMITs | ⛔ | ✅ (where possible) | ✅ |
| §9.2 Transactions | Atomic multi-step ops | ⛔ | ⛔ | ✅ |
| §9.4 Idempotency | Atomic idempotency keys | ⛔ | ⛔ | ✅ |
| §10 Error Handling | DomainError usage only | ⛔ | ✅ | ✅ |
| §11 Logging | pino only, structured logs | ⛔ | ✅ | ✅ |
| §11.3 Audit Logs | Financial audit logging | ⛔ | ⛔ | ✅ |
| §12 Dependency Mgmt | npm audit clean | ✅ | ⛔ | ⛔ |
| §13 ESLint Rules | Mandatory lint rules | ✅ | ✅ | ⛔ |
| §16 API Responses | Standardized error format | ⛔ | ⛔ | ✅ |
| §17 Health Checks | `/health`, `/ready` present | ⛔ | ⛔ | ✅ |
| §18 Timeouts & Retries | Explicit timeouts, retry rules | ⛔ | ⛔ | ✅ |

**Legend:**
- ✅ = Mandatory enforcement
- ⛔ = Not applicable / manual verification

### 21.2 CI/CD Minimum Enforcement Checklist

Each CI pipeline MUST include at minimum:

- [ ] TypeScript compilation in strict mode
- [ ] ESLint with zero warnings allowed (`--max-warnings=0`)
- [ ] Dependency vulnerability scan
- [ ] Test execution
- [ ] Build failure on any security rule violation
- **[HARDENED]** CI SHALL fail if test coverage decreases for security-critical paths

Security-critical paths include: authentication, authorization, financial ledger logic, idempotency mechanisms, and external payment or Stellar integrations.

### 21.3 Pull Request Attestation Requirement

All PRs MUST include a completed compliance checklist confirming:

1. No policy violations introduced
2. All required controls present
3. Any exception is explicitly documented and approved

**[HARDENED]** PRs touching financial, authentication, or authorization logic MUST identify a security reviewer.

**Unsigned or incomplete attestations SHALL block merge.**

---

## Summary of Changes from v1.0.0

| Section | Change Type | Description |
|---------|-------------|-------------|
| 2 | ADDED | Financial ledger and Stellar anchor scope |
| 3 | ADDED | SEP and PCI-DSS references |
| 4 | ADDED | Idempotency and Double-Entry principles |
| 4 | **HARDENED** | **Ledger Derivability invariant** |
| 5 | ADDED | Floating-point, mutable records, atomic idempotency prohibitions |
| 6.1 | ADDED | Idempotency keys, correlation IDs, connection release |
| 6.1 | **FIX** | **AI confirmation format requirement (explicit, enumerated, structured)** |
| 6.3 | NEW | Domain Error requirements |
| 7.3 | NEW | Typed Request Interfaces |
| 8 | ADDED | Webhook/Stellar validation, environment variable validation |
| 8.3 | **FIX** | **Changed console.error→logger.fatal (policy consistency)** |
| 9.3 | NEW | Connection Management requirements |
| 9.4 | NEW | Idempotency Implementation requirements |
| 10.3 | NEW | Error Hierarchy classification |
| 11.2 | ADDED | Tenant ID, Request ID logging |
| 11.3 | NEW | Audit Logging for financial operations |
| 12.3 | REFINED | Approved Default Dependencies (softened from fixed list) |
| 13 | ADDED | Additional ESLint rules |
| 13 | **FIX** | **Zero-warnings enforcement (`--max-warnings=0`)** |
| 14 | ADDED | 5 new checklist items |
| 16 | NEW | API Response Standards |
| 17 | REFINED | Health and Readiness Checks (split critical vs non-critical) |
| 18 | REFINED | Timeout and Retry Policies (converted to upper bounds) |
| **20** | **NEW** | **Governance, Enforcement & Traceability** |
| 20.2 | **FIX** | **Branch protection requirement** |
| 20.3 | **FIX** | **Policy version binding requirement** |
| **21** | **NEW** | **Policy Enforcement Mapping (normative table)** |
| 21.2 | **HARDENED** | **Test coverage non-regression requirement** |
| 21.3 | **HARDENED** | **Security reviewer requirement for sensitive PRs** |

---

## Final Note

This document is now:

- **Policy-locked**
- **AI-enforceable**
- **Audit-defensible**
- **Financial-system appropriate**
- **Founder-survivable** — Contains governance escape hatches for spikes/prototypes
- **Traceable** — Explicit policy-to-enforcement mapping

---

*Prepared based on analysis of:*
- *Phase-7 Code Remediation (CP-38)*
- *Existing AI_CODING_BEST_PRACTICES.md*
- *Domain/Errors.ts error framework*
- *IdempotencyGuard implementation issues*
- *SEP-6/12/24 integration patterns*
- *Founder feedback on survivability and governance*
