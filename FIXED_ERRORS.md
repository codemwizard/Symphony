# Fixed Errors Summary

## 1) TypeScript compile errors (db typing, guard params, role-scoped db usage)

**Errors**
- `libs/db/index.ts`: `T` not constrained to `QueryResultRow` + query functions not assignable to generic signature.
- `libs/guards/authorizationGuard.ts`: duplicate identifier `role`.
- `libs/ledger/invariants.ts`: missing `db.query` / wrong client type when switching to role-scoped db.
- `scripts/audit/verify_persistence.ts`: `setRole` / `db.query` no longer available on db.
- `scripts/ops/restore_from_backup.ts`: `auditLogger.log` missing role argument.
- `scripts/validation/invariant-scanner.ts`: `db.query` missing, implicit any, and missing role for `ProofOfFunds.validateGlobalInvariant`.

**Fixes**
- Constrained `Queryable.query` and related wrappers to `T extends QueryResultRow`, and propagated generics through role-bound clients in `libs/db/index.ts`.
- Renamed the duplicate `role` parameter to `dbRole` in `libs/guards/authorizationGuard.ts` and adjusted usage.
- Made ledger invariants use `db.queryAsRole('symphony_control', ...)` when no client is provided in `libs/ledger/invariants.ts`.
- Reworked persistence proof script to use `withClientAsRole` and `client.query` in `scripts/audit/verify_persistence.ts`.
- Passed explicit role to `auditLogger.log` in `scripts/ops/restore_from_backup.ts`.
- Switched invariant scanner to `db.queryAsRole` and passed the role to `ProofOfFunds.validateGlobalInvariant` with typed rows in `scripts/validation/invariant-scanner.ts`.

**Tests**
```bash
npm test
npm run typecheck
```

## 2) Possible-undefined row access in queries

**Errors**
- `libs/audit/logger.ts`: `result.rows[0]` possibly undefined.
- `libs/auth/trustFabric.ts`: `row` possibly undefined (multiple accesses).
- `libs/db/killSwitch.ts`: `res.rows[0]` possibly undefined.
- `libs/db/policy.ts`: `res.rows[0]` possibly undefined.
- `libs/ledger/invariants.ts`: `res.rows[0]` possibly undefined.
- `libs/ledger/proof-of-funds.ts`: `result.rows[0]` possibly undefined (two places).
- `scripts/audit/verify_persistence.ts`: `result.rows[0]` possibly undefined (multiple accesses).

**Fixes**
- Added row guards and fallbacks before accessing `rows[0]` in each file.
- Introduced typed `queryAsRole` calls where helpful to narrow row shapes.

**Tests**
```bash
npm run typecheck
npm test
```

## 3) Safety test failing due to removed legacy API

**Error**
- `tests/safety.test.js`: assertion expected `db.executeTransaction` (removed by db access discipline work), causing test failure.

**Fix**
- Updated assertion to check `db.transactionAsRole` instead.

**Tests**
```bash
npm test
```
