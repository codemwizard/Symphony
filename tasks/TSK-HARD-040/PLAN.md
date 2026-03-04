# TSK-HARD-040 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-040

- task_id: TSK-HARD-040
- title: Privacy-preserving audit tokenization
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-098]
- goal: Complete PII vault decoupling. Implement the tokenization scheme that
  maps PII subjects to stable pseudonymous tokens. All evidence artifacts and
  audit tables must contain tokens, not raw PII. Audit query responses return
  tokenized references. The token is stable per subject per audit period.
- required_deliverables:
  - tokenization scheme implementation
  - vault decoupling completion (no raw PII in evidence or audit tables)
  - audit query interface returning tokenized references
  - tasks/TSK-HARD-040/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_040.json
- verifier_command: bash scripts/audit/verify_tsk_hard_040.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_040.json
- schema_path: evidence/schemas/hardening/tsk_hard_040.schema.json
- acceptance_assertions:
  - PII vault decoupling complete: verifier scans all evidence artifact schemas
    and audit table schemas for known PII field names (name, id_number,
    phone, email, account_number equivalents); none present in non-vault tables
  - tokenization scheme: PII subject → pseudonymous token mapping is:
    (a) deterministic: same subject always maps to same token within an
    audit period, (b) one-way: token cannot be reversed without vault access,
    (c) stable per audit period: token does not change within a period even if
    subject details change
  - audit query interface: querying by token returns all evidence artifacts
    for that token; no raw PII returned in query response
  - audit query response includes: token, subject_status (LIVE or PURGED),
    evidence_artifacts[] — the boolean status is returned without revealing identity
  - negative-path test: scanning evidence artifact tables directly (without
    vault) returns no resolvable PII
  - negative-path test: audit query for an unknown token returns empty result
    or NOT_FOUND — not an error that reveals vault internals
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - raw PII present in any evidence artifact or audit table => FAIL_CLOSED
  - token not stable within audit period => FAIL
  - audit query returns raw PII in response => FAIL_CLOSED
  - tokenization reversible without vault access => FAIL_CLOSED
  - negative-path tests absent => FAIL

---
