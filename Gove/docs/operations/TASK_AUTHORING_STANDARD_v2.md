# Task Authoring Standard — Symphony v2

**Canonical reference:** `docs/operations/AI_AGENT_OPERATION_MANUAL.md`  
**Template locations:**
- `tasks/_template/meta.yml` — meta.yml template with inline guidance
- `docs/contracts/templates/PLAN_TEMPLATE.md` — PLAN.md companion template
- `docs/contracts/templates/TASK_DOD_TEMPLATE.yml` — DOD template (existing)

**Schema verifier:** `bash scripts/audit/verify_task_meta_schema.sh --mode strict`

---

## Why this standard exists

23 out of 383 tasks in the repo have zero content in `work`, `acceptance_criteria`,
`verification`, `evidence`, and `failure_modes`. They are structurally valid YAML but
operationally hollow. A coding agent reading a hollow task has no signal on what to do,
what not to do, how to prove it is done, or what failure looks like. This standard
eliminates hollow tasks.

The goal is not more YAML. The goal is **determinism**: an agent reading a task meta.yml
should be able to execute it correctly without asking any clarifying questions.

---

## The five fields that determine task quality

A task is **hollow** if any of these five fields is an empty list:

| Field | Hollow cost | What it causes |
|-------|-------------|----------------|
| `work` | Agent has no ordered steps | Implements the wrong thing or the right thing in the wrong order |
| `acceptance_criteria` | No definition of done | Task closes on vibes, not proof |
| `verification` | No runnable commands | Agent cannot self-check; CI cannot gate |
| `evidence` | No artifact path or contract | Phase closeout cannot verify the task ran |
| `failure_modes` | No named failure signatures | Regressions have no detection mechanism |

A task is **rich** when all five fields are populated AND each field passes the quality bar below.

---

## Quality bars per field

### `intent` (new required field)
**Minimum:** 2 sentences.  
**Must answer:** What problem does this close? What risk? Why now?  
**Bad:** `"Implements the SQL injection fix."`  
**Good:** `"The Python supervisor builds SQL from f-strings, bypassing the DB's parameterized SECURITY DEFINER layer. This task eliminates all interpolation patterns and installs a CI lint gate so that the vulnerability class cannot regress silently across any future refactor."`

### `anti_patterns` (new required field)
**Minimum:** 2 named anti-patterns specific to this task's domain.  
**Must name:** The governance theater and fake-PASS patterns that apply to this task type.  
**Bad:** Absent.  
**Good:**
```yaml
anti_patterns:
  - "Marking completed without running the negative test first"
  - "Writing the lint gate but not wiring it into CI (fake PASS pattern)"
  - "Using check_docs_match_manifest.py as a proxy for actual enforcement"
```

### `work`
**Minimum:** 3 items.  
**Each item must be:** Atomic, ordered, and verifiable. Each item must correspond to at least one `acceptance_criteria` check.  
**Bad:** `"Implement the feature."`  
**Good:** `"Audit src/supervisor_api/ for f-string SQL patterns. Document every occurrence in EXEC_LOG.md before writing any fix code. This is the audit step — it produces a finding list, not a fix."`

### `acceptance_criteria`
**Minimum:** 2 items for NORMAL/LOW priority. 3 items for HIGH/CRITICAL.  
**Each item must reference:** An exact script/command that produces a verifiable outcome.  
**Bad:** `"The feature works correctly."`  
**Good:** `"lint_sql_interpolation.sh exits 0 on the fixed codebase AND exits non-zero when run against a test file containing a known f-string SQL injection pattern. Both behaviors must be demonstrated."`

### `negative_tests`
**Minimum:** 1, always. CRITICAL priority tasks require 2.  
**What it proves:** That the exploit path or failure mode is actually blocked — not just that the happy path works.  
**Bad:** Absent.  
**Good:**
```yaml
negative_tests:
  - id: SEC-B-001-N1
    description: >-
      Craft a request with SQL metacharacters ('; DROP TABLE--) in the tenant_id field.
      The supervisor_api must return 400 or reject at binding layer. The SQL string must
      never be constructed. Verified by: running the endpoint with the payload and
      confirming via query log that no raw SQL containing the payload reaches the DB.
    required: true
```

### `verification`
**Minimum:** 3 commands: (1) task-specific verifier, (2) validate_evidence.py, (3) pre_ci.sh.  
**All commands must be runnable verbatim** with only DATABASE_URL set.  
**Bad:** `"Run the tests."`  
**Good:**
```yaml
verification:
  - bash scripts/security/lint_sql_interpolation.sh
  - python3 scripts/audit/validate_evidence.py --task SEC-B-001 --evidence evidence/security_remediation/sec_b_001_sql_injection_remediation.json
  - RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

### `evidence`
**Minimum:** 1 path with `must_include` field list.  
**must_include must name:** Domain-specific fields beyond the baseline (task_id, git_sha, timestamp_utc, status, checks).  
**Bad:** `- evidence/security_remediation/sec_b_001.json`  
**Good:**
```yaml
evidence:
  - path: evidence/security_remediation/sec_b_001_sql_injection_remediation.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - files_audited
      - violations_found
      - violations_fixed
      - remaining_exceptions
      - negative_test_passed
```

### `failure_modes`
**Minimum:** 2 items. CRITICAL priority requires 3.  
**Each item:** Named failure + consequence code.  
**Consequence codes:** FAIL | BLOCKED | CRITICAL_FAIL | FAIL_REVIEW  
**Bad:** `"Evidence file missing."` (too vague — what causes it?)  
**Good:**
```yaml
failure_modes:
  - "SQL f-string pattern found in src/ after fix is declared => CRITICAL_FAIL"
  - "lint_sql_interpolation.sh wired to CI but not covering Python source => FAIL (fake PASS pattern)"
  - "Negative test written after acceptance criteria declared done => BLOCKED"
```

---

## New required fields (v2 additions)

These fields did not exist in the original template. They are required for all new tasks
and must be backfilled into existing tasks when they are reopened for modification.

| Field | Type | Required | Default |
|-------|------|----------|---------|
| `intent` | string | YES | none |
| `anti_patterns` | list[string] | YES (min 2) | none |
| `priority` | enum | YES | NORMAL |
| `risk_class` | enum | YES | GOVERNANCE |
| `blast_radius` | enum | YES | DOCS_ONLY |
| `blocks` | list[task_id] | YES if has dependents | [] |
| `negative_tests` | list[object] | YES (min 1) | none |
| `positive_tests` | list[object] | Optional | [] |
| `evidence[].must_include` | list[string] | YES | none |

---

## Task type profiles

Different task types have different minimum requirements. Use these profiles as a floor,
not a ceiling.

### SECURITY task (risk_class: SECURITY)
```
priority:          CRITICAL or HIGH (never NORMAL for live holes)
anti_patterns:     min 3
work:              min 4 items (audit → fix → test → wire CI)
acceptance_criteria: min 3 (lint gate + negative test gate + CI wiring confirmation)
negative_tests:    min 2 (one per distinct exploit class)
failure_modes:     min 3
blast_radius:      APP_LAYER or DB_SCHEMA
```

### DB_SCHEMA task (blast_radius: DB_SCHEMA)
```
work:              must include: migration file creation, verifier script, SQLSTATE registration
acceptance_criteria: must include: constraint/trigger exists, SQLSTATE in sqlstate_map.yml, negative test passes
negative_tests:    min 1 (the constraint rejection scenario)
failure_modes:     must include: migration violates expand-first discipline => BLOCKED
verification:      must include: check_sqlstate_map_drift.sh
```

### GOVERNANCE / DOCS_ONLY task
```
priority:          NORMAL or LOW
anti_patterns:     min 2 (fake PASS and theater patterns are governance-specific)
work:              min 2 items
acceptance_criteria: min 2
negative_tests:    min 1 (prove the verifier catches a real violation)
failure_modes:     min 2
```

### CI_GATES task (blast_radius: CI_GATES)
```
work:              must include: script creation, CI wiring, parity test
acceptance_criteria: must include both: gate exits non-zero on violation AND gate is called in CI job
negative_tests:    REQUIRED: the gate must be shown to catch the thing it is supposed to catch
failure_modes:     must include: gate passes but does not cover the thing => FAIL (fake PASS)
```

---

## The PLAN.md companion

Every task needs a companion PLAN.md at `implementation_plan` path.  
The PLAN.md is **not optional**. The meta.yml is the contract. The PLAN.md is the instructions.

Minimum PLAN.md sections (from `docs/contracts/templates/PLAN_TEMPLATE.md`):

1. `failure_signature` — machine-readable failure ID for remediation trace
2. `objective` — what done looks like
3. `architectural_context` — why here, why now, what breaks if skipped
4. `pre_conditions` — what must be true before starting
5. `files_to_change` — exact list matching meta.yml::touches
6. `implementation_steps` — ordered, each with What / How / Done-when
7. `verification` — verbatim commands from meta.yml
8. `evidence_contract` — what the JSON must contain
9. `rollback` — how to undo (required for DB_SCHEMA and APP_LAYER)
10. `risk` — table of named risks with consequences and mitigations

---

## Schema enforcement

`scripts/audit/verify_task_meta_schema.sh --mode strict` checks:

- All required fields are non-empty
- `intent` is present and > 50 characters
- `anti_patterns` has >= 2 items
- `negative_tests` has >= 1 item with `required: true`
- `evidence` entries have `must_include` with >= 5 items
- `failure_modes` has >= 2 items using consequence code format
- `verification` has >= 3 commands
- `implementation_plan` path is referenced (existence check is in a separate gate)
- `priority`, `risk_class`, `blast_radius` are valid enum values
- `status` is a valid enum value

Failing this check blocks task assignment to any agent.

---

## Common mistakes and how to avoid them

**Mistake:** Filling `work` with the same text as `title`.
**Fix:** `work` items are implementation steps, not a restatement of the goal.

**Mistake:** Writing `failure_modes` as vague nouns ("evidence file missing").
**Fix:** Name what causes the failure and what happens: "Agent emits evidence before running negative test => BLOCKED".

**Mistake:** Writing `negative_tests` after the fix is complete.
**Fix:** The negative test must be written before acceptance criteria are declared done. The PLAN.md step order enforces this.

**Mistake:** Listing an evidence path without `must_include`.
**Fix:** Evidence without a field contract is unverifiable. Every path needs `must_include`.

**Mistake:** Leaving `anti_patterns` empty because "the task is obvious."
**Fix:** If the task is obvious, the anti-patterns are even more obvious. Name them.

**Mistake:** Setting `blast_radius: DOCS_ONLY` for a task that touches `schema/migrations/`.
**Fix:** blast_radius is derived from `touches`. If `touches` includes schema/ or services/, blast_radius is not DOCS_ONLY.

**Mistake:** Setting `blocks: []` when downstream tasks exist.
**Fix:** The `blocks` field makes the DAG bidirectionally auditable. If other tasks depend_on this one, list them in `blocks`.
