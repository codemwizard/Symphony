# Phase 4 Contract

Status: Prepared, Not Open  
Phase Key: `4`  
Phase Name: Financial Integrity and Statutory Enforcement

## Constitutional Purpose

Phase 4 enforces the legally correct and statutorily compliant financial
consequences of already-admitted decisions. It is the first lifecycle phase
where finality, statutory allocations, and currency legality become
deterministic execution obligations rather than deferred planning surfaces.

## Entry Preconditions

Phase 4 must not be treated as open until all are true:

1. Phase 3 closeout is complete and evidenced.
2. The Phase 4 contract pair exists and passes `verify_phase4_contract.sh`.
3. `docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md` is canonical for Phase 4.
4. A formal `PHASE4-OPENING` approval bundle exists.
5. The root execution envelope is updated by separately approved work.

## Contract Rows

The machine contract declares the authoritative rows. The initial rows are:

- `P4-INV-001` settlement finality boundaries
- `P4-INV-002` BoZ FX reference-rate authority
- `P4-INV-003` asset-to-settlement hard binding
- `P4-INV-004` currency legality gates
- `P4-INV-005` statutory deductions and allocations
- `P4-INV-006` statutory kill criteria

All rows remain `planned` until the opening sequence is complete and Phase 4
runtime task packs are created.

## AI-Free Rule

Phase 4 is constitutionally AI-free.

No AI output may directly contribute to:

- settlement finality determination
- BoZ rate binding
- statutory deduction calculation
- statutory kill criterion evaluation
- currency legality gating

AI-assisted artifacts may appear only as previously admitted evidence inputs.
They must never act as direct financial or statutory decision surfaces.

## Non-Goals

Phase 4 does not open:

- Phase 5 methodology runtime work
- Phase 6 UI or operator workflow work
- Phase 8 registry, authorization, or tokenization work
- any AI execution surface

## Forward Governance

Phase 4 closeout must leave Phase 5 in a guarded non-claimable posture through:

- `docs/PHASE5/README.md`
- `docs/PHASE5/phase5_contract.yml`

The next phase must be visible and anti-drift protected before Phase 4 can be
truthfully described as complete.
