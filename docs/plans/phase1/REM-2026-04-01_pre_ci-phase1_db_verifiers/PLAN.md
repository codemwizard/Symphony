# DRD Full: PRECI.DB.ENVIRONMENT Evidence Contract Remediation
**Phase Key**: `REM-2026-04-01`
**Date**: 2026-04-01

## Incident Summary
The CI pipeline failed on `scripts/audit/verify_task_evidence_contract.sh` because 10 GF Wave 1 Phase 1 task configurations were missing the mandatory `'Evidence file missing'` string in their `failure_modes:` section. After reaching the consecutive failure limit, a DRD lock engaged.

## Root Cause
Task templates generating the Wave 1 manifests omitted the universal evidence verification failure semantics string required by the declarative scope enforcer.

## Remediation Plan
1. Programmatically append `  - "Evidence file missing"` directly under `failure_modes:` in the following files:
   - `tasks/GF-W1-SCH-009/meta.yml`
   - `tasks/GF-W1-FNC-001/meta.yml`
   - `tasks/GF-W1-FNC-002/meta.yml`
   - `tasks/GF-W1-FNC-003/meta.yml`
   - `tasks/GF-W1-FNC-004/meta.yml`
   - `tasks/GF-W1-FNC-005/meta.yml`
   - `tasks/GF-W1-FNC-006/meta.yml`
   - `tasks/GF-W1-FNC-007A/meta.yml`
   - `tasks/GF-W1-FNC-007B/meta.yml`
   - `tasks/GF-W1-PLT-001/meta.yml`
2. Automatically verify using `scripts/audit/verify_task_evidence_contract.sh`.
3. Terminate lockout using privileged escalation script.
