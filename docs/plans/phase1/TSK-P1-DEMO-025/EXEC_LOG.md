# TSK-P1-DEMO-025 Execution Log

failure_signature: PHASE1.DEMO.025.EXECUTION
origin_task_id: TSK-P1-DEMO-025
Plan: docs/plans/phase1/TSK-P1-DEMO-025/PLAN.md

## repro_command

Review and validate the host-based demo deployment contract in docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_demo_025.sh` -> PASS
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-025 --evidence evidence/phase1/tsk_p1_demo_025_runtime_contract.json` -> PASS

## Final Summary

Created the canonical host-based deployment guide, documented the full env/auth contract including the `SYMPHONY_UI_API_KEY` to `INGRESS_API_KEY` relationship, recorded `psql` as a required dependency, and updated operator docs to treat Kestrel as the supported default demo server.

## final_status
COMPLETED
