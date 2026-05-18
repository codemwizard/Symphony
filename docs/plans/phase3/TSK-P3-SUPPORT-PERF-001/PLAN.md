# TSK-P3-SUPPORT-PERF-001 PLAN — Deterministic traversal, spatial, and projection scale bounds

Task: TSK-P3-SUPPORT-PERF-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-PERF-001.PROOF_FAIL
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

Deterministic traversal, spatial, and projection scale bounds. This task forms
a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the shared deterministic
scale-bound contract required by `TSK-P3-SUPPORT-PERF-001`, covering traversal,
projection, and spatial evaluation limits across the owning surfaces, without
importing infrastructure tuning, deployment optimization, runtime product
performance work, or runtime implementation of the owning surfaces.

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
| `docs/architecture/PHASE3_DETERMINISTIC_SCALE_BOUND_CONTRACT.md` | CREATE | Canonical shared scale-bound contract |
| `scripts/agent/verify_tsk_p3_support_perf_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_perf_001_scale_bounds.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-PERF-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-PERF-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into infrastructure tuning, deployment optimization, or runtime product performance work** -> STOP
- **If the shared scale-bound artifact cannot remain additive-only across all three owning surfaces** -> STOP

---

## Non-Goals

- No infrastructure tuning.
- No deployment optimization.
- No runtime product performance work.
- No runtime implementation of lineage, projection, spatial, or temporal surfaces.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one shared deterministic scale-bound artifact
    exists and is machine-inspectable where inspected.
  - The verifier can prove that the artifact covers all three owning surfaces
    and preserves replay-safe deterministic bound declarations.
- Limitations:
  - The verifier cannot prove runtime performance or infrastructure tuning
    outcomes, because this task is planning-only.
  - The verifier cannot prove runtime implementation of the owning surfaces.
  - The verifier cannot prove substantive doctrine correctness beyond declared
    scale-bound contract coverage.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_perf_001_w01] Define one canonical shared deterministic scale-bound artifact for traversal, projection, and spatial evaluation across P3-SURF-001, P3-SURF-003, and P3-SURF-009 without importing infrastructure tuning, deployment optimization, or runtime product performance semantics.
- [ID tsk_p3_support_perf_001_w02] Bind the artifact to additive-only reconciliation, deterministic bound declarations, bounded-nondeterministic guardrails where applicable, and explicit prohibition on weakening replay guarantees or mutating admissibility outcomes.
- [ID tsk_p3_support_perf_001_w03] Add a deterministic verifier that proves the shared scale-bound artifact covers all three owning surfaces, remains replay-safe, and blocks infrastructure-optimization drift under the declared structural contract.
- [ID tsk_p3_support_perf_001_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 4 runtime-node scope or future-phase performance semantics.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_support_perf_001.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_support_perf_001.sh > evidence/phase3/tsk_p3_support_perf_001_scale_bounds.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-SUPPORT-PERF-001/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_support_perf_001.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-PERF-001 --evidence evidence/phase3/tsk_p3_support_perf_001_scale_bounds.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-SUPPORT-PERF-001
```
