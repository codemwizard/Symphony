# Implementation Plan: TSK-P2-W6-REM-16a

## Mission
Move Wave 6 contract documents from `WAVE6_CONTRACT_PACK` to canonical paths, update their headers, and ensure no placeholder tokens exist in normative prose.

## Targets
1. `TRANSITION_HASH_CONTRACT.md` -> `docs/contracts/`
2. `ED25519_SIGNING_CONTRACT.md` -> `docs/contracts/`
3. `DATA_AUTHORITY_DERIVATION_SPEC.md` -> `docs/contracts/`
4. `DATA_AUTHORITY_SYSTEM_DESIGN.md` -> `docs/architecture/`

## Acceptance Criteria
- Documents exist at canonical paths.
- `Canonical-Reference` header is accurate.
- No `TODO`, `FIXME`, `TBD`, `PLACEHOLDER`, or `XXX` inside normative prose.

## Evidence Paths
- `evidence/phase2/tsk_p2_w6_rem_16a.json`
