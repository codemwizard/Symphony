# Tasks List: Outbox Lease Model Closeout

## A) Schema cleanup (DISPATCHING residue)
1) Remove `ix_attempts_dispatching_age` creation from `schema/v1/011_payment_outbox.sql`.
2) Add `DROP INDEX IF EXISTS public.ix_attempts_dispatching_age;` for idempotent cleanup.
3) Add a deprecation note near the attempt-state enum: DISPATCHING is historical-only, no inserts (policy/guardrails).

## B) Guardrails (regression-proofing)
1) Add a guardrail to fail delete-on-claim CTE patterns only:
   - `WITH due AS` + `FOR UPDATE SKIP LOCKED` + `DELETE FROM payment_outbox_pending USING due`.
2) Add a guardrail to fail only when `INSERT INTO payment_outbox_attempts` appears near `DISPATCHING`.
3) Allow legitimate terminal deletes inside DB functions and DDL under `schema/`.
4) Ensure guardrails still pass with `ENFORCE_NO_DB_QUERY=1`.

## C) Evidence bundle generator
1) Create `scripts/reports/generate-outbox-evidence.sh` (or `.ts`) to build `reports/outbox-evidence/`.
2) Include grants for outbox tables/functions.
3) Include full function definitions for:
   - `enqueue_payment_outbox`
   - `claim_outbox_batch`
   - `complete_outbox_attempt`
   - `repair_expired_leases`
   - `deny_outbox_attempts_mutation`
4) Include DDL snippets for:
   - pending lease columns + lease consistency CHECK
   - append-only trigger function + trigger binding
   - terminal uniqueness partial index name
5) Include proof/test manifest (commands + expected SQLSTATEs).
6) Optionally include `schema/views/outbox_status_view.sql` output.
7) Add `reports/.gitkeep` if the repo expects the directory to exist.

## D) Test plan (PR gating)
1) Unit:
   - `tests/unit/outboxAppendOnlyTrigger.spec.ts`
   - `tests/unit/leaseRepairProof.spec.ts`
   - `tests/unit/OutboxRelayer.spec.ts`
2) Integration (DB-gated):
   - `tests/integration/outboxLeaseLossProof.spec.ts`
   - `tests/integration/outboxCompleteConcurrencyProof.spec.ts`
   - `tests/integration/outboxConcurrency.test.ts`
3) CI: run guardrails with `ENFORCE_NO_DB_QUERY=1`.

## E) Acceptance criteria
1) No code path can insert `DISPATCHING` attempts (guardrails + tests).
2) Delete-on-claim is blocked; terminal deletes inside DB functions remain allowed.
3) Evidence generator emits `reports/outbox-evidence/*` deterministically.
4) Optional regression assertion: `SELECT COUNT(*) FROM payment_outbox_attempts WHERE state='DISPATCHING';` is 0 after relayer activity.
