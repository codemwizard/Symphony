# TSK-HARD-082 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-082

- task_id: TSK-HARD-082
- title: BoZ/Auditor demonstration pack — six scripted scenarios
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-081]
- goal: Implement the BoZ/Auditor demonstration pack with exactly six scripted,
  deterministic scenarios. Each scenario produces a signed evidence artifact as
  output. Each scenario script exits non-zero if expected evidence is not produced.
  The pack is the primary institutional sales and regulatory demonstration
  instrument.
- required_deliverables:
  - docs/programs/symphony-hardening/BOZ_DEMO_PACK.md
  - six scenario scripts at scripts/demo/scenario_{01..06}.sh or equivalent
  - reproducible signed evidence artifact per scenario
  - tasks/TSK-HARD-082/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_082.json
- verifier_command: bash scripts/audit/verify_tsk_hard_082.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_082.json
- schema_path: evidence/schemas/hardening/tsk_hard_082.schema.json
- acceptance_assertions:
  - BOZ_DEMO_PACK.md exists and describes all six scenarios with: scenario_id,
    title, narrative, seed_inputs, expected_evidence_artifact, script_path
  - exactly six scenario scripts implemented; none may be deferred:
    SCENARIO-01 SILENT_RAIL_CONTAINMENT: rail returns no response; system
      enters inquiry SCHEDULED→SENT→EXHAUSTED; auto-finalization blocked with
      P7301; evidence artifact produced confirming inquiry_state: EXHAUSTED
      and outcome: BLOCKED
    SCENARIO-02 MALFORMED_RESPONSE_CAPTURE: adapter receives known-malformed
      payload; quarantine record created with parser classification and
      truncation applied; evidence artifact produced; confirmed by querying
      quarantine store
    SCENARIO-03 LATE_CALLBACK_HANDLING: callback arrives after instruction
      reaches terminal state; orphaned attestation landing zone record created
      with classification: LATE_CALLBACK; instruction state unchanged; evidence
      artifact produced
    SCENARIO-04 ADJUSTMENT_WITH_LEGAL_HOLD: adjustment instruction submitted;
      AML hold flag active; execution blocked at blocked_legal_hold or
      cooling_off state; evidence artifact produced containing hold_type: AML_HOLD
      and authority_reference
    SCENARIO-05 HISTORICAL_VERIFICATION_ARCHIVE_ONLY: artifact signed under
      previous key version; verified using archived PKA and canonicalization
      archive only; no operational runtime access; signed verification result
      produced containing operational_runtime_used: false
    SCENARIO-06 DR_RECOVERY_CEREMONY: quorum of required authority categories
      accesses offline bundle; ceremony evidence artifact produced with
      participants[], roles[], authority_categories[], access_timestamp;
      isolated environment verification performed and passed
  - each scenario script: (a) accepts seed inputs as parameters for
    determinism, (b) produces a signed evidence artifact as its primary output,
    (c) exits non-zero if the expected evidence artifact is not produced,
    (d) is idempotent: running twice with same seed inputs produces equivalent
    evidence artifacts (same logical outcome, different timestamps permitted)
  - each scenario evidence artifact is schema-valid against the relevant event
    class from TSK-HARD-002 schema set
  - verifier runs all six scenarios and confirms each exits zero and produces
    schema-valid evidence
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - fewer than six scenarios implemented => FAIL
  - any scenario script exits zero when expected evidence not produced => FAIL_CLOSED
  - any scenario evidence artifact not schema-valid => FAIL_CLOSED
  - any scenario not deterministic given same seed inputs => FAIL
  - BOZ_DEMO_PACK.md absent => FAIL

---
