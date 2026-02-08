# Implementation Plan (TSK-P0-129)

failure_signature: P0.REG.ANCHOR_SYNC_HOOKS.MISSING
origin_task_id: TSK-P0-129
repro_command: source infra/docker/.env && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}" && scripts/db/verify_anchor_sync_hooks.sh

## Goal
Prove Phase-0 hybrid anchor-sync readiness is structurally present (no operational queue semantics).

## Scope
In scope:
- Catalog-based verifier `scripts/db/verify_anchor_sync_hooks.sh`
- Checks anchored on existing Phase-0 schema hooks (e.g., `public.evidence_packs` anchor metadata from migration 0023)
- Evidence JSON at `evidence/phase0/anchor_sync_hooks.json`

Out of scope:
- Adding job-tracking tables (Phase-1 operational scaffolding)
- Implementing evidence signing/anchoring runtime workflows (Phase-1)

## Acceptance
- Verifier proves required anchor metadata columns and indexes exist.
- Verifier emits evidence on PASS and FAIL.

verification_commands_run:
- "PENDING: source infra/docker/.env && export DATABASE_URL=... && scripts/db/verify_anchor_sync_hooks.sh"

final_status: OPEN

