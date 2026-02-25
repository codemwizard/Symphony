# TSK-P1-INF-004 EXEC_LOG

Task: TSK-P1-INF-004
origin_task_id: TSK-P1-INF-004
Plan: docs/plans/phase1/TSK-P1-INF-004/PLAN.md
failure_signature: PHASE1.TSK.P1.INF.004.SERVICE_MTLS_MESH

## repro_command
- `bash scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`

## timeline
- completed

## commands
- `bash scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-004 --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`

## verification_commands_run
- `bash scripts/infra/verify_tsk_p1_inf_004.sh --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-004 --evidence evidence/phase1/tsk_p1_inf_004__service_mtls_mesh.json`

## results
- Istio `PeerAuthentication` enforces `STRICT` mode for sandbox namespace traffic.
- `DestinationRule` resources enforce `ISTIO_MUTUAL` for `ledger-api` and `executor-worker`.
- Verifier emitted deterministic negative-test evidence that plaintext traffic is rejected by policy.

## final_status
completed

## Final summary
- Added strict service-to-service mTLS mesh policy manifests for the sandbox.
- Added INF-004 verifier and registered contract/registry wiring for required evidence.
- Preserved boundary separation: mesh mTLS identity is not reused for evidence-signing keys.
