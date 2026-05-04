# ADR-2026-05-04: Entity Coherence Baseline Update

## Status
Accepted

## Context
Task TSK-P2-W5-REM-01 (entity coherence enforcement) added 4 new migrations (0199-0202) to implement entity binding between policy_decisions and execution_records. These migrations implement:
- Entity type and ID expansion on execution_records table
- Backfill of entity bindings from policy_decisions
- NOT NULL constraints for entity coherence
- Entity coherence trigger enforcement (GF062)

## Decision
Regenerate the baseline snapshot to reflect the new schema state after applying the 4 entity coherence migrations.

## Rationale
The baseline snapshot (`schema/baseline.sql`) must reflect the current schema state after all migrations are applied. Since TSK-P2-W5-REM-01 migrations add new columns, constraints, indexes, and triggers to the execution_records table, the baseline must be updated to:
1. Include new entity_type and entity_id columns on execution_records
2. Include new idx_execution_records_entity_coherence index
3. Include new enforce_policy_decisions_entity_coherence function
4. Include new entity coherence trigger and constraints
5. Reflect the NOT NULL constraints on entity columns

## Consequences
- Positive: Baseline now accurately reflects the schema state with entity coherence enforcement
- Positive: Baseline drift check will pass after this update
- Positive: Canonical hash provides deterministic fingerprint for future drift detection
- Positive: GF062 entity coherence enforcement is properly captured in baseline
- Neutral: Baseline cutoff is now 0202_tsk_p2_w5_rem_01_trigger.sql (latest migration)

## Migration Changes
The following migrations were added in this remediation:
- 0199_tsk_p2_w5_rem_01_expand.sql - Added entity_type and entity_id columns to execution_records
- 0200_tsk_p2_w5_rem_01_backfill.sql - Backfilled entity bindings from policy_decisions
- 0201_tsk_p2_w5_rem_01_constrain.sql - Applied NOT NULL constraints to entity columns
- 0202_tsk_p2_w5_rem_01_trigger.sql - Created entity coherence trigger (GF062 enforcement)

## Baseline Metadata
- Baseline date: 2026-05-04
- Baseline cutoff: 0202_tsk_p2_w5_rem_01_trigger.sql
- Normalized schema SHA256: e2214f6b42480bb39d463c6821da76fb79ee9fe7cae9a8fb76e52a0994b1cdc6
- Dump source: container:symphony-postgres
- pg_dump version: pg_dump (PostgreSQL) 18.3 (Debian 18.3-1.pgdg13+1)
- pg_server_version: 18.3 (Debian 18.3-1.pgdg13+1)

## References
- Task: TSK-P2-W5-REM-01 (Entity Coherence Enforcement)
- Previous baseline: ADR-2026-04-30-wave8-baseline-update.md
- Baseline policy: docs/PLANS-addendum_1.md
