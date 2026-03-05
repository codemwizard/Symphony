# TSK-HARD-001 PLAN

Task: TSK-HARD-001
origin_task_id: TSK-HARD-001
failure_signature: HARDENING.TSK.HARD.001.TRUST_INVARIANTS_REQUIRED

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Produce and freeze `TRUST_INVARIANTS.md` with 12 complete invariant entries.
- Add parser-based verifier and schema-backed evidence for invariant completeness.

## verification_commands_run
- `bash scripts/audit/verify_tsk_hard_001.sh`
- `python3 - <<'PY' ... jsonschema.validate(...) ... PY`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
