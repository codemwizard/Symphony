# TSK-P2-PREAUTH-004-CLEANUP PLAN: Remove Wave4/ Staging Directory

**Task:** TSK-P2-PREAUTH-004-CLEANUP
**Owner:** DB_FOUNDATION
**Depends on:** TSK-P2-PREAUTH-004-01-REM, TSK-P2-PREAUTH-004-03-DAG

## Objective

Wave4/ staging directory contains partial implementations and regressions from Wave 4. After all W4-REM remediation tasks are completed (004-01-REM and 004-03-DAG), this task removes the Wave4/ directory to prevent confusion and ensure the hardened Wave 5 branch is the source of truth.

## Architectural Context

Wave4/ was a staging directory for Wave 4 implementation work. It contains regressions and partial implementations that were superseded by the hardened Wave 5 branch. The Wave 5 branch (feat/pre-phase2-wave-5-state-machine-trigger-layer) contains the correct implementations (migration 0134, verifier scripts, etc.). Wave4/ should be removed to prevent accidental use of outdated code.

## Pre-conditions

- TSK-P2-PREAUTH-004-01-REM is completed
- TSK-P2-PREAUTH-004-03-DAG is completed
- Wave4/ directory exists

## Files to Change

| Path | Type | Change |
|------|------|--------|
| Wave4/ | DELETE | Remove entire directory |

## Stop Conditions

- If remediation tasks 004-01-REM or 004-03-DAG are not completed → STOP

## Implementation Steps

### [ID tsk_p2_preauth_004_cleanup_01] Verify remediation tasks completed

Verify that TSK-P2-PREAUTH-004-01-REM and TSK-P2-PREAUTH-004-03-DAG are completed by checking their meta.yml status fields.

```bash
grep 'status: completed' tasks/TSK-P2-PREAUTH-004-01-REM/meta.yml || exit 1
grep 'status: completed' tasks/TSK-P2-PREAUTH-004-03-DAG/meta.yml || exit 1
```

### [ID tsk_p2_preauth_004_cleanup_02] Delete Wave4/ directory

Delete Wave4/ directory using rm -rf Wave4/.

```bash
rm -rf Wave4/
```

## Acceptance Criteria

- [ID tsk_p2_preauth_004_cleanup_01] Wave4/ directory no longer exists (test ! -d Wave4/).

## Verification

```bash
# [ID tsk_p2_preauth_004_cleanup_01]
test ! -d Wave4/ || exit 1
```

## Evidence Contract

None (cleanup task, no evidence emission)

## Remediation Trace Compliance

Not required (cleanup task, not production-affecting).

## Regulated Surface Compliance

None of the files modified by this task are in REGULATED_SURFACE_PATHS.yml. Approval metadata is not required.

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Wave4/ directory still exists after deletion | Low | Low | Verification command fails if directory exists |
| Remediation tasks not completed before deletion | Low | High | Stop condition triggers if tasks not completed |

## Approval

This task does not modify regulated surfaces. No approval metadata required.
