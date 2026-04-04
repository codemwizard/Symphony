# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.REMEDIATION.TRACE

origin_gate_id: pre_ci.verify_remediation_trace
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: COMPLETE

## Scope
- Record the fixes applied during the DEMO-BUGS phase addressing CI instability and UI functional gaps.

## Root Causes & Remediation
- **PRE_CI_RUN_ID identity loop**: The `git write-tree` derivation caused the hook to produce inherently unstable run identifiers that drifted as the hook executed. Fixed by anchoring to `git rev-parse HEAD`.
- **Worker link mismatch**: The Demo button did not align with the production boundary signature. Fixed by backfilling all 5 mandatory fields directly into the JSON fetch payload.
- **Reporting constraints**: Proof requirement maps leaked into the UI display map. Fixed by introducing `RequiredProofTypes` isolation.
- **Timeline rendering block**: `Pwrm0001MonitoringReportHandler.cs` elided the instruction array needed by the supervisor dashboard. Fixed by embedding the mapping into the aggregate query.
