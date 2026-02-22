# TSK-CLEAN-002 PLAN

origin_task_id: TSK-CLEAN-002
failure_signature: informational_perf_mode_detected
repro_command: scripts/audit/verify_tsk_clean_002.sh --evidence evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json
verification_commands_run:
- scripts/audit/verify_tsk_clean_002.sh --evidence evidence/phase0/tsk_clean_002__kill_informational_only_perf_posture_everywhere.json
- scripts/dev/pre_ci.sh
final_status: IN_PROGRESS

## Scope
- Lock perf baseline posture and remove informational mode fallback from perf gate execution path.
