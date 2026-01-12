# Symphony Secure Coding Policy

**Policy Version:** v1.0.0
**Effective Date:** 2026-01-01
**Status:** ACTIVE

## Purpose
This document defines mandatory secure coding standards for all Symphony development. All code must comply with the AI Secure Coding Standard (see `.agent/MEMORY/ai-secure-coding-standard-policy`).

## Scope
Applies to all TypeScript/JavaScript code in the Symphony platform.

## Mandatory Requirements

### 1. TypeScript Strict Mode
All code must compile under `strict: true` with no suppressions.

### 2. Input Validation
- All external input must be validated using Zod schemas.
- No raw request body access without validation.

### 3. Error Handling
- All errors must extend `DomainError`.
- No silent catch blocks.
- No stack traces exposed to clients.

### 4. Database Security
- Parameterized queries only (`$1`, `$2`).
- No `SELECT *`.
- All queries must include `LIMIT`.
- Connections released in `finally` blocks.

### 5. Logging
- Use `pino` structured logging only.
- No `console.log` in production code.
- No PII or credentials in logs.

### 6. Cryptography
- Use `ProductionKeyManager` for all crypto.
- No hardcoded secrets.
- No custom crypto implementations.

## Enforcement
- CI/CD must include `npm run build` (TypeScript check).
- Security gates run on every PR.
- Policy violations block merge.

## References
- [AI Secure Coding Standard](.agent/MEMORY/ai-secure-coding-standard-policy)
- [Phase 5 Invariants](phase1-6.txt)
