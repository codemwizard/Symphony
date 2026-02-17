# Execution Log (TSK-P0-150)

failure_signature: P0.BIZ.HOOKS.DELTA_TIGHTENING.VERIFIER_NOT_PROVING_ENFORCEMENT
origin_task_id: TSK-P0-150
repro_command: source infra/docker/.env && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}" && scripts/db/verify_business_foundation_hooks.sh
Plan: docs/plans/phase0/TSK-P0-150_business_hooks_verifier_update/PLAN.md

## Change Applied
- Updated `scripts/db/verify_business_foundation_hooks.sh` to prove delta enforcement:
  - new-row-only CHECK constraints (NOT VALID)
  - correlation_id set-if-null triggers + NOT VALID checks
  - billable_clients client_key + unique index
  - external_proofs direct billability attribution trigger + required checks

## Verification Commands Run
verification_commands_run:
- bash scripts/dev/pre_ci.sh

## Status
final_status: PASS

## Evidence
- evidence/phase0/business_foundation_hooks.json (PASS)

## Final summary
- Verifier now proves the delta enforcement mechanisms are present and emits deterministic evidence.
