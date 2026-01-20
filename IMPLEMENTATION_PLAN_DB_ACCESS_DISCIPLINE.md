# Implementation Plan: DB Access Discipline — Explicit Role Parameter Everywhere

## Objective
Eliminate global mutable DB role state (`currentRole` / `setRole`) and require explicit role scoping per operation, with **no default role** and **explicit role validation** to prevent role leakage on pooled connections. Raw role strings are only allowed at the **service boundary** where they are mapped/validated into `DbRole` exactly once. **Anonymous paths must explicitly select `symphony_readonly` at the service boundary** (do not include `anon` in `DbRole`).

## Discovery & Coverage Strategy (Provably Complete)
To avoid whack-a-mole, coverage will be validated by **three passes** plus a **compile gate**:

1. **Direct references**
   - Locate and remove all `setRole(...)` calls.
   - Replace all `db.query(...)` calls with `db.queryAsRole(role, ...)`.
   - Replace all `db.executeTransaction(...)` calls with `db.transactionAsRole(role, ...)`.

2. **Indirect imports / re-exports**
   - Enumerate modules importing from `libs/db` or `libs/db/index` and verify they do not expose or wrap the old API.
   - Update any DB helper wrappers to accept a `DbRole` parameter.

3. **Transaction boundary review**
   - Identify manual transaction usage (e.g., `pool.connect()` + `BEGIN`).
   - Ensure **`SET LOCAL ROLE <role>` happens inside the transaction** and is never set globally.

4. **Compile gate**
   - **Remove legacy exports** from `libs/db/index.ts` (no shims) so TypeScript builds fail on any lingering imports.
   - Optional safety: add a lint/grep check to ensure `setRole(` is absent from the repo.

## Implementation Steps (Order Matters)

### Step 1 — DB layer refactor (single source of truth)
Remove the global mutable role surface and add **role-scoped** APIs only.

**Remove:**
- `currentRole`
- `setRole()`
- role-implicit `query()`
- role-implicit `executeTransaction()`

**Add:**
- `queryAsRole(role, text, params?)`
- `withRoleClient(role, fn)` (role-scoping client wrapper)
- `transactionAsRole(role, fn)`

**Key contract & tighteners:**
- **Never accept a raw string role** at DB entrypoints. Only `DbRole` is accepted. If the caller has a string (config/identity/header), it must be mapped/validated **once at the service boundary**, not inside `libs/db`.
- **Role scoping is a client wrapper**: `withRoleClient(role, fn)` provides a role-bound client wrapper so downstream code uses a scoped client, not global helpers.
- **`withRoleClient` does not expose a raw `PoolClient`.** It exposes a **RoleBoundClient** surface (`query` only), preventing bypass of role discipline.
- **`queryAsRole` uses `SET ROLE` + `RESET ROLE` on a dedicated client in a `try/finally`.** Avoid forcing every query into a transaction (performance); use transactions only when needed. Always reset the role before releasing the client.
- **`queryAsRole` must be role-residue safe**: always `RESET ROLE` even if `SET ROLE` fails, before releasing the client to the pool. Optionally (dev/test) verify with `SELECT current_user` after reset. `SET ROLE` must be identifier-safe: accept only `DbRole`, defensively validate with `assertDbRole()`, and quote the identifier (e.g., `SET ROLE \"${role}\"`) before interpolating.
- **`transactionAsRole` uses `BEGIN; SET LOCAL ROLE <role>; ... COMMIT/ROLLBACK`** on a single client.
- **Prefer `SET LOCAL ROLE` wherever possible** (transactions and multi-step work), but do not force a `BEGIN` for single-statement queries.
- **Role must be set once per transaction**: do not call `queryAsRole()` inside `transactionAsRole()`; pass the transaction client down.
- **Make nested usage impossible by type/wrapper**: `transactionAsRole` passes a TxClient that does not expose role setters or `queryAsRole`, and no helper returns a raw pool client. If a TxClient is passed into `transactionAsRole`, throw immediately.
- **Multi-step work must use a scoped client**: use `withRoleClient` for multi-step independent queries, and `transactionAsRole` for atomic/consistent multi-step work (no repeated `queryAsRole` calls in loops).
- **Add a runtime guard against nested transactions** via `AsyncLocalStorage` (or a wrapper-scoped flag), not by inspecting DB state: if `transactionAsRole` is invoked while already in a transaction, throw a clear error.
- **TxClient must never expose a raw `PoolClient`** (no escape hatch); enforce this by wrapper/type branding rather than DB-state checks.

### Step 2 — Add strict role typing
Create `libs/db/roles.ts`:
- `export type DbRole = 'symphony_control' | 'symphony_ingest' | 'symphony_executor' | 'symphony_readonly' | 'symphony_auditor' | 'symphony_auth';` (no `anon`; **keep `symphony_auth` for security/admin flows**)
- Required: `assertDbRole(role)` (or equivalent mapping) for runtime validation when roles come from env/headers/identity context. This is the **only** boundary where raw strings are accepted.
- Add a boot-time probe exposed as `db.probeRoles()` that runs `BEGIN; SET LOCAL ROLE <role>; SELECT current_user; ROLLBACK;` for each `DbRole` and fails fast if a role is missing/misconfigured. Each service calls this during bootstrap (not at module import time). **Role switching requires DB_USER membership in target roles; `db.probeRoles()` validates this at boot.**

### Step 3 — Update all call sites
- Replace any legacy DB calls with role-explicit calls.
- Remove startup `setRole(...)` usage (e.g., Read API) and pass roles per request/operation.
- Add **identity-context integration** at service boundaries: resolve `DbRole` once from identity and pass it explicitly (or create a role-bound DB wrapper).
- Log the role used at the DB boundary for privileged operations (transactions); include `role`, operation name, and (debug) `pg_backend_pid()` in error logs to aid forensics.

### Step 4 — Add proof test
Add a test that proves per-call role isolation (no leakage) **and pooled-connection hygiene**:
- **Test 1: No cross-request leakage (concurrent)** — run two concurrent calls with different roles and verify each sees its own role via `current_user`.
- **Test 2: No residue on the same physical connection** — use a single pooled client (or controlled wrapper) to set role A, query, reset, then role B, query, reset; confirm `current_user` is back to baseline after each reset and capture `pg_backend_pid()` for evidence.

### Step 5 — DB module cleanup verification checklist
Use this checklist to confirm the DB module is fully migrated and safe:
- **Remove legacy globals**: delete `currentRole`, `setRole`, role-implicit `query()`, and `executeTransaction()` from `libs/db/index.ts`.
- **Export only explicit-role APIs**: `queryAsRole`, `withRoleClient`, `transactionAsRole` (no shims).
- **Replace `ValidRole` with `DbRole`** everywhere inside `libs/db`.
- **Role-bound wrappers only**: ensure `withRoleClient` exposes a RoleBoundClient (no raw `PoolClient` leaks).
- **Transaction scoping**: ensure `transactionAsRole` uses `SET LOCAL ROLE` and TxClient only.
- **Role-residue safety**: ensure `queryAsRole` always `RESET ROLE` before releasing the client (even on errors).
- **Boot-time role existence probe**: verify each `DbRole` can be `SET ROLE`’d at startup.

## Verification
- Build should fail until **all** call sites are migrated (legacy exports removed).
- Concurrency test passes to confirm role isolation and **no role residue** on pooled connections.
- Optional CI check for `setRole(` to prevent regressions.

## Notes on Correctness
- `SET LOCAL ROLE` is transaction-scoped and auto-cleans on commit/rollback; **all transaction helpers must use it**.
- All `SET ROLE` must be paired with `RESET ROLE` in a `finally` block on the same client.
- **Role scoping is separate from `search_path` hardening** in DB functions; both are required and complementary.
