# Zambia CII Designation Brief (Phase-0 Stub)

## Scope and Non-Claims
This document is a Phase-0 technical brief intended to provide line-of-sight to how Symphony is designed to support Critical Information Infrastructure (CII) posture for Zambia payment systems.

It does not claim:
- certification or legal compliance,
- production readiness,
- or regulator approval.

## What Symphony Is (Phase-0)
Phase-0 establishes a mechanically defensible data foundation:
- Forward-only migrations with immutable checksums (migration ledger).
- Deny-by-default privilege posture.
- Append-only attempt history (outbox attempts ledger).
- Mechanical evidence harness (git SHA + schema fingerprint).
- Deterministic correctness tests for outbox idempotency and lease fencing.

## Why This Matters For CII
For CII designation, auditors typically require:
- integrity of operational records,
- ability to prove non-tampering over time,
- deterministic change control and traceability,
- and well-defined escalation and remediation procedures.

Phase-0 focuses on mechanisms that can be audited mechanically (scripts, gates, evidence artifacts).

## Payment Finality (Roadmap)
Payment finality is a P0-impact regulatory requirement. In Phase-0 it is declared (roadmap) rather than enforced in schema:
- Roadmap invariant: `INV-106` (alias `INV-BOZ-04`)
- ADR: `docs/decisions/ADR-0012-payment-finality-model-deferred.md`

Activation to Phase-1 includes:
- rail adapter proof of "committed to rail",
- ISO 20022 reversal-only workflow (e.g., camt.056),
- and DB constraints/triggers plus CI tests that physically prevent cancel/void after finality.

## Evidence and Auditability
Phase-0 emits structured evidence artifacts for key gates (schema, linting, policy stubs, security checks). These artifacts are intended as inputs to later audit logging and long-term retention systems.

## Change Control and Forward-Only Migration Safety
Phase-0 enforces:
- migration immutability (checksums),
- no runtime DDL posture (privilege gates),
- and expand/contract discipline for hot tables (Phase-0 guardrails).

This supports blue/green style cutovers where new schema versions are deployed forward-only and verified before traffic shifts.

## Next Milestones (For Zambia CII Track)
- Phase-1: Activate payment finality enforcement (reversal-only) and rail truth-anchor sequence enforcement for sandbox participant gate.
- Phase-2: Expand operational controls and evidence retention for CII designation readiness.

