# Implementation Plan (TSK-P0-126)

task_id: TSK-P0-126
title: Reconcile Sovereign plan with existing Phase-0 migration/table invariants (no duplicate implementation)

## Goal
Make the Sovereign Hybrid Cloud Phase-0 plan explicitly reuse existing enforced invariants:
- `INV-097` expand/contract migration policy (already implemented)
- `INV-098` PK/FK type stability (already implemented)
- `INV-099` table conventions (already implemented)

## Scope
In scope:
- Plan-only reconciliation (no new invariant IDs or duplicate scripts).

Out of scope:
- Implementation of new sovereign gates (handled by TSK-P0-127..130).

## Verification
- Manual review of `docs/plans/phase0/TSK-P0-125_sovereign_hybrid_cloud_reg_machine/PLAN.md`

## Acceptance
- Sovereign plan references `INV-097/INV-098/INV-099` as reused and does not propose duplicates.

