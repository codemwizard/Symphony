# Option 2A (Hot/Archive + Hybrid Wakeup) — Walkthrough

## Summary of Work
- Added the replace-in-place migration for Option 2A, including the participant sequence allocator, hot pending queue, append-only attempts archive, and the NOTIFY trigger, while dropping the legacy outbox table and enum.
- Updated the outbox producer to allocate participant sequences in-transaction and enqueue into the new pending table with idempotency safeguards.
- Rebuilt the relayer to use LISTEN/NOTIFY plus fallback polling, crash-consistent claim semantics, bounded concurrency, validation, timeout handling, explicit error classification, and retry requeueing with backoff.
- Simplified zombie repair to requeue stale DISPATCHING attempts and record ZOMBIE_REQUEUE audit entries.
- Refreshed supervisor views, evidence export, and ledger replay utilities to read from the new pending/attempts model.

## Unit Tests
- `node --test tests/unit/OutboxDispatchService.spec.ts` (fails: module build output not present).
- `node --test tests/unit/EvidenceExportService.spec.ts` (fails: module build output not present).
- `node --test tests/unit/ZombieRepairWorker.spec.ts` (fails: module build output not present).
