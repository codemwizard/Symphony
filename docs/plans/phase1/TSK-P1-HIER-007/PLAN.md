# TSK-P1-HIER-007 PLAN

Task: TSK-P1-HIER-007
Owner role: SUPERVISOR
Depends on: TSK-P1-HIER-006

## objective
Implement the canonical HIER-007 execution metadata contract by delivering:
- risk formula registry default for Tier-1 deterministic behavior
- program migration event ledger and deterministic migration function
- verifier evidence at the required evidence path

## implementation
- Add migration `0052_hier_007_risk_formula_registry_program_migration.sql` with:
  - `risk_formula_versions` and default active `TIER1_DETERMINISTIC_DEFAULT`
  - `program_migration_events`
  - `migrate_person_to_program(...)` (SECURITY DEFINER + hardened search_path)
  - `tenant_program_year_unique_beneficiaries` view
- Add verifier `scripts/db/verify_tsk_p1_hier_007.sh` covering schema, function hardening, deterministic runtime behavior, and evidence generation.
- Update task metadata and execution log for terminal closeout.

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_tsk_p1_hier_007.sh --evidence evidence/phase1/tsk_p1_hier_007__risk_formula_registry_tier_deterministic_default.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
completed
