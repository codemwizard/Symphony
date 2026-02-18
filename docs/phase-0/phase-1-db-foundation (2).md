# Phase 1: DB Foundation (DB-MIG + Outbox + Boot Policy Table)

## Goal
Establish the minimal production-grade database substrate:
- forward-only migrations with ledger
- outbox tables + lease-fencing functions
- roles + least privilege posture (function-first)
- boot-critical policy table exists and matches runtime query shape

## Scope
- Apply migrations 0001–0005 in order.
- Outbox:
  - `payment_outbox_pending`
  - `payment_outbox_attempts` (append-only)
  - `participant_outbox_sequences`
  - functions: enqueue, claim, complete, repair
- Roles:
  - `symphony_ingest`, `symphony_executor`, `symphony_readonly`, `symphony_auditor`, `symphony_control` (NOLOGIN templates)
  - `test_user` (LOGIN; password set outside migrations)
- Privileges:
  - deny-by-default, revoke-first
  - function-first runtime access
  - Option A: **no overrides** on attempts (even control cannot UPDATE/DELETE/TRUNCATE)
- Policy:
  - `policy_versions` table exists
  - `is_active` exists for compatibility with current boot check

## Seeding (not in migrations)
Provide a seed mechanism that inserts the initial ACTIVE policy version:
- scripts or control-plane command
- idempotent
- must not read local files in migrations

## Acceptance criteria
- Docker/runtime no longer fails with missing `policy_versions`.
- `scripts/db/verify_invariants.sh` passes on fresh DB after migrations.
- Policy seed step can be executed (service may still fail closed until seeded, by design).
