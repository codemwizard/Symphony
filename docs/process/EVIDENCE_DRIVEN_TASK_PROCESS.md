# Evidence-Driven Task Definition Process

## Purpose

Standardize how tasks are defined so that every task has **machine-verifiable acceptance criteria**, **negative tests proving the exploit/bug path is blocked**, and **deterministic evidence artifacts**. This prevents "paper compliance" — where tasks are marked done without proof.

---

## Process Overview

```
1. IDENTIFY → What needs to change and why
2. VALIDATE → Cross-reference against repo reality
3. DEFINE  → Write DOD YAML with acceptance checks + tests + evidence
4. REVIEW  → 8-point review checklist against codebase
5. COMMIT  → DOD YAML becomes the contract; implementation follows
```

---

## Step 1: Identify the Task

Before writing any YAML, answer these questions:

| Question | Purpose |
|----------|---------|
| What is the **intent**? | One sentence: what security/quality property does this establish? |
| What **changes** are required? | Exhaustive list of code, config, and doc changes |
| What **exploit or failure** does this prevent? | Drives negative test design |
| What **CI job** will enforce this? | Must be an existing job or create one first |
| What **evidence** proves it's done? | JSON artifact with specific fields |

---

## Step 2: Validate Against Repo Reality

Run the **8-point review checklist** before finalizing:

| # | Check | How to verify |
|---|-------|--------------|
| 1 | **Script paths match convention** | Lints → `scripts/security/`, verifiers → `scripts/audit/` |
| 2 | **CI jobs exist** | `grep 'job_name:' .github/workflows/*.yml` |
| 3 | **Current state is accurate** | Read the actual code; don't assume a change is needed if it's already done |
| 4 | **Task dependencies are acyclic** | Verify `depends_on` won't create blocking loops |
| 5 | **String matches aren't over-broad** | Lint deny patterns won't match comments, docs, or error messages |
| 6 | **Suppression mechanism is specified** | If CI can fail, how is a justified bypass managed? |
| 7 | **Cross-task dependencies noted** | If task A creates a Semgrep rule that task B relies on, declare it |
| 8 | **Evidence fields are observable** | Every `must_include` field can be populated by the verification command |

---

## Step 3: Write the DOD YAML

Use the template at `docs/contracts/templates/TASK_DOD_TEMPLATE.yml`.

### Required Sections per Task

```yaml
- task_id: <PREFIX>-<NNN>        # Unique ID
  phase: "<phase>"               # Execution phase
  title: "<short title>"         # Human-readable
  depends_on: [<task_ids>]       # Explicit dependencies
  intent: "<why this matters>"   # One sentence
  changes_required:              # Exhaustive change list
    - "<change 1>"
  dod:
    acceptance_checks:           # CI-enforced gates
      - id: <task_id>-A<N>
        description: "<what is checked>"
        status: REQUIRED
        ci_gate:
          job: <existing_ci_job>
          command: "<exact command>"
    negative_tests:              # Proves exploit/failure is blocked
      - id: <task_id>-N<N>
        description: "<what is tested>"
        required: true
    positive_tests:              # Proves correct behavior works
      - id: <task_id>-P<N>
        description: "<what is tested>"
        required: true
    evidence:
      path: "<evidence_root>/<task_id_snake>.json"
      schema: "<schema_root>/<task_id_snake>.schema.json"
      must_include:
        - "<observable_field>"
```

### Rules

1. **Every task MUST have ≥1 negative test** — what fails if the fix is reverted?
2. **Every acceptance check MUST have a CI gate** — manual-only checks are non-compliant
3. **Evidence JSON MUST include** `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks[]`
4. **Suppression comments** follow format: `# symphony:allow:<rule_id> reason=<justification> expires=<YYYY-MM-DD>`
5. **Script paths** follow convention: lints → `scripts/security/`, verifiers → `scripts/audit/`

---

## Step 4: Review

Run the 8-point checklist from Step 2 against the completed YAML. Fix any issues before committing.

Common pitfalls:
- CI job referenced that doesn't exist → add prerequisite task
- Acceptance check that greps for a string that also appears in docs/comments → use functional pattern
- Task A gates on `dotnet test` but the test project is created by Task B → declare dependency
- Evidence `must_include` field that no command actually produces → either change the command or the field

---

## Step 5: Commit and Implement

1. Commit the DOD YAML to `docs/contracts/`
2. Implementation follows the DOD as the contract
3. Each task produces its evidence artifact at the declared path
4. CI validates evidence + acceptance checks
5. Task is not marked done until ALL acceptance checks pass

---

## Integration with Existing Processes

This process extends the existing Symphony patterns:

| Existing Pattern | How This Integrates |
|-----------------|---------------------|
| Evidence-driven verification (`evidence/`) | DOD declares evidence paths and schemas |
| `SECURITY_MANIFEST.yml` | DOD tasks update the manifest when controls change |
| `scripts/audit/verify_*.sh` | DOD acceptance checks reference existing and new verifiers |
| `scripts/security/lint_*.sh` | DOD CI gates use existing and new lint scripts |
| Debug Remediation Policy (DRD) | If a DOD task encounters non-convergence, DRD process applies |
| Gravity-weighted rules | DOD task completion produces commit-ready artifacts per rule 2-3 |
