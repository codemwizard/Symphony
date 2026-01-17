# Tasks List: Security Fixes and Compliance Hardening

## A) ESLint issues (current errors/warnings)
1) Categorize and triage current ESLint failures by rule (no-console, no-undef, no-require-imports, unused-vars, no-explicit-any).
2) Add ESLint overrides for scripts/CI utilities (allow console, allow require, set env node).
3) Remove or rename unused variables/imports (prefix with `_` if required for interface conformance).
4) Replace `any` with `unknown` + narrow or minimal interfaces in core libs and scripts.
5) Convert CJS scripts to ESM where required, or formally exempt them by override.
6) Re-run ESLint and confirm zero errors/warnings.

## B) Database TLS enforcement in production
1) Define production TLS requirement rules (decision: always-on TLS for prod).
2) Update DB config logic to enforce TLS when `NODE_ENV=production`.
3) Add or update config guard checks for required TLS vars (e.g., `DB_CA_CERT`).
4) Add a unit or bootstrap test to validate “fail closed” if TLS is missing in prod.

## C) Identity schema subjectType = user
1) Decide whether `subjectType=user` is supported in current auth model.
2) If supported: add explicit handling in `verifyIdentity` and authorization logic.
3) If unsupported: remove from schema and update docs/tests accordingly.
4) Add unit tests for `user` path (success + failure) based on the decision.

## D) ESLint strictness and coverage
1) Consolidate ESLint configuration (choose `eslint.config.mjs` as primary).
2) Add lint scripts to `package.json` (`lint`, `lint:strict`).
3) Remove or narrow ignore patterns that exclude tests or JS files without justification.
4) Enable type-aware linting (`parserOptions.project`) and security rules in the primary config.
5) Add CI step to enforce lint.

