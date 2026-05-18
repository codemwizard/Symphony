---
exception_id: EXC-20260505-001
inv_scope: change-rule
expiry: 2026-06-01
follow_up_ticket: WAVE8-CLOSURE
reason: Modifying migration 0203 and regenerating the baseline schema snapshot triggers the structural change detector.
author: mwiza
created_at: 2026-05-05
closed_at: 2026-05=18
---

# Exception: Structural Fixes for Append-Only Contract

This exception is necessary to allow committing the structural fixes applied to `0203_converge_policy_decisions_schema.sql` and the associated baseline snapshot updates (`schema/baseline.sql` and `schema/baselines/current/0001_baseline.sql`).

## Reason

During the closure of Wave 8, an incomplete trigger definition was found in `0203` where `policy_decisions_append_only_trigger` was set to `BEFORE DELETE` instead of `BEFORE UPDATE OR DELETE`. Modifying this historical migration to enforce the correct contract structurally alters the DB baseline.

Regenerating the baseline files directly triggers the `migration_file_added_or_deleted` rule in the local git preflight checks.

## Evidence

structural_change: True
primary_reason: migration_file_added_or_deleted
reason_types: migration_file_added_or_deleted

Matched files:
- schema/migrations/0203_converge_policy_decisions_schema.sql
- schema/baselines/current/0001_baseline.sql
- schema/baseline.sql

## Mitigation

The change to `0203` strictly hardens the append-only security posture of the `policy_decisions` table. The baseline modifications are mechanically generated via the official DRD protocol and do not introduce unverified logic.
