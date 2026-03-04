# R-024 PLAN

Task: R-024
origin_task_id: R-024

## objective
Execute assigned Option B migration scope for R-024.

## key_mapping_contract
- `id` -> `task_id`
- `verification_command` -> `verification` (list)
- `implementation_plan_path` -> `implementation_plan`
- `implementation_log_path` -> `implementation_log`
- `evidence_path` / `evidence_paths` -> `evidence` (list)
- `owner` / `role` / `assignee_role` -> `owner_role`
- If canonical and legacy keys both exist and values conflict, fail closed unless `--allow-conflicts-with-justification \"...\"` is provided and reported.
- `--input-root` defines scan base (default repository root); it must be recorded in report metadata.

## repro_command
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh

## verification_commands_run
- (to be filled during execution)

## notes
- Canonical reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
- Determinism: stable file ordering, stable field ordering, stable report ordering.
- `inputs_hash` definition: `sha256(sorted paths + raw file bytes)`, excluding mtimes/permissions/inode metadata.
- Apply-safety: idempotent second run, dirty-worktree refusal by default, backup/patch output support.
- This phase validates apply behavior via `--output-dir` only (no in-place mutation).
- `--output-dir` writes a complete migrated mirror tree for discovered task packs (not a sparse patch set).
- Dry-run report includes per-file mapping/normalization decisions and conflict audit details.
- Evidence schema for dry-run report: `evidence_schemas/r_024_task_meta_migration_dry_run.schema.json`.
