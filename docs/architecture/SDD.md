# Software Design Document (SDD) - Symphony Platform

## Executive summary
Symphony is a clean-slate payment orchestration and ledger control platform with strict
invariants, deterministic database evolution, and policy-as-code as a first-class
control plane. The current repository is foundation-first: PostgreSQL 18 schema and
invariant gates are implemented, while application services remain largely unbuilt.
This SDD specifies the target .NET 10-only architecture, migration of Node.js
components into .NET services, and the compliance-by-design posture required for
custodial payment orchestration.

## Architecture overview
The architecture is organized into explicit trust zones and services with strict
interfaces:

- Edge/API zone: API gateway and ingress service for instruction acceptance.
- Control plane: policy-as-code management, admin, and compliance workflows.
- Orchestration plane: routing decisions, idempotency enforcement, and outbox enqueue.
- Ledger core: double-entry posting, reconciliation primitives, immutable journal.
- Integration plane: adapters for payment rails and external providers.
- Evidence plane: audit, attestations, and tamper-evident logs.
- Data plane: PostgreSQL 18 with forward-only migrations and enforced invariants.

## Target reference architecture (full system)
Services (all .NET 10) and responsibilities:

1) Edge Gateway (future)
   - AuthN/Z termination, request validation, rate limiting, mTLS enforcement.
   - Routes to ingest and admin APIs.

2) Ingest Service
   - Idempotent instruction acceptance.
   - Validates against policy snapshot and schema contracts.
   - Enqueues outbox records via DB API functions.

3) Orchestration Service
   - Policy-gated routing and rail selection.
   - Deterministic retry schedule; writes attempts to append-only outbox ledger.

4) Ledger Core Service
   - Double-entry posting API (append-only journal).
   - Balance computation and reconciliation record management.
   - Strict invariants enforced in DB and contract tests.

5) Policy Service
   - Policy-as-code lifecycle: authoring, checksum, activation, grace, retirement.
   - Versioned policy bundles, signed and stored with evidence.

6) Integration Adapters (one per rail)
   - External API interaction, idempotency, receipt validation.
   - Strict boundary for PCI zones or tokenization services.

7) Evidence and Audit Service
   - Immutable audit/event log materialization, reports, attestations.

Shared libraries (all .NET 10):
- Contracts: OpenAPI/JSON schema/protobuf definitions and shared error codes.
- DB access: strict stored-procedure-only paths; no runtime DDL.
- Crypto: key management client, signing, hashing utilities.

## Trust boundaries and security zones
Zones:
- Zone A (Edge): public ingress, untrusted clients.
- Zone B (Service Mesh): internal services with mTLS and service identity.
- Zone C (Data): PostgreSQL and secrets store.
- Zone D (PCI boundary): optional segregated segment for card data/tokenization.

All cross-zone calls require authenticated identity, explicit authorization, and
auditable logging. Zero Trust is enforced for every request regardless of origin.

## Data design and models
Core entities (Phase 2+):
- tenants, participants, users, roles, credentials
- instructions, idempotency_keys, routes, rails
- ledger_journal, ledger_accounts, ledger_postings, balances
- reconciliation_items, disputes, chargebacks
- policy_versions, policy_bundles, policy_attestations
- outbox tables (pending, attempts, sequences)

Key principles:
- Append-only ledgers for immutable trails.
- Forward-only migrations; no edits to applied migrations.
- SECURITY DEFINER functions with search_path pinned to pg_catalog, public.
- Runtime roles have no direct table DML; they use DB API functions.

## Interface design
Service contracts are explicit and versioned:
- Public APIs: OpenAPI with strict request/response schemas.
- Internal APIs: gRPC or JSON-over-HTTP with contract tests.
- Event contracts: append-only outbox attempts and domain events.

Example public API shapes (illustrative):
- POST /v1/instructions: submit payment instruction
- GET /v1/instructions/{id}: instruction status
- POST /v1/policies: upload policy bundle (control plane only)

## Compliance mapping overview
Compliance is mapped to enforcement points:
- ISO 20022: canonical message model, validation schemas, mapping discipline.
- ISO 27001/27002: control families mapped to service and evidence modules.
- PCI DSS: strict tokenization boundaries and segmentation in PCI zone.
- OWASP ASVS 5.0: API and service controls mapped to tests and gates.
- Zero Trust: service identity, least privilege, mTLS, continuous verification.

## Operational design
- Observability: metrics, traces, and structured audit logs (immutable).
- Incident response hooks: alerting, evidence collection, and containment steps.
- Key management boundaries: external KMS/HSM, short-lived credentials, rotation.

## Scalability plan
- Outbox processing via SKIP LOCKED, batch claim, and worker partitioning.
- Database partitioning for append-only tables (time and tenant based).
- Deterministic retry with explicit ceiling, dead-letter path, and evidence.

## Determinism strategy
- Stable failure modes with consistent error codes.
- CI gates for invariants and policy checks.
- Policy-as-code checksums, strict versioning, and promotion workflow.
- Structural change detector enforces doc updates or exceptions.

## Known gaps and TBDs
- Existing app services and Node.js code are not present in this repo (TBD).
- Exact rail integration priorities and PCI scope need confirmation (TBD).
- Secrets/KMS provider selection and boundary enforcement (TBD).
