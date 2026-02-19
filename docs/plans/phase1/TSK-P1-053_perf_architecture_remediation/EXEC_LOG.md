# EXEC_LOG: TSK-P1-053 Performance + Architecture Remediation

## 2026-02-18
- Reviewed:
  - `docs/operations/Architecture_assessment.md`
  - `docs/operations/PERFORMANCE-REVIEW_2026-02-18.md`
- Cross-checked implementation references in:
  - `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
  - `services/executor-worker/dotnet/src/ExecutorWorker/Program.cs`
  - `schema/migrations/0002_outbox_functions.sql`
  - `schema/migrations/0006_repair_expired_leases_retry_ceiling.sql`
  - `scripts/dev/pre_ci.sh`
  - `scripts/db/verify_invariants.sh`
  - `scripts/audit/run_invariants_fast_checks.sh`
- Ran conformance prerequisite:
  - `bash scripts/audit/verify_agent_conformance.sh` -> PASS
- Produced:
  - `docs/operations/PERF_ARCH_AUDIT_ALIGNMENT_AND_EXECUTION_2026-02-18.md`
  - `docs/plans/phase1/TSK-P1-053_perf_architecture_remediation/PLAN.md`
  - Task chain `TSK-P1-053` through `TSK-P1-060`

Status: Planning complete; implementation pending approval.

## 2026-02-18 (implementation start)
- Implemented Stage-1 core DB-path migration in `LedgerApi`:
  - added pooled Npgsql dependency: `services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj`
  - replaced subprocess stores with pooled DB stores:
    - `NpgsqlIngressDurabilityStore`
    - `NpgsqlEvidencePackStore`
  - retained compatibility aliases for storage mode values: `db`, `db_psql`, `db_npgsql`.
- Implemented Stage-2 fail-closed policy guard:
  - file mode blocked in `ENVIRONMENT=staging|pilot|prod`.
  - unknown `INGRESS_STORAGE_MODE` now fails closed.
- Implemented Stage-3 payload hot-path optimization:
  - single materialization of `payload.GetRawText()` for hash + persistence.
- Verification run results:
  - `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj` -> PASS
  - `dotnet run ... --self-test` -> PASS
  - `dotnet run ... --self-test-evidence-pack` -> PASS
  - `dotnet run ... --self-test-case-pack` -> PASS
  - `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh` -> PASS

Status: Stage-1 complete, Stage-2 policy guard complete (evidence emitter pending), Stage-3 complete.

## 2026-02-18 (stage follow-through)
- Removed AOT tagging from TSK-P1-057 and parent plan per explicit request.
- Implemented Stage-2 evidence verifier:
  - `scripts/audit/verify_evidence_store_mode_policy.sh`
  - emits `evidence/phase1/evidence_store_mode_policy.json`
- Implemented Stage-4 perf smoke scaffolding:
  - `scripts/audit/run_perf_smoke_profile.sh`
  - emits:
    - `evidence/phase1/perf_smoke_profile.json`
    - `evidence/phase1/perf_db_driver_bench.json`
    - `evidence/phase1/perf_driver_batching_telemetry.json`
- Wired both scripts into `RUN_PHASE1_GATES=1` path in `scripts/dev/pre_ci.sh`.

## Remediation Trace Markers
- failure_signature: `pre_push remediation trace gate required markers missing for TSK-P1-053 plan/log pair`
- repro_command: `git push origin feature/phase1-semantic-integrity-prA`
- verification_commands_run:
  - `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh` -> PASS
- final_status: `in_progress`
- origin_task_id: `TSK-P1-053`
- origin_gate_id: `INT-G28`
