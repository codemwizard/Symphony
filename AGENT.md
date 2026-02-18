# Agent Rules (Cursor + Google Antigravity)

You are working in a repo with strict invariants enforced by CI.

## MUST DO (in order)
1) Read `docs/invariants/INVARIANTS_QUICK.md` first. Treat all P0 rules as unbreakable.
2) If you touch DB schema or DB functions, read `docs/invariants/INVARIANTS_IMPLEMENTED.md` next.
3) Never copy legacy schema/code from `archive/*` into live code. Reference-only.
4) Do not introduce runtime DDL. Only migrations may change schema.
5) Prefer SECURITY DEFINER DB APIs over direct table access for runtime roles.
6) Do not weaken lease fencing, idempotency, or append-only ledgers.
7) If you change an invariant:
   - update the relevant invariants doc
   - update enforcement (SQL/constraints/triggers/functions)
   - update verification (`ci_invariant_gate.sql`, tests, or verify script)

## Before you finish
- Run: `DATABASE_URL=... scripts/db/verify_invariants.sh`
- If it fails, fix the issue; do not paper over it.

## Output expectations
- Provide exact SQL diffs for migration changes.
- Keep changes minimal, forward-only, and deterministic.
