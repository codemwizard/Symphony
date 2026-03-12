# TSK-P1-INT-002 Execution Log

failure_signature: PHASE1.TSK_P1_INT_002.EXECUTION_FAILURE
origin_task_id: TSK-P1-INT-002
Plan: docs/plans/phase1/TSK-P1-INT-002/PLAN.md

## repro_command
`bash scripts/audit/verify_tsk_p1_int_002.sh`

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_int_002.sh` -> PASS

## final_status
COMPLETED

## execution_notes
- Added synchronous `chain_record` population to governed signed-instruction and evidence-event writes.
- Implemented reusable chain verification helpers and a dedicated demo-host self-test for INT-002.
- Replaced the scaffold-only verifier with a runtime-backed verifier that checks chain presence, broken-chain rejection, and p95 latency delta over 100 runs.
- Produced evidence at `evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json`.

## Final Summary
- `services/ledger-api/dotnet/src/LedgerApi/Commands/TamperEvidentChain.cs` now computes and verifies per-domain hash-chain records with `single_write_envelope` commit semantics.
- `SignedInstructionFileHandler` now persists a governed-instruction chain record in the same written envelope as the signed artifact.
- `EvidenceLinkSmsDispatchLog`, `EvidenceLinkSubmissionLog`, and `DemoExceptionLog` now persist evidence-event chain records in the same appended envelope as each attested event.
- `services/ledger-api/dotnet/src/LedgerApi/Demo/IntegrityChainSelfTestRunner.cs` proves both governed domains, broken-chain rejection, and a measured p95 chain-population delta of `1.634ms` on the local demo-host reference hardware.
