# Supervisory Reveal API v2

Status: Canonical
Scope: Pilot-demo supervisory shell

## Routes

### GET /v1/supervisory/programmes/{programId}/reveal
Returns the programme-level supervisory reveal payload.

Top-level fields:
- `tenant_id`
- `program_id`
- `programme_summary`
- `timeline`
- `evidence_completeness`
- `exception_log`
- `proof_rows`
- `as_of_utc`
- `read_only`

`proof_rows` is an array of instruction summaries. Each entry contains:
- `instruction_id`
- `status`
- `present_count`
- `proofs`

`proofs` implements the canonical Phase-1 proof model:
- `PT-001` Supplier Invoice
- `PT-002` Delivery Photo + GPS
- `PT-003` Field Officer Token
- `PT-004` Borrower ACK

Each proof row contains:
- `proof_type_id`
- `label`
- `status` (`PRESENT`, `MISSING`, `FAILED`, `FLAGGED`)
- `artifact_type`
- `gps_result` where applicable
- `msisdn_result` where applicable
- `submitter_class`
- `submitted_at_utc`

### GET /v1/supervisory/instructions/{instructionId}/detail
Returns the instruction-level supervisory drill-down payload.

Top-level fields:
- `tenant_id`
- `program_id`
- `instruction_id`
- `instruction_status`
- `proof_rows`
- `raw_artifacts`
- `exception_log`
- `supplier_policy_context`
- `acknowledgement_state`
- `escalation_tier`
- `supervisor_interrupt_state`
- `ack_interrupt_projection_state`
- `read_only`

`acknowledgement_state`, `escalation_tier`, and `supervisor_interrupt_state` remain null or unavailable until Wave D projects the real backend control state.
`ack_interrupt_projection_state` must explicitly declare that pending status.

## Compatibility Rules

- Existing reveal consumers that only use `programme_summary`, `timeline`, `evidence_completeness`, and `exception_log` remain valid.
- New UI surfaces must consume `proof_rows` and the instruction detail route instead of local-only drill-down state.
- The detail route is read-only and tenant-scoped.
