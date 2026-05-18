# TSK-P3-SUPPORT-DOC-001 PLAN — Implementation references, replay specifications, and operator-neutral documentation

Task: TSK-P3-SUPPORT-DOC-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-DOC-001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any regulated file without prior approval metadata.
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

Implementation references, replay specifications, and operator-neutral
documentation. This task forms a closed proof graph from work items to
acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical
operator-neutral implementation reference required by `TSK-P3-SUPPORT-DOC-001`,
covering replay specifications and implementation handoff across the completed
Phase 3 surface set, without importing doctrine authoring, workflow UX,
marketing, or operator-console semantics.

The completed Phase 3 surface set now includes the uncertainty semantics
surface `P3-SURF-013` and the advisory-only AI governance addition routed
through `TSK-P3-GOV-005`.

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
| `docs/architecture/PHASE3_OPERATOR_NEUTRAL_IMPLEMENTATION_REFERENCE.md` | CREATE | Canonical operator-neutral implementation reference |
| `scripts/agent/verify_tsk_p3_support_doc_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_doc_001_operator_neutral_docs.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-DOC-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-DOC-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task introduces doctrine authoring, semantic reinterpretation, workflow UX, marketing, or operator-console semantics** -> STOP
- **If the documentation artifact cannot remain a single operator-neutral additive closeout reference across the completed Phase 3 surface set** -> STOP

---

## Non-Goals

- No doctrine authoring or constitutional reinterpretation.
- No verifier-semantic supersession.
- No marketing material or external disclosure content.
- No user-facing workflow UX or operator-console guidance.
- No implementation ownership of Wave 5 segregation, uncertainty semantics, AI
  governance, or verifier-closure mechanics.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical operator-neutral implementation
    reference exists and is machine-inspectable where inspected.
  - The verifier can prove that the artifact stays descriptive-only and
    additive over the completed Phase 3 surface set under the declared scope.
- Limitations:
  - The verifier cannot prove runtime implementation correctness of any Phase 3
    surface.
  - The verifier cannot prove user-facing workflow guidance, operator-console
    behavior, or external disclosure suitability.
  - The verifier cannot prove doctrine correctness beyond checking that the
    artifact does not locally invent or supersede semantics.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_doc_001_w01] Define one canonical operator-neutral implementation-reference artifact for replay specifications and implementation handoff across the completed Phase 3 surface set without importing doctrine authoring, marketing, workflow UX, or operator-console semantics.
- [ID tsk_p3_support_doc_001_w02] Bind the artifact to descriptive-only documentation rules so it may describe but may not introduce, reinterpret, or supersede constitutional, implementation, or verifier semantics.
- [ID tsk_p3_support_doc_001_w03] Add a deterministic verifier that proves the documentation artifact is mechanically inspectable, additive over prior Wave 1 through Wave 5 truth including the uncertainty and AI governance additions, and blocks doctrine/UX drift under the declared structural contract.
- [ID tsk_p3_support_doc_001_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 5 segregation, uncertainty, AI governance, or verifier-closure implementation scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_support_doc_001.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_support_doc_001.sh > evidence/phase3/tsk_p3_support_doc_001_operator_neutral_docs.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-SUPPORT-DOC-001/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_support_doc_001.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-DOC-001 --evidence evidence/phase3/tsk_p3_support_doc_001_operator_neutral_docs.json

```
