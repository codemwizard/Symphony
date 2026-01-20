# Implementation Plan: Step 2 — DB Access Discipline (Explicit DbRole)

## Objective
Eliminate global/mutable DB role state and enforce explicit `DbRole` per operation to prevent pooled-connection role leakage.

## Scope
- Remove legacy global role APIs from `libs/db/index.ts`:
  - `currentRole`, `setRole`, role-implicit `query`, `executeTransaction`
- Export only explicit-role DB APIs:
  - `queryAsRole(role, sql, params?)` (single statement only)
  - `withClientAsRole(role, fn)`
  - `transactionAsRole(role, fn)` (must use `SET LOCAL ROLE`)
  - Optional: `probeRoles()` for bootstrap verification
- Update all call sites to pass explicit `DbRole`.
- Add tests + CI guardrails to prevent regressions.

## Task Breakdown

## Standards Mapping (Tier-1 Banking)
- **ISO 27001/27002**: A.9 (access control), A.12 (ops security), A.14 (secure development).
- **SOC 2**: CC6.1/CC6.3 (least privilege), CC7.2 (change monitoring).
- **PCI DSS v4.0**: Req 7/8/10.
- **OWASP ASVS L3**: V4 (access control), V7 (error handling/logging).
- **Zero Trust**: explicit verification + least privilege.
- **ISO 20022**: Deterministic processing and integrity of payment domain state.

### Task 1 — Inventory legacy role usage (evidence-producing)
- Locate all usages of:
  - `db.query(...)`
  - `db.setRole(...)`
  - `db.executeTransaction(...)`
  - `currentRole`
- Produce evidence output:
  - `reports/role-usage-scan.txt`
 - **Compliance checkpoint:** Produce evidence list of all legacy API usages for audit trail.
   - **Evidence artifacts:** `reports/role-usage-scan.txt` (rg output), change ticket/PR reference.

Command:
```bash
mkdir -p reports
rg "db\\.query\\(|db\\.setRole\\(|setRole\\(|currentRole|executeTransaction\\(" -n . > reports/role-usage-scan.txt
```

### Task 2 — Refactor DB module API (single source of truth)
- Delete or stop exporting:
  - `currentRole`, `setRole`, `query`, `executeTransaction`
- Implement and export:
  - `queryAsRole(role: DbRole, text: string, params?: unknown[])`
    - uses `SET ROLE "<role>"` + `RESET ROLE` in `finally`
  - `transactionAsRole(role: DbRole, fn)`
    - `BEGIN; SET LOCAL ROLE "<role>"; ... COMMIT/ROLLBACK`
  - `withClientAsRole(role: DbRole, fn)`
    - exposes RoleBoundClient wrapper (no raw PoolClient escape hatch)
  - RoleBoundClient exposes only `query(text, params?)` and must not expose `release()`, `setRole()`, or the underlying client.
  - `queryAsRole` is for single-statement work only; any 2+ query workflow must use `transactionAsRole`.
 - **Compliance checkpoint:** Enforce least privilege and explicit role scoping (ISO 27001 A.9, PCI DSS Req 7, Zero Trust).
   - **Evidence artifacts:** diff of `libs/db/index.ts`, updated API docs, unit test results.

### Task 3 — Migrate call sites
- Replace all legacy DB calls with explicit-role calls.
- Raw role strings are only allowed at service boundaries:
  - map/validate into `DbRole` exactly once
  - anonymous paths must map to `symphony_readonly`
- Update helper wrappers and tests that assumed global role state.
 - **Compliance checkpoint:** Verify no implicit role access remains; document service boundary role mappings (SOC 2 CC6.1/CC6.3, OWASP ASVS V4).
   - **Evidence artifacts:** updated service boundary mapping notes, grep results showing zero legacy API usage.

### Task 4 — Tests and guardrails
- Add a role isolation test:
  - concurrent `queryAsRole()` calls with different roles must not leak
- Add a residue test:
  - reuse a single pooled client, verify role resets correctly
- Add a residue test (failure path):
  - failing query still resets role before releasing client
- Add CI guardrails:
  - Phase A: forbid `setRole(`, `currentRole`, `executeTransaction(`
  - Phase B: forbid `db.query(` after migration completes
 - **Compliance checkpoint:** Include role isolation proof tests and CI guardrail evidence (ISO 27001 A.12, SOC 2 CC7.2).
   - **Evidence artifacts:** CI logs, test output, guardrail script output.

## Continuous Monitoring & Evidence
- Capture CI logs for lint/build/test/security checks per change.
- Retain output of any role-usage scans and guardrail checks as audit evidence.
- Log all changes with commit references for traceability.
- Store artifacts in `reports/` and attach to change record.

## Definition of Done
- No legacy role APIs exported from `libs/db/index.ts`.
- No usage of `db.query`, `db.setRole`, `db.executeTransaction`, or `currentRole` remains.
- All DB calls pass explicit `DbRole`.
- Tests updated/added and passing.

## Commands
```bash
npm run build
npm test
```

## Risks / Notes
- Any failure to `RESET ROLE` before releasing a pooled client can taint the pool.
- Some tests may monkey-patch `db.query`; update them to patch `queryAsRole` or use RoleBoundClient.
- Role mapping must remain the only location where raw strings exist.
- `probeRoles()` must only run during service bootstrap, not at module import time.
