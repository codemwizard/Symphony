# TSK-P2-W8-ARCH-005 PLAN - System design patch for authoritative trigger model

Task: TSK-P2-W8-ARCH-005
Owner: ARCHITECT
failure_signature: P2.W8.TSK_P2_W8_ARCH_005.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Patch the system design so Wave 8 has one dispatcher-trigger model, one authoritative boundary, and one fail-closed control narrative.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `authoritative trigger model`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Scope Discipline

- This task is invalid if it expands into more than one primary enforcement domain.
- If implementation reveals a second enforcement domain, stop and create a follow-on pack.
- No completion credit is permitted unless the artifacts or behavior declared here are fully delivered.

## Intent

This task removes topology ambiguity before runtime work starts and records the no-credit and no-fallback rules inside the architecture layer itself.

## Dependencies

TSK-P2-W8-ARCH-002, TSK-P2-W8-ARCH-003, TSK-P2-W8-ARCH-004

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md` | CREATE | Deliver or update the task-controlled artifact |
| `scripts/agent/verify_tsk_p2_w8_arch_005.py` | CREATE | Deliver or update the task-controlled artifact |
| `evidence/phase2/tsk_p2_w8_arch_005.json` | CREATE | Deliver or update the task-controlled artifact |

## Stop Conditions

- Stop if the work expands beyond `authoritative trigger model`.
- Stop if approval metadata is missing for a regulated-surface edit.
- Stop if the verifier path cannot be tied directly to the work-item IDs below.
- Stop if evidence cannot satisfy `TSK-P1-240` proof-carrying fields.

## Work Items

### Step 1
**What:** [ID w8_arch_005_work_01] Patch the system design to name `asset_batches` as the sole authoritative Wave 8 boundary and to state explicitly that contracts define semantics while SQL executes them.
**Done when:** [ID w8_arch_005_work_01] `DATA_AUTHORITY_SYSTEM_DESIGN.md` explicitly names `asset_batches` as the sole authoritative Wave 8 boundary and distinguishes contract authority from SQL runtime execution.

### Step 2
**What:** [ID w8_arch_005_work_02] Patch the design to require one dispatcher trigger, explicit cross-table equality invariants, and zero lexical trigger-order reliance.
**Done when:** [ID w8_arch_005_work_02] The design explicitly requires one dispatcher trigger and explicit equality invariants instead of emergent trigger behavior.

### Step 3
**What:** [ID w8_arch_005_work_03] Patch the design to record the no-credit rule, no advisory fallback rule, and unavailable-crypto hard-fail rule.
**Done when:** [ID w8_arch_005_work_03] The design explicitly records no-credit, no advisory fallback, and unavailable-crypto hard-fail rules.

## Verification

```bash
python3 scripts/agent/verify_tsk_p2_w8_arch_005.py > evidence/phase2/tsk_p2_w8_arch_005.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-ARCH-005/PLAN.md --meta tasks/TSK-P2-W8-ARCH-005/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_arch_005.json`

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
