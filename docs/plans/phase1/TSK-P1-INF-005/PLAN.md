# TSK-P1-INF-005 PLAN

Task: TSK-P1-INF-005
origin_task_id: TSK-P1-INF-005
failure_signature: PHASE1.TSK.P1.INF.005.OPENBAO_EXTERNAL_SECRETS

## repro_command
- `bash scripts/audit/verify_inf_005_openbao_external_secrets.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-005 --evidence evidence/phase1/inf_005_openbao_external_secrets.json`

## scope
- Add sandbox OpenBao manifests with TLS-enabled listener and file storage backend.
- Add External Secrets Operator store + two `ExternalSecret` resources in the `symphony` namespace.
- Add verifier that validates OpenBao+ESO posture and emits rotation-proof evidence.

## verification_commands_run
- `bash scripts/audit/verify_inf_005_openbao_external_secrets.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-005 --evidence evidence/phase1/inf_005_openbao_external_secrets.json`
