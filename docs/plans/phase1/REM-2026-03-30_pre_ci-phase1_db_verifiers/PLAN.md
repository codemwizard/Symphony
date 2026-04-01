# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: bash scripts/security/lint_ddl_lock_risk.sh
final_status: RESOLVED

## Scope
- lock-risk DDL static lint caught ALTER TABLE ... ADD COLUMN in migration 0110.

## Root Cause
- Migration 0110_gf_fn_regulatory_transitions.sql contained ALTER TABLE public.authority_decisions ADD COLUMN IF NOT EXISTS ... to extend the table created in 0103 with new lifecycle columns (decision_outcome, subject_type, subject_id, from_status, to_status).
- lint_ddl_lock_risk.sh flags ALTER TABLE as risky DDL per lock-risk policy.

## Fix
- Removed ALTER TABLE ADD COLUMN entirely.
- Extra lifecycle fields are now packed into the existing decision_payload_json JSONB column via jsonb_build_object in the record_authority_decision INSERT.
- query_authority_decisions unpacks those fields from JSONB using ->>/::UUID casts.
- verify_gf_fnc_004.sh still passes (exit 0) after change.
- lint_ddl_lock_risk.sh passes (exit 0) after change.

## Prevention
- Never use ALTER TABLE ADD COLUMN on existing GF Phase 0 tables in Phase 1 function migrations; use the existing JSONB payload columns for extensibility.
