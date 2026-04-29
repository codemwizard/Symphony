# DRD Lite: Migration Checksum Mismatches

## Metadata
- Template Type: Lite
- Incident Class: Database Schema Drift
- Severity: L1
- Status: Open
- Owner: Cascade AI Agent
- Date: 2026-04-29
- Task: N/A (investigation only)
- Branch: fix/drd-checksum-mismatches-remediation

## Summary

Persistent local/staging databases that applied migrations with historical content now fail `migrate.sh` checksum validation due to 30 migration files having content changes from their original commits. This affects only persistent databases; CI is unaffected because it starts with a fresh database each run.

## First Failing Signal
- Artifact/log path: `scripts/db/verify_invariants.sh` output
- Error signature: `Checksum mismatch for <migration_file>`
  - Example: `Checksum mismatch for 0134_policy_decisions.sql`
  - Applied: `6716e99c...`
  - Current: `c474294e...`

## Impact
- What was blocked: Local `verify_invariants.sh` execution on persistent databases
- Delay: Investigation required to identify all affected migrations
- Attempts before record: 1 (initial investigation found 9 files, full audit revealed 30 files)

## Diagnostic Trail
- Command: `DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony" scripts/db/verify_invariants.sh`
- Result: Checksum mismatch errors for multiple migration files
- Investigation: Full audit of all 156 migration files revealed 30 affected files

## Root Cause
- Confirmed: Historical content changes to 30 migration files after their initial commits
- Categories:
  - **Category A (4 files)**: Blanked out (now 0 bytes)
  - **Category B (26 files)**: Content changed (including 1 rename)

## Affected Migration Files

### Category A — Blanked out (4 files, now 0 bytes):
- `0095_pre_snapshot.sql`
- `0095_rls_dual_policy_architecture.sql`
- `0095_rollback.sql`
- `0096_rls_admin_governance.sql`

### Category B — Content changed (26 files):

| Migration | Current SHA-256 (prefix) |
|---|---|
| `0032_timeout_posture_defaults.sql` | `91c04527...` |
| `0067_hard_wave5_reference_strategy_rotation_and_allocation_race.sql` | `b74e58e5...` |
| `0073_int_004_ack_gap_controls.sql` | `aee319ef...` |
| `0076_onboarding_control_plane.sql` | `6e3f8d4f...` |
| `0080_gf_adapter_registrations.sql` | `0abb5ec1...` |
| `0097_gf_projects.sql` | `9e16c675...` |
| `0098_gf_methodology_versions.sql` | `27109cf4...` |
| `0115_add_supplier_type_to_registry.sql` | `573304bc...` |
| `0121_create_data_authority_enum.sql` | `52fd2072...` |
| `0122_create_data_authority_triggers.sql` | `4e87659f...` |
| `0128_taxonomy_aligned.sql` | `7e971102...` |
| `0131_execution_records_determinism_columns.sql` | `5faa757a...` |
| `0132_execution_records_determinism_constraints.sql` | `1bfb06f8...` |
| `0133_execution_records_triggers.sql` | `cf59659f...` |
| `0134_policy_decisions.sql` (renamed from `0134_create_policy_decisions.sql`) | `c474294e...` |
| `0136_enforce_authority_transition_binding.sql` | `85c556e4...` |
| `0137_create_state_transitions.sql` | `e4db08a9...` |
| `0160_backfill_policy_decisions_project_id.sql` | `048a6acc...` |
| `0161_enforce_policy_decisions_project_id_not_null.sql` | `72e9acac...` |
| `0162_renumber_hardening_sqlstate.sql` | `964c0400...` |
| `0165_create_public_keys_registry.sql` | `ccd4f012...` |
| `0166_create_delegated_signing_grants.sql` | `38d0beaf...` |
| `0168_attestation_seam_schema.sql` | `a6a55b85...` |
| `0169_add_phase1_boundary_markers.sql` | `51d3a2ff...` |
| `0170_attestation_anti_replay.sql` | `029f8cc7...` |
| `0171_attestation_kill_switch_gate.sql` | `3165de4b...` |

## Fix Applied

### Recommended Remediation Plan (Reversible)

**Option 1: Database Recreation (Recommended for non-production)**
- Backup current database state: `pg_dump "$DATABASE_URL" > backup_before_checksum_fix.sql`
- Drop and recreate database from scratch
- Re-run all migrations with current content
- Restore data if needed (not applicable for dev/staging with no production data)

**Option 2: Checksum Update (Manual, reversible)**
- Backup current `schema_migrations` table: `docker exec symphony-postgres psql -U symphony_admin -d symphony -c "COPY schema_migrations TO STDOUT" > schema_migrations_backup.csv`
- Update checksums for all 30 affected files to match current migration file content
- Verification: Re-run `verify_invariants.sh` to confirm all checksums match

**Option 3: Migration Rollback (If rollback migrations exist)**
- Rollback to last known good state
- Re-apply migrations with current content

### Files Changed
- This DRD document only (no code changes yet)
- Implementation will touch: `schema_migrations` table (in database only, not in code)

### Why It Should Work
- CI is unaffected (fresh DB each run)
- Persistent databases can be safely recreated since no production data exists
- Checksum updates are reversible via database backup
- All changes are to database state, not migration files themselves

## Verification Outcomes

### Pre-Fix Verification
- Command: `DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony" scripts/db/verify_invariants.sh 2>&1 | grep -A2 "Checksum mismatch"`
- Expected: List of 30 migration files with checksum mismatches

### Post-Fix Verification
- Command: `DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony" scripts/db/verify_invariants.sh`
- Expected: `✅ Invariants verified.` with no checksum mismatch errors

### Rollback Verification
- Command: Restore from backup and re-run verify_invariants.sh
- Expected: Returns to pre-fix state (checksum mismatches reappear)

## Escalation Trigger
- Escalate to Full if:
  - Database recreation fails or causes data loss
  - Checksum updates do not resolve all mismatches
  - Additional affected migration files are discovered after fix
  - Production database is affected (currently only dev/staging)

## Reversibility Plan

### Backup Strategy
1. **Database backup**: `pg_dump "$DATABASE_URL" > backup_before_checksum_fix_<timestamp>.sql`
2. **Schema migrations backup**: `docker exec symphony-postgres psql -U symphony_admin -d symphony -c "COPY schema_migrations TO STDOUT" > schema_migrations_backup_<timestamp>.csv`
3. **Git commit**: All changes will be committed to branch for easy revert

### Rollback Procedure
1. Stop any running applications
2. Restore database from backup: `psql "$DATABASE_URL" < backup_before_checksum_fix_<timestamp>.sql`
3. Restore schema_migrations table if needed
4. Verify rollback: `scripts/db/verify_invariants.sh` should show original checksum mismatches
5. Git revert: `git revert <commit-hash>` if any code changes were made

### Recovery Guarantees
- No migration files will be deleted or modified
- No production data will be lost (backups created before any changes)
- All changes are reversible via database restore or git revert
- Baseline drift issue (separate from checksum mismatches) is already fixed on main via commit 133943ca
