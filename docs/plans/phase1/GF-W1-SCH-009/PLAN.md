# PLAN: GF-W1-SCH-009

[ID gf_w1_sch_009]

## Objective
To close out Phase 0 schema creation by promoting invariants and wiring the required CI gates to enforce them permanently, thus securing the baseline for Phase 1 Functions.

## Execution Details
This task touches purely CI and verification scripts (`pre_ci.sh`, `verify_gf_w1_sch_009.sh`). It does not execute a schema migration.

## Constraints
- Must not modify any existing `schema/migrations/` code.
- Must execute after `GF-W1-SCH-008`.

## Verification
The task must provide an evidence payload via `verify_gf_w1_sch_009.sh` showing exact conformance and pass `pre_ci.sh` without failure.
