# TSK-P3-WP-011 PLAN — Verifier suite, CI wiring, evidence expectations, negative tests, invariant-to-verifier registry, capability-boundary contamination tests, and invariant promotion protocol

Task: TSK-P3-WP-011
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-WP-011.PROOF_FAIL
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

Verifier suite, CI wiring, evidence expectations, negative tests,
invariant-to-verifier registry, capability-boundary contamination tests, and
invariant promotion protocol. This task forms a closed proof graph from work
items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical
verifier-closure and CI contract required by `P3-SURF-011`, covering exhaustive
Phase 3 invariant disposition, blocking CI semantics, evidence expectations,
negative-test expectations, and contamination-check obligations, without
importing runtime/verifier segregation implementation or local doctrine
invention.

This closure scope includes the post-merge uncertainty and AI governance
invariants `INV-311`, `INV-312`, and `INV-313` in addition to the original
`INV-301` through `INV-310` set.

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
| `docs/architecture/PHASE3_VERIFIER_CLOSURE_AND_CI_CONTRACT.md` | CREATE | Canonical verifier-closure contract |
| `scripts/agent/verify_tsk_p3_wp_011_verifier_ci_closure.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_wp_011_verifier_ci_closure.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-WP-011/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-WP-011/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task imports runtime/verifier segregation implementation, local doctrine invention, or user-facing workflow semantics** -> STOP
- **If the verifier-closure artifact cannot remain a single canonical closure contract for P3-SURF-011** -> STOP

---

## Non-Goals

- No doctrine creation by verifier or CI configuration.
- No runtime/verifier trust-boundary implementation owned by `P3-SURF-012`.
- No user-facing documentation, workflow UX, or operator console behavior.
- No reinterpretation of lineage, projection, contradiction, failure, authority, regulator, COI, spatial, or temporal semantics.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical verifier-closure artifact exists
    and is machine-inspectable where inspected.
  - The verifier can prove that the artifact exhaustively dispositions the
    enforceable Phase 3 invariants and declares blocking CI, evidence, and
    negative-test posture under the declared scope.
- Limitations:
  - The verifier cannot prove runtime implementation correctness of the
    previously created Phase 3 surfaces.
  - The verifier cannot prove runtime/verifier segregation mechanics beyond
    consuming the declared `P3-SURF-012` boundary contract.
  - The verifier cannot prove user-facing documentation or workflow behavior.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_wp_011_w01] Define one canonical verifier-closure artifact for exhaustive invariant-to-verifier disposition, blocking CI semantics, evidence expectations, negative-test expectations, and contamination-check obligations without importing runtime/verifier segregation implementation or local doctrine invention.
- [ID tsk_p3_wp_011_w02] Bind the artifact to an explicit disposition model where every enforceable Phase 3 invariant is verifier-covered, constitutionally exempted, or formally deferred with justification, and where invariant promotion remains evidence-backed rather than prose-backed.
- [ID tsk_p3_wp_011_w03] Add a deterministic verifier that proves the closure artifact is mechanically inspectable, exhaustive over the Phase 3 invariant set, and explicit about CI blocking posture and capability-boundary contamination checks under the declared structural contract.
- [ID tsk_p3_wp_011_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 5 segregation or documentation-closeout scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_wp_011_verifier_ci_closure.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_wp_011_verifier_ci_closure.sh > evidence/phase3/tsk_p3_wp_011_verifier_ci_closure.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-WP-011/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_wp_011_verifier_ci_closure.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-WP-011 --evidence evidence/phase3/tsk_p3_wp_011_verifier_ci_closure.json

```
