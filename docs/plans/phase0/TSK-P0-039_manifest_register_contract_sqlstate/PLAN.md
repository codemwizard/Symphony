# Implementation Plan (TSK-P0-039)

origin_task_id: TSK-P0-039
title: Register SQLSTATE + contract invariants in manifest
owner_role: INVARIANTS_CURATOR
assigned_agent: invariants_curator
created_utc: 2026-02-09T00:00:00Z

## Goal
Ensure the Phase-0 contract and SQLSTATE drift controls are first-class invariants in the manifest and invariant docs.

## Deliverables
- Manifest entries:
  - `INV-060` for Phase-0 contract verification
  - `INV-061` for SQLSTATE registry drift check
- Doc regeneration:
  - `docs/invariants/INVARIANTS_QUICK.md` aligns with manifest

## Acceptance
- `scripts/audit/validate_invariants_manifest.py` passes.
- `scripts/audit/check_docs_match_manifest.py` passes.

