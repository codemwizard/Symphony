# TSK-P2-W8-GOV-001 PLAN - Wave 8 governance truth repair

Task: TSK-P2-W8-GOV-001
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_GOV_001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Repair Wave 8 governance truth so later task packs inherit one authoritative
closure rubric, one admissibility policy, and one explicit list of fake-proof
patterns that cannot satisfy closure.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `governance control plane`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Intent

This is the control-plane repair task for Wave 8. It revokes fake completion,
anchors the approved `asset_batches` boundary, and makes proof-integrity
admissibility part of closure law before any runtime completion claim is
accepted.

## Dependencies

None

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `docs/governance/WAVE8_GOVERNANCE_REMEDIATION_ADR.md` | CREATE | Governance truth anchor |
| `docs/governance/WAVE8_TASK_STATUS_MATRIX.md` | CREATE | Evidence-backed artifact classification |
| `docs/governance/WAVE8_FALSE_COMPLETION_REVOCATION_LEDGER.md` | CREATE | Fake-completion revocation |
| `docs/governance/WAVE8_MIGRATION_HEAD_TRUTH_TABLE.md` | CREATE | Migration-head truth anchor |
| `docs/governance/WAVE8_CLOSURE_RUBRIC.md` | CREATE | Closure law |
| `docs/governance/WAVE8_PROOF_INTEGRITY_THREAT_REGISTER.md` | CREATE | Threat register |
| `docs/governance/WAVE8_EVIDENCE_ADMISSIBILITY_POLICY.md` | CREATE | Admissibility law |
| `docs/governance/WAVE8_FALSE_COMPLETION_PATTERN_CATALOG.md` | CREATE | Explicit fake-proof catalog |
| `docs/tasks/PHASE2_TASKS.md` | MODIFY | Register closure track |

## Work Items

### Step 1
**What:** [ID w8_gov_001_work_01] Produce a governance remediation ADR that states Wave 8 completion is measured only at the authoritative `asset_batches` boundary and that contract documents outrank implementation drift.
**Done when:** [ID w8_gov_001_work_01] A governance ADR exists and explicitly states that contracts define Wave 8 semantics while SQL executes them at the `asset_batches` boundary.

### Step 2
**What:** [ID w8_gov_001_work_02] Create a corrected Wave 8 task status matrix and false-completion revocation ledger that classify existing `TSK-P2-REG-*` and legacy `TSK-P2-W8-CRYPTO-*` artifacts as scaffold, partial, or true-complete with evidence basis.
**Done when:** [ID w8_gov_001_work_02] The corrected status matrix and revocation ledger classify the legacy Wave 8 artifacts using evidence-backed categories rather than inherited status text.

### Step 3
**What:** [ID w8_gov_001_work_03] Create a migration-head truth table and authoritative Wave 8 closure rubric that bind future task creation to the approved DoD control surface.
**Done when:** [ID w8_gov_001_work_03] The migration-head truth table and closure rubric explicitly name `asset_batches` as the sole authoritative Wave 8 boundary.

### Step 4
**What:** [ID w8_gov_001_work_04] Produce a proof-integrity threat register, evidence admissibility policy, and false-completion pattern catalog that explicitly ban detached function proof, grep proof, reflection-only surface proof, toy-crypto proof, garbage-payload matrix fraud, fake crypto behind real trigger wiring, superuser-only success, and mirrored-vector fraud.
**Done when:** [ID w8_gov_001_work_04] The threat register, evidence admissibility policy, and false-completion pattern catalog exist and explicitly ban the named inadmissible proof patterns.

### Step 5
**What:** [ID w8_gov_001_work_05] Register the governance artifacts in the Phase 2 task index and execution log, and explicitly mark old `TSK-P2-W8-DB-007` as superseded by `007a/007b/007c`.
**Done when:** [ID w8_gov_001_work_05] The Phase 2 index references the Wave 8 closure track and governance artifacts explicitly state that unsplit `W8-DB-007` is non-executable for closure.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_gov_001.py > evidence/phase2/tsk_p2_w8_gov_001.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-GOV-001/PLAN.md --meta tasks/TSK-P2-W8-GOV-001/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_gov_001.json`

Required proof fields:
- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `checks`
- `observed_paths`
- `observed_hashes`
- `command_outputs`
- `execution_trace`

## Approval and Trace

- Stage A approval metadata is required before regulated-surface edits.
- `EXEC_LOG.md` is append-only and must carry remediation trace markers.
