# Symphony Invariants (Quick, P0 Only)

Agents MUST read this file before making changes.

## DB-MIG
1) Applied migrations are immutable (checksum ledger).  
2) Runner wraps each migration in a transaction; migration files MUST NOT contain top-level `BEGIN;` or `COMMIT;`.  
3) Boot-critical relations/columns must exist after migrations on a fresh DB (CI gate enforces).

## Security
4) No runtime DDL: PUBLIC + runtime roles must NOT have CREATE on schema public.  
5) Runtime roles must not have direct DML on core tables; use SECURITY DEFINER DB APIs.  
6) SECURITY DEFINER functions must set `search_path = pg_catalog, public`.  
7) PUBLIC must have no privileges on core tables.

## Outbox
8) `payment_outbox_attempts` is append-only (no UPDATE/DELETE ever), and **control has no override**.  
9) Enqueue is idempotent on `(instruction_id, idempotency_key)`.  
10) Lease fencing is strict: completion requires matching `claimed_by` + `lease_token` + non-expired lease.  
11) Claim uses `FOR UPDATE SKIP LOCKED` and only due + unleased/expired rows.  
12) Retry ceiling is finite (no infinite retries).

## Policy (boot-critical)
13) `policy_versions` must support the boot query shape: `... WHERE is_active = true`.  
14) `policy_versions.checksum` is **required (NOT NULL)**.  
15) DB enforces **single ACTIVE** policy row (`status='ACTIVE'` unique predicate index).

## Process
16) If you change behavior touching any invariant, update docs + enforcement + verification in the same PR.  
17) Run `scripts/db/verify_invariants.sh` before submitting changes.
