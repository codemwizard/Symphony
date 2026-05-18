# TSK-P3-WP-013 PLAN — Uncertainty classification, operator-governed propagation, and replay-admissible authority transfer semantics

Task: TSK-P3-WP-013
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-WP-013.PROOF_FAIL
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

Uncertainty classification, operator-governed propagation, and
replay-admissible authority transfer semantics. This task forms a closed proof
graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical uncertainty
semantics contract required by `P3-SURF-013`, covering the seven doctrinal
uncertainty classes, registered-operator constraints, admissibility-safe
finding classes, and replay-visible authority transfer requirements, without
importing methodology execution, industrial ontology, or disclosure behavior.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.
- [ ] `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` reviewed for class semantics.
- [ ] `docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md` reviewed for operator constraints.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/architecture/PHASE3_UNCERTAINTY_AND_ESTIMATION_SEMANTICS_CONTRACT.md` | CREATE | Canonical uncertainty semantics contract |
| `scripts/audit/verify_p3_uncertainty_semantics.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_013_uncertainty_semantics.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-013/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-013/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task imports methodology execution, industrial ontology, or disclosure behavior** -> STOP
- **If the uncertainty artifact cannot remain a single canonical semantics contract for P3-SURF-013** -> STOP

---

## Non-Goals

- No methodology-specific uncertainty computation or propagation execution.
- No industrial carbon ontology or supply-chain graph execution.
- No external disclosure packaging or CBAM runtime behavior.
- No user-facing uncertainty display, dashboards, or analytics.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical uncertainty semantics artifact
    exists and is machine-inspectable where inspected.
  - The verifier can prove that the artifact declares the seven doctrinal
    uncertainty classes, registered-operator constraints, and replay-visible
    authority transfer requirements under the declared scope.
- Limitations:
  - The verifier cannot prove methodology-specific statistical execution or
    propagation runtime.
  - The verifier cannot prove user-facing display, disclosure packaging, or
    future-phase CBAM execution.
  - The verifier cannot prove runtime behavior of consuming surfaces beyond
    declared transfer and admissibility contracts.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_013_w01] Define one canonical uncertainty semantics artifact for seven doctrinal uncertainty classes, admissibility-safe finding categories, and replay-derived authority transfer record requirements without importing methodology execution or industrial ontology semantics.
- [ID tsk_p3_wp_013_w02] Bind the artifact to registered-operator constraints, explicit UNKNOWN_UNCERTAINTY handling, and deterministic transfer-mode declarations for downstream Phase 3 surface handoffs.
- [ID tsk_p3_wp_013_w03] Add a deterministic verifier that proves the artifact is mechanically inspectable, constrained to the doctrinal class/operator set, and explicit about transfer-mode completeness under the declared structural contract.
- [ID tsk_p3_wp_013_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 5 AI governance or documentation-closeout scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_p3_uncertainty_semantics.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_p3_uncertainty_semantics.sh > evidence/phase3/tsk_p3_wp_013_uncertainty_semantics.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-013/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_p3_uncertainty_semantics.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-013 --evidence evidence/phase3/tsk_p3_wp_013_uncertainty_semantics.json

```
