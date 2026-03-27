# <TASK-ID> PLAN — <Title>

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
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

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. -->

### Step 1: <Name of step>
**What:** <Exact action>
**How:** <Exact method: command, code pattern, file to copy>
**Done when:** <Observable output that confirms completion>

```bash
# Example command or code snippet for this step
```

### Step 2: <Name of step>
**What:** <Exact action>
**How:** <Exact method>
**Done when:** <Observable output>

### Step 3: Write the negative test BEFORE marking acceptance criteria done
<!-- This step is mandatory for all SECURITY and INTEGRITY risk_class tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** Implement <TASK-ID>-N1 negative test from meta.yml.
**How:** <Exact test: what input, what command, what expected output>
**Done when:** Test exits non-zero against unfixed code, exits 0 against fixed code.

### Step N: Emit evidence
**What:** Run verifier and validate evidence schema.
**How:**
```bash
bash scripts/<verifier-type>/verify_<task_slug>.sh
python3 scripts/audit/validate_evidence.py \
  --task <TASK-ID> \
  --evidence evidence/<program>/<task_slug>.json
```
**Done when:** Both commands exit 0. Evidence file exists and contains all must_include fields.

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim. -->

```bash
# 1. Task-specific verifier
bash scripts/<verifier-type>/verify_<task_slug>.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py \
  --task <TASK-ID> \
  --evidence evidence/<program>/<task_slug>.json

# 3. Full local parity check (must pass before committing)
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. -->

File: `evidence/<program_name>/<task_slug>.json`

Required fields:
- `task_id`: "<TASK-ID>"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects, each with `id`, `description`, `status`, `details`
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
