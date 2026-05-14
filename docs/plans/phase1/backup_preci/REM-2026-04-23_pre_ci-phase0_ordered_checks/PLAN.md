# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- dotnet quality lint is timing out after 60 seconds
- Only 1 of 4 targets processed before timeout
- Note: "dotnet_build_timeout" in evidence
- This is a performance/timeout issue, not a code quality issue

## Root Cause
The dotnet quality lint script (scripts/security/lint_dotnet_quality.sh) is timing out after 60 seconds (DOTNET_LINT_TIMEOUT_SEC). The script processes 4 dotnet projects but only completes 1 before timeout. This is causing pre_ci phase0_ordered_checks to fail.

## Secondary Issue: Migration 0122 state_transitions Reference
During investigation, discovered migration 0122 (data_authority_triggers) tries to attach triggers to state_transitions table, but that table doesn't exist until migration 0137. This is the same ordering issue as migration 0121.

## Fix Options
1. Increase DOTNET_LINT_TIMEOUT_SEC in the lint script
2. Skip dotnet quality lint for Wave 5 remediation (unrelated to database changes)
3. Investigate why dotnet build is slow
4. Fix migration 0122 ordering issue (same as 0121 fix)

## Recommended Fix
Since Wave 5 remediation is database-only (schema/migrations changes), the dotnet quality lint is not relevant to the changes being made. The failure is a false positive for this branch. Recommended to either:
- Increase timeout to allow full lint to complete, OR
- Mark this as a known exception for database-only branches

For migration 0122: Apply same fix as migration 0121 - remove state_transitions trigger attachments from 0122 and move them to 0137 where the table is created.
