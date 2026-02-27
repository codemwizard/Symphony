# TSK-P1-202 Plan

failure_signature: P1.TSK.202.CLOSEOUT_CONTRACT_DRIVEN_FAIL_CLOSED
origin_task_id: TSK-P1-202

## repro_command
- bash scripts/audit/verify_tsk_p1_202.sh --evidence evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json

## scope
- Make `verify_phase1_closeout.sh` contract-driven from `docs/PHASE1/phase1_contract.yml`.
- Fail closed for missing contract, zero required artifact set, and missing required artifact.
- Add task verifier and evidence proving the required fail-closed behavior.

## implementation_steps
1. Refactor closeout verifier to enumerate required evidence paths from contract YAML.
2. Add schema-required-key checks from `docs/architecture/evidence_schema.json`.
3. Add task verifier script with negative tests for missing contract/empty required/missing artifact.
4. Wire verifier into pre-CI and contract registries.

## verification_commands_run
- bash scripts/audit/verify_tsk_p1_202.sh --evidence evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json
- python3 scripts/audit/validate_evidence.py --task TSK-P1-202 --evidence evidence/phase1/tsk_p1_202__closeout_verifier_scaffold_fail_if_contract.json
- bash scripts/audit/verify_phase1_closeout.sh
