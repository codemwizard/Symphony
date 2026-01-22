# Tasks List: Lease Model Definition-of-Done Sweep

## A) CI gate (single ordered job)
1) Add a job that runs, in order:
   - guardrails with `ENFORCE_NO_DB_QUERY=1`
   - unit tests
   - integration tests (DB-gated)
   - evidence generation
   - artifact upload (always run)
2) Mark that job as a required status check.

## B) Operational signals
1) Add counters/log hooks for:
   - `expired_lease_count`
   - `repair_requeued_count`
   - `lease_lost_count` (SQLSTATE `P7002`)
   - `terminal_guard_hit_count` (SQLSTATE `23505` on `payment_outbox_attempts_one_terminal_per_outbox`)
2) Log as operational signals (not errors) with one increment per event.
3) Rate-limit or aggregate per cycle if volumes spike.
4) Emit `LEASE_LOST_CONCURRENCY_EVENT` at info/warn for `P7002`.

## C) Regression query gate
1) Add post-test SQL assertion in CI:
   - `SELECT COUNT(*) FROM payment_outbox_attempts WHERE state='DISPATCHING';` must be 0
2) Fail CI if non-zero (DB-gated, post-integration).

## D) Evidence bundle README
1) Extend `scripts/reports/generate-outbox-evidence.sh` to emit `00_README.txt`.
2) Document each file, the invariant it proves, and SQLSTATE expectations with a short mapping list.

## E) Release hygiene
1) Replace “zombie” terminology with “lease repair” in docs/config/log labels.
2) Align config names to:
   - `LEASE_SECONDS`
   - `LEASE_REPAIR_BATCH_SIZE`

## F) Acceptance criteria
1) CI fails if guardrails/proofs/evidence/regression query fails.
2) Operational counters are visible in logs/metrics without error-level noise.
3) Evidence bundle is auditor-readable with `00_README.txt`.
4) No user-facing zombie terminology remains.
5) Evidence artifact uploads even on failed runs.
