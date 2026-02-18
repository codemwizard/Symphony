# Implementation Plan (TSK-P0-037)

origin_task_id: TSK-P0-037
title: Phase-0 evidence contract + gate switch (authoritative)
owner_role: PLATFORM
assigned_agent: platform
created_utc: 2026-02-09T00:00:00Z

## Goal
Make `docs/PHASE0/phase0_contract.yml` the single source of truth for which Phase-0 tasks require evidence, and enforce it mechanically.

## Deliverables
- Contract file: `docs/PHASE0/phase0_contract.yml`
- Contract validator: `scripts/audit/verify_phase0_contract.sh` (emits `evidence/phase0/phase0_contract.json`)
- Evidence gate uses contract semantics: `scripts/ci/check_evidence_required.sh`
- Wired into fast checks: `scripts/audit/run_invariants_fast_checks.sh`

## Evidence
- `evidence/phase0/phase0_contract.json`

## Acceptance
- Contract validates deterministically.
- Evidence gate enforces only `completed` tasks with `evidence_required: true`.

