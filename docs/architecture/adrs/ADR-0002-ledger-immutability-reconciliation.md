# ADR-0002: Ledger design, immutability, and reconciliation strategy

## Status
Proposed

## Context
The platform requires a double-entry ledger with append-only integrity and
deterministic reconciliation. The DB foundation already enforces append-only
outbox attempts and forward-only migrations. Ledger behavior must align with
those invariants and produce auditable evidence.

## Decision
Implement a ledger core with:
- Append-only journal tables for postings and journals.
- Double-entry enforcement via DB constraints and stored procedures.
- Reconciliation records that reference immutable postings.
- Deterministic balance computation (materialized views or functions).
- Idempotent posting API with unique keys for duplicate prevention.

Reconciliation mismatches generate evidence records and do not delete or mutate
ledger history.

## Consequences
- Provides a tamper-evident audit trail compatible with custodial requirements.
- Requires explicit migration plan and invariant tests for ledger tables.
- Enables deterministic replay and dispute resolution.
