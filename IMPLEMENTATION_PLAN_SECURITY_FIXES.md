# Implementation Plan: Security Fixes and Compliance Hardening

Scope: ESLint issues, Database TLS enforcement, Identity schema subjectType handling, ESLint strictness/coverage.

## Plan Overview
1) Eliminate ESLint errors/warnings and establish a clean baseline.
2) Enforce TLS for database connections in production.
3) Align identity schema and verification logic for subjectType = user.
4) Tighten ESLint strictness and coverage, including tests and scripts.

## 1) ESLint issues (current errors/warnings)

### Objective
Achieve zero ESLint errors/warnings for all in-scope code.

### Approach
- Create a short-lived “lint remediation” branch or checklist.
- Fix issues by category (no-console, no-undef, no-require-imports, no-unused-vars, no-explicit-any).
- Minimize behavior changes; prefer refactors limited to lint compliance.

### Key Actions
- Add ESLint overrides for script/CI files where console and CommonJS are expected.
- Remove unused imports/variables or prefix with `_` where intentional.
- Replace `any` with `unknown` + narrow, or small interfaces.
- Convert CJS verification scripts to ESM or mark as `env: node` with allowed `require` (policy decision required).

### Acceptance Criteria
- `eslint . --ignore-pattern "_Legacy_V1/**"` returns zero errors/warnings.

## 2) Database TLS enforcement (production)

### Objective
Guarantee TLS is used for DB connections in production; fail closed if TLS configuration is missing or invalid.

### Approach
- Require TLS in production regardless of `DB_SSL_QUERY`.
- Use `ssl: { rejectUnauthorized: true, ca: DB_CA_CERT }` by default in production.

### Key Actions
- Update config guard or DB config logic to enforce TLS on `NODE_ENV=production`.
- Fail startup if `DB_CA_CERT` is missing in production.

### Acceptance Criteria
- In production, DB connections use TLS and fail if TLS config is missing.

## 3) Identity schema: subjectType = user

### Objective
Either fully support `subjectType = user` or remove it from schema and related expectations.

### Approach
- Decide whether user identities are valid in the current authorization model.
- If valid, implement explicit trust and authorization handling for `subjectType = user`.
- If invalid, remove from schema and update tests/docs.

### Key Actions
- Update `IdentityEnvelopeSchema` and `verifyIdentity` logic to align.
- Add/update unit tests for `user` path (success + failure).

### Acceptance Criteria
- Schema and verification logic are consistent and tested.

## 4) ESLint strictness and coverage

### Objective
Ensure ESLint is applied consistently across all source, test, and script files.

### Approach
- Consolidate ESLint config or define a clear primary config.
- Add `lint` and `lint:strict` scripts.
- Remove overly broad ignores (e.g., `**/*.spec.ts`) unless explicitly justified.
- Add security and type-aware linting rules where feasible.

### Key Actions
- Update `eslint.config.mjs` and/or `.eslintrc.json` with strict coverage rules.
- Add overrides for script files to avoid false positives.
- Add `npm run lint` to CI.

### Acceptance Criteria
- Lint runs across TS/JS, tests, and scripts with no unreviewed exclusions.
- CI enforces lint.

