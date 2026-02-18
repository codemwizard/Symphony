# ZDPA Compliance Map (Phase-0 Stub)

## Scope and Non-Claims
This is a Phase-0 mapping stub intended to describe planned controls for Zambia Data Protection Act (ZDPA) style requirements.

It does not claim:
- legal interpretation,
- certification,
- or implemented right-to-be-forgotten functionality in Phase-0.

## Roadmap Invariant
- `INV-107` (alias `INV-ZDPA-01`): PII decoupling + erasure survivability (evidence remains verifiable after PII purge)
- ADR: `docs/decisions/ADR-0013-zdpa-pii-decoupling-strategy.md`

## Phase-0 Posture (What Exists Today)
- The repo has evidence anchoring for engineering gates (git SHA + schema fingerprint).
- Architecture guidance prohibits storing raw PII in proxy-resolution artifacts; prefer hashes/tokens.
- Security and retention policy stubs exist for audit logging and key management.

## Phase-1/2 Controls (Planned)
### Data Minimization
- Ledger stores non-PII identifiers and/or derived hashes (identity_hash) rather than raw PII.
- Raw PII is isolated in a restricted vault table/service.

### Storage Limitation and Erasure
- Raw PII may be deleted or irreversibly masked after an active period.
- Ledger and evidence bundles remain valid via cryptographic binding to non-PII identifiers and verification material.

### Integrity and Confidentiality
- Deny-by-default database privileges.
- Secrets management and key policy posture (OpenBao and key management policy stubs).

## Evidence and Audit Artifacts (Planned)
- PII inventory and classification register.
- Key/salt management procedures for identity_hash derivation.
- Purge runbooks and periodic proof that purge does not break evidence verification.

## Open Questions
- Exact ZDPA section mapping: to be filled by compliance counsel and implementation evidence in Phase-1/2.
- Whether hashing/tokenization should be performed in DB, application, or a security service.

