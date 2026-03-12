# TSK-P1-STOR-001 Plan

Task ID: TSK-P1-STOR-001

## objective
Replace sandbox MinIO-backed archive path with SeaweedFS S3 gateway

## scope
1. Dependency completion: TSK-P1-INT-009A, TSK-P1-LED-002.
2. Implement only the behavior listed in this task and preserve existing invariants.
3. Generate required evidence and fail closed when required semantics are missing.

## implementation_steps
1. Introduce SeaweedFS S3-compatible endpoint configuration for sandbox archive/backup path.
2. Replace MinIO-specific retention posture wording/checks with backend-neutral retention controls.
3. Update LED-002 verifier/evidence vocabulary on storage posture fields.
4. Execute cutover with post-cutover smoke IO, archive run, restore drill, and rollback drill.

## acceptance_criteria
- CNPG backup/archive destination points to SeaweedFS gateway with expected secret references.
- Post-cutover archive write/read smoke path succeeds.
- LED-002 verifier has no MinIO-only assumptions and emits backend-neutral retention posture fields.
- Evidence confirms storage_backend="seaweedfs", post_cutover_smoke_io_passed=true, archive_run_pass=true, restore_drill_passed=true, retention_controls_verified=true, integrity_verifier_parity_pass=true.
- Rollback procedure is documented and test-run in sandbox.
- No new storage-backend-specific trust-root claims are introduced.

## remediation_trace
failure_signature: PHASE1.TSK_P1_STOR_001.EXECUTION_FAILURE
repro_command: bash scripts/audit/verify_tsk_p1_stor_001.sh
verification_commands_run:
- bash scripts/audit/verify_tsk_p1_stor_001.sh
- bash scripts/audit/verify_led_002_retention_archive_restore.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-STOR-001 --evidence evidence/phase1/tsk_p1_stor_001_minio_to_seaweedfs_cutover.json
final_status: planned
origin_task_id: TSK-P1-STOR-001
origin_gate_id: TSK_P1_STOR_001
