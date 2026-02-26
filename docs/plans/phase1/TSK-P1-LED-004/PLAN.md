# TSK-P1-LED-004 Plan

failure_signature: P1.LED.004.KYC_HASH_BRIDGE_ENDPOINT
origin_task_id: TSK-P1-LED-004

## repro_command
- bash scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh

## scope
- Implement `POST /v1/kyc/hash` endpoint with provider registry enforcement.
- Reject prohibited PII fields fail-closed.
- Ensure retained records are marked `FIC_AML_CUSTOMER_ID`.
- Emit verifier-backed evidence for valid, unknown-provider, and PII-reject scenarios.

## implementation_steps
1. Add KYC hash bridge request parsing and validation with explicit prohibited PII field denial.
2. Add bridge persistence abstractions for file/db modes with provider checks and retention class assignment.
3. Add handler and endpoint wiring for `/v1/kyc/hash`.
4. Add LED-004 self-test mode and verifier evidence validation script.

## verification_commands_run
- bash scripts/audit/verify_led_004_kyc_hash_bridge_endpoint.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-004 --evidence evidence/phase1/led_004_kyc_hash_bridge_endpoint.json
