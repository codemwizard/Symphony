# Implementation Plan (TSK-P0-042)

origin_task_id: TSK-P0-042
title: Add tenant/member invariants + evidence contract entries
owner_role: PLATFORM
assigned_agent: invariants_curator
created_utc: 2026-02-09T00:00:00Z

## Goal
Make tenant/client/member rails and their verifier first-class Phase-0 invariants, and ensure the contract requires the right evidence artifact.

## Deliverables
- Manifest entries for INV-062..INV-066 reference `scripts/db/verify_tenant_member_hooks.sh`.
- Quick doc regenerated and consistent with the manifest.
- Phase-0 contract contains a row for `TSK-P0-042` requiring:
  - `evidence/phase0/invariants_quick.json`

## Verification
- `bash scripts/audit/run_invariants_fast_checks.sh`
- `bash scripts/audit/verify_phase0_contract.sh`

## Evidence
- `evidence/phase0/invariants_quick.json`

