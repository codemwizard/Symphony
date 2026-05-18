# Phase 4 Policy Guard

Status: Prepared, Not Open  
Owner: Operations / Governance

## Purpose

This policy defines the allowed and prohibited work surfaces for Phase 4
preparation and, once opened, for Phase 4 execution.

This document does not itself open Phase 4. The active execution envelope
remains Phase 3 until a formal `PHASE4-OPENING` approval bundle and envelope
revision exist.

## Allowed Capability Domains

When Phase 4 is open, allowed implementation domains are limited to:

- settlement finality enforcement
- BoZ FX reference-rate authority
- asset-to-settlement hard binding
- currency legality gating
- statutory deductions and allocations
- statutory kill criteria
- deterministic evidence, verifier, and replay surfaces needed to prove the above

## Prohibited Capability Domains

Phase 4 must reject:

- any AI execution or AI-derived direct financial decision surface
- methodology adapter runtime work
- external registry bridges
- sovereign authorization workflow execution
- tokenization/export runtime
- UI/operator workspace behavior
- any later-phase claim implied by convenience or proximity

## AI-Free Constraint

Phase 4 is AI-free.

No model output may directly participate in settlement finality, statutory
calculation, BoZ rate binding, kill criteria, or currency legality. Only
admitted deterministic evidence may reach these surfaces.

## Opening Rule

No Phase 4 runtime task pack may be created or implemented until:

1. Phase 3 closeout is admissible.
2. `scripts/audit/verify_phase4_contract.sh` passes.
3. a `PHASE4-OPENING` approval bundle exists.
4. `docs/operations/PHASE_EXECUTION_ENVELOPE.md` is separately updated to Phase 4.

## Forward Closeout Rule

Phase 4 closeout planning must include next-phase anti-drift protection.

At minimum, these must exist before any Phase 4 completion claim:

- `docs/PHASE5/README.md`
- `docs/PHASE5/phase5_contract.yml`

These Phase 5 stubs must remain explicitly non-claimable and contain zero
implementation rows until a later opening cycle authorizes otherwise.
