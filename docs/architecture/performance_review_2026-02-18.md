# Performance Review — 2026-02-18

## Scope and method

This review is static (code + schema inspection) of the current implementation for:

- `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
- `services/executor-worker/dotnet/src/ExecutorWorker/Program.cs`
- `schema/migrations/0001_init.sql`, `0002_outbox_functions.sql`, `0013_outbox_pending_indexes_concurrently.sql`, `0018_outbox_tenant_attribution.sql`

Phase-1 governance note: `docs/operations/AI_AGENT_OPERATION_MANUAL.md` remains the canonical operational reference for regulated workflows.

## 1) Bottlenecks identified

### A. Per-request `psql` process spawning in API DB mode

`PsqlIngressDurabilityStore` and `PsqlEvidencePackStore` shell out to `psql` for each request (`Process.Start`, write SQL to stdin, read stdout/stderr, wait for exit). This adds process startup + IPC overhead on every call and limits throughput under concurrency.

- Impact: higher p95/p99 latency and lower RPS in `db_psql` mode.
- Recommendation: replace `psql` subprocess calls with a pooled PostgreSQL client (`NpgsqlDataSource`) and prepared commands.
- Priority: **P0** for production traffic.

### B. O(n) evidence lookups in file mode

`FileEvidencePackStore.FindAsync` linearly scans an NDJSON file and parses each row until a match is found.

- Impact: lookup cost grows with total attestations; latency can become unbounded for large files.
- Recommendation: switch to DB-backed lookups for non-trivial scale, or maintain a sidecar index (instruction_id + tenant_id -> file offset) if file mode must persist.
- Priority: **P1** if file mode is used beyond local/dev.

### C. Repeated string/JSON transformations on hot path

Ingress handling computes payload hash from `request.payload.GetRawText()` and separately calls `GetRawText()` again for persistence, causing duplicate materialization and allocation.

- Impact: avoidable CPU + memory churn proportional to payload size.
- Recommendation: extract payload JSON text once, reuse for hash and persistence.
- Priority: **P2**.

### D. Attempt-number resolution scans in SQL functions

`complete_outbox_attempt` and `repair_expired_leases` compute next attempt number via `MAX(attempt_no)` by `outbox_id`. Indexing exists, but high-attempt items still require repeated aggregate reads.

- Impact: extra DB work under retry-heavy load.
- Recommendation: prefer `payment_outbox_pending.attempt_count + 1` as authoritative next attempt number inside the same row lock path, while keeping uniqueness constraint as safety backstop.
- Priority: **P2**.

## 2) Resource utilization check

### CPU

- Fixed-time API-key checks allocate byte arrays each request (`Encoding.UTF8.GetBytes` twice). Correct for security, but could use stackalloc/span for lower allocation overhead if needed.
- JSON parse/serialize is frequent in file-backed persistence and retrieval.

### Memory

- File evidence lookup repeatedly allocates `JsonDocument` per line.
- `stdout.Split('\n').ToList()` on DB mode paths allocates intermediate arrays/lists.

### I/O

- File mode performs append writes and full-file scans.
- DB mode does short-lived subprocess I/O instead of persistent socket pooling.

### DB utilization posture

- Outbox claim path is reasonably optimized with due-claim index and `FOR UPDATE SKIP LOCKED`.
- Tenant-aware index also exists for Phase-1 query shapes.

## 3) Algorithmic efficiency review

- **Good**: queue claiming is bounded by `LIMIT p_batch_size` with indexed ordering and lock-skipping semantics.
- **Needs improvement**: file evidence retrieval is linear scan; subprocess-per-query is effectively high constant-factor overhead.
- **Potential refinement**: repeated `MAX(attempt_no)` reads can be replaced by monotonic counter reuse under lock.

## 4) Caching strategy assessment

- No in-process caching layer is present for ingress auth/config, evidence lookups, or query plans.
- Current architecture appears intentionally deterministic/fail-closed, but performance can improve with constrained caches that preserve correctness:
  - short-lived API-key/config snapshot cache with explicit reload interval.
  - prepared statement cache via native DB driver (automatic in pooled provider).
  - optional read-through cache for evidence packs with tenant-scoped keys and low TTL.

## Recommended optimization plan

1. **Migrate DB access from `psql` subprocesses to Npgsql pooling** (largest win).
2. **Keep file mode dev-only and document hard scale limits**; prefer DB mode in any shared/staging/prod environment.
3. **Single-materialize request payload JSON** on ingress path.
4. **Replace `MAX(attempt_no)` lookups with locked-counter increment strategy** while retaining unique constraint.
5. **Add performance telemetry**:
   - endpoint latency histograms (p50/p95/p99)
   - DB call duration metrics
   - outbox queue depth + claim lag
6. **Load-test gates** in CI for regression prevention (small deterministic k6/vegeta profile).

## Suggested acceptance criteria for follow-up PRs

- ≥40% reduction in p95 latency for DB-backed ingress writes under representative concurrency.
- Zero regression in fail-closed behavior and append-only invariants.
- Stable memory profile under sustained evidence lookup load.
