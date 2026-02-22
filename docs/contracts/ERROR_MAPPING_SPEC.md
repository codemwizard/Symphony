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
## SQLSTATE Registry (`docs/contracts/sqlstate_map.yml`)
This repository also maintains a **SQLSTATE-focused registry** for database-trigger and invariant codes.

### File format policy
`docs/contracts/sqlstate_map.yml` is stored as **JSON-compatible YAML** (valid JSON text in a `.yml` file) so it can be parsed deterministically by shell+Python checks without optional YAML parser dependencies.

### Mandatory top-level fields (deterministic + auditable)
The registry MUST include these top-level fields:
- `schema_version` (semver for the registry schema)
- `registry_id` (stable registry identifier)
- `owner` (team or function accountable for changes)
- `code_pattern` (currently `^P\\d{4}$`)
- `entry_required_fields` (must list `class`, `subsystem`, `meaning`, `retryable`)
- `source_scan_scope` (contractual scan roots only)
- `ranges` (coarse range taxonomy)
- `codes` (the actual code registry)

### Mandatory per-code entry fields
Every code under `codes` MUST include:
- `class` (`A` | `B` | `C`)
- `subsystem` (stable subsystem name)
- `meaning` (single canonical meaning)
- `retryable` (`true` | `false`)

Optional:
- `canonical` (alias/remap to canonical code)
- `introduced_by`, `deprecated`, `notes`

### Drift detection process (`scripts/audit/check_sqlstate_map_drift.sh`)
The drift check does three things:
1. Parse `docs/contracts/sqlstate_map.yml`
2. Validate structure (and validate against `docs/contracts/sqlstate_map.schema.json` when `jsonschema` is installed)
3. Scan **only contractual source roots** for `P####` occurrences:
   - `schema/`
   - `scripts/`
   - `services/`
   - `docs/contracts/`

This intentionally excludes prompt packs, backups, and draft docs so CI only enforces codes that affect runtime/contract behavior.

### How SQLSTATE errors are created and mapped
1. A database function/trigger or service invariant raises/returns a code (e.g. `P7301`).
2. The code must be registered in `sqlstate_map.yml` with stable semantics.
3. API/domain error translation layers read the registry (or generated artifacts from it) to map:
   - internal code → class / retryability / external response policy
4. CI drift checks fail if a code appears in the scoped sources but is not registered.

### CI hook recommendation
Add these steps to CI (before broad integration tests):
1. `python3 -m jsonschema -i docs/contracts/sqlstate_map.yml docs/contracts/sqlstate_map.schema.json` (optional but recommended if dependency installed)
2. `scripts/audit/check_sqlstate_map_drift.sh`

The drift script already emits evidence to:
- `evidence/phase0/sqlstate_map_drift.json`

### Change workflow (safe + deterministic)
When introducing a new `P####` code:
1. Add/modify runtime source (SQL trigger/function/service logic)
2. Register the code in `docs/contracts/sqlstate_map.yml`
3. If schema structure changes, update `docs/contracts/sqlstate_map.schema.json`
4. Run `scripts/audit/check_sqlstate_map_drift.sh`
5. Commit code + registry + evidence together
