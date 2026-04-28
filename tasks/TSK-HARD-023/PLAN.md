# TSK-HARD-023 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-023

- task_id: TSK-HARD-023
- title: Recipient inheritance enforcement
- phase: Hardening
- wave: 2
- depends_on: [TSK-HARD-022]
- goal: Enforce that the recipient of an adjustment is inherited exclusively from
  the parent instruction. The issue_adjustment() interface does not accept a
  recipient parameter. Any attempt to supply a recipient — directly or via an
  alternate field name — is rejected. This closes the redirect exploit where
  a corrective adjustment could be directed to a different recipient than the
  original instruction.
- required_deliverables:
  - issue_adjustment() interface with recipient parameter removed
  - recipient resolution logic (from parent instruction at execution time)
  - redirect exploit negative-path test
  - tasks/TSK-HARD-023/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_023.json
- verifier_command: bash scripts/audit/verify_tsk_hard_023.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_023.json
- schema_path: evidence/schemas/hardening/tsk_hard_023.schema.json
- acceptance_assertions:
  - issue_adjustment() function/API signature does not contain a recipient,
    payee, beneficiary, or equivalent parameter; verifier confirms this by
    static analysis of the interface definition
  - recipient is resolved at execution time by reading parent instruction's
    recipient field directly — not passed through by the caller
  - any HTTP request body or function call containing a recipient field when
    calling the adjustment endpoint is rejected with a named error
    (e.g. P7504 ADJUSTMENT_RECIPIENT_NOT_PERMITTED)
  - recipient on the produced adjustment record matches parent instruction
    recipient exactly; verified by comparing fields post-execution
  - negative-path test: calling issue_adjustment() with an explicit recipient
    field value different from the parent instruction recipient is rejected
    with P7504; no adjustment record created
  - negative-path test: calling issue_adjustment() with an explicit recipient
    field matching the parent instruction recipient is also rejected with P7504
    (the parameter is not permitted regardless of value)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - recipient accepted as an input parameter => FAIL_CLOSED
  - redirect exploit not blocked (mismatched recipient applied) => FAIL_CLOSED
  - recipient resolved from caller input rather than parent instruction => FAIL_CLOSED
  - negative-path tests absent => FAIL

---
