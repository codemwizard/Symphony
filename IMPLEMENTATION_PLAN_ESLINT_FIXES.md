# Implementation Plan: ESLint Error Remediation

Goal: resolve all listed ESLint errors/warnings without changing runtime behavior.

## Phase 1: Configuration & Parser
- Scope ESLint type-aware parsing to TS files only.
- Ensure `tsconfig.json` includes all TS entry points (e.g., `test-parity.ts`).

## Phase 2: Type Safety & Unused Symbols
- Replace `any` with `unknown` or narrow interfaces.
- Remove or underscore unused variables and parameters.
- Remove unused eslint-disable directives where the rule is not triggered.

## Phase 3: Script/Test Hygiene
- Fix or explicitly type test mocks.
- Normalize private method access in tests using typed `unknown` casts.
- Ensure no unused imports remain.

## Acceptance Criteria
- `eslint . --ignore-pattern "_Legacy_V1/**"` yields zero errors/warnings.
- No behavior changes beyond lint compliance.

