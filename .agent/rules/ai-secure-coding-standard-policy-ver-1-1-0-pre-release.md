---
trigger: always_on
---

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
- Approval by Security & Archi