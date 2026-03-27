# REM-2026-03-27 PLAN — Green Finance Wrong-Diagnosis Rollback

Task: REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback
Owner: ARCHITECT
Depends on: GF-W1-GOV-005
failure_signature: PRECI.DB.GF_MIGRATION_GRAPH_WRONG_DIAGNOSIS
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Remove the diagnosis-linked Green Finance artifacts whose correctness depended
on the false assumption that downstream patching was valid. The correct end
state is a clean rollback surface with no ownerless references left behind and
new corrective task packs ready to rebuild the graph in the right order. A
reviewer should be able to inspect the deleted artifact list, the replacement
task packs, and the rollback verification commands and see that the drift has
been reset rather than papered over.

---

## Architectural Context

The defect is a graph-integrity failure: foundational tables were assumed to be
patchable downstream instead of being owned and created before first use. This
remediation prevents three anti-patterns from being ported forward: downstream
patching, numeric-pattern-only rollback, and partial-state success claims. It
must happen before any new Wave 1 schema task is considered ready.

---

## Pre-conditions

- [ ] `GF-W1-GOV-005` is completed and its migration sequence guard remains the repo-wide source of sequence truth.
- [ ] Approval metadata exists for the regulated-surface changes in this remediation wave.
- [ ] The rollback classifier is applied mechanically, not by ad hoc judgment.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/plans/phase1/REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback/PLAN.md` | CREATE | Record rollback contract |
| `docs/plans/phase1/REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback/EXEC_LOG.md` | CREATE | Append-only remediation trace |

---

## Stop Conditions

- **If rollback scope cannot be explained by the mechanical classifier** -> STOP
- **If any deleted artifact leaves an ownerless governed reference behind** -> STOP
- **If the replacement task packs cannot be created without colliding with existing migration numbers** -> STOP
- **If approval scope no longer matches the regulated files touched** -> STOP

---

## Implementation Steps

### Step 1: Remove invalid artifacts
**What:** `[ID rem_gf_wrong_diag_work_item_01]` Delete the diagnosis-linked task packs, stale remediation folders, verifier scripts, and invalid GF migrations created under the wrong assumption.
**How:** Remove only artifacts matched by the rollback classifier and record them in the remediation log.
**Done when:** The known invalid 002-005 task-pack surfaces and GF migrations `0081` through `0084` are absent.

### Step 2: Verify rollback state
**What:** `[ID rem_gf_wrong_diag_work_item_02]` Run rollback checks for artifact absence, ownerless-reference detection, and sequence integrity.
**How:** Use the explicit absence checks plus the graph verifier in pre-rebuild mode.
**Done when:** No removed-object references remain and sequence/head state is still mechanically valid.

### Step 3: Register the replacement path
**What:** `[ID rem_gf_wrong_diag_work_item_03]` Create the corrective remediation and task-pack documentation that supersedes the invalid chain.
**How:** Point the replacement chain at `GF-W1-SCH-002A` and `GF-W1-GOV-005A`, and record the forward-renumbered sequence.
**Done when:** All replacement task packs and DAG docs exist and align.

---

## Verification

```bash
# [ID rem_gf_wrong_diag_work_item_02]
test ! -f schema/migrations/0081_gf_interpretation_packs.sql || exit 1

# [ID rem_gf_wrong_diag_work_item_02]
test ! -f schema/migrations/0082_gf_monitoring_records.sql || exit 1

# [ID rem_gf_wrong_diag_work_item_02]
python3 scripts/audit/verify_migration_reference_order.py --mode pre_rebuild --fail-on-missing-owner || exit 1

# [ID rem_gf_wrong_diag_work_item_02]
python3 scripts/audit/verify_migration_reference_order.py --mode sequence_only || exit 1
```

---

## Evidence Contract

File: `docs/plans/phase1/REM-2026-03-27_gf-wave1-migration-graph-wrong-diagnosis-rollback/EXEC_LOG.md`

Required fields:
- `failure_signature`
- `origin_gate_id`
- `deleted_artifacts`
- `verification_commands_run`
- `final_status`

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Wrong artifact retained after rollback | CRITICAL_FAIL | Use the mechanical rollback classifier and explicit absence checks |
| Replacement sequence collides with existing repo migrations | FAIL | Renumber forward consistently before creating packs |
| Anti-pattern: downstream patching survives in docs or DAG | FAIL_REVIEW | Update all affected Wave 1 docs in the same remediation wave |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`
