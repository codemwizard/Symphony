# TSK-HARD-026 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-026

- task_id: TSK-HARD-026
- title: Approval attribution and role attestation
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-025]
- goal: Record cryptographic role-attestation at the moment of each approval
  signing. Role and department must be captured at signing time — not resolved
  from current user state at query time. Attestation is linked to the specific
  approval stage. This closes the role-spoofing attack where a role change after
  approval could retroactively alter the attestation record.
- required_deliverables:
  - role and department capture at signing time (snapshot, not live lookup)
  - attestation schema extension to approval record
  - signature or signature reference per attestation
  - signing-time capture test
  - tasks/TSK-HARD-026/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_026.json
- verifier_command: bash scripts/audit/verify_tsk_hard_026.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_026.json
- schema_path: evidence/schemas/hardening/tsk_hard_026.schema.json
- acceptance_assertions:
  - each approval record contains: approver_id, role_at_time_of_signing,
    department_at_time_of_signing, attestation_timestamp, signature_ref
  - role_at_time_of_signing and department_at_time_of_signing are populated
    at the moment the approval action is submitted — not resolved lazily
    from a user directory at query time
  - signature_ref links to an evidence artifact signed with key class AAK
    (adjustment attestation key, defined in TSK-HARD-050); if TSK-HARD-050
    is not yet complete, signature_ref is populated with
    unsigned_reason=DEPENDENCY_NOT_READY and updated once TSK-HARD-050 is done
  - attestation record is linked to a specific approval stage_id — not to the
    adjustment_id alone
  - test: changing the approver's role in the user directory after approval
    does not alter role_at_time_of_signing on the historical approval record;
    verified by querying the record before and after the role change
  - negative-path test: approval record without role_at_time_of_signing or
    department_at_time_of_signing fields fails schema validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - role resolved at query time rather than signing time => FAIL_CLOSED
  - role-change-after-approval mutates historical attestation record => FAIL_CLOSED
  - attestation not linked to specific approval stage_id => FAIL
  - signature_ref absent and unsigned_reason not populated => FAIL
  - negative-path test absent => FAIL

---
