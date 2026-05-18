# REM-2026-05-17 Phase 3 Task-Pack Stubbed Verification And Status Drift

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PHASE3.TASK_PACK.STUBBED_VERIFICATION_AND_STATUS_DRIFT
first_observed_utc: 2026-05-17T00:00:00Z
where: Phase 3 CREATE-TASK output review across Waves 1 through 5
origin_gate_id: create_task.phase3.wave1_wave5_integrity
repro_command: bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>
scope_boundary: document and remediate the systemic Phase 3 task-pack creation failure affecting all created Wave 1 through Wave 5 task packs; do not begin implementation from the affected packs until the process-level and pack-level repairs are approved and applied
initial_hypotheses:
  - the Phase 3 CREATE-TASK workflow emitted scaffold-style verifier entries that are structurally valid but operationally inert
  - the current readiness and schema checks validate task-pack structure without proving executable verifier truth or deliverable existence
  - planning truth surfaces were advanced to tasks-created without a mechanically enforced status-semantic reconciliation with task meta truth

## Problem Summary

This remediation casefile records a systemic failure in the Phase 3 task-pack
creation process. The issue is not confined to one task. It affects every
Phase 3 Wave 1 through Wave 5 task pack created in this sequence, including
Wave 4 and Wave 5.

The affected task packs present a false readiness posture:

- the primary task-specific verifier entry is stubbed as a quoted shell comment
  rather than an executable command
- `tasks/<TASK_ID>/meta.yml` still records `status: planned`
- planning truth surfaces were promoted to `tasks-created`
- implementation deliverables such as migrations, verifier scripts, contract
  docs, and evidence files do not yet exist

The result is a structurally valid scaffold set that was described too
strongly as readiness-valid for downstream execution. The packs are planning
and scaffolding artifacts, not implementation-complete or execution-ready
artifacts.

The missing deliverables are not, by themselves, the defect. They are normal
before `IMPLEMENT-TASK`. The true defect is that the workflow did not separate:

- planning truth
- task-packed truth
- `resume-ready` truth
- completed implementation truth

## Affected Scope

All 21 created Phase 3 Wave 1 through Wave 5 task packs are affected.

### Wave 1

- `TSK-P3-WP-001`
- `TSK-P3-WP-002`
- `TSK-P3-SUPPORT-CONTRACT-001`
- `TSK-P3-SUPPORT-DB-001`
- `TSK-P3-SUPPORT-SEC-001`

### Wave 2

- `TSK-P3-WP-003`
- `TSK-P3-SUPPORT-VERSION-001`
- `TSK-P3-WP-006`
- `TSK-P3-SUPPORT-FIXTURE-001`

### Wave 3

- `TSK-P3-WP-004`
- `TSK-P3-WP-005`
- `TSK-P3-SUPPORT-MIG-001`

### Wave 4

- `TSK-P3-WP-007`
- `TSK-P3-WP-008`
- `TSK-P3-WP-009`
- `TSK-P3-WP-010`
- `TSK-P3-SUPPORT-OBS-001`
- `TSK-P3-SUPPORT-PERF-001`

### Wave 5

- `TSK-P3-WP-012`
- `TSK-P3-WP-011`
- `TSK-P3-SUPPORT-DOC-001`

For every affected pack, the same three true defects are present:

- the primary verifier contract is stubbed or commented
- task meta status remains `planned`
- planning truth surfaces overstate the pack's implementation readiness

Deliverable absence is a normal pre-implementation condition, but it became
misleading because the process did not distinguish scaffold-only from
implementation-ready states.

## Final Root Cause

The root cause is a combined process and truth-reconciliation failure in the
Phase 3 `CREATE-TASK` workflow:

- the generated or author-copied verification pattern allowed the first
  task-specific verifier entry to be emitted as a quoted shell comment rather
  than an executable verifier command
- the post-creation validation path proved schema and structural readiness but
  did not prove that the declared verifier contract was executable or that the
  verifier would emit the declared evidence artifact
- planning truth surfaces were advanced to `tasks-created` without a
  mechanically defined and enforced relationship to `meta.yml status`
- no current guard rejects the combination of inert verifier command,
  `meta.yml status: planned`, and missing implementation deliverables

## Final Solution Summary

- update the planning-to-task workflow so it distinguishes:
  - planned
  - task-packed
  - `resume-ready`
  - completed
- redefine existing Phase 3 `tasks-created` truth surfaces to mean task-packed,
  not implementation-ready
- strengthen the task-pack readiness gate so commented or inert primary
  verifier contracts fail closed
- strengthen the task runner so commented or inert verifier commands are
  rejected during execution bootstrap
- fix the task generator so new task packs emit executable primary verifier
  contracts and enter the task-packed state model directly
- reconcile all 21 affected Phase 3 Wave 1 through Wave 5 task packs by:
  - changing `status: planned` to `status: ready`
  - removing the quoted-comment prefix from the primary verifier contract

## Impact

- `tasks-created` currently overstates the real state of the 21 affected
  Phase 3 task packs
- no affected task may safely enter `RESUME-TASK` or `IMPLEMENT-TASK` from its
  current pack state
- Wave 4 and Wave 5 are not exceptions; they are affected by the same failure
  pattern as Waves 1 through 3
- the defect is at the task-pack creation and promotion layer; the Wave plans
  and CAP plans remain planning artifacts and are not themselves invalidated by
  this remediation

## Required Remediation Path

### Workflow Placement

The remediation must land inside the existing repo ladder rather than as a side
process:

`broad wave plan -> CAP plan -> CREATE-TASK -> RESUME-TASK -> IMPLEMENT-TASK -> evidence`

The required changes belong at these exact transition points:

- `CREATE-IMPLEMENTATION-PLAN`
  - planning artifacts may nominate task candidates but must not imply
    implementation readiness
- planning-to-task handoff
  - the node must be eligible for `CREATE-TASK`
- `CREATE-TASK`
  - the task pack becomes **task-packed** only when meta, plan, log, and a
    real verifier contract exist
- `RESUME-TASK`
  - the task-packed unit becomes `resume-ready` only after readiness, blocker,
    and verifier-contract checks pass
- `IMPLEMENT-TASK`
  - deliverables are created and evidence is emitted here, not during
    `CREATE-TASK`

### Process-Level Fixes

These must be approved before further Phase 3 task creation continues:

- add a mechanical guard that rejects commented, quoted-comment, placeholder,
  or otherwise non-executable verifier commands in `meta.yml`
- define and enforce consistent status semantics across:
  - `tasks/<TASK_ID>/meta.yml`
  - `docs/PHASE3/PHASE3_TASK_DAG.md`
  - `docs/PHASE3/phase3_task_dag.yml`
  - `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md`
  - `docs/PHASE3/phase3_task_registry.yml`
- add a mechanical distinction between:
  - planned
  - task-packed
  - `resume-ready`
  - completed
- keep `tasks-created` as the existing Phase 3 truth-surface label, but define
  it explicitly as `task-packed` rather than implementation-ready
- require the primary verifier contract to be executable and to write the
  declared evidence artifact
- add durable lessons-learned or task-creation guidance updates so this
  failure mode cannot be silently repeated

### Pack-Level Fixes

These must be applied to all 21 affected task packs:

- replace the stubbed primary verifier entry with a real executable verifier
  contract so the pack may truthfully be treated as task-packed
- reconcile `meta.yml` status with the intended planning state and repo-wide
  status semantics
- update human-readable plan/log language where necessary so scaffolding is not
  described as implementation proof
- prevent any affected pack from being treated as `resume-ready` or
  implementation-ready until:
  - the verifier exists and is executable
  - the verifier writes the declared evidence artifact
  - normal `RESUME-TASK` dependency and blocker checks pass

### Derived Remediation Work

This remediation will likely require multiple derived tasks rather than one
large patch:

- one process-fix task for generator, gates, and readiness policy
- one or more Phase 3 reconciliation tasks for the 21 affected packs
- additional split tasks if regulated surfaces or agent-surface boundaries
  require separate ownership

## Stop Conditions

- stop all `IMPLEMENT-TASK` work for the 21 affected Phase 3 Wave 1 through
  Wave 5 task packs until remediation is approved and applied
- stop further Phase 3 `CREATE-TASK` work until the process-level fix is
  approved
- do not treat prior “readiness-valid” language for these packs as proof of
  executable implementation readiness
- preserve the existing Wave and CAP planning artifacts as planning truth; this
  remediation targets task-pack creation and promotion semantics only

## Acceptance Criteria For Remediation

The remediation is complete only when:

- a repo-wide audit over the 21 affected task packs finds no stubbed or
  commented primary verifier entries
- status semantics are mechanically consistent across task meta, DAG, master
  plan, and task registry truth surfaces
- scaffold-only and implementation-ready states are explicitly and mechanically
  distinguishable
- strengthened readiness checks fail closed when a task pack declares a
  non-executable verifier or lacks evidence-writing behavior
- all derived remediation tasks required by agent-surface or regulated-surface
  boundaries are created and tracked

## Derived Tasks

- pending approval: process-fix task for Phase 3 task-pack generation and gates
- pending approval: reconciliation task set for all affected Wave 1 through
  Wave 5 task packs

## verification_commands_run

- `rg -n "^status: planned$|^verification:|^  - '#" tasks/TSK-P3-WP-* tasks/TSK-P3-SUPPORT-*`
- `python3 - <<'PY' ... PY` task-pack audit for commented verifier entries,
  missing deliverables, and status drift across the 21 affected packs
- `sed -n '1,260p' docs/operations/TASK_CREATION_PROCESS.md`
- `sed -n '1,240p' docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `sed -n '1,220p' scripts/agent/run_task.sh`
- `PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks --scope all`
- `PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>` across all 21 affected Phase 3 Wave 1 through Wave 5 task packs

final_status: PASS
