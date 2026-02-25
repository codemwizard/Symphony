# TSK-P1-INF-002 PLAN

Task: TSK-P1-INF-002
origin_task_id: TSK-P1-INF-002
failure_signature: PHASE1.TSK.P1.INF.002.CONTAINER_BUILD_PIPELINE

## repro_command
- `bash scripts/audit/verify_inf_002_container_build_pipeline.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-002 --evidence evidence/phase1/inf_002_container_build_pipeline.json`

## scope
- Add digest-pinned, non-root Dockerfiles for `ledger-api`, `executor-worker`, and `db-migration-job`.
- Add deterministic build verifier that builds each image twice and enforces stable image digest.
- Wire verifier/evidence into Phase-1 contract governance and local `pre_ci` Phase-1 gates.

## verification_commands_run
- `bash scripts/audit/verify_inf_002_container_build_pipeline.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-002 --evidence evidence/phase1/inf_002_container_build_pipeline.json`
