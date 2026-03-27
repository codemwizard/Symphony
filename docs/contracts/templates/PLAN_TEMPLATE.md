# <TASK-ID> PLAN — <Title>

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

Task: <TASK-ID>
Owner: <AGENT-ROLE>
Depends on: <TASK-ID-OR-CHECKPOINT>
failure_signature: <PHASE>.<TRACK>.<TASK-SLUG>.<FAILURE-CLASS>
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

<State the concrete end state. What exists that did not exist before.
What attack surface is closed. What invariant is now enforced.
What evidence file proves it.>

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

<Explain the dependency rationale. Reference the wave/sprint ordering logic.
Name the anti-patterns from meta.yml::anti_patterns that this plan actively guards against.>

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] <depends_on task ID> is status=completed and evidence validates.
- [ ] <environmental requirement: e.g., "DATABASE_URL is set to a fresh test DB">
- [ ] <tooling requirement: e.g., "semgrep >= 1.x is installed">
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `<path/to/file>` | CREATE \| MODIFY \| DELETE | <one-line reason> |
| `tasks/<TASK-ID>/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: <Name of step>
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID <task_slug>_work_item_01]` <Exact action>
**How:** <Exact method: command, code pattern, file to copy>
**Done when:** <Observable output that confirms completion>

```bash
# Example command or code snippet for this step
```

### Step 2: <Name of step>
**What:** `[ID <task_slug>_work_item_02]` <Exact action>
**How:** <Exact method>
**Done when:** <Observable output>

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID <task_slug>_work_item_03]` Implement the verification integration test script.
**How:** Define execution failure tests (N1...NN) that explicitly simulate corruption. Feed bad paths into the verification logic and ensure they are explicitly rejected.
**Done when:** The integration wrapper shell script exits non-zero against unfixed/dummy code, and exits 0 against the target implementation.

### Step N: Emit evidence
**What:** `[ID <task_slug>_work_item_N]` Run verifier and validate evidence schema.
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/<verifier-type>/verify_<task_slug>.sh && bash scripts/<verifier-type>/verify_<task_slug>.sh > evidence/<program>/<task_slug>.json || exit 1
```
**Done when:** Verification executes natively through failure paths and the explicit JSON schema is written to disk.

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID <task_slug>_work_item_01] [ID <task_slug>_work_item_02] [ID <task_slug>_work_item_N]
test -x scripts/<verifier-type>/verify_<task_slug>.sh && bash scripts/<verifier-type>/verify_<task_slug>.sh > evidence/<program>/<task_slug>.json || exit 1

# [ID <task_slug>_work_item_N]
test -f evidence/<program>/<task_slug>.json && cat evidence/<program>/<task_slug>.json | grep "observed_hashes" || exit 1

# [ID <task_slug>_work_item_N]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/<program_name>/<task_slug>.json`

Required fields:
- `task_id`: "<TASK-ID>"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `<domain_field_1>`: <what it must contain>
- `<domain_field_2>`: <what it must contain>

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. <Step 1: what to undo first>
2. <Step 2: migration rollback if applicable (expand/contract discipline)>
3. <Step 3: update status back to 'ready' in meta.yml>
4. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk
<!-- REQUIRED. Name what can go wrong in this specific task.
     These must match or extend the failure_modes in meta.yml. -->

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| <Named risk 1 from failure_modes> | FAIL / BLOCKED / CRITICAL_FAIL | <How to detect and handle> |
| <Named risk 2> | | |
| Anti-pattern: <anti_pattern from meta.yml> | FAIL_REVIEW | <How this plan guards against it> |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/<program>/approvals/<TASK-ID>.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
