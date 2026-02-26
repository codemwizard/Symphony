# TSK-P1-LED-003 Plan

failure_signature: P1.LED.003.CANONICAL_MESSAGE_MODEL
origin_task_id: TSK-P1-LED-003

## repro_command
- bash scripts/audit/verify_led_003_canonical_message_model.sh

## scope
- Define canonical instruction JSON schema with explicit versioning.
- Enforce schema validation at ingress before persistence.
- Emit verifier-backed evidence for valid, missing-field, and wrong-type cases.

## implementation_steps
1. Add `schema/messages/canonical_instruction_v1.json` with required fields and constraints.
2. Add ingress payload schema validation and fail-closed 400 response (`SCHEMA_VALIDATION_FAILED`).
3. Add LED-003 self-test mode and verifier script that validates evidence integrity.
4. Wire task metadata and contract/registry governance entries.

## verification_commands_run
- bash scripts/audit/verify_led_003_canonical_message_model.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-003 --evidence evidence/phase1/led_003_canonical_message_model.json
