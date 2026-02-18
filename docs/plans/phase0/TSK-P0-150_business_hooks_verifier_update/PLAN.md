# Implementation Plan (TSK-P0-150)

failure_signature: P0.BIZ.HOOKS.DELTA_TIGHTENING.VERIFIER_NOT_PROVING_ENFORCEMENT
origin_task_id: TSK-P0-150
repro_command: source infra/docker/.env && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}" && scripts/db/verify_business_foundation_hooks.sh

## Goal
Update the Phase-0 business hooks verifier so it proves the new-row enforcement semantics introduced by TSK-P0-149:
- NOT VALID CHECK constraints exist (billability + stitchability)
- set-if-null correlation triggers exist
- external_proofs payer attribution derivation is present and fail-closed

## Scope
In scope:
- `scripts/db/verify_business_foundation_hooks.sh` catalog checks
- Evidence: `evidence/phase0/business_foundation_hooks.json`

Out of scope:
- adding new invariants (reuse `INV-090..INV-096` where applicable)

## Acceptance
- Verifier checks and records (at minimum):
  - constraint presence (by name) for new-row enforcement
  - trigger presence on the expected tables
  - billable_clients client_key column + unique index presence
  - external_proofs tenant_id + billable_client_id columns present and enforced for new rows
- Evidence is emitted on PASS and FAIL, deterministically.

## Verification
verification_commands_run:
- "bash scripts/dev/pre_ci.sh"
- "source infra/docker/.env && export DATABASE_URL=\"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}\" && scripts/db/verify_business_foundation_hooks.sh"

final_status: OPEN

