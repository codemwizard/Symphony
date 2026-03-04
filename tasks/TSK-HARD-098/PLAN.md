# TSK-HARD-098 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-098

- task_id: TSK-HARD-098
- title: Penalty defense pack generation
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-095]
- goal: Implement the penalty defense pack generator for regulatory dispute
  scenarios. Given an instruction_id, adjustment_id, or submission_id, the
  generator produces a single signed JSON pack containing the complete evidence
  chain for that entity. The pack contains no raw PII. This is the primary
  artifact used in regulatory penalty proceedings and commercial disputes.
- required_deliverables:
  - defense pack generator script at scripts/tools/generate_penalty_defense_pack.sh
    or equivalent
  - defense pack schema at evidence/schemas/hardening/penalty_defense_pack.schema.json
  - sample defense pack evidence artifact
  - tasks/TSK-HARD-098/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_098.json
- verifier_command: bash scripts/audit/verify_tsk_hard_098.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_098.json
- schema_path: evidence/schemas/hardening/tsk_hard_098.schema.json
- acceptance_assertions:
  - generator accepts as input: instruction_id OR adjustment_id OR submission_id
    (exactly one required; multiple inputs rejected)
  - output is a single signed JSON pack schema-valid against
    penalty_defense_pack.schema.json and containing: pack_id, generated_at,
    signing_key_id, assurance_tier, entity_type, entity_id,
    evidence_artifacts[], instruction_lifecycle_timeline,
    approval_trail (if adjustment), submission_record (if submission),
    verification_results[]
  - pack contains no raw PII: all subject references are pseudonymous tokens
    (from TSK-HARD-040); verifier confirms by scanning pack for any field
    matching known PII patterns
  - pack is signed with key class EASK (TSK-HARD-050) at generation time
  - generator exits non-zero if it cannot produce a complete and schema-valid
    pack; partial packs not permitted
  - verification_results[] in pack contains at least one verification result
    confirming the primary evidence artifact is valid
  - negative-path test: calling generator with unknown entity_id produces
    named error and exits non-zero; no partial pack produced
  - negative-path test: generated pack fails schema validation if pack is
    manually edited (confirming schema enforcement is not bypassed)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - pack contains raw PII => FAIL_CLOSED
  - pack not signed => FAIL_CLOSED
  - generator produces partial pack on incomplete evidence => FAIL_CLOSED
  - pack fails schema validation => FAIL
  - generator exits zero on unknown entity_id => FAIL
  - negative-path tests absent => FAIL

---
