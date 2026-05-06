# REMEDIATION PLAN

Canonical-Reference: docs/operations/REMEDIATION_TRACE_WORKFLOW.md

failure_signature: CRYPTO.ED25519.SIGNATURE_FORMAT_REGRESSION

origin_task_id: TSK-P2-W8-DB-006

origin_gate_id: code_review

repro_command: grep -n -A 2 -B 2 "signature.*hex.*64" schema/migrations/*.sql

verification_commands_run: pending

final_status: OPEN

## Scope

**In-scope:**
- Signature validation logic in migration
- Ed25519 signature format enforcement
- Cryptographic contract compliance

**Out-of-scope:**
- Other cryptographic validations
- Non-cryptographic schema changes

## Initial Hypotheses

1. Validator incorrectly assumes 64 hex characters for Ed25519 signatures
2. Ed25519 signatures are actually 64 bytes = 128 hex characters
3. Current validation rejects legitimate signatures
4. Need to verify against Ed25519 signing contract specification

## Derived Tasks

- TSK-P2-W8-DB-006-REM-04: Fix signature validation to accept 128 hex characters
- TSK-P2-W8-DB-006-REM-05: Add Ed25519 test vectors to validation suite
- TSK-P2-W8-DB-006-REM-06: Verify all cryptographic validations against contracts

## Risk Assessment

**Criticality:** HIGH - Breaks cryptographic enforcement for valid signatures
**Blast Radius:** Ed25519 signature validation and asset_batches dispatcher
**Dependencies:** Ed25519 signing contract reference
