# TSK-P2-PREAUTH-004-01

## Objective
Create policy_decisions table enforcing execution binding, entity binding, and cryptographic integrity.

## Architectural Context
This table represents the authoritative decision layer required for state transitions.

## Determinism Contract
decision_hash = sha256(canonical_json(payload))  
signature = ed25519_sign(decision_hash)

## Pre-Conditions
MIGRATION_HEAD must be 0133

## Files to Change
- schema/migrations/0134_policy_decisions.sql
- scripts/audit/verify_policy_decisions_schema.sh

## Implementation Steps
1. Create table with required fields
2. Add FK to execution_records
3. Add NOT NULL constraints
4. Add UNIQUE(execution_id, decision_type)
5. Add append-only trigger

## Acceptance Criteria
- Table exists
- Constraints enforced
- FK enforced

## Verification
- psql schema checks
- verifier script
- CI gates

## Negative Tests
- NULL execution_id → fail
- NULL signature → fail

## Evidence Contract
evidence/phase2/tsk_p2_preauth_004_01.json

## Rollback
DROP TABLE policy_decisions

## Risks
Incorrect binding allows authority replay

## Approval
Required

failure_signature: PRE-PHASE2.W4.TSK-P2-PREAUTH-004-01.MIGRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md