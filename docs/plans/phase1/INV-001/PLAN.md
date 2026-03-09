# INV-001 PLAN

Task: INV-001
Owner role: SUPERVISOR
Depends on: FP-001, SEC-002
failure_signature: PHASE1.INV.001.REQUIRED

## objective
Invariant governance upgrade

## scope
- Install fail-closed invariant promotion semantics: verifier + CI gate + deterministic evidence.
- Bind invariant -> verifier -> gate -> evidence path in canonical docs/contracts.
- Prevent new invariants from being claimed implemented without mechanical proof.

## acceptance_criteria
- Implemented invariant status requires verifier, blocking CI path, and evidence path.
- Contract/manifest/docs are synchronized for promoted invariants.
- Evidence validation path is explicit and reusable by agents/reviewers.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task INV-001 --evidence evidence/invariants/inv_001_governance_upgrade.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not create a second canonical source of truth for invariant status.

## evidence_output
- `evidence/invariants/inv_001_governance_upgrade.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task INV-001 --evidence evidence/invariants/inv_001_governance_upgrade.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
