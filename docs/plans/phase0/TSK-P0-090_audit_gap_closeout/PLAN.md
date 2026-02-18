# PLAN — Phase-0 audit gap closeout (Tier-1)

## Task IDs
- TSK-P0-090
- TSK-P0-091
- TSK-P0-092
- TSK-P0-093
- TSK-P0-094
- TSK-P0-095
- TSK-P0-096
- TSK-P0-097
- TSK-P0-098
- TSK-P0-099
- TSK-P0-100
- TSK-P0-101
- TSK-P0-102
- TSK-P0-103

## Scope
- Close the remaining Tier-1 gaps identified in:
- `docs/audits/TIER1_GAP_AUDIT_2026-02-06.md`
- `docs/audits/TIER1_GAP_AUDIT_ADDENDUM_2026-02-07.md`
- `Phase0_Audit-Gap_Closeout_Plan_Draft.txt`
- By adding Phase-0-appropriate artifacts:
  - policy stubs + mechanical presence/reference verifiers
  - expand/contract migration guardrails (PaC lints)
  - catalog-based table conventions verification
  - CI and pre-CI wiring
  - governance record reconciliation for already-implemented hooks

## Non-Goals
- Claim compliance or certification (ISO/PCI/NIST).
- Implement Phase-1/2 runtime services or external integrations.
- Add runtime DDL or weaken existing invariants (append-only, revoke-first, migration immutability).

## Files / Paths Touched
- `docs/PHASE0/PHASE0_AUDIT_GAP_CLOSEOUT_IMPLEMENTATION.md`
- `docs/tasks/PHASE0_TASKS.md`
- `docs/plans/phase0/INDEX.md`
- `docs/PHASE0/phase0_contract.yml`
- `tasks/TSK-P0-090/meta.yml`
- `tasks/TSK-P0-091/meta.yml`
- `tasks/TSK-P0-092/meta.yml`
- `tasks/TSK-P0-093/meta.yml`
- `tasks/TSK-P0-094/meta.yml`
- `tasks/TSK-P0-095/meta.yml`
- `tasks/TSK-P0-096/meta.yml`
- `tasks/TSK-P0-097/meta.yml`
- `tasks/TSK-P0-098/meta.yml`
- `tasks/TSK-P0-099/meta.yml`

## Gates / Verifiers
- (When implemented) `scripts/audit/run_invariants_fast_checks.sh`
- (When implemented) `scripts/audit/run_security_fast_checks.sh`
- (When implemented) `scripts/db/verify_invariants.sh`
- (When implemented) `scripts/audit/verify_phase0_contract.sh`

## Expected Failure Modes
- Migration guardrails are too permissive (allow destructive/compat-breaking changes in Expand).
- Policy stubs exist but are not mechanically referenced/validated (audit fails on “paper policy”).
- Table conventions are regex-based rather than catalog-based (auditor rejects as non-authoritative).
- Governance records drift (implemented controls still marked planned).

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_phase0_contract.sh`

## Dependencies
- TSK-P0-088, TSK-P0-089 (audit + addendum)
