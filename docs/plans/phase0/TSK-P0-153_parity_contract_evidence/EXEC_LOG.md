# Execution Log (TSK-P0-153)

failure_signature: CI.LOCAL_CONTRACT_EVIDENCE_PARITY
origin_task_id: TSK-P0-153

## repro_command
SKIP_OPENBAO_BOOTSTRAP=1 bash scripts/audit/run_phase0_ordered_checks.sh

## error_observed
Local ordered checks skipped `verify_phase0_contract_evidence_status.sh` via `SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS`, so missing GOV-G02 evidence only appeared later in CI. Need parity.

## change_applied
- Added a plan+log pair describing the parity fix and recorded the evidence mismatch.
- Captured the reproduction command and failure signature for the remediation trace gate.

## verification_commands_run
- bash scripts/audit/verify_phase0_contract_evidence_status.sh

## final_status
OPEN
