# Wave 5 Task Creation and Implementation: Lessons Learned Report

**Date:** 2026-04-23
**Author:** Cascade AI Agent
**Scope:** Analysis of Wave 5 remediation task creation vs Wave 4/earlier approaches
**Purpose:** Extract must-have requirements for future task templates

---

## Executive Summary

Wave 5 remediation task creation demonstrated a significant improvement in governance compliance compared to Wave 4 and earlier implementations. The key differentiator was the **explicit enforcement of Regulated Surface compliance and Remediation Trace documentation as mandatory pre-conditions** in the implementation plan, rather than as afterthoughts. This report documents the differences, traces implementation errors, and proposes an enhanced task template.

---

## Part 1: Wave 5 vs Wave 4 Implementation Plan Differences

### 1.1 Regulated Surface Compliance

**Wave 4 / Earlier Approach (TSK-P2-PREAUTH-005-01 PLAN.md):**
- No explicit mention of regulated surface compliance in the PLAN.md
- Approval section was generic: "This task modifies database schema (HIGHEST RISK area). Requires human review before merge."
- No reference to REGULATED_SURFACE_PATHS.yml
- No requirement for approval metadata BEFORE editing migration files
- No Stage A / Stage B approval workflow

**Wave 5 Approach (Wave5-remediation-atomic-tasks-cee35f.md):**
- **Explicit CRITICAL section** titled "Regulated Surface Compliance (CRITICAL)"
- Direct reference to REGULATED_SURFACE_PATHS.yml
- **Mandatory pre-condition**: "MUST NOT edit any migration file without prior approval metadata"
- **Approval artifacts MUST be created BEFORE editing regulated surfaces**
- Two-stage approval workflow:
  - Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch-name>.md and .approval.json)
  - Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Validation with approval_metadata.schema.json
- Conformance check with `--mode=stage-a --branch=<branch-name>`

**Impact:** This prevented the common anti-pattern of editing regulated surfaces first and creating approval artifacts as an afterthought (or forgetting them entirely).

### 1.2 Remediation Trace Compliance

**Wave 4 / Earlier Approach (TSK-P2-PREAUTH-005-01 PLAN.md):**
- No mention of remediation trace requirements
- No required markers in EXEC_LOG.md
- EXEC_LOG.md was optional or not structured for remediation trace
- No reference to REMEDIATION_TRACE_WORKFLOW.md

**Wave 5 Approach (Wave5-remediation-atomic-tasks-cee35f.md):**
- **Explicit CRITICAL section** titled "Remediation Trace Compliance (CRITICAL)"
- Direct reference to REMEDIATION_TRACE_WORKFLOW.md
- **Mandatory EXEC_LOG.md markers**: failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
- **Append-only requirement**: "EXEC_LOG.md is append-only - never delete or modify existing entries"
- **Timing requirement**: "Markers must be present when migration file is modified - not deferred to pre_ci"
- Task PLAN.md/EXEC_LOG.md pair explicitly satisfies remediation trace requirement

**Impact:** This ensured that every regulated surface change carried a durable, searchable trace of the debugging and remediation work, preventing "silent fixes" with no audit trail.

### 1.3 Implementation Sequence Enforcement

**Wave 4 / Earlier Approach (TSK-P2-PREAUTH-005-01 PLAN.md):**
- Implementation steps were:
  1. Write migration
  2. Update MIGRATION_HEAD
  3. Write verification script
  4. Write negative test
  5. Run verification
- No pre-edit documentation step
- Approval metadata could be created at any point (or not at all)

**Wave 5 Approach (Wave5-remediation-atomic-tasks-cee35f.md):**
- **Mandatory sequence** for each remediation task:
  1. **Pre-Edit Documentation (Before touching any file):**
     - Create Stage A approval artifact
     - Create Stage A approval sidecar
     - Validate with approval_metadata.schema.json
     - Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command
  2. **File Modification:**
     - Edit migration file or trigger function
     - Update EXEC_LOG.md with exact change made
  3. **Post-Edit Documentation:**
     - Update EXEC_LOG.md with verification_commands_run and final_status
     - Run conformance check with `--mode=stage-a --branch=<branch-name>`
  4. **After PR Opening:**
     - Create Stage B approval artifact
     - Create Stage B approval sidecar
     - Run conformance check with `--mode=stage-b --pr=<PR-number>`

**Impact:** This enforced the "documentation first" discipline, preventing the common anti-pattern of implementing first and documenting later (or never).

### 1.4 Stop Conditions

**Wave 4 / Earlier Approach (TSK-P2-PREAUTH-005-01 PLAN.md):**
- Stop conditions were generic:
  - "If any node in the proof graph is orphaned"
  - "If any verifier lacks a symbolic failure obligation"
  - "If evidence is static or self-declared"
  - "If verification does not inspect real system state"
  - "If ≥3 weak signals detected"
- No specific stop conditions for regulated surface compliance

**Wave 5 Approach (Wave5-remediation-atomic-tasks-cee35f.md):**
- **Specific stop conditions for regulated surfaces:**
  - "If approval metadata is not created before editing migration" -> STOP
- **Specific stop conditions for remediation trace:**
  - "If EXEC_LOG.md does not contain all required markers" -> STOP
- **Specific stop conditions for migration modification:**
  - "If MIGRATION_HEAD is not updated" -> STOP

**Impact:** This provided clear, actionable stop conditions that agents could mechanically check before proceeding.

---

## Part 2: Implementation Errors Traced from Chat History

### 2.1 DATABASE_URL Not Used When Required

**Error:** Initial verification commands in Wave 5 tasks did not use DATABASE_URL environment variable.

**Evidence from chat history:**
- User requested: "Continue testing with DATABASE_URL after cleanup"
- This indicates that earlier verification attempts were not using DATABASE_URL properly

**Root Cause:** TASK_AUTHORING_STANDARD_v2.md section 91-96 states:
> "All commands must be runnable verbatim with only DATABASE_URL set."

However, the Wave 5 task meta.yml files initially had verification commands that did not consistently use `psql "$DATABASE_URL"` format.

**Prevention at Task Creation Time:**
- Task template should require DATABASE_URL in all verification commands
- PLAN.md should explicitly state: "All verification commands must use DATABASE_URL environment variable"
- meta.yml verification field should have a comment: "Must use DATABASE_URL for all database operations"

### 2.2 Database Credentials Not Known from Start

**Error:** The database connection string format was not documented in the task creation phase.

**Evidence from chat history:**
- During implementation, had to reference infra/docker/docker-compose.yml to find credentials
- Connection string: `postgresql://symphony_admin:symphony_pass@localhost:5432/symphony`
- Container name: symphony-postgres

**Root Cause:** Task meta.yml and PLAN.md did not include:
- Database connection string format
- Container name (for docker exec)
- How to set DATABASE_URL

**Prevention at Task Creation Time:**
- Task template should include a `database_connection` section for DB_SCHEMA tasks
- Should document:
  - Connection string format
  - Container name (if using Docker)
  - How to set DATABASE_URL
  - Example: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"`

### 2.3 Migration Ordering Bug (0121 referencing state_transitions)

**Error:** Migration 0121 tried to ALTER TABLE state_transitions, but that table doesn't exist until migration 0137.

**Evidence from chat history:**
- pre_ci failure: `psql:/home/mwiza/workspaces/Symphony-Demo/Symphony/schema/migrations/0121_create_data_authority_enum.sql:34: ERROR: relation "state_transitions" does not exist`
- Fix required: Remove state_transitions ALTER statements from 0121, add columns to 0137 table definition instead

**Root Cause:** Task creation did not include:
- Migration dependency analysis
- Verification that referenced tables exist in earlier migrations
- Pre-verification of migration ordering

**Prevention at Task Creation Time:**
- Task template for DB_SCHEMA tasks should require:
  - `migration_dependencies` field listing earlier migrations that must exist
  - `table_dependencies` field listing tables that must exist
  - Verification step: "Confirm all referenced tables exist in earlier migrations"
- PLAN.md should include a "Migration Dependencies" section

### 2.4 Task Meta Schema Compliance Failures

**Error:** 7 Wave 5 remediation task meta.yml files failed verify_task_meta_schema.sh with:
- schema_version_not_v1:1.0
- missing_required: invariants, notes, client, assigned_agent, model

**Evidence from chat history:**
- Governance preflight failure showing all 7 REM tasks nonconforming
- Required fixing schema_version from "1.0" to 1
- Required adding missing fields

**Root Cause:** Task creation did not follow the current template strictly. The tasks were created with:
- schema_version: "1.0" (string) instead of 1 (integer)
- Missing invariants field
- Missing notes field
- Missing client field
- Missing assigned_agent field
- Missing model field

**Prevention at Task Creation Time:**
- Task template should have these fields as REQUIRED with non-empty defaults
- verify_task_meta_schema.sh should be run BEFORE task status can move to 'ready'
- Template should include explicit "DO NOT CHANGE" markers for schema_version

### 2.5 Churn Cleanup Required Before Commit

**Error:** Work tree had 258 files of churn that needed cleanup before commit.

**Evidence from chat history:**
- User requested: "Commit these files. But before committing them, read up on the Churn Cleanup policy"
- Required reading docs/operations/EVIDENCE_CHURN_CLEANUP_POLICY.md
- Required computing keep-set and deleting incidental churn

**Root Cause:** Task creation did not include:
- Churn cleanup as a mandatory step
- Definition of what files should be in the deliverable
- Clean work tree requirement before commit

**Prevention at Task Creation Time:**
- Task template should include a `deliverable_files` field listing exactly what files constitute the task output
- PLAN.md should include a "Cleanup" step: "Remove incidental churn before commit"
- Should reference EVIDENCE_CHURN_CLEANUP_POLICY.md

---

## Part 3: Enhanced Task Template

Based on the analysis above, here is an enhanced task template that incorporates all must-have requirements:

```yaml
# ══════════════════════════════════════════════════════════════════════════════
# Symphony Task Meta — Enhanced Template v3 (Wave 5 Lessons Learned)
#
# ENHANCEMENTS OVER v2:
# - Explicit regulated surface compliance requirements
# - Explicit remediation trace compliance requirements
# - Database connection documentation for DB_SCHEMA tasks
# - Migration dependency tracking for DB_SCHEMA tasks
# - Deliverable files list for churn control
# - DATABASE_URL enforcement in verification commands
# ══════════════════════════════════════════════════════════════════════════════

schema_version: 1  # DO NOT CHANGE - must be integer 1
phase: '<PHASE>'   # '0', '1', 'sec-revamp', etc.
task_id: <TASK-ID>
title: "<Verb> <object> so that <outcome>"
owner_role: <AGENT-ROLE>
status: planned
priority: NORMAL
risk_class: GOVERNANCE
blast_radius: DOCS_ONLY

# ── Why this task exists ───────────────────────────────────────────────────
intent: >-
  <2-4 sentences: what problem, what risk, why now. Reference the architectural
  diagnosis. Cite the anti-pattern being closed.>

# ── What this task must NOT do ─────────────────────────────────────────────
anti_patterns:
  - "<Anti-pattern 1: specific to this domain>"
  - "<Anti-pattern 2: governance theater pattern>"
  - "<Anti-pattern 3: fake PASS pattern>"

# ── Anti-drift boundaries ──────────────────────────────────────────────────
out_of_scope:
  - "<Non-goal 1>"
stop_conditions:
  - "<Stop condition 1: boundary failure state>"
  - "<Stop condition 2: compliance failure state>"

# ── Proof limits ───────────────────────────────────────────────────────────
proof_guarantees:
  - "<Guarantee: specific assertion covered by verification>"
proof_limitations:
  - "<Limitation: verification bypass or manual review gap>"

# ── Dependencies ───────────────────────────────────────────────────────────
depends_on:
  - <TASK-ID-OR-CHECKPOINT>
blocks:
  - <TASK-ID>

# ── File scope ─────────────────────────────────────────────────────────────
touches:
  - <exact/file/path/one>
  - <exact/file/path/two>
  - tasks/<TASK-ID>/meta.yml

# ── Deliverable files (for churn control) ─────────────────────────────────
# NEW: List exactly what files constitute the task output. Any other files
# created during implementation are incidental churn and must be removed before commit.
deliverable_files:
  - <exact/file/path/one>
  - <exact/file/path/two>
  - docs/plans/<phase>/<TASK-ID>/PLAN.md
  - docs/plans/<phase>/<TASK-ID>/EXEC_LOG.md

# ── Invariants ─────────────────────────────────────────────────────────────
invariants:
  - INV-XXX

# ── Regulated Surface Compliance (CRITICAL) ───────────────────────────────
# NEW: Required for tasks touching regulated surfaces per REGULATED_SURFACE_PATHS.yml
# If touches includes schema/migrations/**, scripts/security/**, scripts/audit/**,
# docs/operations/**, evidence/**, docs/PHASE1/**, docs/control_planes/**, this section is REQUIRED.
regulated_surface_compliance:
  enabled: false  # Set to true if task touches regulated surfaces
  approval_workflow: stage_a_stage_b  # Options: none, stage_a_only, stage_a_stage_b
  stage_a_required_before_edit: true  # Approval artifacts must exist BEFORE editing files
  regulated_paths:
    - <path from REGULATED_SURFACE_PATHS.yml>
  must_read:
    - docs/operations/REGULATED_SURFACE_PATHS.yml
    - docs/operations/approval_metadata.schema.json

# ── Remediation Trace Compliance (CRITICAL) ───────────────────────────────
# NEW: Required for tasks touching production-affecting surfaces per REMEDIATION_TRACE_WORKFLOW.md
# If touches includes schema/**, scripts/**, .github/workflows/**, src/**, packages/**,
# infra/**, docs/PHASE0/**, docs/invariants/**, docs/control_planes/**, this section is REQUIRED.
remediation_trace_compliance:
  enabled: false  # Set to true if task touches production-affecting surfaces
  required_markers:
    - failure_signature
    - origin_task_id
    - repro_command
    - verification_commands_run
    - final_status
  marker_location: EXEC_LOG.md  # PLAN.md/EXEC_LOG.md pair satisfies requirement
  append_only: true  # EXEC_LOG.md must be append-only, never rewrite history
  markers_required_at_edit: true  # Markers must be present when file is modified, not deferred
  must_read:
    - docs/operations/REMEDIATION_TRACE_WORKFLOW.md

# ── Database Connection (for DB_SCHEMA tasks) ───────────────────────────────
# NEW: Required for blast_radius: DB_SCHEMA tasks
database_connection:
  enabled: false  # Set to true for DB_SCHEMA tasks
  connection_string_format: "postgresql://<user>:<password>@<host>:<port>/<database>"
  example_connection_string: "postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"
  container_name: <container-name>  # If using Docker
  database_url_env_var: DATABASE_URL
  setup_command: "export DATABASE_URL=\"postgresql://symphony_admin:symphony_pass@localhost:5432/symphony\""

# ── Migration Dependencies (for DB_SCHEMA tasks) ─────────────────────────
# NEW: Required for tasks that create or modify migrations
migration_dependencies:
  enabled: false  # Set to true for migration tasks
  required_migrations:
    - <migration-number>: <description>
  table_dependencies:
    - <table-name>: <must-exist-in-migration>
  verification_step: "Confirm all referenced tables exist in earlier migrations"

# ── Work items ─────────────────────────────────────────────────────────────
work:
  - >-
    <Step 1: specific, verifiable, atomic action. For regulated surface tasks:
     Step 1 MUST be: Create Stage A approval artifact BEFORE editing any file.>
  - >-
    <Step 2: next atomic action. Include exact file names.>
  - >-
    <Step 3: ...>

# ── Acceptance criteria ────────────────────────────────────────────────────
acceptance_criteria:
  - >-
    <Criterion 1: what is true, how is it verified, what CI job enforces it.
     For regulated surface tasks: Include approval artifact validation.>
  - >-
    <Criterion 2: ...>

# ── Negative tests ─────────────────────────────────────────────────────────
negative_tests:
  - id: <TASK-ID>-N1
    description: >-
      <What adversarial input or missing condition is tested.>
    required: true

# ── Positive tests ─────────────────────────────────────────────────────────
positive_tests:
  - id: <TASK-ID>-P1
    description: >-
      <What the legitimate/expected input produces after the fix.>
    required: false

# ── Verification commands ──────────────────────────────────────────────────
# CRITICAL: All commands must be runnable verbatim with only DATABASE_URL set.
# For DB_SCHEMA tasks, all psql commands must use "$DATABASE_URL" environment variable.
verification:
  - bash scripts/<verifier-type>/verify_<task_slug>.sh
  - python3 scripts/audit/validate_evidence.py --task <TASK-ID> --evidence evidence/<program>/<task_slug>.json
  - RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh

# ── Evidence contract ──────────────────────────────────────────────────────
evidence:
  - path: evidence/<program_name>/<task_slug>.json
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - <domain_specific_field_1>
      - <domain_specific_field_2>

# ── Failure modes ──────────────────────────────────────────────────────────
failure_modes:
  - "<What goes wrong: specific, named> => FAIL"
  - "<What the agent does wrong: e.g., edits regulated surface without approval> => CRITICAL_FAIL"
  - "<What creates a governance regression: named anti-pattern> => BLOCKED"

# ── Required reading ───────────────────────────────────────────────────────
must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - <domain-specific doc 1>
  - <domain-specific doc 2>

# ── Companion documents ────────────────────────────────────────────────────
implementation_plan: docs/plans/<phase>/<TASK-ID>/PLAN.md
implementation_log: docs/plans/<phase>/<TASK-ID>/EXEC_LOG.md

# ── Metadata ───────────────────────────────────────────────────────────────
notes: >-
  <Ordering rationale, known exceptions, architecture decisions.>
client: codex_cli
assigned_agent: <agent-id>
model: <UNASSIGNED>
```

---

## Part 4: Comparison with Current Template (tasks/_template/meta.yml)

### 4.1 New Fields in Enhanced Template

| Field | Current Template | Enhanced Template | Rationale |
|-------|------------------|-------------------|-----------|
| `deliverable_files` | Not present | NEW | Controls churn by defining exact deliverables |
| `regulated_surface_compliance` | Not present | NEW | Enforces approval workflow for regulated surfaces |
| `remediation_trace_compliance` | Not present | NEW | Enforces remediation trace markers for production-affecting changes |
| `database_connection` | Not present | NEW | Documents DB connection for DB_SCHEMA tasks |
| `migration_dependencies` | Not present | NEW | Tracks migration/table dependencies to prevent ordering bugs |

### 4.2 Enhanced Fields in Enhanced Template

| Field | Current Template | Enhanced Template | Enhancement |
|-------|------------------|-------------------|-------------|
| `schema_version` | Comment: "Always 1. Do not change." | Comment: "DO NOT CHANGE - must be integer 1" | More explicit about integer type |
| `stop_conditions` | Generic examples | Specific compliance stop conditions | Adds regulated surface and remediation trace stop conditions |
| `verification` | Generic example | Comment about DATABASE_URL requirement | Explicit DATABASE_URL enforcement |
| `work` | Generic guidance | Specific guidance for regulated surface tasks | Enforces "approval first" sequence |
| `acceptance_criteria` | Generic guidance | Specific guidance for regulated surface tasks | Includes approval artifact validation |

### 4.3 Unchanged Fields

The following fields remain unchanged and are already well-defined in the current template:
- `phase`, `task_id`, `title`, `owner_role`, `status`
- `priority`, `risk_class`, `blast_radius`
- `intent`, `anti_patterns`, `out_of_scope`
- `proof_guarantees`, `proof_limitations`
- `depends_on`, `blocks`, `touches`
- `invariants`
- `negative_tests`, `positive_tests`
- `evidence`, `failure_modes`
- `must_read`, `implementation_plan`, `implementation_log`
- `notes`, `client`, `assigned_agent`, `model`

### 4.4 Recommendation: Is a New Template Worth It?

**YES, a new template is worth it.**

**Reasons:**

1. **Prevents Specific Errors:** The new fields directly address the errors encountered in Wave 5:
   - `regulated_surface_compliance` prevents editing regulated surfaces without approval
   - `remediation_trace_compliance` prevents missing remediation trace markers
   - `database_connection` prevents DATABASE_URL confusion
   - `migration_dependencies` prevents migration ordering bugs
   - `deliverable_files` prevents churn accumulation

2. **Enforces Governance:** The current template relies on human discipline to remember regulated surface and remediation trace requirements. The enhanced template makes them explicit, mechanical requirements.

3. **Reduces Cognitive Load:** Agents don't need to remember to check REGULATED_SURFACE_PATHS.yml or REMEDIATION_TRACE_WORKFLOW.md - the template tells them exactly what to do.

4. **Improves Determinism:** The enhanced template makes task execution more deterministic by reducing the number of implicit requirements.

5. **Backward Compatible:** The new fields are optional (enabled: false by default), so existing tasks continue to work. New tasks can opt-in to the enhanced features.

**Implementation Strategy:**

1. Create `tasks/_template/meta_v3.yml` with the enhanced template
2. Keep `tasks/_template/meta.yml` as the v2 template for backward compatibility
3. Update TASK_AUTHORING_STANDARD_v2.md to reference v3 for new tasks
4. Update verify_task_meta_schema.sh to validate new fields when present
5. Migrate existing tasks to v3 over time as they are reopened

---

## Part 5: Summary of Must-Have Requirements

Based on Wave 5 lessons learned, the following are **must-have requirements** for all future tasks:

### 5.1 For All Tasks Touching Regulated Surfaces

1. **Approval Before Edit:** Approval artifacts MUST be created BEFORE editing any regulated surface file
2. **Two-Stage Workflow:** Stage A (before edit) and Stage B (after PR) approval artifacts
3. **Schema Validation:** Approval artifacts must validate against approval_metadata.schema.json
4. **Stop Condition:** Task must STOP if approval metadata is not created before editing

### 5.2 For All Tasks Touching Production-Affecting Surfaces

1. **Remediation Trace Markers:** EXEC_LOG.md must include failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
2. **Append-Only:** EXEC_LOG.md must be append-only, never rewrite history
3. **At Edit Time:** Markers must be present when file is modified, not deferred to pre_ci
4. **Stop Condition:** Task must STOP if EXEC_LOG.md does not contain all required markers

### 5.3 For All DB_SCHEMA Tasks

1. **DATABASE_URL Documentation:** Connection string format, container name, setup command must be documented
2. **DATABASE_URL Usage:** All verification commands must use DATABASE_URL environment variable
3. **Migration Dependencies:** Must list required migrations and table dependencies
4. **Dependency Verification:** Must verify all referenced tables exist in earlier migrations

### 5.4 For All Tasks

1. **Deliverable Files List:** Must define exactly what files constitute the task output
2. **Churn Cleanup:** Must remove incidental churn before commit
3. **Schema Version:** Must be integer 1, not string "1.0"
4. **Required Fields:** invariants, notes, client, assigned_agent, model must be present

---

## Part 6: Conclusion

Wave 5 demonstrated that explicit governance requirements in the task creation phase significantly reduce implementation errors. By making Regulated Surface compliance and Remediation Trace compliance mandatory pre-conditions in the task template, we can prevent the common anti-patterns of:

- Editing regulated surfaces without approval
- Missing remediation trace markers
- DATABASE_URL confusion
- Migration ordering bugs
- Churn accumulation

The enhanced template (v3) incorporates these lessons learned while maintaining backward compatibility. It is recommended to adopt this template for all new tasks and migrate existing tasks over time as they are reopened.
