# TSK-P1-INF-001 PLAN

Task: TSK-P1-INF-001
origin_task_id: TSK-P1-INF-001
failure_signature: PHASE1.TSK.P1.INF.001.POSTGRES_HA_BACKUPS_PITR

## repro_command
- `bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_001.sh || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_001.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_001.sh --evidence evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json'`

## scope
- Add sandbox CNPG-style cluster and backup schedule manifests for HA + backup posture.
- Add deterministic PITR probe script and INF-001 verifier wrappers.
- Wire INF-001 verifier/evidence into Phase-1 contract and pre-CI Phase-1 gate path.

## verification_commands_run
- `bash scripts/infra/verify_tsk_p1_inf_001.sh --evidence evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-001 --evidence evidence/phase1/tsk_p1_inf_001__postgres_ha_backups_pitr_operator.json`
