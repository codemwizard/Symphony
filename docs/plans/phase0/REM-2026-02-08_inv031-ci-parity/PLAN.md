# Remediation Plan

failure_signature: CI.INV-031.OUTBOX_PENDING_INDEXES.MISSING_ON_FRESH_DB
origin_task_id: TSK-P0-146
first_observed_utc: 2026-02-08T17:48:14Z

## production-affecting surfaces
- scripts/**
- .github/workflows/**
- docs/PHASE0/**
- docs/control_planes/**

## repro_command
bash scripts/db/tests/test_outbox_pending_indexes.sh

## scope_boundary
In scope:
- Ensure the outbox pending indexes verifier only executes after migrations in CI (fresh DB) and local pre-push parity.
- Ensure no duplicate evidence writers overwrite `evidence/phase0/outbox_pending_indexes.json` with inconsistent schemas.

Out of scope:
- Any schema changes to the outbox index definition (migrations are assumed correct).

## proposed_fix
- Remove any CI step that runs `run_phase0_ordered_checks.sh` in a DB job before migrations.
- Keep DB verification of `INV-031` under `scripts/db/verify_invariants.sh` (which applies migrations first).
- Normalize evidence emission to a single canonical producer.

## verification_commands_run
- scripts/dev/pre_ci.sh
- bash scripts/audit/run_phase0_ordered_checks.sh
- bash scripts/audit/verify_remediation_trace.sh

## final_status
PASS

