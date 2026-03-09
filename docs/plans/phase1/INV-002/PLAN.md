# INV-002 PLAN

Task: INV-002
Owner role: SUPERVISOR
Depends on: INV-001
failure_signature: PHASE1.INV.002.REQUIRED

## objective
Immediate runtime-truth invariant pack

## scope
- Adopt the first runtime-truth invariant pack with Symphony-specific wording and verifier bindings.
- Add manifest rows, quick/implemented/roadmap doc updates, contract rows, and evidence paths.
- Keep future accounting invariants deferred; do not overclaim design-only controls as implemented.

## acceptance_criteria
- Every adopted invariant has concrete Symphony wording.
- Every implemented invariant has a verifier and evidence path.
- Deferred/advisory invariants are clearly labeled and not overclaimed.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task INV-002 --evidence evidence/invariants/inv_002_runtime_truth_pack.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not import phase-2 accounting invariants into Sprint-1.
- Do not use framework jargon without Symphony-specific enforcement mapping.

## evidence_output
- `evidence/invariants/inv_002_runtime_truth_pack.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `python3 scripts/audit/validate_evidence.py --task INV-002 --evidence evidence/invariants/inv_002_runtime_truth_pack.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
