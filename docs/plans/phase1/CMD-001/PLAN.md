# CMD-001 PLAN

Task: CMD-001
Owner role: SUPERVISOR
Depends on: FP-001, INV-001
failure_signature: PHASE1.CMD.001.REQUIRED

## objective
Attestation to outbox atomicity proof

## scope
- Define and verify invariant: no ACK without attestation + outbox durability in the same persistence boundary.
- Add negative tests for orphan attestation and orphan outbox conditions.
- Document that no remote dependency may sit between attestation and enqueue on the hot path.

## acceptance_criteria
- DB-backed durability path proves atomic attestation/outbox semantics.
- No acknowledged command can exist without durable outbox lineage.
- Verifier catches orphan conditions and fails closed.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_attestation_outbox_atomicity.sh`
- `python3 scripts/audit/validate_evidence.py --task CMD-001 --evidence evidence/command_integrity/cmd_001_attestation_outbox_atomicity.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## no_touch_warnings
- Do not add external bus or remote dependencies between attestation and enqueue.
- Do not redesign queue architecture in Sprint-1.

## evidence_output
- `evidence/command_integrity/cmd_001_attestation_outbox_atomicity.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_attestation_outbox_atomicity.sh`
- `python3 scripts/audit/validate_evidence.py --task CMD-001 --evidence evidence/command_integrity/cmd_001_attestation_outbox_atomicity.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
