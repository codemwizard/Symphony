# Phase-1 Pilot Integration Contract

This contract defines the deterministic sandbox interface for the Phase-1 pilot.

## Endpoints
- `POST /v1/ingress/instructions`
  - Required fields: `instruction_id`, `participant_id`, `idempotency_key`, `rail_type`, `payload`, `tenant_id`
  - Success: `202` with `ack=true`
  - Contract error: `400 INVALID_REQUEST`
  - Durability error: `503 ATTESTATION_DURABILITY_FAILED`
- `GET /v1/evidence-packs/{instruction_id}`
  - Required header: `x-tenant-id`
  - Success: `200` with `schema_version=phase1-evidence-pack-v1`
  - Not found/cross-tenant: `404 EVIDENCE_PACK_NOT_FOUND`
- `GET /v1/exceptions/{instruction_id}/case-pack`
  - Required header: `x-tenant-id`
  - Success: `200` with `schema_version=phase1-exception-case-pack-v1`
  - Incomplete lifecycle refs: `422 CASE_PACK_INCOMPLETE`

## Deterministic Sample Payload
```json
{
  "instruction_id": "pilot-ins-001",
  "participant_id": "bank-a",
  "idempotency_key": "idem-pilot-001",
  "rail_type": "RTGS",
  "payload": { "amount": 100, "currency": "ZMW" },
  "tenant_id": "11111111-1111-1111-1111-111111111111"
}
```

## Deterministic Malformed Payload
```json
{
  "instruction_id": "",
  "participant_id": "bank-a",
  "idempotency_key": "idem-pilot-bad",
  "rail_type": "RTGS",
  "payload": null,
  "tenant_id": "not-a-uuid"
}
```
Expected: `400 INVALID_REQUEST`.

## Replay Command
- `scripts/dev/run_phase1_pilot_harness.sh`

## Evidence Outputs
- `evidence/phase1/pilot_harness_replay.json`
- `evidence/phase1/pilot_onboarding_readiness.json`
