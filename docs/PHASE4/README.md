# Phase 4 - Financial Integrity and Statutory Enforcement

**Status: PREPARING TO OPEN**

Phase 4 is not open yet. The repository remains on the Phase 3 execution
envelope, but the structural Phase 4 contract, policy, verifier, and planning
artifacts are now prepared so the formal opening can be completed once Phase 3
closeout is admissible and a `PHASE4-OPENING` approval bundle exists.

## Current Governance Posture

- **Lifecycle Status**: Not Open
- **Claimability**: Opening preparation only
- **Envelope Authority**: Still Phase 3
- **Gate Flag On Open**: `RUN_PHASE4_GATES=1`
- **Evidence Namespace On Open**: `evidence/phase4/**`
- **AI Status**: Phase 4 is constitutionally AI-free

## Phase 4 Capability Boundary

Phase 4 governs the deterministic financial and statutory consequences of
already-admitted decisions. Its initial execution surfaces are:

- settlement finality
- BoZ FX reference-rate authority
- asset-to-settlement hard binding
- currency legality gates
- statutory deductions and allocations
- statutory kill criteria

## Opening Blockers

Phase 4 must not be treated as open until all are true:

1. Phase 3 closeout is verifier-backed and admissible.
2. `docs/PHASE4/PHASE4_CONTRACT.md` and `docs/PHASE4/phase4_contract.yml`
   are accepted as the canonical contract pair.
3. `docs/operations/AGENTIC_SDLC_PHASE4_POLICY.md` exists and governs the
   allowed/prohibited Phase 4 surfaces.
4. `scripts/audit/verify_phase4_contract.sh` passes.
5. A formal `approvals/*/PHASE4-OPENING.md` and sidecar JSON exist.
6. The root execution envelope is revised by separately approved work.

## Forward Governance Requirement

Phase 4 closeout must leave Phase 5 in the same guarded posture Phase 4
originally inherited:

- `docs/PHASE5/README.md` must exist as a non-claimable stub.
- `docs/PHASE5/phase5_contract.yml` must exist with zero implementation rows.

No Phase 4 completion claim is valid if the next-phase anti-drift stubs are
missing.
