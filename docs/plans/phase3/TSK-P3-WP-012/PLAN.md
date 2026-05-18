# TSK-P3-WP-012 PLAN — Runtime/verifier trust-boundary segregation, artifact exchange contracts, and privilege-separated verification surfaces

Task: TSK-P3-WP-012
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-WP-012.PROOF_FAIL
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

Runtime/verifier trust-boundary segregation, artifact exchange contracts, and
privilege-separated verification surfaces. This task forms a closed proof graph
from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical
runtime/verifier segregation contract required by `P3-SURF-012`, covering
replay-addressable artifact exchange, privilege separation, and anti-trust-collapse
constraints, without importing generic auth redesign, portal workflow, or
external replay package productization semantics.

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
| `docs/architecture/PHASE3_RUNTIME_VERIFIER_SEGREGATION_CONTRACT.md` | CREATE | Canonical runtime/verifier segregation contract |
| `scripts/agent/verify_tsk_p3_wp_012_runtime_verifier_segregation.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_012_runtime_verifier_segregation.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-012/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-012/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into generic auth redesign, portal workflow behavior, or disclosure-packaging semantics** -> STOP
- **If the segregation artifact cannot remain a single canonical boundary contract for P3-SURF-012** -> STOP

---

## Non-Goals

- No generalized application authentication or authorization redesign.
- No external verifier portal behavior or user-facing verifier workflow.
- No authority-scope or COI semantic ownership already assigned to other surfaces.
- No external replay package productization or disclosure packaging.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical runtime/verifier segregation
    artifact exists and is machine-inspectable where inspected.
  - The verifier can prove that the artifact declares replay-addressable
    runtime/verifier boundaries, privilege separation, and anti-trust-collapse
    constraints under the declared scope.
- Limitations:
  - The verifier cannot prove generic authentication or authorization
    behavior.
  - The verifier cannot prove user-facing verifier portal workflows or
    external replay package productization.
  - The verifier cannot prove runtime implementation of failure continuity,
    authority scope, or COI surfaces beyond declared segregation-boundary
    dependencies.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_012_w01] Define one canonical runtime/verifier segregation artifact for replay-addressable artifact exchange and privilege-separated verification surfaces without importing generic auth redesign, portal workflow, or disclosure-packaging semantics.
- [ID tsk_p3_wp_012_w02] Bind the artifact to deterministic boundary declarations for runtime-emitted artifacts, verifier-consumed artifacts, prohibited mutations, and explicit prohibition on shared trust context or runtime-authored verifier proof.
- [ID tsk_p3_wp_012_w03] Add a deterministic verifier that proves the segregation artifact is mechanically inspectable, remains anchored to Wave 3 and Wave 4 substrate truth, and blocks trust-collapse semantics under the declared structural contract.
- [ID tsk_p3_wp_012_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 5 verifier-closure or documentation-closeout scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_wp_012_runtime_verifier_segregation.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_wp_012_runtime_verifier_segregation.sh > evidence/phase3/tsk_p3_wp_012_runtime_verifier_segregation.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-012/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_wp_012_runtime_verifier_segregation.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-012 --evidence evidence/phase3/tsk_p3_wp_012_runtime_verifier_segregation.json

```
