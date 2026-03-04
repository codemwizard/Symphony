# TSK-HARD-051 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-051

- task_id: TSK-HARD-051
- title: HSM/KMS signing path enforcement
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-050]
- goal: Enforce that all evidence artifact signing operations route through the
  HSM/KMS backend (OpenBao or equivalent). Private keys are non-exportable. The
  signing service supports digest signing (caller supplies hash; HSM signs hash —
  raw payload not transmitted to HSM). Rate limits and caller-level authorization
  are enforced. Every sign operation produces an audit log entry. Completion of
  this task triggers the DEPENDENCY_NOT_READY re-sign sweep for all prior waves.
- required_deliverables:
  - signing service with HSM/KMS backend fully operational
  - digest signing endpoint
  - per-key-class rate limits configured
  - sign audit log
  - DEPENDENCY_NOT_READY re-sign sweep record in EXEC_LOG.md
  - tasks/TSK-HARD-051/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_051.json
- verifier_command: bash scripts/audit/verify_tsk_hard_051.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_051.json
- schema_path: evidence/schemas/hardening/tsk_hard_051.schema.json
- acceptance_assertions:
  - all evidence artifact sign operations route through HSM/KMS backend;
    verifier confirms by audit log inspection — no sign operations appear
    that lack an HSM/KMS audit log entry
  - private keys are non-exportable: no sign operation response contains
    raw key material; verified by inspecting signing service response schema
  - digest signing supported: signing endpoint accepts pre-computed hash and
    returns signature; raw payload path does not transmit full payload to HSM
  - rate limits configured per key class: verifier confirms rate limit config
    exists for each of the four key classes defined in TSK-HARD-050
  - caller-level authorization enforced: signing request authenticated by
    caller identity before key class authorization is checked
  - every sign operation produces an audit log entry containing: caller_id,
    key_id, key_class, artifact_type, digest_hash, timestamp, outcome
  - sign audit log is append-only and independently queryable
  - EXEC_LOG.md includes a re-sign sweep record confirming: (1) all evidence
    artifacts from Waves 1–3 with unsigned_reason=DEPENDENCY_NOT_READY have
    been re-signed, (2) each re-signed artifact has re_sign_timestamp and
    re_sign_key_id populated, (3) original_activation_event_id back-reference
    is present on each re-signed artifact, (4) sweep_completed_timestamp
  - negative-path test: sign operation bypassing HSM (e.g. direct software
    signing call) is blocked and produces rejection evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any sign operation bypasses HSM/KMS => FAIL_CLOSED
  - raw key material returned by signing service => FAIL_CLOSED
  - sign audit log absent or not append-only => FAIL
  - DEPENDENCY_NOT_READY re-sign sweep not completed => FAIL
    (all prior unsigned artifacts must be re-signed before this task closes)
  - re-signed artifact missing back-reference to original event => FAIL
  - negative-path test absent => FAIL

---
