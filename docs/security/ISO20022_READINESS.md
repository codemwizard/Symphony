# ISO 20022 Readiness (Phase-0)

Status: Phase-0 readiness document (no runtime adapters in Phase-0).

## Purpose
Define what "ISO 20022 readiness" means for Symphony in Phase-0:
- message contract registry location
- validation expectations
- integrity and traceability expectations that must be preserved by schema and evidence posture

This document does not claim ISO 20022 compliance or certification.

## Contract Registry (Phase-0)
Canonical registry file:
- `docs/iso20022/contract_registry.yml`

The registry declares which ISO 20022 message families and versions are in scope (or explicitly out of scope) and where fixtures/schemas are stored in-repo.

## Validation Expectations
Phase-0 establishes the contract for later adapter tests:
- schema validation must be deterministic
- parsing failures must be fail-closed
- message provenance must be captured via correlation identifiers and participant anchors where applicable

## Phase-1/2 Follow-ups (Not Implemented Here)
- adapter contract tests that validate message fixtures against the registry
- canonical normalization rules per rail/participant
- non-repudiation signature strategy for evidence packs (key management + signing policies)

