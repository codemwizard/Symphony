# Architecture Roadmap

## Phase 0/1: Foundations (Completed)
Goals:
- Deterministic DB foundation, forward-only migrations.
- Invariants system and CI gates.
- Outbox tables/functions with lease fencing.

Deliverables:
- `schema/migrations/0001-0006`
- `scripts/db/verify_invariants.sh`
- Invariants docs and detector gates.

Invariants used/created:
- INV-001..INV-018 (see `docs/invariants/INVARIANTS_MANIFEST.yml`)

Required CI controls/gates:
- Structural change detector, invariants fast checks, DB verify.

Risks and mitigations:
- Risk: docs-only invariants drift. Mitigation: CI gate and QUICK regeneration.
- Risk: privilege regression. Mitigation: revoke-first and CI invariants.

Dependencies:
- None (foundation).

## Phase 2: Policy-as-Code lifecycle + curator agents (Planned)
Goals:
- Policy bundle format and checksum enforcement beyond bootstrap.
- Documented rotation workflow with grace windows.
- Curator agents enforce manifest/doc linkage.

Implementation plan and tasks:
- Define policy bundle schema and signing process.
- Add policy promotion workflow (dev -> staging -> prod).
- Add policy checksum verification to ingest/orchestration path.

Invariants:
- New invariant: policy bundle checksum must match deployed hash.
- New invariant: only one ACTIVE policy; GRACE policy must have expiry.

Deliverables:
- Policy bundle spec and validation tooling.
- CI gate for policy checksum verification.

Required CI controls/gates:
- Updated invariants manifest and tests.
- Policy checksum verification test suite.

Risks and mitigations:
- Risk: inconsistent policy promotion. Mitigation: signed bundles + audit logs.
- Risk: missing GRACE semantics. Mitigation: explicit phase-gated rollout.

Dependencies:
- Phase 0/1 foundation.

## Phase 3: Core domain services (Planned)
Goals:
- Implement .NET 10 services for ingest, orchestration, ledger core.
- Establish contract testing and service identity.

Implementation plan and tasks:
- Define service contracts and shared error codes.
- Implement ingest service with idempotency and outbox enqueue.
- Implement orchestration worker with deterministic retry/backoff.
- Implement ledger core posting API and reconciliation primitives.

Invariants:
- New invariants for ledger append-only tables and double-entry checks.
- New invariants for idempotency keys and instruction uniqueness.

Deliverables:
- .NET 10 service skeletons and contract tests.
- Ledger schema migrations and DB functions.

Required CI controls/gates:
- Contract test suite and DB invariant verification.
- Security fast checks for privilege posture.

Risks and mitigations:
- Risk: scope creep into monolith. Mitigation: ADR-0001 boundaries.
- Risk: replay gaps. Mitigation: deterministic outbox and idempotent APIs.

Dependencies:
- Policy-as-code lifecycle.

## Phase 4: Rail integration + ISO 20022 gateway (Planned)
Goals:
- Adapter framework with at least one simulated rail.
- ISO 20022 canonical model and mapping validation.

Implementation plan and tasks:
- Build adapter SDK and sandbox adapter.
- Implement ISO 20022 validation and mapping rules.
- Add contract tests for message schemas.

Invariants:
- New invariant: message validation required before dispatch.
- New invariant: canonical message schema version pinned per policy.

Deliverables:
- Rail adapter interface and reference implementation.
- ISO 20022 mapping spec and validators.

Required CI controls/gates:
- Schema validation tests.
- Adapter contract tests.

Risks and mitigations:
- Risk: inconsistent mapping across rails. Mitigation: canonical model gate.
- Risk: schema drift. Mitigation: schema version pinning.

Dependencies:
- Core domain services.

## Phase 5: Custodial hardening (Planned)
Goals:
- PCI segmentation and tokenization boundaries.
- Strong evidence, audit, and retention workflows.

Implementation plan and tasks:
- Define PCI zone network segmentation and tokenization service.
- Implement evidence bundle generation and retention policies.
- Add automated audit report generation.

Invariants:
- New invariant: PCI boundary enforced by network and identity policy.
- New invariant: evidence bundles are immutable and versioned.

Deliverables:
- PCI zone architecture and tokenization integration.
- Evidence and audit service with retention controls.

Required CI controls/gates:
- Security checks for privileged access paths.
- Evidence artifact generation tests.

Risks and mitigations:
- Risk: compliance gaps. Mitigation: control mapping and periodic reviews.
- Risk: evidence gaps. Mitigation: immutable logs and retention testing.

Dependencies:
- Rail integration and policy-as-code.
