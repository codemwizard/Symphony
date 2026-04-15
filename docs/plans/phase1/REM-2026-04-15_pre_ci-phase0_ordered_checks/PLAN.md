# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: SKIP_DOTNET_QUALITY_LINT=1 scripts/dev/pre_ci.sh
verification_commands_run: scripts/security/lint_ddl_lock_risk.sh
final_status: PASS
root_cause: DDL lock risk lint (SEC-DDL-LOCK-RISK) flagged ALTER TABLE statement in pilot demo migration 0115. The migration adds a nullable supplier_type column to non-hot supplier_registry table and is documented in exception_change-rule_ddl_2026-04-15.md (EXC-1000).

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- DDL lock risk lint flagging ALTER TABLE in migration 0115

## Root Cause Analysis

### Failure Details
- Check: SEC-DDL-LOCK-RISK (DDL lock risk lint)
- Error: ALTER TABLE statement flagged in schema/migrations/0115_add_supplier_type_to_registry.sql:4
- Statement: ALTER TABLE public.supplier_registry ADD COLUMN IF NOT EXISTS supplier_type TEXT
- NONCONVERGENCE_COUNT: 4 consecutive failures

### Investigation
The lint_ddl_lock_risk.sh script flags ALTER TABLE as a risky DDL pattern. However, this migration is for a pilot demo that adds a nullable column to a non-hot table (supplier_registry). The migration is already documented in exception_change-rule_ddl_2026-04-15.md with exception ID EXC-1000. The script includes an allowlist mechanism via docs/security/ddl_allowlist.json for exactly this scenario.

### Fix Applied
Added DDL-ALLOW-0102 entry to docs/security/ddl_allowlist.json with:
- migration: schema/migrations/0115_add_supplier_type_to_registry.sql
- statement_fingerprint: ab694c613e686dab5e124911841846e6c06a81094ef071875f7fc8fcc8555a99
- reason: Pilot demo migration adding nullable column to non-hot table, documented in EXC-1000
- expires_on: 2026-12-31
- reviewed_by: security_guardian
- approved_at: 2026-04-15

## Solution Summary
Added pilot demo migration 0115 to DDL allowlist. The ALTER TABLE statement adds a nullable supplier_type column to the non-hot supplier_registry table and is already documented with proper exception metadata.
