# TSK-HARD-096 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-096

- task_id: TSK-HARD-096
- title: Assurance tier disclosure evidence
- phase: Hardening
- wave: 4
- depends_on: [TSK-HARD-011B]
- goal: Establish the assurance tier taxonomy and enforce that every signed evidence
  artifact carries an assurance_tier field populated by the signing service.
  The tier field discloses whether signing was HSM-backed, software-backed, or
  involved a DEPENDENCY_NOT_READY interim state. Retroactively update all
  re-signed artifacts from prior waves with the correct tier value.
- required_deliverables:
  - assurance tier taxonomy document at docs/architecture/ASSURANCE_TIER_TAXONOMY.md
  - assurance_tier field enforced in signing service output
  - tier value validation in evidence schema
  - retroactive tier assignment for re-signed artifacts from prior waves
  - tasks/TSK-HARD-096/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_096.json
- verifier_command: bash scripts/audit/verify_tsk_hard_096.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_096.json
- schema_path: evidence/schemas/hardening/tsk_hard_096.schema.json
- acceptance_assertions:
  - assurance tier taxonomy defines at minimum three tiers: HSM_BACKED,
    SOFTWARE_BACKED, DEPENDENCY_NOT_READY; taxonomy document identifies
    which tier applies to which signing path
  - every signed evidence artifact produced from this task forward contains
    assurance_tier field with one of the defined tier values
  - assurance_tier field is populated by the signing service — not self-reported
    by the caller; signing service determines tier from key backend type
  - disclosure test: artifact produced via HSM path carries assurance_tier:
    HSM_BACKED; artifact produced via software path carries
    assurance_tier: SOFTWARE_BACKED
  - EXEC_LOG.md includes a retroactive tier assignment record: all re-signed
    artifacts from Waves 1–3 (which were previously marked
    unsigned_reason=DEPENDENCY_NOT_READY) must now have assurance_tier field
    populated with the correct tier value; sweep_completed_timestamp recorded
  - artifacts from prior waves with assurance_tier: PENDING_TIER_ASSIGNMENT
    (stub from TSK-HARD-052) are updated to their correct tier value
  - taxonomy document is informational; schema in evidence/schemas/hardening/
    is the enforcement surface; docs mirror not gating
  - negative-path test: artifact from HSM path that claims
    assurance_tier: SOFTWARE_BACKED fails signing service internal validation
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - assurance_tier absent from any signed artifact produced after this task => FAIL
  - tier self-reported by caller rather than set by signing service => FAIL_CLOSED
  - taxonomy not documented => FAIL
  - retroactive sweep not completed for prior-wave artifacts => FAIL
  - PENDING_TIER_ASSIGNMENT stubs remaining after this task closes => FAIL
  - negative-path test absent => FAIL

---
