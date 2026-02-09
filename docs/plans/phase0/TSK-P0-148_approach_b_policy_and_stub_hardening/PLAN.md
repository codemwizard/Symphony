# Implementation Plan (TSK-P0-148)

failure_signature: P0.SKIPPED_GATES.POLICY_AMBIGUITY
origin_task_id: TSK-P0-147
first_observed_utc: 2026-02-09T00:00:00Z

repro_command: bash scripts/audit/run_invariants_fast_checks.sh

## goal
Make “Approach B (declare early + SKIPPED stubs)” an explicit, enforced Phase-0 policy, and harden the repo so stubs are:
- uniform,
- deterministic,
- parity-wired,
- and cannot be accidentally promoted to contract-required in a way that triggers missing evidence failures.

## scope_boundary
In scope:
- Add canonical policy doc under `docs/PHASE0/`.
- Add a shared stub helper that emits SKIPPED evidence in a uniform schema.
- Add a mechanical verifier that enforces stub conventions (marker + evidence emission + required fields).

Out of scope:
- Implementing the non-stub verifiers for BoZ seat / PII lint / anchor-sync readiness (those remain under their owning tasks).

## deliverables
- Policy: `docs/PHASE0/PLANNED_SKIPPED_GATES_POLICY.md`
- Helper: `scripts/audit/emit_skipped_evidence.sh`
- Verifier: `scripts/audit/verify_skipped_gate_stubs.sh`
- Wiring: verifier runs in `scripts/audit/run_invariants_fast_checks.sh` (fast, no DB)

## acceptance
- `verify_skipped_gate_stubs.sh` passes and produces evidence.
- Introducing a stub script without the required marker or without evidence emission fails fast in local pre-CI and CI.

## verification_commands_run
- bash scripts/audit/run_invariants_fast_checks.sh
- scripts/dev/pre_ci.sh

## final_status
OPEN

