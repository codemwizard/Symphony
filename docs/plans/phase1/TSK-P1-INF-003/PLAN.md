# TSK-P1-INF-003 PLAN

Task: TSK-P1-INF-003
origin_task_id: TSK-P1-INF-003
failure_signature: PHASE1.TSK.P1.INF.003.K8S_MIGRATION_HEALTH_PROOF

## repro_command
- `bash scripts/infra/verify_tsk_p1_inf_003.sh --evidence evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json`

## scope
- Add sandbox first-boot K8s manifests including migration Job and ledger Service.
- Enforce migration completion gate before `ledger-api` and `executor-worker` startup.
- Add health probes and verifier-backed readiness evidence.

## verification_commands_run
- `bash scripts/infra/verify_tsk_p1_inf_003.sh --evidence evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-003 --evidence evidence/phase1/tsk_p1_inf_003__k8s_manifests_migration_job_health_proof.json`
