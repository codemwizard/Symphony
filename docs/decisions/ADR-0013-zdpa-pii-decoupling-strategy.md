# ADR-0013: ZDPA PII Decoupling and Evidence Survivability (Deferred Enforcement)

## Status
Phase-0 ADR stub (roadmap-backed). No Phase-0 schema enforcement.

## Invariants
- Roadmap invariant: `INV-107` (alias: `INV-ZDPA-01`)
- Related implemented invariant: `INV-020` (evidence anchoring: git SHA + schema hash)

## Decision
Symphony will decouple raw PII from the ledger so that:
- the ledger and evidence bundles remain cryptographically verifiable over long retention windows,
- while raw PII can be purged or masked according to policy.

Phase-0 declares the requirement and activation criteria, but does not add PII vault tables or purge hooks.

## Rationale
ZDPA-style requirements are P0-impact in production, but Phase-0 deliberately avoids:
- jurisdiction-specific retention + erasure workflows,
- runtime services for tokenization/vaulting,
- and schema refactors that would introduce hard migration coupling before the system has rail adapters.

Declaring the invariant and the enforcement model early reduces later rework and avoids audit surprises.

## Phase-0 Boundary
Phase-0 commits to:
- avoiding raw PII storage in new proxy-resolution artifacts (hashed proxies),
- evidence anchoring mechanics for Phase-0 gates.

Phase-0 does not implement:
- a PII vault (`vault_pii`) or identity tokenization lifecycle,
- right-to-be-forgotten purge workflows,
- cryptographic signing over identity_hash payloads.

## Activation Preconditions (Phase-1/2)
Promotion from roadmap -> implemented requires:
- A PII vault/table design with strict access boundaries and documented retention rules.
- Tokenization strategy:
  - ledger stores `identity_hash` or `pii_token`, not raw PII.
  - salts/keys are managed under the key management policy.
- A purge/mask mechanism that deletes or irreversibly masks raw PII while leaving ledger and evidence signatures verifiable.
- Mechanical verification in CI:
  - purge tests,
  - signature verification tests across pre/post purge.

## Intended Phase-1/2 Enforcement (Design Outline)
Schema changes (forward-only, expand-first):
- Introduce dedicated identity/vault table(s) for raw PII (names and columns defined in Phase-1).
- Add `identity_hash` (salted hash) or `pii_token` references in instruction/ledger domain tables.

Evidence model:
- Sign payloads so that a verifier can validate the evidence bundle without needing raw PII.
- Preserve verification material per retention policy.

Mechanical checks required for promotion:
- DB: asserts raw PII does not appear in ledger tables (schema allowlist + pg_catalog checks).
- DB: purge operation succeeds and does not break signature verification.
- Security: access controls for vault tables are deny-by-default and auditable.

## Failure Modes (What Must Become Impossible)
- Raw PII persists in the canonical ledger beyond retention policy.
- Evidence bundle validity depends on raw PII fields that are subject to purge/mask.
- Operators can purge PII in a way that corrupts audit verifiability.

## Audit Artifacts (Phase-1+)
- PII inventory and classification.
- Retention/purge runbooks and evidence of review cadence.
- Evidence bundle verification reports (pre/post purge).

## Open Questions (Phase-1)
- Whether identity_hash is computed in DB, app, or a dedicated security service.
- Key/salt rotation strategy and how verifiers bind historical signatures.

