# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: 
- scripts/security/lint_dotnet_quality.sh
- scripts/audit/validate_evidence_schema.sh
- scripts/audit/validate_evidence_json.sh
- scripts/dev/pre_ci.sh
final_status: PASS

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- Whitespace errors in dotnet files

## Root Cause
- dotnet formatting failed because of unformatted C# files in LedgerApi.
- `pwrm0001_monitoring_report.json` was being validated against audit evidence schema, failing because it's a business report.
- `run_id` mismatch occurred because the `EVIDENCE_SIGNATURE_VERIFY` gate in `pre_ci.sh` ran *before* the GF verifiers, failing on stale IDs from previous commits before they could be updated.

## Fix
- Ran `dotnet format` on the csproj files.
- Modified `scripts/audit/validate_evidence_schema.sh` and `scripts/audit/validate_evidence_json.sh` to skip `pwrm0001_monitoring_report.json` and `pwrm_monitoring_report.json`.
- Relocated the `EVIDENCE_SIGNATURE_VERIFY` gate in `scripts/dev/pre_ci.sh` to the end of the script, ensuring verifiers update the `run_id` before verification.
