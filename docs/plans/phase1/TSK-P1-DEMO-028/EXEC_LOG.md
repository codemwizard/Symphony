# TSK-P1-DEMO-028 Execution Log

failure_signature: PHASE1.DEMO.028.EXECUTION
origin_task_id: TSK-P1-DEMO-028
Plan: docs/plans/phase1/TSK-P1-DEMO-028/PLAN.md

## repro_command

Replace placeholder Dockerfiles with real packaging, add deterministic image-build commands for `ledger-api` and `executor-worker`, and keep the deployment guide explicit that host-based `dotnet publish` remains the supported demo path.

## verification_commands_run
- `chmod +x scripts/dev/build_demo_images.sh scripts/audit/verify_tsk_p1_demo_028.sh`
- `bash scripts/audit/verify_tsk_p1_demo_028.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-028 --evidence evidence/phase1/tsk_p1_demo_028_image_flow.json`

## Final Summary

Replaced the placeholder `ledger-api` and `executor-worker` Dockerfiles with real runtime images fed by a deterministic host-side publish-and-build script. The deployment guide now documents `scripts/dev/build_demo_images.sh` for reproducible image builds while preserving host-based Kestrel plus `dotnet publish` as the supported operator demo path. The verifier now performs real Docker builds and confirms the ledger image bundles the supervisory UI assets.

## final_status
COMPLETED
