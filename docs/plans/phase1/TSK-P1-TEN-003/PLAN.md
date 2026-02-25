# TSK-P1-TEN-003 PLAN

Task: TSK-P1-TEN-003
origin_task_id: TSK-P1-TEN-003
failure_signature: PHASE1.TSK.P1.TEN.003.TENANT_ONBOARDING_ADMIN

## repro_command
- `bash scripts/audit/verify_ten_003_tenant_onboarding_admin.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-003 --evidence evidence/phase1/ten_003_tenant_onboarding_admin.json`

## scope
- Implement `POST /v1/admin/tenants` with admin-only authorization.
- Enforce create-or-return idempotency keyed by `tenant_onboarding:<tenant_id>`.
- Emit deterministic `TENANT_CREATED` outbox event on first creation and preserve idempotent return path.
- Produce verifier-backed evidence for tenant creation, outbox emission, idempotency, and non-admin rejection.

## verification_commands_run
- `bash scripts/audit/verify_ten_003_tenant_onboarding_admin.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-TEN-003 --evidence evidence/phase1/ten_003_tenant_onboarding_admin.json`
- `bash scripts/audit/verify_agent_conformance.sh`
