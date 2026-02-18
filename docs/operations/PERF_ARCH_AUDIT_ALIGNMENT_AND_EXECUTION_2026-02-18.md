# Performance + Architecture Audit Alignment (2026-02-18)

## Scope Reviewed
- `docs/operations/Architecture_assessment.md`
- `docs/operations/PERFORMANCE-REVIEW_2026-02-18.md`
- Current implementation in:
  - `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
  - `services/executor-worker/dotnet/src/ExecutorWorker/Program.cs`
  - `schema/migrations/0002_outbox_functions.sql`
  - `schema/migrations/0006_repair_expired_leases_retry_ceiling.sql`
  - `scripts/dev/pre_ci.sh`
  - `scripts/db/verify_invariants.sh`
  - `scripts/audit/run_invariants_fast_checks.sh`

## What I Agree With (Confirmed)

### 1) Per-request `psql` subprocess overhead is real (P0)
Confirmed in code:
- `PsqlIngressDurabilityStore` shells out to `psql`: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:412`, `services/ledger-api/dotnet/src/LedgerApi/Program.cs:473`
- `PsqlEvidencePackStore` shells out to `psql`: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:676`, `services/ledger-api/dotnet/src/LedgerApi/Program.cs:724`
- Worker also shells out to `psql`: `services/executor-worker/dotnet/src/ExecutorWorker/Program.cs:393`

Assessment: valid bottleneck and high-priority remediation candidate for pilot-readiness throughput.

### 2) File evidence lookup is linear scan and unbounded at scale (P1)
Confirmed in code:
- NDJSON read loop scans until match: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:598-664`
- Parses each row (`JsonDocument.Parse`) in loop: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:616`

Assessment: valid. If file mode is used outside local/dev, latency growth is structural.

### 3) Duplicate payload materialization exists on ingress path (P2)
Confirmed in code:
- Hash path calls `GetRawText()`: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:267`
- Persist payload calls `GetRawText()` again: `services/ledger-api/dotnet/src/LedgerApi/Program.cs:275`

Assessment: valid micro-optimization; safe to fix with parity tests.

### 4) `MAX(attempt_no)` lookup exists in retry paths (P2)
Confirmed in SQL:
- `complete_outbox_attempt`: `schema/migrations/0002_outbox_functions.sql:239-240`
- `repair_expired_leases`: `schema/migrations/0002_outbox_functions.sql:296-297`
- Retained in retry-ceiling migration: `schema/migrations/0006_repair_expired_leases_retry_ceiling.sql:29-30`

Assessment: valid observation. Keep correctness first (append-only + uniqueness constraints remain non-negotiable).

### 5) Architecture is governance-heavy with minimal service footprint
Confirmed from current tree:
- Service files are small in count (two .NET entrypoints + configs): `services/`
- Large central gate scripts:
  - `scripts/dev/pre_ci.sh` (487 lines)
  - `scripts/db/verify_invariants.sh` (286 lines)
  - `scripts/audit/run_invariants_fast_checks.sh` (381 lines)

Assessment: architecture-audit claim is directionally correct.

## What I Partially Agree With (Needs Scope Discipline)

### 6) “Break god scripts now”
Agree with objective; disagree with doing broad refactor before preserving gate parity.
- Required approach: modularize behind unchanged top-level entrypoints and evidence contracts.
- No behavior drift allowed in `pre_ci`/contract gates during decomposition.

### 7) “Move to domain DB schemas now”
Agree long-term; not a Phase-1 immediate blocker.
- This is migration-heavy and can create operational risk if mixed into hot-path performance work.
- Should be staged after immediate throughput and determinism remediations.

## What I Disagree With (Current State Already Remediated)

### 8) Local reproducibility failure due to missing PyYAML as a current blocker
This was true in older local contexts but is not accurate as current-state blocker.
- Toolchain bootstrap pins `pyyaml`: `scripts/audit/bootstrap_local_ci_toolchain.sh:37`
- `verify_agent_conformance.sh` runs in current environment (validated run on this branch).

Assessment: keep as historical risk note, not a present-severity blocker.

## Phase-1 Remediation Position
Phase-1 execution should prioritize throughput bottlenecks and fail-closed parity while preserving current invariant chain.

Required sequencing:
1. Replace subprocess DB access with pooled DB client path (without weakening durability semantics).
2. Enforce file-mode policy (dev-only for pilot paths) or ship indexed file lookup.
3. Remove duplicate payload materialization.
4. Add deterministic perf smoke evidence + regression thresholding.
5. Only then optimize attempt-number lookup if retry-heavy telemetry confirms need.

## Evidence Standards for This Program
Every completed item must include:
- invariant mapping (existing or newly allocated)
- verifier command
- evidence artifact path
- contract/gate wiring decision (required vs informational)

Canonical operational reference for all Phase-1 execution:
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
