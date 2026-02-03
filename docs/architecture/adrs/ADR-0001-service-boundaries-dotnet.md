# ADR-0001: Service boundary and modular decomposition (.NET 10)

## Status
Proposed

## Context
The platform must be .NET 10-only and enforce strict separation of concerns between
edge, orchestration, ledger, policy, and integration responsibilities. The current
repo has a DB foundation but no service implementation. We need explicit boundaries
to avoid a monolith that bypasses invariants or policy gates.

## Decision
Adopt the following .NET 10 service boundaries:
- Edge Gateway: external auth, request validation, rate limiting.
- Ingest Service: idempotent acceptance, policy snapshot validation, outbox enqueue.
- Orchestration Service: routing decisions, retry logic, outbox attempt recording.
- Ledger Core Service: double-entry posting and reconciliation primitives.
- Policy Service: policy-as-code lifecycle and promotion.
- Integration Adapters: rail-specific dispatch and receipt validation.
- Evidence/Audit Service: immutable evidence materialization and reporting.

Shared libraries define contracts and data access patterns; runtime services do not
directly mutate tables outside stored procedures.

## Consequences
- Clear ownership and test seams enable contract testing and compliance evidence.
- Requires service-to-service auth and observability from the start.
- Enables incremental implementation with deterministic boundaries.
