# LEDGER-002 PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Task: LEDGER-002
Failure Signature: PHASE2.LEDGER.002.INTERNAL_PROOF_SCOPE_DRIFT

## Scope
- Implement internal zero-sum proof jobs over posting sets.
- Implement posting idempotency verifier jobs.
- Implement tenant-scope proof queries and no-cross-tenant posting checks.
- Keep evidence generation tied to the current internal evidence format only.

## Design Reference
- docs/architecture/adrs/ADR-0002-ledger-immutability-reconciliation.md

## Explicitly Allowed In This Task
- zero-sum proof jobs
- posting idempotency verifier jobs
- tenant-scope proof queries
- no-cross-tenant posting checks
- evidence-generation internals tied to the current internal format

## Explicitly Blocked In This Task
- external verification artifact canonicalization
- legal-hold precedence semantics
- broader regulatory correction authority semantics
- final production signing/export chain
- regulator-facing attested truth exports

## Acceptance Criteria
- Zero-sum proof jobs execute deterministically against posting sets and emit machine-readable pass or fail output.
- Posting idempotency verifiers fail on replay and duplicate-submission fixture cases.
- Tenant-scope proof queries reject cross-tenant access and produce fail-closed results.
- No-cross-tenant posting checks are enforced by verifiers and covered by negative tests.
- Evidence JSON is emitted at `evidence/phase2/ledger_002_internal_proof_jobs.json`, `evidence/phase2/ledger_002_posting_idempotency.json`, and `evidence/phase2/ledger_002_tenant_scope_checks.json`.
- No blocked Lane B scope appears in implementation artifacts for this task.

## Verification Commands
- `test -x scripts/db/verify_ledger_zero_sum.sh`
- `test -x scripts/db/verify_posting_idempotency.sh`
- `test -x scripts/db/verify_no_cross_tenant_postings.sh`
- `bash scripts/db/verify_ledger_zero_sum.sh`
- `bash scripts/db/verify_posting_idempotency.sh`
- `bash scripts/db/verify_no_cross_tenant_postings.sh`
- `python3 scripts/audit/validate_evidence.py --task LEDGER-002 --evidence evidence/phase2/ledger_002_internal_proof_jobs.json`
- `python3 scripts/audit/validate_evidence.py --task LEDGER-002 --evidence evidence/phase2/ledger_002_posting_idempotency.json`
- `python3 scripts/audit/validate_evidence.py --task LEDGER-002 --evidence evidence/phase2/ledger_002_tenant_scope_checks.json`
