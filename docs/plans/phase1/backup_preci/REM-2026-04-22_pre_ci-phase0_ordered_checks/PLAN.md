# REMEDIATION PLAN — Wave 4 Verifier & Migration Compliance

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES
origin_task_id: TSK-P2-PREAUTH-004-03
origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: SKIP_DOTNET_QUALITY_LINT=1 bash scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Root Cause

Wave 4 implementation (TSK-P2-PREAUTH-004-01 through 004-03) left multiple
regulated surfaces in an inconsistent state after a merge to the feature branch:

1. **Missing migration 0134**: `policy_decisions` table was never created
   despite being required by the enforcement function in migration 0136.
   TSK-P2-PREAUTH-004-01 planned it as 0119 but the file was never authored.

2. **Faked V3 verifier scenario**: `verify_authority_transition_binding.sh`
   hardcoded a PASS at line 111 for the hash recompute step (V3) without any
   actual database test or sha256 canonical_json recompute. Violates AGENTS.md
   ("Never: mark implemented without enforcement + verification evidence")
   and the PLAN's own stop condition.

3. **Wrong column names in verifier INSERTs**: Verifier used `instruction_id`
   column which does not exist on `execution_records` (actual columns per
   migration 0118+0131+0132).

4. **policy_decisions INSERT used bytea instead of TEXT hex**: Contract
   (004-00 PLAN) specifies TEXT columns with `CHECK (decision_hash ~ '^[0-9a-f]{64}$')`.

5. **SQLSTATE P0002 missing from sqlstate_map.yml**: Migration 0136 uses
   SQLSTATE P0002 (no_data_found) but it wasn't registered in the map.

6. **INVARIANTS_QUICK.md stale**: INV-124 field restoration and INV-138
   addition changed the manifest but INVARIANTS_QUICK.md was not regenerated
   and committed before running pre_ci. The QUICK regeneration drift check
   (`git_assert_clean_path`) fails if the file has uncommitted changes.

7. **state_rules verifier hardcoded MIGRATION_HEAD=0135**: MIGRATION_HEAD is
   now 0136 after the enforce_authority_transition_binding migration.

8. **INV-124 missing sla_days/enforcement**: Fields were lost during a prior edit.

## Scope Boundary

### In scope
- `schema/migrations/0134_create_policy_decisions.sql` (NEW)
- `scripts/db/verify_authority_transition_binding.sh` (MODIFY)
- `scripts/db/verify_state_rules_schema.sh` (MODIFY)
- `docs/invariants/INVARIANTS_MANIFEST.yml` (MODIFY)
- `docs/invariants/INVARIANTS_QUICK.md` (REGENERATE)
- `docs/contracts/sqlstate_map.yml` (MODIFY)
- `schema/migrations/MIGRATION_HEAD` (VERIFY — already 0136)
- This casefile and its EXEC_LOG

### Out of scope
- Migration 0136 itself (already correct, SECURITY DEFINER hardened)
- Wave 5 trigger attachment
- Signature authenticity verification (declared proof_limitation)

## Fix Sequence (Derived Tasks)

### Already completed (prior to DRD creation)
- [x] MIGRATION_HEAD confirmed at 0136
- [x] verify_state_rules_schema.sh updated to expect 0136
- [x] INV-124 sla_days/enforcement/notes restored
- [x] Migration 0134 created (policy_decisions table per 004-00 contract)
- [x] Verifier rewritten with correct columns and real V3 recompute
- [x] SQLSTATE P0002 registered in sqlstate_map.yml

### Remaining (commit-state discipline)
- [ ] Regenerate INVARIANTS_QUICK.md and commit all regulated surface changes
- [ ] Clear DRD lockout via `bash scripts/audit/verify_drd_casefile.sh --clear`
- [ ] Re-run `SKIP_DOTNET_QUALITY_LINT=1 bash scripts/dev/pre_ci.sh`
- [ ] Update final_status to PASS

## Commit-State Discipline

The QUICK regeneration gate evaluates committed diff state.
All modified files MUST be staged/committed before re-running pre_ci.
Required staging set:
- schema/migrations/0134_create_policy_decisions.sql
- scripts/db/verify_authority_transition_binding.sh
- scripts/db/verify_state_rules_schema.sh
- docs/invariants/INVARIANTS_MANIFEST.yml
- docs/invariants/INVARIANTS_QUICK.md (after regeneration)
- docs/contracts/sqlstate_map.yml
- docs/plans/phase1/REM-2026-04-22_pre_ci-phase0_ordered_checks/PLAN.md
- docs/plans/phase1/REM-2026-04-22_pre_ci-phase0_ordered_checks/EXEC_LOG.md
