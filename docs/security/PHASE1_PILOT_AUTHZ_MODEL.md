# Phase-1 Pilot AuthN/AuthZ Model

## Pilot Mode
- Auth mode: API key (`x-symphony-api-key`)
- Catalog source: `SYMPHONY_PILOT_API_KEYS`
- Catalog row format: `api_key:tenant_id:participant_id:role` (comma-separated rows)

Default local catalog (used when env variable is unset):
- `pilot-participant-key:11111111-1111-1111-1111-111111111111:bank-a:participant`
- `pilot-boz-key:*:*:boz_readonly`

## Authorization Rules
- Ingress endpoint (`POST /v1/ingress/instructions`):
  - Requires valid API key.
  - `participant` role must match request `tenant_id` and `participant_id`.
  - `boz_readonly` role is denied for ingress writes.
- Read endpoints (`GET /v1/evidence-packs/{instruction_id}`, `GET /v1/exceptions/{instruction_id}/case-pack`):
  - Requires valid API key.
  - `participant` role is tenant-scoped and cannot read cross-tenant.
  - `boz_readonly` role is read-only and may read regulator-facing data.

## Deterministic Evidence
- `evidence/phase1/authz_tenant_boundary.json`
- `evidence/phase1/boz_access_boundary_runtime.json`
