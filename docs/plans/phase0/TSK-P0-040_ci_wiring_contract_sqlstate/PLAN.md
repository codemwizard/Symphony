# Implementation Plan (TSK-P0-040)

origin_task_id: TSK-P0-040
title: Wire contract + SQLSTATE drift checks into CI
owner_role: SECURITY_GUARDIAN
assigned_agent: security_guardian
created_utc: 2026-02-09T00:00:00Z

## Goal
Ensure CI runs the contract validator and SQLSTATE drift gate as part of the mechanical invariants job, and uploads evidence.

## Deliverables
- CI workflow includes the canonical ordered runner:
  - `.github/workflows/invariants.yml` runs `scripts/audit/run_phase0_ordered_checks.sh`
- Evidence uploaded:
  - `evidence/phase0/phase0_contract.json`
  - `evidence/phase0/sqlstate_map_drift.json`

## Acceptance
- CI runs ordered checks and evidence status gate.
- Evidence artifacts are included in the Phase-0 evidence upload.

