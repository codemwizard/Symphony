---
exception_id: EXC-20260419-001
inv_scope: change-rule
expiry: 2026-06-01
follow_up_ticket: WAVE8-POSTGIS-FIX
reason: Fix migration 0128 to comply with expand/contract policy lint. Changed from direct NOT NULL ADD COLUMN to expand/contract pattern (add nullable, backfill, then add NOT NULL constraint).
author: mwiza
created_at: 2026-04-19
---

# Exception: ddl structural change for expand/contract compliance

This exception is for fixing migration 0128 to comply with the expand/contract policy lint.

## Reason

Migration 0128 originally added a NOT NULL column directly with DEFAULT, which violates the expand/contract policy. The fix changes it to follow the proper pattern: add as nullable, backfill existing rows, then add NOT NULL constraint.

## Evidence

structural_change: True
confidence_hint: 1.0
primary_reason: ddl
reason_types: ddl

Matched files:
- schema/migrations/0128_taxonomy_aligned.sql

Top matches:
- ddl | docs/security/ddl_allowlist.json | +: "statement_fingerprint": "alter table public.projects add column taxonomy_aligned boolean",
- ddl | schema/migrations/0128_taxonomy_aligned.sql | +: -- Expand phase: Add column as nullable
- ddl | schema/migrations/0128_taxonomy_aligned.sql | -: ALTER TABLE public.projects ADD COLUMN taxonomy_aligned BOOLEAN NOT NULL DEFAULT false;
- ddl | schema/migrations/0128_taxonomy_aligned.sql | +: ALTER TABLE public.projects ADD COLUMN taxonomy_aligned BOOLEAN;
- ddl | schema/migrations/0128_taxonomy_aligned.sql | +: ALTER TABLE public.projects ALTER COLUMN taxonomy_aligned SET NOT NULL;

## Mitigation

The migration now follows the expand/contract pattern:
1. Add column as nullable (expand)
2. Backfill existing rows with default value
3. Add NOT NULL constraint (contract)

This ensures zero-downtime deployment and compliance with the expand/contract policy.
