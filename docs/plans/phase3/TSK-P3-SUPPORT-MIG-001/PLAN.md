# TSK-P3-SUPPORT-MIG-001 PLAN — Replay-addressable migration and backfill planning contract

Task: TSK-P3-SUPPORT-MIG-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-MIG-001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Replay-addressable migration and backfill planning contract. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical shared
migration/backfill planning contract required by `TSK-P3-SUPPORT-MIG-001`
across `P3-SURF-001` through `P3-SURF-006`, without importing applied
migration execution, runtime backfill, destructive historical rewrites, or
future-phase migration semantics.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

- [ ] `docs/operations/TASK_ID_NOMENCLATURE.md` reviewed for task-family and wave rules.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.


---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/architecture/PHASE3_REPLAY_MIGRATION_AND_BACKFILL_CONTRACT.md` | CREATE | Canonical shared migration/backfill planning contract |
| `scripts/agent/verify_tsk_p3_support_mig_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_mig_001_migration_contract.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-MIG-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-MIG-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the shared migration artifact cannot remain one additive-only contract across all six owning surfaces** -> STOP
- **If the task expands into applied migration execution, runtime backfill, or destructive historical rewrite semantics** -> STOP
- **If any owning surface requires undeclared ordering, tie-break, or authority-transfer ownership assumptions** -> STOP

---

## Non-Goals

- No applied migration execution, schema edits, or runtime backfill work.
- No destructive historical rewrites or silent semantic compression of prior-wave artifacts.
- No unilateral freezing of migration semantics for one owning surface.
- No local invention of contradiction, failure, authority, or projection doctrine.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical shared migration/backfill
    planning artifact exists and covers all six owning surfaces where
    inspected.
  - The verifier can prove additive-only reconciliation, replay-addressable
    preservation intent, and explicit anti-drift guards against unapproved
    runtime migration scope.
- Limitations:
  - The verifier cannot prove applied migration correctness or runtime
    backfill execution.
  - The verifier cannot prove substantive doctrine correctness for the owning
    surfaces beyond declared migration/backfill obligations.
  - The verifier cannot prove future-phase workflow semantics or downstream
    authority-transfer resolution outcomes beyond declared citation gates.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_mig_001_w01] Define one canonical shared migration and backfill planning artifact for replay-addressable lineage, authority, projection, contradiction, and failure records across P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-004, P3-SURF-005, and P3-SURF-006 without importing applied migration execution, runtime backfill, or destructive historical rewrite semantics.
- [ID tsk_p3_support_mig_001_w02] Bind the artifact to additive-only reconciliation, deterministic replay-equality declaration rules, cross-surface ontology transition constraints, and explicit fixture-equality preservation requirements so later migration work cannot silently alter Wave 1 or Wave 2 meaning.
- [ID tsk_p3_support_mig_001_w03] Add a deterministic verifier that proves the shared migration artifact covers all six owning surfaces, preserves replay-addressable historical truth, and blocks unilateral scope freezing, undeclared ordering assumptions, and unapproved runtime migration drift under the declared structural contract.
- [ID tsk_p3_support_mig_001_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 3 runtime-node scope or future-phase migration semantics.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_support_mig_001.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_support_mig_001.sh > evidence/phase3/tsk_p3_support_mig_001_migration_contract.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-SUPPORT-MIG-001/meta.yml` as the live runtime task-pack source.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_support_mig_001.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-MIG-001 --evidence evidence/phase3/tsk_p3_support_mig_001_migration_contract.json

# 3. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
