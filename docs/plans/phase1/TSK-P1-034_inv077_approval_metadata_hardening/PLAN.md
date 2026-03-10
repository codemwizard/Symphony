# TSK-P1-034 Plan

failure_signature: PHASE1.TSK.P1.034
origin_task_id: TSK-P1-034
first_observed_utc: 2026-03-10T00:00:00Z

## Mission
Make INV-077 task-complete by pairing centralized approval-metadata requirement logic with deterministic task-scoped evidence proving the requirement is enforced.

## Scope
In scope:
- shared approval-requirement logic
- contract and conformance verifier parity
- fixture validation for regulated/non-regulated approval cases
- task-scoped wrapper evidence

Out of scope:
- weakening approval requirements
- replacing the approval metadata schema

## Acceptance
- The approval requirement policy is centralized and enforced consistently.
- Approval metadata remains schema-valid and fail-closed when required.
- Task evidence proves the hardening path passed end-to-end.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_034.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-034 --evidence evidence/phase1/tsk_p1_034_approval_metadata_hardening.json`
