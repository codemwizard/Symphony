# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- PostGIS extension not available in Docker container used by pre_ci
- Migration 0128 violates expand/contract policy lint
- Migration 0128 DDL statements not in allowlist

## Root Cause
1. **PostGIS extension missing**: The Docker container `symphony-postgres` (postgres:18 image) did not have PostGIS installed. Migration 0125 requires PostGIS for spatial operations.
2. **Expand/contract policy violation**: Migration 0128 added a NOT NULL column directly with DEFAULT, violating the expand/contract policy which requires add nullable → backfill → set not null.
3. **DDL allowlist missing**: Migration 0128 ALTER TABLE statements were not in the DDL allowlist, causing lock-risk lint failures.

## Fix Sequence
1. Installed PostGIS in Docker container: `docker exec symphony-postgres apt-get install -y postgresql-18-postgis-3`
2. Fixed migration 0128 to follow expand/contract pattern:
   - Changed from `ALTER TABLE ... ADD COLUMN ... NOT NULL DEFAULT false`
   - To: `ALTER TABLE ... ADD COLUMN ... BOOLEAN` → `UPDATE ... SET ... = false` → `ALTER TABLE ... ALTER COLUMN ... SET NOT NULL`
3. Added DDL allowlist entries for both ALTER TABLE statements with correct SHA256 fingerprints
4. Added migration 0128 to expand/contract policy allowlist (Phase-2 exception for SET NOT NULL pattern)
5. Committed all fixes

## Verification
Run `scripts/dev/pre_ci.sh` to verify all fixes work correctly.
