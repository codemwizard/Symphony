# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/audit/verify_gf_rls_runtime.sh
final_status: RESOLVED

## Root Cause

The GF RLS runtime verifier (`scripts/audit/verify_gf_rls_runtime.sh`) was written
for the pre-0095 single-policy RLS architecture (migration 0059), where each table
had **exactly 1 RESTRICTIVE policy** containing the full tenant isolation expression.

Migration `0095_rls_dual_policy_architecture.sql` introduced a **dual-policy model**
for all tenant-isolated tables:
  - `rls_base_<table>` — PERMISSIVE, `USING (true)`, no WITH CHECK
  - `rls_iso_<table>` — RESTRICTIVE, `USING (col = current_tenant_id_or_null())`,
    `WITH CHECK (col = current_tenant_id_or_null())`

The verifier was never updated to match, causing two failures on `adapter_registrations`
(the only GF table that currently exists in the DB):
  1. `wrong_policy_count:expected_1_got_2` — finds 2 policies, expects 1.
  2. `policy_shape_invalid` — `LIMIT 1` picks the base policy (`USING (true)`),
     which lacks the tenant function and WITH CHECK.

## Fix

Update `verify_gf_rls_runtime.sh` to understand the dual-policy architecture:
1. Accept **2 policies** per table (base + iso) instead of 1.
2. Validate the base policy: PERMISSIVE, FOR ALL, TO PUBLIC, USING (true).
3. Validate the isolation policy: RESTRICTIVE, FOR ALL, TO PUBLIC, correct
   USING and WITH CHECK expressions per isolation class.
4. Query the isolation policy specifically (`polname LIKE 'rls_iso_%'`) for
   the shape check instead of `LIMIT 1`.
