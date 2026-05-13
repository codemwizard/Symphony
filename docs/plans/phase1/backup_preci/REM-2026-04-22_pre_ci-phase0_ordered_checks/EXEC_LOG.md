# REMEDIATION EXEC LOG

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
origin_task_id: TSK-P2-PREAUTH-004-03
repro_command: SKIP_DOTNET_QUALITY_LINT=1 bash scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

- created_at_utc: 2026-04-22T03:41:37Z
- action: remediation casefile scaffold created

- timestamp_utc: 2026-04-22T03:43:00Z
- action: Prior fixes applied before DRD creation (documented retroactively)
- fixes_applied:
  - MIGRATION_HEAD confirmed at 0136 (no conflict markers)
  - verify_state_rules_schema.sh MIGRATION_HEAD check updated from 0135 to 0136
  - INV-124 sla_days, enforcement, notes restored in INVARIANTS_MANIFEST.yml
  - Migration 0134_create_policy_decisions.sql created per 004-00 contract
    - 11 columns, FK to execution_records, UNIQUE(execution_id, decision_type)
    - CHECK constraints on decision_hash (64 hex) and signature (128 hex)
    - Append-only trigger (GF060), SECURITY DEFINER, revoke-first posture
  - verify_authority_transition_binding.sh fully rewritten:
    - execution_records INSERT uses actual columns from 0118+0131+0132
    - policy_decisions INSERT uses TEXT hex (not bytea) per 004-00 contract
    - V3 performs real sha256(canonical_json) recompute via sha256sum
    - Handles interpretation_packs RLS and temporal trigger dependencies
  - SQLSTATE P0002 registered in docs/contracts/sqlstate_map.yml

- timestamp_utc: 2026-04-22T03:43:00Z
- action: First pre_ci attempt (after DRD lockout clear)
- result: FAIL — SQLSTATE map drift (P0002 missing)
- fix: Added P0002 to sqlstate_map.yml

- timestamp_utc: 2026-04-22T03:43:00Z
- action: Second pre_ci attempt
- result: FAIL — INVARIANTS_QUICK.md regeneration drift
- root_cause: Manifest changes (INV-124 restoration + INV-138 addition) caused
  INVARIANTS_QUICK.md to regenerate differently, but the regenerated file was
  not committed. The git_assert_clean_path check fails on uncommitted changes.
- lesson: Commit-state discipline required — all regulated surface changes must
  be staged/committed before re-running pre_ci gates that check git cleanliness.

- timestamp_utc: 2026-04-22T03:43:00Z
- action: DRD Full casefile created (this log)
- next_steps:
  1. Regenerate INVARIANTS_QUICK.md
  2. Stage and commit all regulated surface changes
  3. Clear DRD lockout via verify_drd_casefile.sh --clear
  4. Re-run pre_ci
