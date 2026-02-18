# Implementation Plan (TSK-P0-144)

failure_signature: P0.PERF.GUARDRAILS.MISSING
origin_task_id: TSK-P0-144
repro_command: bash scripts/audit/verify_performance_guardrails.sh || true

## Purpose
Implement mechanical verifiers that make common Phase-0 performance foot-guns hard to introduce (static/catalog-based checks only).

## Scope
In scope:
- One or more verifier scripts:
  - `scripts/db/verify_performance_invariants.sh` and/or
  - `scripts/audit/verify_performance_guardrails.sh`
- Evidence output:
  - `evidence/phase0/performance_guardrails.json`
- Deterministic execution in CI + local pre-CI.

Out of scope:
- Runtime profiling, EXPLAIN ANALYZE thresholds, or numeric SLA guarantees.

## Typical Checks (Phase-0 appropriate)
- Required index posture exists for known hot paths (extend existing `INV-031` and `INV-012` posture).
- No obvious unbounded polling constructs in repo scripts (where applicable).

verification_commands_run:
- "PENDING: bash scripts/audit/verify_performance_guardrails.sh"

final_status: OPEN

