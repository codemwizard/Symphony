# Phase-2 Contract: Internal Ledger Truth

## Phase Identity

Phase-2 establishes the **Internal Ledger Truth** foundation for the Symphony system. This phase focuses on creating a deterministic, auditable internal ledger system with proper state machine enforcement and authority controls.

## Capability Boundary

**In Scope:**
- Internal posting-set model with event taxonomy
- Compensation model and escrow/freeze mechanisms
- Deterministic ledger proofs with idempotent operations
- State machine enforcement via trigger layer
- Data authority level enforcement
- Phase-1 C# output non-authoritative marking

**Explicitly Out of Scope:**
- External trust surface assumptions
- Cross-tenant data sharing
- Real-time external integrations
- Phase-3 governance structures
- Human-readable policy documents

## Non-Goals

This phase does **not** attempt to:
- Create external-facing APIs
- Implement real-time settlement
- Define Phase-3 governance processes
- Replace existing Phase-1 capabilities
- Create new invariant claims beyond registered invariants

## Required Artifacts

### Machine Contract (Authoritative)
- **File**: `docs/PHASE2/phase2_contract.yml`
- **Status**: Invariant-centric contract rows only
- **Authority**: Authoritative for all delivery claims

### Verification Evidence
- **Verifier**: `scripts/audit/verify_phase2_contract.sh`
- **Evidence**: `evidence/phase2/phase2_contract_status.json`
- **Status**: Generated on-demand, deterministic

### Invariant References
- **INV-156**: Sprint 5 gated Lane A mode enforcement
- **INV-157**: Internal model definition without external assumptions
- **INV-158**: Deterministic ledger proofs
- **INV-175**: Data authority level enforcement
- **INV-176**: State machine trigger layer enforcement
- **INV-177**: Phase-1 C# non-authoritative markers

## Authority Boundary

**CRITICAL**: `docs/PHASE2/phase2_contract.yml` is the **sole authoritative source** for delivery-claimable Phase-2 requirements. This human document serves only as explanatory material and must not introduce additional claims or requirements.

Any apparent conflicts between this document and the machine contract must be resolved in favor of the machine contract.

## Verification and Compliance

### Automated Verification
The Phase-2 contract is verified by `scripts/audit/verify_phase2_contract.sh` which validates:
- Contract structure and required fields
- Invariant ID registration status
- Status vocabulary compliance
- Verifier and evidence path references
- Absence of task_id-based rows

### Evidence Generation
Verification evidence is generated at `evidence/phase2/phase2_contract_status.json` containing:
- Contract validation status
- Violation details (if any)
- Row counts and statistics
- Git SHA and timestamp for reproducibility

### CI Integration
Phase-2 contract verification is integrated into:
- Local development via `RUN_PHASE2_GATES=1 scripts/dev/pre_ci.sh`
- CI workflow via `.github/workflows/invariants.yml`
- Both use fail-closed behavior (exit 1 on violations)

## Governance Notes

This human contract is maintained in parallel with the machine contract but holds no authority for delivery claims. All changes to Phase-2 requirements must be reflected in both documents, with the machine contract serving as the source of truth.

## Version Information

- **Phase**: 2
- **Phase Name**: Internal Ledger Truth
- **Status**: Active (subject to machine contract verification)
- **Last Updated**: Generated from git commit during verification

---

*This document is human-readable explanatory material. The authoritative Phase-2 contract is maintained in `docs/PHASE2/phase2_contract.yml`.*
