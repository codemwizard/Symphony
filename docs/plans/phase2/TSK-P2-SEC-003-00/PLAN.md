# TSK-P2-SEC-003-00 PLAN — Create PLAN.md and verify alignment for INV-132

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification command MUST be explicitly mapped using tracking IDs (e.g., `[ID <task_id>_work_item_01]`).
-->

Task: TSK-P2-SEC-003-00
Owner: SECURITY_GUARDIAN
Depends on: None
failure_signature: PRE-PHASE2.SEC.INV132-PLAN.MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
Create the PLAN.md for INV-132 promotion. The plan will document the INV-132 promotion requirements including fail-closed behavior. This task eliminates the risk of incomplete or incorrect implementation by providing architectural documentation and verification trace before implementation begins.

---

## Architectural Context
This task exists at the ground zero of Wave 1 because it has no dependencies and provides the plan for a security invariant promotion. Without a verified plan, the security invariant promotion lacks architectural documentation and verification trace, creating risk of incomplete or incorrect implementation. This plan guards against the anti-pattern of creating PLAN.md after implementation has already started.

---

## Pre-conditions
- [ ] No dependencies (this is a ground-zero task)
- [ ] docs/operations/AI_AGENT_OPERATION_MANUAL.md has been read
- [ ] docs/operations/TASK_CREATION_PROCESS.md has been read
- [ ] docs/contracts/templates/PLAN_TEMPLATE.md has been read
- [ ] docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md has been read
- [ ] This PLAN.md has been reviewed and approved

---

## Files to Change
| File | Action | Reason |
|------|--------|--------|
| `docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md` | MODIFY | This file (populate with content) |
| `tasks/TSK-P2-SEC-003-00/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions
- **If verify_plan_semantic_alignment.py fails with orphaned nodes** -> STOP
- **If the plan lacks explicit verifier specifications** -> STOP
- **If the plan lacks negative test definitions** -> STOP
- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP

---

## Implementation Steps

### Step 1: Create PLAN.md from template
**What:** `[ID tsk_p2_sec_003_00_work_item_01]` Create PLAN.md at docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md from PLAN_TEMPLATE.md with all required sections.
**How:** Copy template and fill in objective, architectural context, pre-conditions, files to change, stop conditions, implementation steps, verification, evidence contract, and risk sections.
**Done when:** PLAN.md exists and contains all required sections.

### Step 2: Document INV-132 promotion requirements
**What:** `[ID tsk_p2_sec_003_00_work_item_02]` Document the INV-132 promotion requirements including fail-closed behavior.
**How:** Add the grep pattern to the implementation steps section.
**Done when:** PLAN.md documents the fail-closed behavior.

### Step 3: Run verify_plan_semantic_alignment.py
**What:** `[ID tsk_p2_sec_003_00_work_item_03]` Run verify_plan_semantic_alignment.py to validate proof graph integrity.
**How:** Run python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md --meta tasks/TSK-P2-SEC-003-00/meta.yml
**Done when:** verify_plan_semantic_alignment.py exits 0 with NO_ORPHANS=true and GRAPH_CONNECTED=true.

---

## Verification

```bash
test -f docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md || exit 1

grep -q "fail-closed" docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md || exit 1

python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md --meta tasks/TSK-P2-SEC-003-00/meta.yml || exit 1
```

---

## Evidence Contract
File: `evidence/phase2/tsk_p2_sec_003_00.json`

Required fields:
- `task_id`: "TSK-P2-SEC-003-00"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `plan_path`: "docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md"
- `graph_validation_enabled`: true
- `no_orphans`: true
- `graph_connected`: true

---

## Rollback
Not applicable for DOCS_ONLY tasks. If this task must be reverted:
1. Delete docs/plans/phase2/TSK-P2-SEC-003-00/PLAN.md
2. Update status back to 'planned' in meta.yml
3. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| PLAN.md missing | CRITICAL_FAIL | Verification checks file existence |
| verify_plan_semantic_alignment.py fails | FAIL | Verification runs the script and checks exit code |
| PLAN lacks grep pattern | FAIL_REVIEW | Verification checks for specific pattern |
| Anti-pattern: Creating PLAN.md after implementation has already started | FAIL_REVIEW | This task is at ground zero with no dependencies |
