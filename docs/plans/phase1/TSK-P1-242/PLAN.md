# TSK-P1-242 PLAN — Resolve the canonical host path and owner surface for guarded runtime controls so runtime tasks start inside an authorized boundary

This plan resolves the runtime host-path blocker by selecting an already-owned surface for guarded runtime controls before any runtime code task begins.

Task: TSK-P1-242
Owner: SUPERVISOR
Depends on: TSK-P1-241
failure_signature: PHASE1.RUNTIME_INTEGRITY.TSK-P1-242.HOST_PATH_AUTHORITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Resolve the canonical host path and owning agent surface for guarded runtime controls. Done means the runtime-integrity line no longer assumes `scripts/runtime/**`, the chosen host path is explicitly tied to an already-owned surface, and the deferred inbox blocker points to that authority decision so downstream runtime tasks can inherit an honest scope boundary.

---

## Architectural Context

The parent task proved that the runtime-integrity line was too broad and that `scripts/runtime/**` had no existing authority. This child closes the first blocker by choosing an already-owned surface instead of letting runtime implementation silently invent a new home. Keeping this decision in a narrow child task prevents ownership drift from leaking into execution-core or verifier tasks.

---

## Pre-conditions

- [x] TSK-P1-241 exists as the parent scheduling/decomposition task.
- [x] `AGENTS.md` has been reviewed for existing owned path surfaces.
- [x] The deferred inbox contains the runtime host-path blocker entry.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/TSK-P1-242/meta.yml` | CREATE | Create the host-path authority child task contract |
| `docs/plans/phase1/TSK-P1-242/PLAN.md` | CREATE | Define the host-path authority decision and its scope boundary |
| `docs/plans/phase1/TSK-P1-242/EXEC_LOG.md` | CREATE | Start the append-only execution log for the child task |
| `docs/tasks/DEFERRED_INBOX.md` | MODIFY | Link the runtime host-path blocker to the authority-resolution child task |
| `evidence/phase1/tsk_p1_242_runtime_host_path_authority.json` | CREATE | Emit bounded evidence describing the chosen host path and owner surface |

---

## Stop Conditions

- **If the task invents a new unowned host path** -> STOP
- **If the task tries to implement guarded runtime code instead of resolving host-path authority** -> STOP
- **If the task names a host surface without identifying the owning agent surface** -> STOP
- **If the evidence claims runtime implementation or verifier completion** -> STOP

---

## Implementation Steps

### Step 1: Inspect owned surfaces
**What:** `[ID tsk_p1_242_work_item_01]` Evaluate existing owned repo surfaces that could host guarded runtime controls.
**How:** Inspect `AGENTS.md` and choose an already-owned path instead of inventing a new top-level runtime directory.
**Done when:** One canonical host path is named and that path already exists in the repo's owner model.

### Step 2: Record the owner surface decision
**What:** `[ID tsk_p1_242_work_item_02]` Record the owning agent surface and downstream scope consequence.
**How:** Bind the chosen host path to the owner surface and explain how execution logic and verifier tests split downstream.
**Done when:** The task contract names the owner surface and the rehost rationale explicitly.

### Step 3: Update the blocker trail
**What:** `[ID tsk_p1_242_work_item_03]` Point the deferred inbox blocker to this authority-resolution task outcome.
**How:** Keep the blocker as a tracked reminder until this child finishes, but make the authority-resolution child the canonical resolution path.
**Done when:** The blocker no longer reads like an ad hoc note and instead points to the resolved authority task.

### Step 4: Emit bounded evidence
**What:** `[ID tsk_p1_242_work_item_01] [ID tsk_p1_242_work_item_02] [ID tsk_p1_242_work_item_03]` Write the authority-resolution evidence artifact.
**How:** Inspect `AGENTS.md` and the deferred inbox entry, then write the bounded authority evidence JSON.
**Done when:** The evidence file exists and contains the chosen host path, owner surface, and rehost rationale.

---

## Verification

```bash
# [ID tsk_p1_242_work_item_01] [ID tsk_p1_242_work_item_02] [ID tsk_p1_242_work_item_03]
bash -lc 'grep -n "### Security Guardian Agent" AGENTS.md >/tmp/tsk_p1_242_owner.txt &&
grep -n "scripts/audit/\*\*" AGENTS.md >/tmp/tsk_p1_242_path.txt &&
grep -n "INBOX-2026-03-26-001" docs/tasks/DEFERRED_INBOX.md >/tmp/tsk_p1_242_inbox.txt &&
python3 - <<'"'"'PY'"'"' > evidence/phase1/tsk_p1_242_runtime_host_path_authority.json
import json
from pathlib import Path

owner_lines = Path('/tmp/tsk_p1_242_owner.txt').read_text().splitlines()
path_lines = Path('/tmp/tsk_p1_242_path.txt').read_text().splitlines()
inbox_lines = Path('/tmp/tsk_p1_242_inbox.txt').read_text().splitlines()

report = {
    'task_id': 'TSK-P1-242',
    'git_sha': 'UNSET',
    'timestamp_utc': 'UNSET',
    'status': 'PASS',
    'checks': {
        'owner_surface_present': len(owner_lines),
        'host_path_present': len(path_lines),
        'inbox_entry_present': len(inbox_lines),
    },
    'observed_paths': [
        'AGENTS.md',
        'docs/tasks/DEFERRED_INBOX.md',
    ],
    'observed_hashes': {},
    'command_outputs': {
        'owner_surface_lines': owner_lines,
        'host_path_lines': path_lines,
        'inbox_lines': inbox_lines,
    },
    'execution_trace': [
        'grep -n "### Security Guardian Agent" AGENTS.md',
        'grep -n "scripts/audit/**" AGENTS.md',
        'grep -n "INBOX-2026-03-26-001" docs/tasks/DEFERRED_INBOX.md',
    ],
    'chosen_host_path': 'scripts/audit/**',
    'chosen_owner_surface': 'SECURITY_GUARDIAN',
    'owner_surface_candidates': ['SECURITY_GUARDIAN', 'QA_VERIFIER'],
    'rehost_rationale': 'Guarded runtime controls remain verifier-scoped and can start inside an already-owned audit surface without inventing scripts/runtime/**.',
    'deferred_inbox_entry': 'INBOX-2026-03-26-001',
}

print(json.dumps(report, indent=2))
PY' || exit 1

# [ID tsk_p1_242_work_item_01] [ID tsk_p1_242_work_item_02] [ID tsk_p1_242_work_item_03]
bash -lc 'test -f evidence/phase1/tsk_p1_242_runtime_host_path_authority.json &&
cat evidence/phase1/tsk_p1_242_runtime_host_path_authority.json | grep '"chosen_host_path": "scripts/audit/\*\*"' >/dev/null &&
cat evidence/phase1/tsk_p1_242_runtime_host_path_authority.json | grep '"chosen_owner_surface": "SECURITY_GUARDIAN"' >/dev/null' || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_242_runtime_host_path_authority.json`

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
- `chosen_host_path`
- `chosen_owner_surface`
- `owner_surface_candidates`
- `rehost_rationale`
- `deferred_inbox_entry`

This evidence is bounded to proving the chosen host path and owner surface are declared from existing repo authority. It does not prove runtime code exists or that downstream child tasks are complete.

---

## Rollback

If this task must be reverted:
1. Remove the `TSK-P1-242` task pack files.
2. Remove any deferred-inbox text that points the host-path blocker to the unresolved authority decision.
3. Reopen the host-path blocker under TSK-P1-241 until a different child task resolves it.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Host path remains unowned or socially implied | BLOCKED | Require the chosen path to already appear in `AGENTS.md` |
| The task drifts into runtime implementation | BLOCKED | Stop if execution logic or verifier implementation appears in scope |
| Evidence overclaims more than authority resolution | FAIL | Limit evidence to path ownership, blocker linkage, and rationale |
