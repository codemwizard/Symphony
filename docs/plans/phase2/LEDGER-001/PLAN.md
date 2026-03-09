# LEDGER-001 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Task: LEDGER-001
Failure Signature: PHASE2.LEDGER.001.INTERNAL_MODEL_SCOPE_DRIFT

## Scope
- Define the internal posting-set model for accounting truth.
- Define event taxonomy and compensation model.
- Define escrow, freeze, and FX schema required for internal accounting semantics.
- Register invariants and verifier seams for zero-sum, idempotency, tenant scope, and
  no-cross-tenant posting constraints.

## Evidence Output
- `evidence/phase2/ledger_001_internal_model.json`

## Explicitly Out of Scope
- external verification artifact canonicalization
- legal-hold precedence semantics
- broader regulatory correction authority semantics
- final production signing/export chain assumptions
- regulator-facing attested truth exports

## Verification Commands
- `bash scripts/audit/verify_ledger_internal_model.sh`
- `python3 scripts/audit/validate_evidence.py --task LEDGER-001 --evidence evidence/phase2/ledger_001_internal_model.json`
