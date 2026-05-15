# Stage A Approval

**Date**: 2026-05-15  
**Approver**: mwiza  
**Scope**: Pre-CI remediation for expired exception metadata on `phase3/P3W0-governance-cleanup`  
**Status**: APPROVED

## Scope

This approval covers the regulated-surface remediation required to restore local `pre_ci.sh` convergence on this branch after the reproduced `PRECI.AUDIT.GATES` failure in `pre_ci.phase0_ordered_checks`.

Approved regulated edits:
- `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md`
- `evidence/phase1/approval_metadata.json`
- `approvals/2026-05-15/BRANCH-phase3-P3W0-governance-cleanup.approval.json`
- `approvals/2026-05-15/BRANCH-phase3-P3W0-governance-cleanup.md`

## Change Reason

`pre_ci.sh` failed in `scripts/audit/verify_exception_template.sh` because `docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md` has `expiry: 2026-05-14` without a matching `closed_at`. This approval authorizes the minimal regulated-surface correction needed to capture and remediate that failure.

## Verification Plan

- `bash scripts/audit/verify_exception_template.sh docs/invariants/exceptions/exception_change-rule_ddl_2026-04-30.md`
- `PRE_CI_CONTEXT=1 bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=phase3-P3W0-governance-cleanup`
- `SKIP_DOTNET_QUALITY_LINT=1 scripts/dev/pre_ci.sh`

## 8. Cross-References (Machine-Readable)

Approval Sidecar JSON: approvals/2026-05-15/BRANCH-phase3-P3W0-governance-cleanup.approval.json
