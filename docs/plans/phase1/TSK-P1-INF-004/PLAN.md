# TSK-P1-INF-004 PLAN

Task: TSK-P1-INF-004
origin_task_id: TSK-P1-INF-004
failure_signature: PHASE1.TSK.P1.INF.004.SERVICE_MTLS_MESH

## repro_command
- `bash -lc 'set -euo pipefail; test -f docs/PHASE1/phase1_contract.yml || { echo MISSING_CONTRACT:docs/PHASE1/phase1_contract.yml; exit 1; }; test -x scripts/infra/verify_tsk_p1_inf_004.sh || { echo MISSING_VERIFIER:scripts/infra/verify_tsk_p1_inf_004.sh; exit 1; }; scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json'`

## scope
- Add Istio STRICT mTLS policy resources for `ledger-api` and `executor-worker` in sandbox manifests.
- Keep mesh identity and evidence-signing identity explicitly separated.
- Add deterministic verifier that checks strict mTLS resources and plaintext rejection posture.

## verification_commands_run
- `bash scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-004 --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`
