# TSK-HARD-074 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-074

- task_id: TSK-HARD-074
- title: Regulator access audit envelope
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-073]
- goal: Implement the regulator-accessible audit envelope that packages signed
  evidence artifacts for regulatory inspection. The regulator role is read-only —
  it cannot mutate any record. Every regulator access event is logged in an
  append-only, signed access log. This is the delivery mechanism for BoZ and
  equivalent regulatory access.
- required_deliverables:
  - regulator audit envelope schema
  - read-only regulator role enforcement
  - access log (append-only, signed)
  - envelope packaging tool
  - tasks/TSK-HARD-074/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_074.json
- verifier_command: bash scripts/audit/verify_tsk_hard_074.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_074.json
- schema_path: evidence/schemas/hardening/tsk_hard_074.schema.json
- acceptance_assertions:
  - regulator audit envelope contains: signed evidence artifacts, access log
    excerpt, package manifest with package_timestamp and signing_key_id
  - regulator role enforced at DB/API layer: any write operation (INSERT,
    UPDATE, DELETE) attempted by a regulator-role session is rejected with
    a named error (e.g. P8301 REGULATOR_WRITE_DENIED)
  - every regulator access event is logged: accessor_id, role, access_timestamp,
    session_id, artifacts_accessed[]
  - access log is append-only: no UPDATE or DELETE on access log entries;
    verified by negative-path test
  - access log is signed at each append: each log entry carries a signature
    or the log is periodically signed as a batch with Merkle proof
  - envelope packaging tool accepts: instruction_id or adjustment_id or date
    range, and produces a single signed package
  - negative-path test: regulator-role session attempting INSERT on any evidence
    table is rejected with P8301
  - negative-path test: UPDATE on access log entry is rejected
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - regulator role can mutate any record => FAIL_CLOSED
  - access log not append-only => FAIL_CLOSED
  - access log entries unsigned or unbatched for > 24h => FAIL
  - envelope produced without signing => FAIL_CLOSED
  - negative-path tests absent => FAIL

---
