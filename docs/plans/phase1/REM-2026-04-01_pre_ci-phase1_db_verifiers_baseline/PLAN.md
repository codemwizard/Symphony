# DRD Full: PRECI.DB.ENVIRONMENT Baseline Governance Drift Remediation
**Phase Key**: `REM-2026-04-01-Baseline`
**Date**: 2026-04-01

## Incident Summary
The CI pipeline hit `PRECI.DB.ENVIRONMENT` error via `scripts/audit/verify_baseline_change_governance.sh` specifically stating that `schema/baseline.sql` changed but the required accompanying schema configuration (`docs/decisions/ADR-0010-baseline-policy.md`) was untouched. This flagged a fundamental protocol breach.

## Root Cause
A previous automated or manual run updated the baseline SQL snapshot to incorporate Green Finance (0097-0114) adjustments, but failed to synchronize the `ADR-0010-baseline-policy.md` Update Log simultaneously as mandated by Symphony governance.

## Remediation Plan
1. Manually injected the appropriate missing update entry onto `docs/decisions/ADR-0010-baseline-policy.md`: `- 2026-04-01: Baseline regenerated after Green Finance Wave 1 DB verifier integration (0097-0114).`
2. Executed `scripts/audit/verify_baseline_change_governance.sh` dynamically to trace validation bounds correctly.
3. Terminate lockout cleanly via `clear_drd_lockout_privileged.sh`.
