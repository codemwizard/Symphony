---
exception_id: EXC-20260310-REFPOL-BASELINE
inv_scope: change-rule
expiry: 2026-12-31
follow_up_ticket: TSK-HARD-030
reason: Baseline snapshot refresh after rebasing the reference-policy post-active immutability migration to 0072 introduces a new dated baseline directory as required by baseline governance.
author: codex
created_at: 2026-03-10
---

# Exception: migration_file_added_or_deleted structural change without invariants linkage

This exception covers the dated baseline snapshot refresh required after rebasing the reference-policy post-deactivation immutability migration onto current `origin/main` as `0072_hard_wave6_reference_policy_post_deactivation_immutability.sql`.

## Reason

The branch legitimately adds `schema/baselines/2026-03-10/*` and updates the current baseline pointers because the rebased branch now changes schema state beyond `0071_phase2_internal_ledger_core.sql`. Baseline regeneration is required to keep drift checks truthful.

## Evidence

structural_change: True
confidence_hint: 0.7
primary_reason: migration_file_added_or_deleted
reason_types: migration_file_added_or_deleted
origin_task_id: TSK-HARD-030
repro_command: DATABASE_URL=postgresql://symphony:symphony@127.0.0.1:55432/symphony bash scripts/db/generate_baseline_snapshot.sh 2026-03-10
verification_commands_run:
- DATABASE_URL=postgresql://symphony:symphony@127.0.0.1:55432/symphony bash scripts/db/reset_and_migrate.sh
- DATABASE_URL=postgresql://symphony:symphony@127.0.0.1:55432/symphony bash scripts/db/generate_baseline_snapshot.sh 2026-03-10
- POSTGRES_USER=symphony POSTGRES_PASSWORD=symphony POSTGRES_DB=symphony HOST_POSTGRES_PORT=55432 DATABASE_URL=postgresql://symphony:symphony@127.0.0.1:55432/symphony bash scripts/dev/pre_ci.sh
final_status: PASS

Matched files:
- schema/baselines/2026-03-10/baseline.normalized.sql
- schema/baseline.sql
- schema/baselines/current/0001_baseline.sql
- schema/baselines/current/baseline.cutoff
- schema/baselines/current/baseline.meta.json

## Mitigation

The schema change itself is already linked to the hardening remediation trace and governance docs. This exception only acknowledges the mechanical addition of the dated baseline snapshot directory required by baseline governance after the migration was renumbered and replayed against current main.
