# Implementation Plan: Step 3 — DB Boundary Enforcement (No pg Outside libs/db)

## Objective
Enforce the DB access boundary so runtime code cannot bypass `libs/db`, eliminating direct `pg` usage outside `libs/db` and aligning runtime access with explicit-role APIs only.

## Scope
- Forbid `pg` imports and `new Pool(` in runtime code outside `libs/db`.
- Refactor runtime libraries currently using `pg` to rely on `db.queryAsRole`, `db.withRoleClient`, or `db.transactionAsRole`.
- Decide and document a policy for tests/scripts (`strict` vs `pragmatic`).
- Add CI guardrails to enforce the boundary.

## Standards Mapping (Tier-1 Banking)
- **ISO 27001/27002**: A.9 (access control), A.12 (ops security), A.14 (secure development).
- **SOC 2**: CC6.1/CC6.3 (least privilege), CC7.2 (change monitoring).
- **PCI DSS v4.0**: Req 7/8/10.
- **OWASP ASVS L3**: V4 (access control), V7 (error handling/logging).
- **Zero Trust**: explicit verification + least privilege.
- **ISO 20022**: deterministic processing and integrity of payment domain state.

## Policy Decision
- **Strict**: forbid `pg` imports everywhere except `libs/db/**` (including tests and scripts).

## Task Breakdown

### Task 1 — Inventory direct pg usage (evidence-producing)
- Find all `pg` imports and `new Pool(` outside `libs/db/**`.
- Produce evidence output:
  - `reports/pg-usage-scan.before.txt`

Command:
```bash
mkdir -p reports
rg "from\s+['\"]pg['\"]|require\(['\"]pg['\"]\)|new\s+Pool\s*\(" -n . > reports/pg-usage-scan.before.txt
```

### Task 2 — Enforce CI guardrails
- Update guardrails to fail on `pg` import / `new Pool(` outside `libs/db/**` per chosen policy.
- Add `pool.query(` guardrail outside `libs/db/**`.
- Emit guardrail output to `reports/guardrails-db-boundary.txt`.

### Task 3 — Refactor runtime libs (highest priority)
- Remove direct `pg` usage and replace with explicit-role db APIs:
  - `db.queryAsRole(role, ...)`
  - `db.withRoleClient(role, ...)`
  - `db.transactionAsRole(role, ...)`

**High-priority runtime files**
- `libs/outbox/OutboxRelayer.ts`
- `libs/outbox/OutboxDispatchService.ts`
- `libs/repair/ZombieRepairWorker.ts`
- `libs/policy/PolicyConsistencyMiddleware.ts`
- `libs/attestation/IngressAttestationMiddleware.ts`
- `libs/export/EvidenceExportService.ts`

**Listener handling (OutboxRelayer)**
- Move LISTEN/UNLISTEN client lifecycle into `libs/db` (e.g., `db.listenAsRole(...)`), or
- Add a `db.withListenClient(role, fn)` wrapper that owns client acquire/release, so no `pg` import is needed in outbox code.

### Task 4 — Tests and scripts (strict)
- Migrate tests/scripts to use `db.queryAsRole` and `db.__testOnly.queryNoRole`.
- Remove any `pg` imports from `tests/**` and `scripts/**`.

### Task 5 — Evidence and verification
- Run after-migration scan:
  - `reports/pg-usage-scan.after.txt`
- Validate guardrails in CI and attach outputs.

Command (after migration):
```bash
rg "from\s+['\"]pg['\"]|require\(['\"]pg['\"]\)|new\s+Pool\s*\(" -n . > reports/pg-usage-scan.after.txt
```

## Definition of Done
- No `pg` imports or `new Pool(` anywhere outside `libs/db/**` (including tests/scripts).
- All DB interactions use explicit-role db APIs.
- Guardrails active and passing for the strict policy.
- Evidence artifacts captured.

## Evidence Artifacts
- `reports/pg-usage-scan.before.txt`
- `reports/pg-usage-scan.after.txt`
- `reports/guardrails-db-boundary.txt`
- CI logs (guardrails + tests)

## Commands
```bash
npm run guardrails:db
npm run build
npm test
```

## Risks / Notes
- LISTEN/UNLISTEN requires a dedicated client; ensure lifecycle is managed inside `libs/db`.
- Failing to enforce the boundary allows bypass of role discipline and reintroduces pool taint risk.
