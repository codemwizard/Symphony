# TSK-P1-017 Execution Log

failure_signature: PHASE1.TSK.P1.017
origin_task_id: TSK-P1-017

## repro_command
`scripts/dev/pre_ci.sh`

## verification_commands_run
- `dotnet build services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -nologo -v minimal`
- `scripts/services/test_evidence_pack_api_contract.sh`
- `scripts/dev/pre_ci.sh`

## final_status
COMPLETED

Plan: `docs/plans/phase1/TSK-P1-017_evidence_pack_api_customer_endpoint/PLAN.md`

## Final Summary
- Added customer-facing evidence pack endpoint: `GET /v1/evidence-packs/{instruction_id}`.
- Enforced tenant-safe fail-closed behavior via required `x-tenant-id` and non-disclosing not-found responses.
- Stabilized deterministic, versioned response contract (`api_version=v1`, `schema_version=phase1-evidence-pack-v1`).
- Added deterministic self-test wrapper `scripts/services/test_evidence_pack_api_contract.sh`.
- Emitted required evidence artifacts:
  - `evidence/phase1/evidence_pack_api_contract.json`
  - `evidence/phase1/evidence_pack_api_access_control.json`
