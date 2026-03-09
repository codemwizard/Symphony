# TSK-P1-018 Plan

failure_signature: PHASE1.TSK.P1.018
origin_task_id: TSK-P1-018
first_observed_utc: 2026-02-13T00:00:00Z

## Mission
Exception Case Pack Generator.

## Scope
In scope:
- Use the existing LedgerApi exception case-pack self-test as the deterministic generator proof for Phase-1.
- Emit deterministic evidence artifacts and keep Phase-0 non-regression.

Out of scope:
- New runtime service surfaces.
- External dispute workflow expansion beyond the current Phase-1 case-pack format.

## Acceptance
- Case pack generation is reproducible with deterministic content rules.
- Missing required lifecycle references fail generation deterministically.
- Evidence artifacts listed in task meta are generated and valid.

## Verification Commands
- `bash scripts/services/test_exception_case_pack_generator.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-018 --evidence evidence/phase1/exception_case_pack_generation.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-018 --evidence evidence/phase1/exception_case_pack_completeness.json`
