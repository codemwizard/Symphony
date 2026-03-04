# REM-2026-03-04 Option-B Task Meta Migration

failure_signature: REM.SECURITY_REMEDIATION.OPTION_B_META_V1
origin_task_id: R-024

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Migrate task metadata contracts to schema_version v1.
- Enforce strict task meta validation in local and CI gates.

## verification_commands_run
- `python3 scripts/audit/migrate_task_meta_to_v1.py --dry-run --run-id R-024-DRYRUN-EVIDENCE --report evidence/security_remediation/r_024_task_meta_migration_dry_run.json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --json --out evidence/security_remediation/r_026_run_task_strict_enforcement.json`
