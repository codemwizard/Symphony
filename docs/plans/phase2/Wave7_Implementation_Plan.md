# Wave 7 Implementation Plan — Invariant Registration + CI Wiring

**Phase Key**: PRE-PHASE2
**Wave Number**: 7
**Stage**: Stage 5 — Invariant Registration + CI Wiring
**Owner**: Invariants Curator Agent
**Source Plan**: docs/plans/phase2/WAVE_IMPLEMENTATION_PLAN.md
**Implementation Process**: docs/operations/SYMPHONY_TASK_IMPLEMENTATION_PROCESS.md

---

## Executive Summary

Wave 7 registers three new invariants (INV-175, INV-176, INV-177), promotes two existing invariants (INV-165, INV-167), and wires new verifier scripts into pre_ci.sh. This wave is the critical gate that enables Stage 6 regulatory work. No database migrations are involved in this wave.

**Total Tasks**: 6
**Migration Range**: None (no schema changes)
**Checkpoint**: INV-REG
**Prerequisites**: Wave 2 (001-02), Wave 5 (005-08), Wave 6 (006C-03) must be completed

---

## Pre-Flight Requirements

### 1. Verify Prerequisite Waves Complete

Before starting Wave 7, verify that the following tasks are marked `completed` in their respective meta.yml files:
- TSK-P2-PREAUTH-001-02 (Wave 2)
- TSK-P2-PREAUTH-005-08 (Wave 5)
- TSK-P2-PREAUTH-006C-03 (Wave 6)

**Verification Command**:
```bash
# Check completion status of prerequisite tasks
for task in "TSK-P2-PREAUTH-001-02" "TSK-P2-PREAUTH-005-08" "TSK-P2-PREAUTH-006C-03"; do
  echo "Checking $task..."
  grep "^status:" tasks/$task/meta.yml
done
```

### 2. Verify Current Branch

**Requirement**: Work must occur on a feature branch, not `main`.

**Verification Command**:
```bash
git branch --show-current
```

**Expected**: Output should NOT be `main`. If it is `main`, create a feature branch first:
```bash
git checkout -b feature/wave-7-invariant-registration
```

### 3. Check for DRD Lockout

**Requirement**: Verify no active DRD lockout before proceeding.

**Verification Command**:
```bash
if [ -f .agent/rejection_context.md ]; then
  cat .agent/rejection_context.md
  echo "DRD_STATUS check required"
else
  echo "No rejection context - safe to proceed"
fi
```

### 4. Check Evidence Ack Gate State

**Requirement**: Verify no evidence ack gates are blocking task execution.

**Verification Command**:
```bash
ls -la .toolchain/evidence_ack/*.required 2>/dev/null || echo "No evidence ack gates active"
```

---

## Wave 7 Task Overview

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-007-00 | PLAN creation | Invariants Curator | plan semantic alignment | 001-02, 005-08, 006C-03 |
| TSK-P2-PREAUTH-007-01 | Runtime INV ID assignment | Invariants Curator | verify_tsk_p2_preauth_007_01.sh | 007-00 |
| TSK-P2-PREAUTH-007-02 | Register INV-175 (data_authority_enforced) | Invariants Curator | verify_tsk_p2_preauth_007_02.sh | 007-01 |
| TSK-P2-PREAUTH-007-03 | Register INV-176 (state_machine_enforced) | Invariants Curator | verify_tsk_p2_preauth_007_03.sh | 007-02 |
| TSK-P2-PREAUTH-007-04 | Register INV-177 (phase1_boundary_marked) | Invariants Curator | verify_tsk_p2_preauth_007_04.sh | 007-03 |
| TSK-P2-PREAUTH-007-05 | Promote INV-165/167 + wire pre_ci.sh | Invariants Curator | verify_tsk_p2_preauth_007_05.sh | 007-04 |

---

## Mode Classification

**Mode**: IMPLEMENT-TASK (Mode 3)

Before any implementation work, the agent must:

1. **Read AGENT_ENTRYPOINT.md** (canonical entry point)
2. **Classify the prompt** against AGENT_PROMPT_ROUTER.md
3. **Confirm Mode 3 (IMPLEMENT-TASK)** applies
4. **Pass Mode 2 (RESUME-TASK) inspection** for each task before implementation

---

## Task Execution Sequence

### Phase 1: Mode 2 Inspection (All Tasks)

For each task in sequence (007-00 through 007-05), run the RESUME-TASK inspection algorithm:

1. **Meta readable**: Verify `tasks/<TASK_ID>/meta.yml` exists and is readable
2. **Plan present**: Verify `implementation_plan` field resolves to an existing PLAN.md
3. **Log present**: Verify `implementation_log` field resolves to an existing EXEC_LOG.md
4. **Pack ready**: Run `bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>`
5. **Dependencies satisfied**: Verify all tasks in `depends_on` are marked `completed`
6. **If all pass**: Report `STATE: resume-ready` and continue to Mode 3

**Stop Condition**: If any task fails inspection, report the failure state and STOP. Do not proceed with implementation.

---

### Phase 2: Boot Sequence (Per Task)

For each task in sequence (007-00 through 007-05), execute the boot sequence:

1. **Conformance Gate**: `scripts/audit/verify_agent_conformance.sh`
   - Validates canonical references
   - Validates stop conditions
   - Validates regulated-surface approval metadata
   - Emits role-scoped conformance evidence

2. **Local Parity Gate**: `scripts/dev/pre_ci.sh`
   - Fresh DB
   - Ordered checks
   - Remediation trace validation
   - Evidence scripts must produce evidence JSON files

3. **Task Execution**: `scripts/agent/run_task.sh <TASK_ID>`
   - Parses meta.yml
   - Runs verification commands from meta.yml
   - Produces evidence artifacts
   - Validates evidence freshness

**Stop Condition**: If any step in the boot sequence fails, STOP immediately and open or update remediation trace.

---

### Phase 3: Task-Specific Implementation

#### Task TSK-P2-PREAUTH-007-00: PLAN Creation

**Objective**: Create the implementation plan for Wave 7 invariant registration work.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-00/meta.yml`
   - Extract `touches` list
   - Extract `verification` commands
   - Extract `evidence` paths
   - Extract `must_read` documents
   - Extract `invariants` to enforce
   - Extract `stop_conditions`

2. **Read Required Documentation**:
   - docs/operations/AI_AGENT_OPERATION_MANUAL.md
   - docs/operations/TASK_CREATION_PROCESS.md
   - docs/invariants/INVARIANTS_MANIFEST.yml
   - docs/operations/AGENT_GUARDRAILS_GREEN_FINANCE.md (if applicable)

3. **Create PLAN.md** at `docs/plans/phase2/TSK-P2-PREAUTH-007-00/PLAN.md`:
   - Required front-matter fields:
     - `failure_signature: PRE-PHASE2.PREAUTH.INV-REG.PLAN-CREATION`
     - `canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md`
   - Content sections:
     - Objective and architectural context
     - Pre-conditions (Wave 2, 5, 6 completion)
     - Files to change (docs/invariants/INVARIANTS_MANIFEST.yml, scripts/audit/)
     - Stop conditions
     - Implementation steps with ID tags
     - Verification requirements
     - Evidence contract
     - Rollback procedure
     - Risk assessment

4. **Create EXEC_LOG.md** at `docs/plans/phase2/TSK-P2-PREAUTH-007-00/EXEC_LOG.md`:
   - Initialize with execution history table
   - No entries yet (plan creation phase)

5. **Update meta.yml**:
   - Set `status: completed` after plan creation

6. **Run Verification**:
   - Execute plan semantic alignment check
   - Verify PLAN.md follows PLAN_TEMPLATE.md structure
   - Verify front-matter fields are present

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` (regulated surface). Before writing, verify approval metadata exists per REGULATED_SURFACE_PATHS.yml.

---

#### Task TSK-P2-PREAUTH-007-01: Runtime INV ID Assignment

**Objective**: Assign runtime invariant IDs to INV-175, INV-176, INV-177.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-01/meta.yml`

2. **Read PLAN.md**: `docs/plans/phase2/TSK-P2-PREAUTH-007-01/PLAN.md`

3. **Implement According to PLAN.md**:
   - Assign next available INV IDs in the runtime range
   - Update `docs/invariants/INVARIANTS_MANIFEST.yml` with new INV entries
   - Ensure INV IDs follow the established pattern (INV-XXX where XXX is sequential)

4. **Modify Only Files in touches List**:
   - Verify all modifications are within the `touches` list from meta.yml
   - If scope drift is detected, STOP and report

5. **Implement Negative Test** (MANDATORY):
   - Write negative test BEFORE implementing the fix
   - Test: Attempt to assign duplicate INV ID
   - Verify test fails against unfixed code
   - Verify test passes after implementation

6. **Produce Evidence Artifacts** (MANDATORY EXECUTION):
   - Execute verification script: `scripts/db/verify_tsk_p2_preauth_007_01.sh`
   - Produce evidence JSON at path specified in meta.yml
   - Verify evidence includes `run_id` matching current execution
   - Verify evidence includes required fields: task_id, git_sha, timestamp_utc, status, checks

7. **Update EXEC_LOG.md** (Append-Only):
   - Add entry with timestamp, action, result

8. **Update meta.yml**:
   - Set `status: completed` after all verification passes

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` (regulated surface). Verify approval metadata exists before writing.

---

#### Task TSK-P2-PREAUTH-007-02: Register INV-175 (data_authority_enforced)

**Objective**: Register INV-175 to enforce data authority level enforcement.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-02/meta.yml`

2. **Read PLAN.md**: `docs/plans/phase2/TSK-P2-PREAUTH-007-02/PLAN.md`

3. **Implement According to PLAN.md**:
   - Add INV-175 entry to `docs/invariants/INVARIANTS_MANIFEST.yml`
   - Define invariant scope: data_authority_level column enforcement
   - Define invariant check: verify data_authority triggers are active
   - Define invariant remediation: re-enable triggers if disabled

4. **Modify Only Files in touches List**:
   - Verify all modifications are within the `touches` list

5. **Implement Negative Test** (MANDATORY):
   - Write negative test BEFORE implementation
   - Test: Attempt to violate data_authority invariant
   - Verify test fails against unfixed code
   - Verify test passes after implementation

6. **Create/Update Verification Script**: `scripts/db/verify_tsk_p2_preauth_007_02.sh`
   - Check that INV-175 is registered in INVARIANTS_MANIFEST.yml
   - Check that data_authority triggers exist and are enabled
   - Check that trigger firing logic matches invariant definition
   - Write evidence JSON to specified path

7. **Produce Evidence Artifacts** (MANDATORY EXECUTION):
   - Execute verification script
   - Verify evidence freshness
   - Verify evidence completeness

8. **Update EXEC_LOG.md** (Append-Only)

9. **Update meta.yml**:
   - Set `status: completed`

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` and `scripts/db/` (regulated surfaces). Verify approval metadata exists before writing.

---

#### Task TSK-P2-PREAUTH-007-03: Register INV-176 (state_machine_enforced)

**Objective**: Register INV-176 to enforce state machine integrity.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-03/meta.yml`

2. **Read PLAN.md**: `docs/plans/phase2/TSK-P2-PREAUTH-007-03/PLAN.md`

3. **Implement According to PLAN.md**:
   - Add INV-176 entry to `docs/invariants/INVARIANTS_MANIFEST.yml`
   - Define invariant scope: state_transitions table and triggers
   - Define invariant check: verify all 6 enforcement triggers are active
   - Define invariant remediation: re-enable triggers if disabled

4. **Modify Only Files in touches List**:
   - Verify all modifications are within the `touches` list

5. **Implement Negative Test** (MANDATORY):
   - Write negative test BEFORE implementation
   - Test: Attempt to disable state machine trigger
   - Verify test fails against unfixed code
   - Verify test passes after implementation

6. **Create/Update Verification Script**: `scripts/db/verify_tsk_p2_preauth_007_03.sh`
   - Check that INV-176 is registered
   - Check that all 6 state machine triggers exist and are enabled
   - Check trigger ordering (enforce_transition_state_rules first)
   - Write evidence JSON to specified path

7. **Produce Evidence Artifacts** (MANDATORY EXECUTION):
   - Execute verification script
   - Verify evidence freshness
   - Verify evidence completeness

8. **Update EXEC_LOG.md** (Append-Only)

9. **Update meta.yml**:
   - Set `status: completed`

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` and `scripts/db/` (regulated surfaces). Verify approval metadata exists before writing.

---

#### Task TSK-P2-PREAUTH-007-04: Register INV-177 (phase1_boundary_marked)

**Objective**: Register INV-177 to enforce Phase 1 boundary marking in C# read models.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-04/meta.yml`

2. **Read PLAN.md**: `docs/plans/phase2/TSK-P2-PREAUTH-007-04/PLAN.md`

3. **Implement According to PLAN.md**:
   - Add INV-177 entry to `docs/invariants/INVARIANTS_MANIFEST.yml`
   - Define invariant scope: C# read model data_authority fields
   - Define invariant check: verify data_authority="phase1_indicative_only" and audit_grade=false
   - Define invariant remediation: correct read model if boundary marking is missing

4. **Modify Only Files in touches List**:
   - Verify all modifications are within the `touches` list

5. **Implement Negative Test** (MANDATORY):
   - Write negative test BEFORE implementation
   - Test: Attempt to return read model without boundary marking
   - Verify test fails against unfixed code
   - Verify test passes after implementation

6. **Create/Update Verification Script**: `scripts/db/verify_tsk_p2_preauth_007_04.sh`
   - Check that INV-177 is registered
   - Check that C# read models include data_authority fields
   - Check that API responses include phase1 boundary marking
   - Write evidence JSON to specified path

7. **Produce Evidence Artifacts** (MANDATORY EXECUTION):
   - Execute verification script
   - Verify evidence freshness
   - Verify evidence completeness

8. **Update EXEC_LOG.md** (Append-Only)

9. **Update meta.yml**:
   - Set `status: completed`

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` and `scripts/db/` (regulated surfaces). Verify approval metadata exists before writing.

---

#### Task TSK-P2-PREAUTH-007-05: Promote INV-165/167 + Wire pre_ci.sh

**Objective**: Promote INV-165 and INV-167 to Phase 2, and wire all new verifier scripts into pre_ci.sh.

**Steps**:

1. **Read Task Metadata**: `tasks/TSK-P2-PREAUTH-007-05/meta.yml`

2. **Read PLAN.md**: `docs/plans/phase2/TSK-P2-PREAUTH-007-05/PLAN.md`

3. **Implement According to PLAN.md**:
   - Update INV-165 in `docs/invariants/INVARIANTS_MANIFEST.yml` (promote to Phase 2)
   - Update INV-167 in `docs/invariants/INVARIANTS_MANIFEST.yml` (promote to Phase 2)
   - Edit `scripts/dev/pre_ci.sh` to add calls to:
     - verify_tsk_p2_preauth_007_01.sh
     - verify_tsk_p2_preauth_007_02.sh
     - verify_tsk_p2_preauth_007_03.sh
     - verify_tsk_p2_preauth_007_04.sh
     - verify_tsk_p2_preauth_007_05.sh
   - Ensure verifier calls are in the correct order (007-01 through 007-05)

4. **Modify Only Files in touches List**:
   - Verify all modifications are within the `touches` list
   - **Critical**: pre_ci.sh is a regulated surface - verify approval metadata exists

5. **Implement Negative Test** (MANDATORY):
   - Write negative test BEFORE implementation
   - Test: Attempt to run pre_ci.sh without new verifiers
   - Verify test fails against unfixed code
   - Verify test passes after implementation

6. **Create/Update Verification Script**: `scripts/db/verify_tsk_p2_preauth_007_05.sh`
   - Check that INV-165 and INV-167 are promoted in INVARIANTS_MANIFEST.yml
   - Check that all 5 new verifier scripts are called in pre_ci.sh
   - Check that verifier calls are in correct order
   - Write evidence JSON to specified path

7. **Produce Evidence Artifacts** (MANDATORY EXECUTION):
   - Execute verification script
   - Verify evidence freshness
   - Verify evidence completeness

8. **Update EXEC_LOG.md** (Append-Only)

9. **Update meta.yml**:
   - Set `status: completed`

**Regulated Surface Check**: This task touches `docs/invariants/INVARIANTS_MANIFEST.yml` and `scripts/dev/pre_ci.sh` (regulated surfaces). Verify approval metadata exists before writing.

---

## Post-Implementation Steps

### Step 1: Resolve Structural Change Governance (Change-Rule Gate)

Since Wave 7 does not involve database migrations, no structural change governance documentation is required for schema changes. However, if any new scripts or documentation were added, verify they are documented in:

1. **docs/architecture/THREAT_MODEL.md** (if security implications exist)
2. **docs/architecture/COMPLIANCE_MAP.md** (if compliance controls are affected)

### Step 2: Verify No Schema Baseline Drift

Since Wave 7 has no migrations, no baseline regeneration is required. Verify baseline remains unchanged:

```bash
bash scripts/db/check_baseline_drift.sh
```

**Expected**: No drift detected (exit code 0)

### Step 3: Verify Regulated Surface Compliance

For all regulated surfaces modified in Wave 7:

1. **Consult REGULATED_SURFACE_PATHS.yml**:
   ```bash
   cat docs/operations/REGULATED_SURFACE_PATHS.yml
   ```

2. **Verify Two-Stage Approval Artifacts**:
   - **Stage A (Pre-Push)**: `approvals/YYYY-MM-DD/BRANCH-<branch-key>.md` and `.approval.json`
   - **Stage B (Post-PR)**: Will be created after PR is opened

3. **Run Conformance Check**:
   ```bash
   scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=feature/wave-7-invariant-registration
   ```

### Step 4: Update Task Registration in Human Task Index

1. **Locate the task index**: `docs/tasks/PHASE2_TASKS.md`
2. **Verify all 6 Wave 7 tasks are listed** with appropriate metadata
3. **Update task status** to `completed` for all 6 tasks

### Step 5: Verify CI Wiring

1. **Locate evidence check script**: `scripts/ci/check_evidence_required.sh`
2. **Verify new evidence paths** are added to the Phase 2 contract
3. **Verify the script passes locally**:
   ```bash
   bash scripts/ci/check_evidence_required.sh
   ```

### Step 6: Document Anti-Drift Cheating Limits

Since Wave 7 involves invariant registration but no schema changes, document the remaining attack surfaces:

1. **Identify attack surfaces** that remain open after Wave 7
2. **Document in PLAN.md** or dedicated security note
3. **Specify which cheating modes** are still possible

**Example** (to be added to 007-05 PLAN.md):
```markdown
## Anti-Drift Cheating Limits

After implementing Wave 7 invariant registration, the following attack surfaces remain open:
- Direct table bypass (if triggers are disabled at database level)
- Role escalation (if runtime roles regain excessive privileges)
- API bypass (if C# read models return unmarked data)

These will be addressed in Wave 8 (Regulatory Extensions) with additional hardening.
```

---

## Wave 7 Verification Order

### Per-Task Verification

For each task in sequence (007-00 through 007-05):

1. Run the task's verification script
2. Verify evidence artifacts are produced
3. Verify evidence freshness (run_id matches)
4. Update EXEC_LOG.md
5. Mark task as completed in meta.yml

### Wave-Level Verification

After all 6 tasks complete:

1. **Run pre_ci.sh**:
   ```bash
   bash scripts/dev/pre_ci.sh
   ```

2. **Verify checkpoint INV-REG passes**:
   - All three new invariants (INV-175, INV-176, INV-177) are registered
   - INV-165 and INV-167 are promoted
   - All 5 new verifier scripts are wired into pre_ci.sh

3. **Verify evidence completeness**:
   - All 6 evidence JSON files exist
   - All evidence files have fresh run_id
   - All evidence files include required fields

---

## Commit Message (Wave 7)

```
feat(pre-phase2/wave-7): invariant registration + CI wiring — INV-175/176/177 registered, INV-165/167 promoted, verifiers wired to pre_ci.sh

Tasks completed: TSK-P2-PREAUTH-007-00 through 007-05
Checkpoint INV-REG: ✅
pre_ci: PASS ✅
```

---

## Completion Criteria

Wave 7 is complete when:

1. **All 6 task verification scripts pass** (exit code 0)
2. **All evidence artifacts exist and are fresh** (run_id matches)
3. **Evidence includes all required fields** from meta.yml `must_include`
4. **All 6 EXEC_LOG.md files have been updated** with execution history
5. **For regulated surfaces**: approval metadata is present and valid
6. **scripts/dev/pre_ci.sh passes**
7. **All 6 task statuses in meta.yml are set to `completed`**
8. **All 6 tasks are registered** in docs/tasks/PHASE2_TASKS.md with status `completed`
9. **Evidence paths are wired into CI** (check_evidence_required.sh)
10. **Checkpoint INV-REG passes** (all invariants registered and verifiers wired)

---

## Hard Constraints (Never Violate)

- No runtime DDL on production paths (not applicable to Wave 7 - no migrations)
- Forward-only migrations (not applicable to Wave 7 - no migrations)
- SECURITY DEFINER functions must explicitly set `search_path = pg_catalog, public` (if any functions are modified)
- Roles follow revoke-first (if any role changes are made)
- Outbox attempts remain append-only (if outbox is modified)
- **No direct pushes or pulls to/from `main`**; work only on feature branches/PRs
- No placeholder verifiers (exit 0, echo PASS)
- No scope drift (modifications outside touches list)
- **Regulated surface changes require approval metadata**
- **Evidence must be fresh** (run_id matches current execution)
- **Negative tests must be written BEFORE fixes**

---

## Failure Handling and Remediation

If any verification step fails:

1. **Read failure artifacts** from `tmp/task_runs/<TASK_ID>/<RUN_ID>/check_<index>/`
2. **Identify root cause** from actual stdout/stderr, not assumptions
3. **Check DRD status** - If DRD lockout is active, create casefile FIRST
4. **Enter REMEDIATE mode** per AGENT_PROMPT_ROUTER.md Mode 4
5. **Open or update remediation trace** before changing any file
6. **Re-run ONLY the failing verifier** before broader checks
7. **Two-strike rule**: After two full reruns without convergence, switch to DRD Full

**DRD Policy**:
- L0 trivial: no DRD record required
- L1 blocker: DRD Lite required
- L2/L3 non-converging or systemic: DRD Full required

---

## System Invariant Gate (Post Wave 7)

**CAUTION**

Per the ATOMIC_TASK_BREAKDOWN_PLAN system invariant: The system is **NOT ALLOWED** to produce authoritative outputs, issue credits, or claim compliance until TSK-P2-PREAUTH-007-05 is complete and pre_ci.sh passes. This is enforced at the end of Wave 7, not Wave 8.

**Verification**:
```bash
# Verify Wave 7 completion before proceeding to Wave 8
grep "^status:" tasks/TSK-P2-PREAUTH-007-05/meta.yml | grep "completed"
bash scripts/dev/pre_ci.sh
```

---

## Next Steps After Wave 7

Upon successful completion of Wave 7:

1. **Commit Wave 7 changes** with the commit message above
2. **Push to remote branch**
3. **Open PR** for Wave 7
4. **Create Stage B approval artifacts** (PR-linked)
5. **Wait for PR approval and merge**
6. **Begin Wave 8** (Regulatory Extensions) only after Wave 7 commit is accepted

**Wave 8 Prerequisites**:
- Wave 7 commit merged to main
- Checkpoint INV-REG verified
- pre_ci.sh passes with all Wave 7 verifiers wired
