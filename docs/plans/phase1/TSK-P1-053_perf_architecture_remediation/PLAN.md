# PLAN: Phase-1 Performance + Architecture Remediation Program

## Metadata
- plan_id: `TSK-P1-053_perf_architecture_remediation`
- date: `2026-02-18`
- status: `proposed_for_review`
- program_type: `phase1_required_with_phase2_followthrough`
- canonical_reference: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

## Decision Summary
This program accepts the performance audit as immediately actionable and accepts the architecture audit as directionally correct with staged execution.

Immediate Phase-1 objective:
- Remove known hot-path performance ceilings while preserving deterministic fail-closed behavior and existing invariant posture.

Deferred Phase-2 objective:
- Modular decomposition and schema domain partitioning after Phase-1 throughput parity evidence is stable.

## Scope Consistency Guard (No Ghost Scope)
- Current canonical contract state includes governance invariant `INV-119` in Phase-1 (`docs/PHASE1/phase1_contract.yml`), enforced through `INT-G28`.
- This program does not reintroduce MCP runtime scope. It only acknowledges currently required governance checks that remain in the existing Phase-1 contract chain.
- If governance is later moved out of Phase-1, that contract change must land first (manifest + control planes + phase1 contract + verifier wiring) in a dedicated scope-change task before this program is rebased.

## Confirmed Issues (with code anchors)
1. Subprocess-based DB access on hot paths:
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:473`
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:724`
- `services/executor-worker/dotnet/src/ExecutorWorker/Program.cs:393`

2. File evidence linear scan:
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:598`
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:616`

3. Duplicate payload materialization:
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:267`
- `services/ledger-api/dotnet/src/LedgerApi/Program.cs:275`

4. Attempt-number aggregate reads:
- `schema/migrations/0002_outbox_functions.sql:239`
- `schema/migrations/0002_outbox_functions.sql:296`
- `schema/migrations/0006_repair_expired_leases_retry_ceiling.sql:29`

## Staged Execution Order

### Stage 1 (Phase-1 Required): DB Driver + Hot Path
- Migrate `db_psql` ingress/evidence path to pooled DB client (`NpgsqlDataSource`) with prepared commands.
- Keep behavior parity: ack only after durable write; tenant fail-closed behavior unchanged.
- Add deterministic parity test coverage for ingress and evidence retrieval.

### Stage 2 (Phase-1 Required): File Mode Policy
- Enforce file mode as dev/local only for pilot deployment profiles.
- Add startup-time fail-closed guard for disallowed environments.
- Add policy evidence artifact.

### Stage 3 (Phase-1 Required): Payload Allocation Reduction
- Single-materialize JSON payload on ingress path.
- Preserve payload hash/output parity and idempotency outcomes.

### Stage 4 (Phase-1 Required): Perf Regression Guard
- Add deterministic microbenchmark/perf-smoke script.
- Emit machine-readable perf evidence (latency + DB duration + throughput summary).
- Add .NET 10 Metrics/OpenTelemetry proof that batching occurs at driver runtime (not only in config docs).
- Wire as non-flaky gate policy (informational first, required after baseline stabilization).

### Stage 5 (Phase-1 Conditional): Attempt Counter Optimization
- Replace `MAX(attempt_no)` path with locked counter increment where safe.
- Preserve uniqueness and append-only invariants.
- Execute only if telemetry shows retry-heavy pressure.

### Stage 6 (Phase-2 Followthrough): Architecture Hardening
- Decompose major scripts into composable modules without changing entrypoints.
- Introduce boundary conformance tests tied to ADR-0001.
- Scope domain-schema migration as separate forward-only program.

## Mechanical Mapping By Stage (Invariant -> Gate -> Verifier -> Evidence)

### Stage 1
- invariants: `INV-117`, `INV-118`, `INV-077`
- gates: `INT-G32`, `INT-G33`, `INT-G28`
- verifiers: `scripts/db/verify_timeout_posture.sh`, `scripts/db/tests/test_ingress_hotpath_indexes.sh`, `scripts/audit/verify_phase1_contract.sh`
- evidence: `evidence/phase0/db_timeout_posture.json`, `evidence/phase1/ingress_hotpath_indexes.json`, `evidence/phase1/perf_db_driver_bench.json`

### Stage 2
- invariants: `INV-077`
- gates: `INT-G28`
- verifiers: `scripts/audit/verify_phase1_contract.sh` + new mode-policy verifier
- evidence: `evidence/phase1/evidence_store_mode_policy.json`
- policy rule:
  - allow: `ENVIRONMENT=local|dev|ci`
  - deny (fail closed at startup): `ENVIRONMENT=staging|pilot|prod`
  - decision evidence must include `{environment, store_mode, decision, reason}`

### Stage 3
- invariants: `INV-117`, `INV-077`
- gates: `INT-G32`, `INT-G28`
- verifiers: `scripts/db/verify_timeout_posture.sh`, `scripts/audit/verify_phase1_contract.sh`
- evidence: `evidence/phase1/perf_db_driver_bench.json`

### Stage 4
- invariants: `INV-077`
- gates: `INT-G28`
- verifiers: new deterministic perf-smoke verifier + `scripts/audit/verify_phase1_contract.sh`
- evidence: `evidence/phase1/perf_smoke_profile.json`, `evidence/phase1/perf_driver_batching_telemetry.json`
- promotion rule:
  - informational until baseline exists and stability threshold is met
  - required only after `N=5` consecutive stable runs with coefficient-of-variation <= `0.15` on p95 latency under fixed profile
  - baseline artifact must be committed with checksum and profile parameters

### Stage 5 (conditional)
- invariants: `INV-117`, `INV-118`
- gates: `INT-G32`, `INT-G33`
- verifiers: `scripts/db/verify_invariants.sh`, `scripts/db/tests/test_db_functions.sh`
- evidence: `evidence/phase1/outbox_retry_semantics.json`
- required safety proofs:
  - concurrency test: no attempt-number collisions under parallel completion/repair
  - append-only proof remains true
  - retry ceiling behavior unchanged

### Stage 6
- invariants: allocate as part of Phase-2 architecture program
- gates: allocate as part of Phase-2 architecture program
- verifiers: boundary conformance verifier(s) + script modularization parity verifier(s)
- evidence: Phase-2 scope (not a Phase-1 closeout blocker)

## Acceptance Criteria (Program)
1. `pre_ci` and Phase-1 contract chain pass with no regression in existing evidence contracts.
2. DB hot-path no longer relies on subprocess shell-out in pilot mode.
3. File mode enforcement prevents unintended staging/prod use.
4. Perf evidence artifact is deterministic and reproducible.
5. Any invariant/gate additions are explicitly registered before claims of completion.
6. No new contract requirement may be introduced unless verifier wiring and evidence emission land in the same PR.

## Verification Commands (Program)
- `bash scripts/audit/verify_agent_conformance.sh`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- `bash scripts/db/verify_invariants.sh`
- `bash scripts/db/tests/test_db_functions.sh`
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `bash scripts/audit/verify_phase1_contract.sh`

## Evidence Targets (Program)
- Existing:
  - `evidence/phase1/phase1_contract_status.json`
  - `evidence/phase1/phase1_closeout.json`
  - `evidence/phase1/agent_conformance_architect.json`
  - `evidence/phase1/agent_conformance_implementer.json`
  - `evidence/phase1/agent_conformance_policy_guardian.json`
- Planned additions (to be allocated/implemented in this program):
  - `evidence/phase1/perf_db_driver_bench.json`
  - `evidence/phase1/evidence_store_mode_policy.json`
  - `evidence/phase1/perf_smoke_profile.json`
  - `evidence/phase1/perf_driver_batching_telemetry.json`
  - `evidence/phase1/outbox_retry_semantics.json` (conditional stage)

## Risks and Controls
- Risk: performance changes break deterministic behavior.
  - Control: parity tests + fail-closed error-path tests before enabling by default.
- Risk: flaky perf gate causes bypass pressure.
  - Control: deterministic profile + informational rollout + threshold hardening.
- Risk: architecture refactor dilutes gate clarity.
  - Control: keep top-level script interfaces and evidence contracts unchanged while refactoring internals.
