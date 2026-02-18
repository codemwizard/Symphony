# Implementation Plan (TSK-P0-038)

origin_task_id: TSK-P0-038
title: SQLSTATE registry + drift check (scoped, deterministic)
owner_role: PLATFORM
assigned_agent: platform
created_utc: 2026-02-09T00:00:00Z

## Goal
Ensure all custom SQLSTATE codes used in migrations/scripts/docs are registered and drift-free.

## Deliverables
- Registry: `docs/contracts/sqlstate_map.yml`
- Drift check: `scripts/audit/check_sqlstate_map_drift.sh` emitting:
  - `evidence/phase0/sqlstate_map_drift.json`
- Wired into fast checks: `scripts/audit/run_invariants_fast_checks.sh`

## Evidence
- `evidence/phase0/sqlstate_map_drift.json`

## Acceptance
- Drift check fails when codes are missing from registry.
- Evidence JSON is emitted deterministically (PASS/FAIL).

