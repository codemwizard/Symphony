# Execution Log — TSK-P2-PREAUTH-007-14

## Remediation Trace

- **failure_signature**: PHASE2.STRICT.TSK-P2-PREAUTH-007-14.PROOF_FAIL
- **origin_task_id**: TSK-P2-PREAUTH-007-14
- **repro_command**: `bash scripts/audit/verify_tsk_p2_preauth_007_14.sh`
- **remediation_action**: 
  - Dropped architecturally invalid migration `0171_db_kill_switch_gate.sql` (which incorrectly queried mutable health status from the registry).
  - Authored new `0171_attestation_kill_switch_gate.sql` implementing structural attestation validation and registry-contract binding.
  - Hardened schema with strict `VARCHAR(64)` and regex constraints for attestation hashes and snapshot hashes.
  - Implemented deterministic JSONB-based snapshot canonicalization.
  - Rewrote the verifier from string-matching theatre to live behavioral DB tests proving physical rejection of malformed/stale/contract-mismatched attestations.
- **verification_commands_run**: `bash scripts/audit/verify_tsk_p2_preauth_007_14.sh`
- **final_status**: PASS

## Audit Evidence

- **Evidence File**: `evidence/phase2/tsk_p2_preauth_007_14.json`
- **Trigger**: `trg_attestation_gate_asset_batches`
- **Boundary**: `BEFORE INSERT ON public.asset_batches`
- **Mechanical Rejection Codes**: 
  - `GF074`: Structural integrity failure
  - `GF075`: Stale timestamp (>300s TTL)
  - `GF076`: Future timestamp skew
  - `GF077`: Registry contract mismatch
