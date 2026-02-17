# Error Mapping Specification

## Purpose
Define a single, stable mapping between internal failures (SQLSTATE, domain errors, policy invariants) and external error responses. This document standardizes how Symphony produces API errors so clients can build consistent handling logic and so audits can trace failures to their policy or platform cause.

## Standards and References
- Problem Details for HTTP APIs (RFC 9457) defines the error response envelope (type, title, status, detail, instance).
- HTTP status code semantics (RFC 7231) define the meaning of 4xx vs 5xx responses.
- Google API error model (AIP-193 / google.rpc.Status) demonstrates a structured error model with code, message, and details for consistent handling.

## Scope
This spec applies to:
- SQLSTATEs raised by Postgres functions/triggers.
- Application-level invariants and policy violations.
- Infrastructure and dependency failures surfaced at the API boundary.

## Error Classification
We use a 3-class model to align operational handling and audit semantics.

Class A - Platform/Infra failures
- Examples: transient DB errors, timeouts, connection loss, serialization conflicts.
- Typically map to 500/503/504 or equivalent.
- Retryable only when explicitly transient.

Class B - Policy/Business-rule invariants (custom P7xxx)
- Meaning: request refused because it violates a declared invariant.
- Fail-closed, non-retryable unless policy or state changes.

Class C - Developer/Safety guardrails (custom P9xxx)
- Meaning: forbidden call path or programming error.
- Triggers incident workflow and panic-level evidence.

## Canonical Response Envelope (RFC 9457)
All external API errors MUST serialize as Problem Details with these fields:
- type (URI identifying the problem type)
- title (short, human-readable summary)
- status (HTTP status code)
- detail (human-readable description)
- instance (request or occurrence identifier)

Required extensions:
- internal_code (SQLSTATE or domain error code)
- retryable (boolean)
- correlation_id (trace/request id)

## Required Mapping Fields
Each error mapping entry MUST include:
- internal_code: Stable internal identifier (SQLSTATE or domain code).
- class: A | B | C.
- http_status: HTTP status code.
- problem_type_uri: URI for the error type.
- title: Short summary.
- developer_message: Technical description for developers.
- user_message: Human-readable message for UI.
- retryable: true | false.
- remediation: Actionable guidance for client behavior.
- safe_to_expose: true | false (controls detail leakage).
- version: Mapping version.

## Mapping Rules
1) Always set HTTP status code according to RFC semantics; do not overload status codes.
2) Use Problem Details for all error responses; do not invent per-service envelopes.
3) Do not expose stack traces, secrets, or internal object identifiers in detail.
4) Preserve internal_code stability; never change meaning without a migration plan.
5) If multiple codes could apply, return the most specific one.

## Canonical Storage (single source of truth)
Create and maintain a machine-readable registry:
- docs/contracts/error_map.yml (authoritative)
- docs/contracts/ERROR_MAPPING_SPEC.md (this document)

All API surfaces and test suites MUST use the registry as the source of truth.

## Example Registry Entry (YAML)
```yaml
- internal_code: P7102
  class: B
  http_status: 409
  problem_type_uri: https://symphony.example/errors/outbox-lease-mismatch
  title: Outbox lease mismatch
  developer_message: Lease token does not match current lease for outbox attempt.
  user_message: The request cannot be completed because the item is already being processed.
  retryable: false
  remediation: Re-fetch state and retry only if the lease was reacquired.
  safe_to_expose: true
  version: 1
```

## Example Response (Problem Details)
```json
{
  "type": "https://symphony.example/errors/outbox-lease-mismatch",
  "title": "Outbox lease mismatch",
  "status": 409,
  "detail": "Lease token does not match current lease for outbox attempt.",
  "instance": "urn:request:7bfc3b2b-4c4e-4d8d-8c7d-8f0a4c1a1d1f",
  "internal_code": "P7102",
  "retryable": false,
  "correlation_id": "req-01HXH9M6P3C9AEQK7D2F"
}
```

## Localization
If localized user messages are required, use the client locale or HTTP Accept-Language to select a translation. Do not localize developer_message.

## Validation and Drift Checks
Add a CI check that:
- Validates error_map.yml schema.
- Ensures every SQLSTATE or domain code used in DB/app code exists in the mapping.
- Ensures mapping entries have required fields.
- Emits evidence (evidence/phase0/error_map_drift.json).

## Security and Privacy
- Treat all error details as potentially sensitive.
- Expose only safe fields to clients; log full details internally.
- Avoid leaking schema names, table names, or stack traces in user-visible responses.

## Change Control
- Increment mapping version when meanings change.
- Preserve legacy mappings with explicit deprecation timelines.
- Require an ADR for breaking changes to external error contracts.

