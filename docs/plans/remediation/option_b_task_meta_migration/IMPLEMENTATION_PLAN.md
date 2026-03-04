# Option B Implementation Plan: Task Meta Schema Migration First

## Objective
Execute a strict migration from legacy task meta keys to the canonical task meta template before enabling strict task runner enforcement.

## Scope
- Migrate all `tasks/*/meta.yml` files to canonical keys.
- Enforce canonical schema in `scripts/agent/run_task.sh` with no legacy aliases.
- Add deterministic validation gate in CI/pre-CI.
- Produce evidence for inventory, migration, enforcement, and closeout.

## Canonical References
- `tasks/_template/meta.yml`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

## Non-Goals
- No runtime domain behavior changes.
- No invariant semantic changes.
- No schema/db changes.

## Execution Waves
1. `R-023` Freeze canonical schema and baseline all task meta variants.
2. `R-024` Build and verify migration tool (dry-run + report).
3. `R-025` Apply migration to all task packs and validate repository-wide conformance.
4. `R-026` Make `scripts/agent/run_task.sh` strict canonical-only and wire fail-closed gate.
5. `R-027` Finalize guardrails and emit closeout evidence.

## Definition of Done
- All `tasks/*/meta.yml` validate against canonical schema contract.
- `run_task.sh` reads canonical shape only and fails closed on invalid/missing required keys.
- Pre-CI includes canonical meta validation gate.
- Evidence artifacts for R-023..R-027 are generated and schema-valid.

## Risk Controls
- Migration runs in staged mode (`report` then `apply`) with diff artifacts.
- Deterministic rollback via git if migration output invalid.
- No task marked complete unless verifier and evidence both pass.
