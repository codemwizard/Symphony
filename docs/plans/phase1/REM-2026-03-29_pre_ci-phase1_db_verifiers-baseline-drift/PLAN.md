# REMEDIATION PLAN — Baseline Drift from GF Migrations

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Baseline drift caused by migrations 0097 (`projects`) and 0098 (`methodology_versions`) added for task GF-W1-SCH-002A without regenerating the schema baseline snapshot.

## Root Cause

The `check_baseline_drift.sh` gate applies all migrations to a temp DB, runs `pg_dump`, and compares the dump against `schema/baselines/current/0001_baseline.sql`. The baseline was last regenerated before migrations 0097/0098 existed, so it contains zero references to `projects` or `methodology_versions`. The dump includes those tables → diff fails → `PRECI.DB.ENVIRONMENT`.

Evidence: `evidence/phase0/baseline_drift.json` shows `status: FAIL`, `reason: baseline drift`, with `baseline_hash ≠ current_hash`.

## Fix Sequence
1. Start Docker containers (`symphony-postgres`, `symphony-openbao`)
2. Apply migrations to running DB via `scripts/db/migrate.sh`
3. Regenerate baseline via `scripts/db/generate_baseline_snapshot.sh`
4. Verify with `scripts/db/check_baseline_drift.sh`

## Secondary Issue
`scripts/db/verify_gf_sch_002a.sh` generates evidence without the required `check_id` field, causing `validate_evidence_schema.sh` to also fail. Fix: add `check_id` to the evidence template.

## Nonconvergence Note
DRD count reached 23 because the lockout file was repeatedly removed without root cause analysis. The actual failure was always the same: baseline drift from missing table definitions.
