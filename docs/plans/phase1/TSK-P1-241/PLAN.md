# TSK-P1-241 PLAN — Create the runtime-integrity parent task graph so implementation starts from narrow repo-local child tasks

This plan creates the repo-local parent scheduling task for TSK-P1-241 so runtime-integrity work begins from narrow child tasks instead of one broad implementation bundle.

Task: TSK-P1-241
Owner: SUPERVISOR
Depends on: TSK-P1-239
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-241.SCHEDULING_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create the authoritative repo-local parent task pack for the runtime-integrity line. Done means TSK-P1-241 exists as a scheduling and decomposition contract, the deferred reminder is stored in the canonical inbox, the Phase-1 governance index references the task, and the parent plan defines child-task boundaries without claiming runtime implementation is complete.

---

## Architectural Context

TSK-P1-239 hardened the repo against drift by requiring exact scope, explicit stop conditions, bounded evidence claims, and proof-graph integrity. This task applies that discipline to the runtime-integrity line by turning TSK-P1-241 into a parent scheduling task rather than a broad implementation bundle. The parent must keep host-path authority unresolved until a narrower child task proves where guarded runtime controls are allowed to live.

---

## Pre-conditions

- [x] TSK-P1-239 is status=completed and its anti-drift template/process outputs exist.
- [x] `AGENT_ENTRYPOINT.md` and `docs/operations/AGENT_PROMPT_ROUTER.md` were read before task-pack creation.
- [x] The `must_read` files listed in `tasks/TSK-P1-239/meta.yml` were read before writing this plan.
- [x] The current branch is not `main`.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/TSK-P1-241/meta.yml` | CREATE | Create the parent task contract in the canonical task-pack location |
| `docs/plans/phase1/TSK-P1-241/PLAN.md` | CREATE | Define the parent scheduling scope, stop conditions, and child-task graph |
| `docs/plans/phase1/TSK-P1-241/EXEC_LOG.md` | CREATE | Start the append-only execution log required by the task process |
| `docs/tasks/DEFERRED_INBOX.md` | MODIFY | Track the unresolved runtime host-path and ownership decision in the canonical inbox |
| `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` | MODIFY | Register TSK-P1-241 in the Phase-1 human task index |
| `evidence/phase1/tsk_p1_241_parent_task_pack.json` | CREATE | Declare the bounded evidence artifact for the parent task pack |

---

## Stop Conditions

- **If TSK-P1-241 starts to absorb runtime implementation work** -> STOP
- **If any child boundary spans multiple owner/path surfaces without a dependency split** -> STOP
- **If the runtime host path is treated as settled before a child task proves it** -> STOP
- **If the parent evidence contract claims child completion or runtime guarantees it cannot prove** -> STOP
- **If the deferred inbox reminder becomes a pseudo-task instead of a reminder with unblock criteria** -> STOP

---

## Implementation Steps

### Step 1: Create the parent task pack shell
**What:** `[ID tsk_p1_241_parent_work_item_01]` Create `TSK-P1-241` in the canonical task-pack locations.
**How:** Write the parent `meta.yml`, `PLAN.md`, and `EXEC_LOG.md` in the Phase-1 locations prescribed by `TASK_CREATION_PROCESS.md`.
**Done when:** The repo-local parent files exist and the phase-1 paths resolve.

### Step 2: Register the deferred reminder
**What:** `[ID tsk_p1_241_parent_work_item_02]` Add one inbox entry for the unresolved runtime host-path and ownership decision.
**How:** Update `docs/tasks/DEFERRED_INBOX.md` with owner, trigger, done criteria, and links.
**Done when:** The reminder is present in the canonical inbox and remains narrower than an executable child task.

### Step 3: Register the parent task in the human index
**What:** `[ID tsk_p1_241_parent_work_item_03]` Add TSK-P1-241 to `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`.
**How:** Record the task id, owner, status, plan path, and log path in the Phase-1 governance index.
**Done when:** Reviewers can find the parent task from the canonical human index.

### Step 4: Define the child-task graph
**What:** `[ID tsk_p1_241_parent_work_item_04]` Define the first child-task boundaries and dependency order inside the parent task contract.
**How:** Limit the graph to scheduling/decomposition and record the initial boundary set with `TSK-P1-242` as the first concrete child for host-path authority, followed by guarded execution core, repository/filesystem integrity, evidence finalization, adversarial verifier suite, and optional invariant promotion.
**Done when:** The parent task describes the dependency order and boundary names without claiming any child work is complete.

### Step 5: Validate the parent task pack
**What:** `[ID tsk_p1_241_parent_work_item_01] [ID tsk_p1_241_parent_work_item_02] [ID tsk_p1_241_parent_work_item_03] [ID tsk_p1_241_parent_work_item_04]` Run the task-pack gates for the parent pack.
**How:** Run task-meta schema validation, run task-pack readiness, and write the bounded parent evidence artifact.
**Done when:** The parent task pack is structurally valid and still limited to scheduling scope.

---

## Verification

```bash
# [ID tsk_p1_241_parent_work_item_01] [ID tsk_p1_241_parent_work_item_02]
# [ID tsk_p1_241_parent_work_item_03] [ID tsk_p1_241_parent_work_item_04]
bash -lc 'ls tasks/TSK-P1-241 docs/plans/phase1/TSK-P1-241 docs/tasks >/dev/null &&
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/TSK-P1-241 --json > /tmp/tsk_p1_241_meta_schema.json &&
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-241 --json > /tmp/tsk_p1_241_pack_readiness.json &&
python3 - <<'"'"'PY'"'"' > evidence/phase1/tsk_p1_241_parent_task_pack.json
import hashlib
import json
from pathlib import Path

root = Path('.')
observed_files = sorted(str(p) for p in (root / 'tasks' / 'TSK-P1-241').glob('*'))
observed_files += sorted(str(p) for p in (root / 'docs' / 'plans' / 'phase1' / 'TSK-P1-241').glob('*'))
observed_files += ['docs/tasks/DEFERRED_INBOX.md', 'docs/tasks/PHASE1_GOVERNANCE_TASKS.md']

def digest(path_str):
    path = root / path_str
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

meta_report = json.loads(Path('/tmp/tsk_p1_241_meta_schema.json').read_text())
readiness_report = json.loads(Path('/tmp/tsk_p1_241_pack_readiness.json').read_text())

report = {
    'task_id': 'TSK-P1-241',
    'git_sha': 'UNSET',
    'timestamp_utc': 'UNSET',
    'status': 'PASS' if meta_report['status'] == 'PASS' and readiness_report['status'] == 'PASS' else 'FAIL',
    'checks': {
        'task_meta_schema': meta_report['status'],
        'task_pack_readiness': readiness_report['status'],
    },
    'observed_paths': observed_files,
    'observed_hashes': {path: digest(path) for path in observed_files},
    'command_outputs': {
        'task_meta_schema': meta_report,
        'task_pack_readiness': readiness_report,
    },
    'execution_trace': [
        'bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy --root tasks/TSK-P1-241 --json',
        'bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-241 --json',
    ],
    'child_task_boundaries': [
        'TSK-P1-242:runtime_host_path_authority',
        'guarded_execution_core',
        'repository_filesystem_integrity',
        'evidence_finalization',
        'adversarial_verifier_suite',
        'optional_invariant_promotion',
    ],
    'dependency_edges': [
        'TSK-P1-241->TSK-P1-242',
        'TSK-P1-242->guarded_execution_core',
        'guarded_execution_core->repository_filesystem_integrity',
        'guarded_execution_core->evidence_finalization',
        'repository_filesystem_integrity+evidence_finalization->adversarial_verifier_suite',
    ],
    'inbox_entry_ref': 'docs/tasks/DEFERRED_INBOX.md',
    'phase1_index_ref': 'docs/tasks/PHASE1_GOVERNANCE_TASKS.md',
}

print(json.dumps(report, indent=2))
if report['status'] != 'PASS':
    raise SystemExit(1)
PY' || exit 1

# [ID tsk_p1_241_parent_work_item_01] [ID tsk_p1_241_parent_work_item_02]
# [ID tsk_p1_241_parent_work_item_03] [ID tsk_p1_241_parent_work_item_04]
bash -lc 'test -f evidence/phase1/tsk_p1_241_parent_task_pack.json &&
cat evidence/phase1/tsk_p1_241_parent_task_pack.json | grep '"status": "PASS"' >/dev/null &&
cat evidence/phase1/tsk_p1_241_parent_task_pack.json | grep 'child_task_boundaries' >/dev/null' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_241_parent_task_pack.json`

Required fields:
- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `checks`
- `observed_paths`
- `observed_hashes`
- `command_outputs`
- `execution_trace`
- `child_task_boundaries`
- `dependency_edges`
- `inbox_entry_ref`
- `phase1_index_ref`

The parent evidence is limited to proving that the scheduling pack exists, the reminder is registered, the human index entry exists, and the child-task graph is declared. It does not prove runtime implementation, host-path authority resolution, or child completion.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-241` task pack files from the Phase-1 task locations.
2. Remove the deferred inbox reminder for the runtime host-path decision.
3. Remove the Phase-1 governance index entry for TSK-P1-241.
4. Return the runtime-integrity line to pre-task-pack review state and reopen scheduling through a new parent task.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Parent plan still bundles runtime implementation into the scheduling task | BLOCKED | Keep child boundaries explicit and stop if implementation scope leaks into the parent |
| Reminder or governance index entry is missing | FAIL | Verify both repo-local registration points before treating the pack as ready |
| Runtime host path is implied without an authority task | BLOCKED | Keep host-path authority as a named child boundary, not a solved assumption |
| Evidence overclaims child completion | FAIL | Limit evidence fields to pack existence, registration, and declared dependency edges |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
