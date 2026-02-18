# Implementation Plan (TSK-P0-019)

origin_task_id: TSK-P0-019
title: CI artifact upload verification (integration)
owner_role: PLATFORM
assigned_agent: worker
created_utc: 2026-02-09T00:00:00Z

## Goal
Make Phase-0 evidence artifact upload mechanically verifiable in CI, not a manual expectation.

## Deliverables
- CI-only verifier script that:
  - asserts evidence outputs exist before upload
  - asserts the CI workflow is configured to upload `phase0-evidence` from `evidence/**`
  - emits evidence JSON for the check
- Contract entry uses a file-based evidence path (not a GitHub artifact name).

## Evidence
- `evidence/phase0/ci_artifact_upload_verified.json`

## Wiring
- Run in CI as part of the canonical ordered runner (`scripts/audit/run_phase0_ordered_checks.sh`).
- Mark contract row as `verification_mode: ci` so local pre-push does not require a CI-only artifact check.

## Acceptance
- CI emits `evidence/phase0/ci_artifact_upload_verified.json` with `PASS`.
- `docs/PHASE0/phase0_contract.yml` requires that evidence only in CI mode.

