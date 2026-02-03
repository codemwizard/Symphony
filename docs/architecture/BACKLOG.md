# Backlog (Prioritized)

## Epic 1: Policy-as-Code lifecycle
User story: As a platform operator, I can promote signed policy bundles through
dev/staging/prod with explicit checksums.
Acceptance criteria:
- Policy bundle schema is versioned and validated in CI.
- Policy checksum must match deployed hash before activation.
- Audit log records activation and signer identity.
Test strategy:
- Unit tests for policy validation.
- Integration tests for policy activation and rollback.
Threat/compliance references:
- ISO 27001 change management, Zero Trust, OWASP ASVS 5.0 V2.

## Epic 2: Ingest service (.NET 10)
User story: As a client, I can submit an instruction with idempotency and receive
an instruction_id deterministically.
Acceptance criteria:
- POST /v1/instructions is idempotent by (instruction_id, idempotency_key).
- Enqueue uses DB API only; no direct table writes.
Test strategy:
- Contract tests for API schema.
- DB integration tests for enqueue idempotency.
Threat/compliance references:
- OWASP ASVS 5.0 V3/V4, ISO 20022 validation discipline.

## Epic 3: Orchestration worker
User story: As the system, I can claim, dispatch, and complete outbox attempts
with strict lease fencing.
Acceptance criteria:
- Uses claim_outbox_batch with SKIP LOCKED.
- completion requires matching lease_token and claimed_by.
- retry ceiling enforced deterministically.
Test strategy:
- Integration tests for lease expiry and retry behavior.
Threat/compliance references:
- ISO 27001 A.12 logging and monitoring, OWASP ASVS 5.0 V10.

## Epic 4: Ledger core
User story: As the system, I can post double-entry journal entries with immutable
append-only storage.
Acceptance criteria:
- Append-only tables for postings.
- Double-entry constraints enforced at DB layer.
Test strategy:
- Property tests for balanced postings.
- Integration tests for reconciliation mismatches.
Threat/compliance references:
- PCI DSS logging, ISO 27001 audit trails.

## Epic 5: Rail adapter framework
User story: As the system, I can dispatch to a simulated rail and record receipts.
Acceptance criteria:
- Adapter interface is stable and contract-tested.
- ISO 20022 validation runs before dispatch.
Test strategy:
- Contract tests for adapter behaviors.
- Schema validation tests.
Threat/compliance references:
- ISO 20022, OWASP ASVS 5.0 input validation.

## Epic 6: Evidence and audit service
User story: As an auditor, I can retrieve immutable evidence bundles per
instruction and policy version.
Acceptance criteria:
- Evidence bundles include policy checksum and ledger references.
- Bundles are immutable and versioned.
Test strategy:
- End-to-end evidence generation tests.
Threat/compliance references:
- ISO 27001/27002 audit, SOC2-style evidence.
