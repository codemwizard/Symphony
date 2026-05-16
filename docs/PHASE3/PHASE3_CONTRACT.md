# Phase-3 Contract: Constraint and Legitimacy Engine

## Phase Identity

Phase-3 establishes the **Constraint and Legitimacy Engine** for Symphony. This
phase governs typed dependency graphs, recursive legitimacy evaluation,
contradiction detection, failure composition, authority scope enforcement,
conflict-of-interest enforcement, and spatial or DNSH gates as defined by the
Phase 3 machine contract and governing constitutional doctrine.

## Capability Boundary

**In Scope:**
- Typed dependency graph lineage and traversal
- Recursive legitimacy and replay projection
- Contradiction detection and quarantine
- Failure composition and evidence continuity
- Authority scope and delegation enforcement
- Regulator-aware arbitration mechanics
- Conflict-of-interest enforcement
- Spatial constraint and DNSH gates
- Dwell-time forensic enforcement
- Phase-3 verifier and CI enforcement

**Explicitly Out of Scope:**
- Methodology adapter execution runtime
- Settlement finality or statutory deductions
- ZDPA erasure workflows
- MADD or MAIN authorization runtime
- External registry integrations
- Tokenization or disclosure packages

## Non-Goals

This phase does **not** attempt to:
- Redefine constitutional doctrine inside task packs
- Treat planning artifacts as delivery proof
- Claim opened-phase execution merely because the machine contract exists
- Override the root execution envelope by implication
- Expand into future-phase capability domains

## Required Artifacts

### Machine Contract (Authoritative)
- **File**: `docs/PHASE3/phase3_contract.yml`
- **Status**: Authoritative for delivery claims
- **Authority**: Sole authoritative source for delivery-claimable Phase-3 requirements

### Human Contract (Explanatory)
- **File**: `docs/PHASE3/PHASE3_CONTRACT.md`
- **Status**: Human-readable explanatory material
- **Authority**: Must defer to `docs/PHASE3/phase3_contract.yml` on conflicts

### Policy Guard
- **File**: `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`
- **Status**: Phase-specific SDLC policy and claim discipline

### Verification Evidence
- **Verifier**: `scripts/audit/verify_phase3_contract.sh`
- **Evidence**: `evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json`
- **Gate Flag**: `RUN_PHASE3_GATES=1`

## Authority Boundary

**CRITICAL**: `docs/PHASE3/phase3_contract.yml` is the **sole authoritative
source** for delivery-claimable Phase-3 requirements. This human document is
explanatory and must not introduce additional delivery claims beyond the machine
contract and cited doctrine.

The root execution envelope remains the controlling authority for what work is
currently executable. This contract establishes the lifecycle artifact set used
by the activation sequence; it does not by itself claim that the root execution
envelope has already been updated.

## Verification and Compliance

### Automated Verification
The Phase-3 contract is verified by `scripts/audit/verify_phase3_contract.sh`
which validates:
- existence of the required Phase-3 lifecycle artifact set
- machine-contract YAML validity and phase identity
- human and policy document references to the correct phase, verifier, gate
  flag, and evidence namespace
- cross-artifact alignment on `RUN_PHASE3_GATES=1` and `evidence/phase3/**`

### Evidence Generation
Verification evidence is generated at
`evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json` containing:
- lifecycle artifact validation status
- per-check results
- observed paths and hashes
- git SHA and timestamp for reproducibility

### CI Integration
Phase-3 contract verification is intended for:
- local development via `RUN_PHASE3_GATES=1 scripts/dev/pre_ci.sh`
- CI workflow wiring after the activation sequence advances
- fail-closed behavior on lifecycle artifact contradictions

## Governance Notes

This contract participates in the formal Phase-3 activation sequence. It is
valid to create this artifact before the root execution envelope is rewritten,
provided the activation work is explicitly authorized and auditable.

## Version Information

- **Phase**: 3
- **Phase Name**: Constraint and Legitimacy Engine
- **Machine Contract**: `docs/PHASE3/phase3_contract.yml`
- **Verifier**: `scripts/audit/verify_phase3_contract.sh`

---

*This document is human-readable explanatory material. The authoritative Phase-3
contract is maintained in `docs/PHASE3/phase3_contract.yml`.*
