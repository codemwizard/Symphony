# Sprint 5 Lane B Blockers

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Sprint 5 may implement internal ledger semantics and verifier-backed accounting proofs, but any task touching production signing architecture, legal-hold/correction authority, or external verification artifact formats requires explicit architecture approval before implementation.

## Required Confirmations
- key-management architecture
- authority model for governance events
- external verification artifact format

## Lane A — Start now
- LEDGER-001 fully
- LEDGER-002 partially, for internal proofs and verifier jobs

## Lane B — Blocked pending ratification
- external verification artifact canonicalization
- legal-hold/correction governance logic
- final production signing/export chain
- regulator-facing attested truth exports

## Interpretation Rule
- If a Sprint 5 change introduces assumptions about production-wide key-management architecture beyond existing evidence-signing/OpenBao/HSM seams, it is Lane B.
- If a Sprint 5 change defines legal-hold precedence or broader regulatory correction authority semantics, it is Lane B.
- If a Sprint 5 change defines or hardcodes externally attestable verification or export formats, it is Lane B.
- If a Sprint 5 change introduces externally consumable balance, posting, or attestation outputs intended to be relied upon outside internal verification, it is Lane B unless explicitly approved.
- Lane B work must not proceed until all required confirmations are explicitly ratified.
