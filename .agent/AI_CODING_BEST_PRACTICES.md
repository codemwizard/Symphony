# AI Coding Best Practices Guide
## Strict Mode | Production-Level Standards

**Version:** 1.0
**Authority:** ISO/IEC 27000 Series, OWASP, Node.js Security WG
**Scope:** TypeScript/JavaScript Backend Systems

---

## 1. Normative References

This guide is based on the following authoritative sources:

| Standard | Title | Relevance |
|:---------|:------|:----------|
| **ISO/IEC 27001:2022** | Information Security Management Systems | ISMS requirements, risk assessment |
| **ISO/IEC 27002:2022** | Information Security Controls (Control 8.28) | Secure coding practices |
| **OWASP Top 10:2021** | Top 10 Web Application Security Risks | Injection, XSS, SSRF, etc. |
| **OWASP ASVS 4.0** | Application Security Verification Standard | Verification levels |
| **CWE/SANS Top 25** | Most Dangerous Software Weaknesses | Common vulnerability patterns |
| **Node.js Security WG** | Security Best Practices | Runtime-specific guidance |
| **TypeScript Handbook** | Strict Mode & Type Safety | Language-level safety |

---

## 2. Security Fundamentals (ISO/IEC 27002:2022 Control 8.28)

### 2.1 Secure Coding Principles

Per **ISO/IEC 27002:2022, Control 8.28 (Secure Coding)**, AI models MUST:

> [!IMPORTANT]
> **ISO 27002 Control 8.28** requires organizations to establish and apply secure coding principles to software development.

1. **Defense in Depth**: Never rely on a single security control.
2. **Least Privilege**: Code should request only the minimum permissions required.
3. **Fail Securely**: Errors must not reveal sensitive information or leave systems in insecure states.
4. **Input Validation**: All external input is untrusted and must be validated.
5. **Output Encoding**: Data must be encoded appropriately for its context (HTML, SQL, CLI).

### 2.2 Secure Development Lifecycle

Per **ISO/IEC 27001:2022, Annex A.8.25-8.31**, the following controls apply:

- **A.8.25**: Secure development environment.
- **A.8.26**: Security requirements specification.
- **A.8.27**: Secure system architecture and engineering.
- **A.8.28**: Secure coding (this document).
- **A.8.29**: Security testing.
- **A.8.30**: Outsourced development security.
- **A.8.31**: Separation of development, test, and production environments.

---

## 3. OWASP Top 10:2021 Compliance

AI-generated code MUST NOT introduce any of the following vulnerabilities:

### A01:2021 – Broken Access Control
**Rule**: Every endpoint must verify authorization before processing.
```typescript
// ❌ BAD: No authorization check
app.get('/admin/users', async (req, res) => {
    const users = await db.query('SELECT * FROM users');
    res.json(users);
});

// ✅ GOOD: Authorization enforced
app.get('/admin/users', authorize('ADMIN'), async (req, res) => {
    const users = await db.query('SELECT * FROM users');
    res.json(users);
});
```

### A02:2021 – Cryptographic Failures
**Rule**: Never store secrets in code. Use environment variables or secret managers.
```typescript
// ❌ BAD: Hardcoded secret
const API_KEY = 'sk-1234567890abcdef';

// ✅ GOOD: Environment variable (required)
const API_KEY = process.env.API_KEY;
if (!API_KEY) throw new Error('API_KEY is required');
```

### A03:2021 – Injection
**Rule**: Always use parameterized queries. Never concatenate user input into queries.
```typescript
// ❌ BAD: SQL Injection vulnerability
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// ✅ GOOD: Parameterized query
const query = 'SELECT * FROM users WHERE id = $1';
const result = await pool.query(query, [userId]);
```

### A04:2021 – Insecure Design
**Rule**: Implement proper error handling and business logic validation.
```typescript
// ❌ BAD: No validation
async function transferFunds(from: string, to: string, amount: number) {
    await db.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, from]);
    await db.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, to]);
}

// ✅ GOOD: Validation and transaction
async function transferFunds(from: string, to: string, amount: number) {
    if (amount <= 0) throw new Error('Amount must be positive');
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const balance = await client.query('SELECT balance FROM accounts WHERE id = $1 FOR UPDATE', [from]);
        if (balance.rows[0].balance < amount) throw new Error('Insufficient funds');
        await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, from]);
        await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, to]);
        await client.query('COMMIT');
    } catch (e) {
        await client.query('ROLLBACK');
        throw e;
    } finally {
        client.release();
    }
}
```

### A05:2021 – Security Misconfiguration
**Rule**: No default credentials. No debug mode in production.
```typescript
// ❌ BAD: Default fallback
const password = process.env.DB_PASSWORD || 'admin123';

// ✅ GOOD: Fail if not configured
const password = process.env.DB_PASSWORD;
if (!password) {
    console.error('FATAL: DB_PASSWORD not set');
    process.exit(1);
}
```

### A06:2021 – Vulnerable and Outdated Components
**Rule**: Regularly audit dependencies.
```bash
# Run regularly in CI/CD
npm audit --audit-level=high
npx @snyk/cli test
```

### A07:2021 – Identification and Authentication Failures
**Rule**: Use proven libraries for authentication. Never implement custom crypto.
```typescript
// ❌ BAD: Custom password comparison
if (user.password === providedPassword) { ... }

// ✅ GOOD: Timing-safe comparison
import { timingSafeEqual } from 'crypto';
const isValid = timingSafeEqual(Buffer.from(hash1), Buffer.from(hash2));
```

### A08:2021 – Software and Data Integrity Failures
**Rule**: Validate all external data. Use checksums for critical operations.

### A09:2021 – Security Logging and Monitoring Failures
**Rule**: Log security-relevant events. Never log sensitive data (passwords, tokens).
```typescript
// ❌ BAD: Logging sensitive data
logger.info('User login', { password: req.body.password });

// ✅ GOOD: Redact sensitive fields
logger.info('User login', { userId: user.id, ip: req.ip });
```

### A10:2021 – Server-Side Request Forgery (SSRF)
**Rule**: Validate and restrict outbound URLs.
```typescript
// ❌ BAD: Unvalidated URL
const response = await fetch(req.body.url);

// ✅ GOOD: Allowlist validation
const ALLOWED_HOSTS = ['api.partner.com', 'webhook.internal'];
const url = new URL(req.body.url);
if (!ALLOWED_HOSTS.includes(url.hostname)) {
    throw new Error('URL not allowed');
}
```

---

## 4. TypeScript Strict Mode Requirements

AI models MUST generate code that compiles under TypeScript strict mode:

### tsconfig.json (Required Settings)
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
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

### Type Safety Rules
```typescript
// ❌ BAD: Using 'any'
function process(data: any) { ... }

// ✅ GOOD: Explicit types
interface UserData {
    id: string;
    name: string;
    email: string;
}
function process(data: UserData) { ... }
```

---

## 5. Database Operations

### 5.1 Connection Management
```typescript
// ❌ BAD: Connection leak
const client = await pool.connect();
const result = await client.query('SELECT ...');
// Missing client.release()

// ✅ GOOD: Always release in finally
const client = await pool.connect();
try {
    const result = await client.query('SELECT ...');
    return result.rows;
} finally {
    client.release();
}
```

### 5.2 Transaction Boundaries
```typescript
// ❌ BAD: No transaction for multi-step operations
await db.query('INSERT INTO orders ...');
await db.query('UPDATE inventory ...');

// ✅ GOOD: Atomic transaction
await client.query('BEGIN');
try {
    await client.query('INSERT INTO orders ...');
    await client.query('UPDATE inventory ...');
    await client.query('COMMIT');
} catch (e) {
    await client.query('ROLLBACK');
    throw e;
}
```

### 5.3 Query Safety
```typescript
// ✅ REQUIRED: Always use LIMIT on unbounded queries
const result = await pool.query(
    'SELECT * FROM events ORDER BY created_at DESC LIMIT $1',
    [Math.min(requestedLimit, 1000)]
);
```

---

## 6. Error Handling

### 6.1 Never Swallow Errors Silently
```typescript
// ❌ BAD: Silent failure
try {
    await criticalOperation();
} catch (e) {
    console.log('Error occurred');
}

// ✅ GOOD: Log, alert, and handle
try {
    await criticalOperation();
} catch (e) {
    logger.error('Critical operation failed', { error: e, correlationId });
    metrics.increment('critical_operation_failures');
    throw e; // Or handle appropriately
}
```

### 6.2 Error Messages
```typescript
// ❌ BAD: Exposing internal details
res.status(500).json({ error: err.stack });

// ✅ GOOD: Generic message, log details
logger.error('Request failed', { error: err, requestId });
res.status(500).json({ error: 'Internal server error', requestId });
```

---

## 7. Input Validation

### 7.1 Required Validation Points
All external input MUST be validated:
- HTTP request bodies
- Query parameters
- Headers
- File uploads
- WebSocket messages
- Environment variables

### 7.2 Validation Pattern
```typescript
// ✅ GOOD: Schema validation
import { z } from 'zod';

const TransferSchema = z.object({
    from: z.string().uuid(),
    to: z.string().uuid(),
    amount: z.number().positive().max(1000000),
    currency: z.enum(['USD', 'EUR', 'GBP'])
});

app.post('/transfer', async (req, res) => {
    const result = TransferSchema.safeParse(req.body);
    if (!result.success) {
        return res.status(400).json({ error: result.error.issues });
    }
    // Proceed with validated data
    const { from, to, amount, currency } = result.data;
});
```

---

## 8. Dependency Management

### 8.1 Security Auditing
```bash
# Required in CI/CD pipeline
npm audit --audit-level=moderate
npm outdated
```

### 8.2 Lock Files
- Always commit `package-lock.json`.
- Use `npm ci` in CI/CD (not `npm install`).

### 8.3 Minimal Dependencies
- Prefer standard library over third-party packages.
- Audit new dependencies before adding.

---

## 9. Logging Standards

### 9.1 Structured Logging
```typescript
// ✅ GOOD: Structured JSON logs
logger.info('Transaction processed', {
    transactionId,
    userId,
    amount, // Only if not PII
    duration: endTime - startTime,
    correlationId
});
```

### 9.2 Never Log
- Passwords or secrets
- Full credit card numbers
- Personal identification numbers
- Authentication tokens
- Stack traces in production responses

---

## 10. ESLint Configuration

### .eslintrc.json (Required Rules)
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "plugin:security/recommended"
  ],
  "plugins": ["@typescript-eslint", "security"],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "security/detect-object-injection": "warn",
    "security/detect-non-literal-fs-filename": "error",
    "security/detect-possible-timing-attacks": "error",
    "no-eval": "error",
    "no-implied-eval": "error"
  }
}
```

---

## 11. Compliance Checklist

Before submitting code, AI models MUST verify:

- [ ] No hardcoded secrets or credentials.
- [ ] All database queries are parameterized.
- [ ] All external input is validated.
- [ ] All database operations have proper transaction boundaries.
- [ ] All connections are properly released in `finally` blocks.
- [ ] No `any` type usage (use `unknown` if type is truly unknown).
- [ ] All errors are logged, not swallowed.
- [ ] No sensitive data in logs.
- [ ] All queries have `LIMIT` clauses.
- [ ] Dependencies are audited (`npm audit`).

---

## 12. References

1. **ISO/IEC 27001:2022** - Information Security Management Systems
   - https://www.iso.org/standard/82875.html

2. **ISO/IEC 27002:2022** - Information Security Controls
   - https://www.iso.org/standard/75652.html

3. **OWASP Top 10:2021**
   - https://owasp.org/Top10/

4. **OWASP Application Security Verification Standard (ASVS) 4.0**
   - https://owasp.org/www-project-application-security-verification-standard/

5. **CWE/SANS Top 25 Most Dangerous Software Weaknesses**
   - https://cwe.mitre.org/top25/

6. **Node.js Security Best Practices**
   - https://nodejs.org/en/docs/guides/security/

7. **TypeScript Handbook - Strict Mode**
   - https://www.typescriptlang.org/tsconfig#strict

8. **eslint-plugin-security**
   - https://github.com/eslint-community/eslint-plugin-security

---

> [!CAUTION]
> **Enforcement Statement**
> Any code that violates these guidelines MUST be flagged during code review and remediated before merge. These are non-negotiable production requirements.
