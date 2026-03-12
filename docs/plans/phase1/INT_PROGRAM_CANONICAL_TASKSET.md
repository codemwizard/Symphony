# INT Program Canonical Taskset (INT + STOR)

Execution order (authoritative):

1. TSK-P1-INT-001
2. TSK-P1-INT-002
3. TSK-P1-INT-003
4. TSK-P1-INT-004
5. TSK-P1-INT-005
6. TSK-P1-INT-006
7. TSK-P1-INT-007
8. TSK-P1-INT-008
9. TSK-P1-INT-009A
10. TSK-P1-STOR-001
11. TSK-P1-INT-009B
12. TSK-P1-INT-010
13. TSK-P1-INT-012
14. TSK-P1-INT-011

Each task is materialized with:
- `tasks/<TASK_ID>/meta.yml`
- `docs/plans/phase1/<TASK_ID>/PLAN.md`
- `docs/plans/phase1/<TASK_ID>/EXEC_LOG.md`
- `scripts/audit/verify_<task>.sh`
- evidence path registered in `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`

This file is for review and sequencing discipline only; implementation status is controlled in each task `meta.yml`.
