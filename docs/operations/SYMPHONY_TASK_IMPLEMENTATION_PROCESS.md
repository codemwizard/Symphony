# Symphony Task Implementation Process

This document provides comprehensive instructions for a coding agent to implement Symphony tasks in full compliance with the Symphony Task Implementation Process. These instructions are task-agnostic and apply to all phases and task types.

## Overview

This document outlines the complete implementation process for Symphony tasks, covering pre-flight checks, mode classification, boot sequence, regulated surface compliance, evidence production, and post-implementation governance. All tasks must follow this process regardless of phase or complexity.

## Pre-Step: Rejection Context / DRD Lockout Check (MANDATORY)

Before any mode classification or implementation work begins, the agent MUST perform this pre-step as defined in AGENT_ENTRYPOINT.md:

1. **Check for `.agent/rejection_context.md`**
   - If it exists, read it fully — it contains the real failure reason and artifact paths
   - Check `DRD_STATUS` in the file

2. **If DRD_STATUS: ACTIVE_LOCKOUT**
   - The agent is **mechanically blocked** from running `pre_ci.sh` (exits 99) and `run_task.sh` (exits 99)
   - You MUST create the remediation casefile using the `DRD_SCAFFOLD_CMD` shown in the file
   - Then clear the lockout with: `bash scripts/audit/verify_drd_casefile.sh --clear`
   - Do NOT attempt to remove the lockout file directly

3. **If DRD_STATUS: NOT_ACTIVE**
   - Default to REMEDIATE mode unless the human explicitly states otherwise

4. **Check for evidence ack gate state**
   - If `.toolchain/evidence_ack/<TASK_ID>.required` exists, `run_task.sh` will exit 51 on the next run until you write a valid ack file
   - Read the failure artifacts first, then create the ack file as directed by the exit message
   - If retry count is >= 3, `run_task.sh` will exit 50 (hard block) — a human must run `bash scripts/audit/reset_evidence_gate.sh <TASK_ID>` to clear it

5. **Do not begin new implementation work** until the prior failure is resolved
6. **The artifact paths in the rejection context file are the source of truth** — do not infer or assume what they contain

If `.agent/rejection_context.md` does not exist: proceed to Mode Classification.

## Mode Classification (MANDATORY)

Before any implementation work, the agent MUST:

1. **Read AGENT_ENTRYPOINT.md** (canonical entry point)
2. **Classify the incoming prompt** against all five modes in AGENT_PROMPT_ROUTER.md:
   - Mode 1: CREATE-TASK
   - Mode 2: RESUME-TASK
   - Mode 3: IMPLEMENT-TASK
   - Mode 4: REMEDIATE
   - Mode 5: PUSH-READY-CHECK

3. **If the prompt does not map to exactly one mode** after non-mutating inspection: STOP and ask the human which mode applies. Do not guess.

4. **For task implementation**, the agent must operate in Mode 3 (IMPLEMENT-TASK), but only after passing Mode 2 (RESUME-TASK) inspection.

## Mode 2: RESUME-TASK Inspection Algorithm (MANDATORY Before IMPLEMENT-TASK)

The agent must run this ordered inspection algorithm before IMPLEMENT-TASK is permitted. Stop on first failure:

1. **Meta readable**
   - If `tasks/<TASK_ID>/meta.yml` is missing or unreadable: report `STATE: stub-only` and STOP

2. **Plan present**
   - If `implementation_plan` does not resolve: report `STATE: plan-missing` and STOP

3. **Log present**
   - If `implementation_log` does not resolve: report `STATE: log-missing` and STOP

4. **Pack ready**
   - Run: `bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>`
   - If it fails: report `STATE: not-ready` and STOP with the readiness output

5. **Dependencies satisfied**
   - Every task in `depends_on` must be `completed`
   - If not: report `STATE: blocked` and list the blocking tasks

6. **If all pass**
   - Report `STATE: resume-ready` and continue to Mode 3 (IMPLEMENT-TASK)

**The agent must not implement from any state other than `resume-ready`.**

## Pre-Flight Requirements

Before any implementation work begins, the agent must:

1. **Verify current branch is not main** - Work must occur on a feature branch only
2. **Read the task's touches list** from meta.yml to understand permitted file modifications
3. **Check for scope drift** - If intended modifications fall outside touches, STOP and report
4. **Check regulated surface approval requirements** - If task touches regulated surfaces, verify approval metadata exists before writing those files

## Boot Sequence (IMPLEMENT-TASK Mode)

Execute the following sequence in exact order. If any step fails, STOP immediately and open or update remediation trace:

1. **Conformance Gate**: `scripts/audit/verify_agent_conformance.sh`
   - Validates canonical references, stop conditions, regulated-surface approval metadata
   - Emits role-scoped conformance evidence

2. **Local Parity Gate**: `scripts/dev/pre_ci.sh`
   - Fresh DB, ordered checks, remediation trace validation
   - Evidence scripts must produce evidence JSON files

3. **Task Execution**: `scripts/agent/run_task.sh <TASK_ID>`
   - Parses meta.yml
   - Runs verification commands from meta.yml
   - Produces evidence artifacts
   - Validates evidence freshness

## Task-Specific Implementation Instructions

### Step 1: Read Task Metadata

Read the task's meta.yml to understand:
- `touches`: List of files permitted for modification
- `verification`: Verification commands to run
- `evidence`: Evidence artifacts to produce
- `must_read`: Required documentation to review
- `invariants`: Invariants enforced by this task
- `stop_conditions`: Conditions that must halt implementation

### Step 2: Read Required Documentation

Read all documents listed in `must_read` before making any changes:
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
- docs/operations/TASK_CREATION_PROCESS.md
- Phase-specific implementation plans
- Any other task-specific documentation

### Step 3: Read the Implementation Plan

Read the PLAN.md at the path specified in `implementation_plan` to understand:
- Objective and architectural context
- Pre-conditions
- Files to change
- Stop conditions
- Implementation steps (with ID tags)
- Verification requirements
- Evidence contract
- Rollback procedure
- Risk assessment

**PLAN.md Required Fields**:
Per docs/contracts/templates/PLAN_TEMPLATE.md, every PLAN.md must have these required fields at the top (front-matter format):
- `failure_signature: <PHASE>.<TRACK>.<TASK-SLUG>.<FAILURE-CLASS>` — Must match format used in `verify_remediation_trace.sh`
- `canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md` — Apex authority reference

**Note**: Existing PLAN.md files may use "Failure Signature" as an inline bold header. The agent should verify these are converted to the correct front-matter field format before implementation.

### Step 4: Implement According to PLAN.md

Follow the implementation steps in PLAN.md exactly as written. For each step:

1. **What**: Understand the work item with its ID tag
2. **How**: Execute the exact method specified (command, code pattern, file to copy)
3. **Done when**: Verify the observable output matches the completion criteria

**Critical**: Do not deviate from the PLAN.md. If you encounter a blocker, STOP and open remediation trace.

### Step 5: Modify Only Files in touches List

The agent may only modify files listed in the task's `touches` field.

**Scope drift rule**: If you need to modify files outside touches, STOP and report scope drift. Return to task-pack repair instead of silently expanding scope.

### Step 6: Implement Negative Tests (Mandatory)

Per PLAN_TEMPLATE.md, negative tests are mandatory for all tasks. The agent MUST:

1. **Write the negative test BEFORE implementing the fix** — This is a mandatory ordering requirement
2. **Prove it catches the problem** — The negative test must fail against the unfixed code
3. **Verify it passes after the fix** — After implementing the fix, the negative test must pass

**Critical**: Do not write the negative test after the fix. The negative test must be written first to prove it detects the issue before the fix is applied.

The negative test should be implemented as part of the verification script and must:
- Have a clear ID tag matching meta.yml (e.g., <TASK_ID>-N1)
- Test the specific failure condition described in the negative test
- Be executable independently from the positive verification path

### Step 7: Produce Evidence Artifacts (MANDATORY EXECUTION)

**CRITICAL**: Creating verification scripts and evidence schemas is NOT sufficient. The agent MUST execute the verification commands against a running database to produce actual evidence artifacts. Full implementation requires:

1. **Execute verification scripts** - Run the verification commands listed in meta.yml
2. **Produce evidence JSON** - Evidence must be written to the specified paths
3. **Verify evidence freshness** - Evidence must include `run_id` matching the current execution

For each verification command in meta.yml, ensure it:
- Inspects external system state (not self-referential)
- Has explicit failure path (`|| exit 1`)
- Writes evidence to the path specified in `evidence` field
- Includes required fields: task_id, git_sha, timestamp_utc, status, checks, and task-specific fields

**Evidence freshness**: Evidence must include `run_id` matching the current execution. Stale evidence (from previous runs) will be rejected.

**Verification execution is mandatory**: A task is NOT complete until verification scripts have been executed and evidence artifacts have been produced. Merely creating verification scripts without executing them does NOT constitute a complete implementation.

### Step 8: Update EXEC_LOG.md (Append-Only)

Update the EXEC_LOG.md at the path specified in `implementation_log`:

```markdown
## Execution History

| Timestamp | Action | Result |
|-----------|--------|--------|
| <ISO-8601 timestamp> | <action description> | <result> |
```

**Append-only rule**: Never delete or modify existing entries. Only add new entries.

**Required Remediation Markers for Production-Affecting Surfaces**:
When a task plan/log serves as a remediation trace (i.e., when the change touches production-affecting surfaces), the EXEC_LOG MUST contain these specific markers per REMEDIATION_TRACE_WORKFLOW.md:

- `failure_signature` — Format: `<PHASE>.<TRACK>.<TASK-SLUG>.<FAILURE-CLASS>`
- `origin_task_id` (or `origin_gate_id`) — The originating task or gate that caused this remediation
- `repro_command` — Command to reproduce the failure
- `verification_commands_run` — List of verification commands executed
- `final_status` — Final status after remediation (e.g., RESOLVED, BLOCKED, ESCALATED)

Example EXEC_LOG entry with remediation markers:
```markdown
| <timestamp> | Remediation for schema drift in migration <number> | failure_signature: <PHASE>.<TRACK>.<TASK-SLUG>.<FAILURE-CLASS>; origin_task_id: <TASK_ID>; repro_command: bash scripts/db/verify_<task>.sh; verification_commands_run: [verification_1, verification_2]; final_status: RESOLVED | Documented in EXEC_LOG |
```

## Post-Implementation Schema & Structural Drift Remediation (MANDATORY)

After implementing migration files, the agent MUST resolve the following governance gates that will inevitably fail during `pre_ci.sh`. These steps are required to satisfy pipeline gates.

### Step 9: Resolve Structural Change Governance (Change-Rule Gate)

Whenever a new migration or structural code is added, the `PRECI.STRUCTURAL.CHANGE_RULE` gate will flag it. The agent MUST manually document the change in the architecture documents:

1. **Append entry to `docs/architecture/THREAT_MODEL.md`**
   - Detail the security implications (or lack thereof) of the new tables/columns
   - Document any new attack vectors introduced
   - Specify mitigation strategies if applicable

2. **Append entry to `docs/architecture/COMPLIANCE_MAP.md`**
   - Map the change to its corresponding compliance control
   - Reference the specific control framework requirement
   - Document audit trail implications

**Critical**: Failure to do this will block the pipeline. Do not rely on auto-generated exception files.

### Step 10: Resolve Schema Baseline Drift

New migrations alter the database schema, causing the `DB-BASELINE-DRIFT` check to fail because the ephemeral DB schema hash no longer matches the committed baseline. 

**CRITICAL**: Do NOT rely on `pre_ci.sh` to auto-regenerate the baseline. By design, `pre_ci.sh` acts as a strict governance enforcement gate - it checks for drift and fails explicitly when it finds it, and it drops the ephemeral database after its testing run (even on failure). You must explicitly provision a developer database to regenerate the snapshot.

**Why this happens:**
Whenever standard DDL operations (`CREATE`, `ALTER`, `DROP`) are introduced into a new migration file:
1. The structural hash of the database deviates from the committed baseline
2. The automated `check_baseline_drift.sh` script performs a canonical comparison between the old `schema/baseline.sql` and the live ephemeral database representation
3. The `pre_ci.sh` script stops the process to ensure no blind schema changes are pushed without the architect intentionally logging it via `generate_baseline_snapshot.sh`
4. This is a governance enforcement mechanism to maintain auditability of all schema changes

**Path A: Check for REGEN_BASELINE flag (Preferred)**

Before manual regeneration, check whether `pre_ci.sh` supports an auto-regenerate flag:

```bash
grep -n "REGEN_BASELINE\|regen_baseline\|generate_baseline\|baseline drift" scripts/dev/pre_ci.sh | head -30
```

If the script contains something like `REGEN_BASELINE=1`, use that:
```bash
REGEN_BASELINE=1 bash scripts/dev/pre_ci.sh
```

This will recreate the ephemeral DB, apply all migrations, run `generate_baseline_snapshot.sh`, and continue with the rest of the gate.

If the flag doesn't exist, proceed to Path B.

**Path B: Manual Regeneration (General Case)**

The agent MUST follow one of these scenarios:

**Situation A: You maintain a local development database**
If you normally run a local Symphony database stack (e.g., via `docker-compose` or local Postgres):

1. **Verify container health**:
   ```bash
   docker ps | grep symphony-postgres
   ```

2. **Point your terminal to your Dev DB**:
   ```bash
   export DATABASE_URL="postgres://username:password@localhost:5432/symphony"
   ```

3. **Optionally apply migration manually** (if not already applied to dev DB):
   ```bash
   psql "$DATABASE_URL" -f schema/migrations/<number>_<description>.sql
   ```

4. **Reset the schema and apply all migrations** (including your new one):
   ```bash
   ./scripts/db/reset_and_migrate.sh
   ```

5. **Capture the new Baseline Snapshot**:
   ```bash
   ./scripts/db/generate_baseline_snapshot.sh
   ```

6. **Verify output**:
   ```bash
   ls -la schema/baselines/current/
   cat schema/baselines/current/baseline.meta.json
   ```

7. **Stage the Output Files** (complete set):
   ```bash
   git add schema/baseline.sql
   git add schema/baselines/current/0001_baseline.sql
   git add schema/baselines/current/baseline.cutoff
   git add schema/baselines/current/baseline.meta.json
   git add schema/baselines/$(date +%Y-%m-%d)/
   ```

**Situation B: You rely ONLY on ephemeral databases**
If you don't run a local developer DB and rely completely on CI/automated scripts:

1. **Spin up a temporary Postgres container** (use the correct Postgres version from your docker-compose.yml):
   ```bash
   docker run --name symphony-regen-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:18
   ```

2. **Target it with your environment variables** (wait for DB to be ready):
   ```bash
   export DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres"
   ```

3. **Reset, migrate, and regenerate** (same sequence as local development):
   ```bash
   ./scripts/db/reset_and_migrate.sh
   ./scripts/db/generate_baseline_snapshot.sh
   ```

4. **Tear down the temporary database container**:
   ```bash
   docker rm -f symphony-regen-db
   ```

5. **Stage the changes** (complete set):
   ```bash
   git add schema/baseline.sql
   git add schema/baselines/current/0001_baseline.sql
   git add schema/baselines/current/baseline.cutoff
   git add schema/baselines/current/baseline.meta.json
   git add schema/baselines/$(date +%Y-%m-%d)/
   ```

**Post-Regeneration Steps (Baseline Governance)**

Once the new snapshot is physically created (from either Situation A or B), you must satisfy ADR-0010 Baseline Governance:

1. **Update ADR-0010** (MANDATORY):
   - Edit `docs/decisions/ADR-0010-baseline-policy.md`
   - Add a dated line to the `## Baseline Update Log` section
   - Format: `- YYYY-MM-DD: Baseline regenerated after <brief description> (migration <number>).`
   - Example: `- 2026-04-18: Baseline regenerated after adding state_transitions table and associated triggers (migration 0120).`

2. **Stage the ADR update**:
   ```bash
   git add docs/decisions/ADR-0010-baseline-policy.md
   ```

3. **Generate the Evidence Check**:
   ```bash
   ./scripts/audit/run_invariants_fast_checks.sh
   ```

4. **Stage the generated evidence**:
   ```bash
   git add evidence/phase0/baseline_drift.json
   git add evidence/phase0/baseline_governance.json
   git add evidence/phase0/schema_hash.txt
   git add evidence/phase0/structural_doc_linkage.json
   ```

5. **Stage the migration file** (if not already staged):
   ```bash
   git add schema/migrations/<number>_<description>.sql
   ```

6. **Verify staged files**:
   ```bash
   git status
   git diff --cached --stat
   ```
   Confirm that `schema/baseline.sql`, the migration file, and `docs/decisions/ADR-0010-baseline-policy.md` are all staged together.

7. **Run `pre_ci.sh` to confirm**:
   ```bash
   ./scripts/dev/pre_ci.sh
   ```
   
   `pre_ci.sh` will provision a new ephemeral database, run the `check_baseline_drift.sh` assertion, map it against the files you just regenerated, and pass successfully.

**Situation Variants and Mitigations**

**Variant A: Governance check fails after regeneration**
- **Symptom**: `Baseline governance failed: baseline changed without required migration + ADR update`
- **Cause**: ADR not edited or files not staged together
- **Fix**: Verify `git diff --name-only origin/main HEAD` shows all three: baseline, migration, ADR. Add missing files and stage them.

**Variant B: Version mismatch error**
- **Symptom**: `pg_dump: server version ... but pg_dump version ...`
- **Cause**: Host pg_dump binary different version than Postgres container
- **Fix**: Ensure `symphony-postgres` container is running. If persistent, run dump through container:
  ```bash
  pg_container=$(docker ps --format '{{.Names}}' | grep postgres | head -1)
  docker exec "$pg_container" pg_dump \
    "postgresql://symphony@localhost:5432/symphony" \
    --schema-only --no-owner --no-privileges --no-comments --schema=public \
    > schema/baselines/current/0001_baseline.sql
  ```

**Variant C: Hashes still mismatch after regeneration**
- **Symptom**: `pre_ci.sh` still says "Baseline drift detected"
- **Cause**: Dev DB had extra objects or migration applied incorrectly
- **Diagnosis**: 
  ```bash
  bash scripts/db/canonicalize_schema_dump.sh schema/baselines/current/0001_baseline.sql /tmp/baseline_norm.sql
  bash scripts/db/canonicalize_schema_dump.sh /tmp/symphony_schema_dump_raw.sql /tmp/live_norm.sql
  diff /tmp/baseline_norm.sql /tmp/live_norm.sql | head -60
  ```
- **Fix**: Use a truly clean migration-only DB (Situation B) or reset dev DB with `reset_and_migrate.sh`

**Variant D: Rebaseline strategy verification fails**
- **Symptom**: `ERROR: rebaseline_missing_files`
- **Cause**: Missing `baseline.cutoff`, ADR-0011, or Rebaseline-Decision.md
- **Fix**: Re-run `generate_baseline_snapshot.sh` or restore missing files from git

**Variant E: Port already allocated error**
- **Symptom**: `Bind for 0.0.0.0:5432 failed: port is already allocated`
- **Cause**: Existing Postgres container already using port 5432
- **Fix**: Use existing container (Situation A) instead of spinning up new one, or use different port for temporary container

### Step 11: Satisfy Baseline Governance (ADR-0010)

The `verify_baseline_change_governance.sh` script enforces that any modification to the schema baselines is formally documented. If the baseline is changed, the agent MUST:

1. **Append a dated justification** to `docs/decisions/ADR-0010-baseline-policy.md`
2. **Explicitly state**:
   - Which task caused the baseline regeneration (e.g., <TASK_ID>)
   - Which migration was added (e.g., <number>_<description>.sql)
   - Why the baseline change was necessary
   - What the new baseline represents

**Example entry**:
```markdown
## <YYYY-MM-DD>: Baseline Regeneration for <TASK_ID>

Task: <TASK_ID>
Migration: <number>_<description>.sql
Reason: <explanation of why baseline regeneration was necessary>
New Baseline: <description of what the new baseline includes>
```

### Step 12: Handle DDL Lock-Risk Allowlisting

If the migration uses necessary operations that flag the `SEC-DDL-LOCK-RISK` linter (such as idempotent `ALTER TABLE` operations or `CREATE INDEX` without `CONCURRENTLY` on non-hot tables):

1. **Calculate the SHA-256 fingerprint** of the normalized SQL line
   - Normalize the SQL (remove extra whitespace, standardize case)
   - Compute SHA-256 hash of the normalized line
   - Use the hash as the allowlist entry identifier

2. **Append a new approved entry** to `docs/security/ddl_allowlist.json`
   - Use the next available `DDL-ALLOW-XXXX` sequence number
   - Include the SQL line, fingerprint, and justification
   - Reference the task ID that requires this exception

**Example entry**:
```json
{
  "id": "DDL-ALLOW-XXXX",
  "sql_line": "<SQL line>",
  "fingerprint": "sha256:abc123...",
  "justification": "<justification>",
  "task_id": "<TASK_ID>",
  "approved_by": "<approver_id>",
  "approved_at": "<ISO-8601 timestamp>"
}
```

### Step 13: Stage Regenerated Evidence Files

Schema changes will implicitly invalidate multiple auto-generated evidence files during the `pre_ci.sh` run. The agent MUST stage and commit these changed files alongside the migration:

- `evidence/phase0/schema_hash.txt`
- `evidence/phase0/baseline_governance.json`
- `evidence/phase0/structural_doc_linkage.json`
- Any other phase0/phase1 JSON scopes modified by the pipeline run

**Critical**: These files must be committed together with the migration. Failing to stage them will cause CI to fail on subsequent runs.

## Regulated Surface Compliance

When tasks modify regulated surfaces (schema/migrations/**, scripts/db/**, scripts/security/**, scripts/audit/**, docs/operations/**, evidence/**, docs/PHASE1/**, docs/control_planes/**, etc.), the agent MUST follow this complete lifecycle:

### Step 1: Consult REGULATED_SURFACE_PATHS.yml (Source of Truth)

Before modifying any file, the agent MUST:
- Read `docs/operations/REGULATED_SURFACE_PATHS.yml`
- Verify whether the file to be touched matches a regulated-surface path pattern
- If the file is missing or unreadable: verification fails closed
- If the file is regulated: proceed with approval requirements below

**Critical**: Never assume a file is not regulated. Always consult REGULATED_SURFACE_PATHS.yml first.

### Step 2: Two-Stage Approval Artifact Process

For regulated surface changes, approval artifacts are required in TWO stages:

**Stage A (Pre-Push, Branch-Linked)**
- Create BEFORE pushing to the remote branch
- Markdown record: `approvals/YYYY-MM-DD/BRANCH-<branch-key>.md`
- Sidecar JSON: `approvals/YYYY-MM-DD/BRANCH-<branch-key>.approval.json`
- `branch-key` is branch name normalized with `/` replaced by `-`
- `change_ref` must be `branch/<branch-name>`
- Must pass `docs/operations/approval_sidecar.schema.json` validation

**Stage B (Post-Push, PR-Linked)**
- Create AFTER the PR is opened
- Markdown record: `approvals/YYYY-MM-DD/PR-<number>.md`
- Sidecar JSON: `approvals/YYYY-MM-DD/PR-<number>.approval.json`
- `change_ref` must be `pr/<number>`
- Must pass `docs/operations/approval_sidecar.schema.json` validation

**Cross-Linking Requirements**:
- Each markdown approval file must include H2 `## 8. Cross-References (Machine-Readable)`
- Must include the exact line: `Approval Sidecar JSON: <sidecar-path>`
- `evidence/phase1/approval_metadata.json` must cross-link AI + human approvals and regulated-surface scope

### Step 3: Conformance Check Stage-Mode Flags

When running `scripts/audit/verify_agent_conformance.sh`, use the correct mode flags:

**For Stage A (Pre-Push)**:
```bash
scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=<branch-name>
```

**For Stage B (Post-PR)**:
```bash
scripts/audit/verify_agent_conformance.sh --mode=stage-b --pr=<PR-number>
```

**Critical**: Running conformance at PR time without `--mode=stage-b` will not detect a missing PR-linked approval.

### Step 4: Schema Drift Detection and Documentation

When modifying migration files (e.g., adding tables to an existing migration file), this is a restricted surface edit. The agent MUST:

1. **Detect whether migration is already applied**:
   - Check if the migration number is <= current MIGRATION_HEAD
   - If migration is already applied: STOP — never edit applied migrations (hard constraint)
   - If migration is not applied: proceed with modification

2. **Document schema drift in EXEC_LOG.md**:
   - Record the drift with `failure_signature` and `change_reason`
   - Reference the originating task and the scope boundary explicitly
   - Example entry:
     ```markdown
     | <timestamp> | Schema drift: added <table> to migration <number> (origin: <TASK_ID>) | Documented in EXEC_LOG |
     ```

3. **Confirm forward-only semantics**:
   - Verify MIGRATION_HEAD still reflects forward-only progression
   - Never decrease MIGRATION_HEAD
   - Never edit migration files that have already been applied

### Step 5: Evidence Metadata Requirements

When modifying regulated surfaces, the resulting evidence MUST include:

- `ai_prompt_hash` (non-empty string)
- `model_id` (non-empty string)
- `approver_id` (non-empty string)
- `approval_artifact_ref` (path to approval document)
- `change_reason` (short human-readable explanation)

**PII Validation**: These metadata values must NEVER include raw PII (emails, national IDs, phone numbers). The mechanism for validation is `docs/operations/approval_metadata.schema.json`. If PII is detected, verification fails with code `CONFORMANCE_012_PII_LEAK_DETECTED`.

## Hard Constraints (Never Violate)

- No runtime DDL on production paths; schema changes only in `schema/migrations/**`
- Forward-only migrations with `symphony:no_tx` when needed; never edit applied migrations
- SECURITY DEFINER functions must explicitly set `search_path = pg_catalog, public`
- Roles follow revoke-first: runtime roles do not regain CREATE
- Outbox attempts remain append-only
- No direct pushes or pulls to/from `main`; work only on feature branches/PRs
- No placeholder verifiers (exit 0, echo PASS)
- No scope drift (modifications outside touches list)
- Regulated surface changes require approval metadata
- **MIGRATION_HEAD Integrity**: `schema/migrations/MIGRATION_HEAD` must rigidly point to the exact new SQL file sequence. The sequence must not conflict with concurrent branches. Never decrease MIGRATION_HEAD. Verify MIGRATION_HEAD reflects forward-only progression after each migration.
- **Idempotency Guards**: All migrations must use `IF NOT EXISTS` for CREATE statements and `DO` blocks for ALTER statements to survive repeat runs against ephemeral `pre_ci` container DBs. This prevents idempotency failures during CI/CD pipeline runs.

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

## Task Execution Order

Tasks must be executed in dependency order as specified in their `depends_on` field.

**Dependency rule**: Do not start a task until all tasks in its `depends_on` list are marked `completed`.

## Completion Criteria

A task is complete when:

1. All verification commands in meta.yml pass (exit code 0)
2. All evidence artifacts exist and are fresh (run_id matches)
3. Evidence includes all required fields from meta.yml `must_include`
4. EXEC_LOG.md has been updated with execution history
5. For regulated surfaces: approval metadata is present and valid
6. `scripts/dev/pre_ci.sh` passes
7. Task status in meta.yml is set to `completed`
8. Task is registered in the phase-appropriate human task index
9. Evidence paths are wired into CI (`check_evidence_required.sh` or phase contract)

## Task Registration in Human Task Index

Per TASK_CREATION_PROCESS.md Step 6, every task MUST be registered in the phase-appropriate human task index:

1. **Locate the task index** for the appropriate phase (e.g., `docs/tasks/PHASE2_TASKS.md`)
2. **Verify the task is listed** with its task ID, title, owner, and status
3. **If not listed**: Add the task to the index with appropriate metadata
4. **At task completion**: Update the task status to `completed` in the index

**For task packs**: Since tasks created as part of a task-pack may already be registered, the agent MUST verify this and update the status at completion if needed.

## CI Wiring Verification at Completion

Per TASK_CREATION_PROCESS.md Section 5, verification commands must be wired into CI and evidence must be included in CI expectations. At task completion, the agent MUST:

1. **Locate the evidence check script**: `scripts/ci/check_evidence_required.sh`
2. **Verify the new evidence paths are added** to the appropriate phase contract
3. **If paths are missing**: Add them to the phase contract with appropriate validation logic
4. **Verify the script passes** locally before marking task complete

**Critical**: If evidence paths are not wired into CI, CI will fail after the tasks are marked "complete" per local verification.

## Anti-Drift Cheating Limits Documentation

Per TASK_CREATION_PROCESS.md Section 8, foundational task packs must explicitly state which anti-drift cheating modes remain open after their implementation.

At task completion, the agent MUST:

1. **Identify the attack surface** that remains open after the task completes
2. **Document this in the task's PLAN.md** or a dedicated security note
3. **Specify which cheating modes** are still possible (e.g., direct table bypass, trigger disable, role escalation)
4. **Reference this documentation** in the task's meta.yml `notes` or `security_notes` field

**Example**:
```markdown
## Anti-Drift Cheating Limits

After implementing <task description>, the following attack surfaces remain open:
- <attack surface 1>
- <attack surface 2>
- <attack surface 3>

These will be addressed in future waves with additional hardening.
```

## Verification Commands Reference

Each task's verification commands are defined in its meta.yml. The agent must:

- Execute commands in the order specified
- Preserve ID tags for traceability
- Ensure each command has failure path (`|| exit 1`)
- Capture stdout/stderr for evidence
- Write evidence JSON with required fields

## Evidence Contract Reference

Each task's evidence contract is defined in its meta.yml and PLAN.md. The agent must ensure:

- Evidence files are written to the specified paths
- Evidence includes all `must_include` fields
- Evidence is fresh (run_id matches current execution)
- For non-JSON evidence, receipt files are generated with sha256

## Summary

The coding agent must:
- **Pre-Step**: Check for rejection_context.md and DRD lockout before any mode classification
- **Mode Classification**: Classify prompt against all five modes in AGENT_PROMPT_ROUTER.md
- **Mode 2 Inspection**: Run RESUME-TASK inspection algorithm before IMPLEMENT-TASK
- Follow IMPLEMENT-TASK mode (Mode 3) from AGENT_PROMPT_ROUTER.md
- Execute the boot sequence: conformance → parity → task execution
- Modify only files in the task's touches list
- Implement negative tests BEFORE fixes (mandatory ordering requirement)
- Produce evidence artifacts per the evidence contract
- Update EXEC_LOG.md (append-only) with required remediation markers for production-affecting surfaces
- Comply with regulated surface approval requirements:
  - Consult REGULATED_SURFACE_PATHS.yml (source of truth)
  - Follow two-stage approval lifecycle (Stage A pre-push, Stage B post-PR)
  - Use correct stage-mode flags for conformance checks
  - Detect and document schema drift
  - Validate PII-free approval metadata
- Verify PLAN.md has required fields (failure_signature, canonical_reference)
- Register task in human task index at completion
- Wire evidence paths into CI (phase contract or check_evidence_required.sh)
- Document anti-drift cheating limits for foundational work
- **Post-Implementation Schema & Structural Drift Remediation** (MANDATORY):
  - Resolve Structural Change Governance (Change-Rule Gate) — document in THREAT_MODEL.md and COMPLIANCE_MAP.md
  - Resolve Schema Baseline Drift — regenerate baseline.sql and baselines/current/0001_baseline.sql
  - Satisfy Baseline Governance (ADR-0010) — append dated justification to ADR-0010-baseline-policy.md
  - Handle DDL Lock-Risk Allowlisting — calculate SHA-256 fingerprint and append to ddl_allowlist.json
  - Stage Regenerated Evidence Files — commit schema_hash.txt, baseline_governance.json, structural_doc_linkage.json
- Handle failures through remediation trace and DRD policy
- Execute tasks in dependency order
- Mark tasks complete only when all verification passes, evidence is fresh, CI is wired, registration is complete, and post-implementation governance is satisfied

## Pitfalls and Limitations

### Boot Sequence is Two-Pass, Not Linear

The boot sequence lists `pre_ci.sh` as Step 2, but this can be misleading. For tasks involving schema changes (migrations), `pre_ci.sh` is designed to fail on the first run because the baseline drift check will detect the new migration. The intended workflow is:

1. **First pass**: Perform governance work (regenerate baseline, update ADR-0010, etc.) OUTSIDE of `pre_ci.sh`
2. **Second pass**: Run `pre_ci.sh` to verify all governance work is complete

The system runs evidence cleaning at `pre_ci.sh` startup, ensuring a clean-slate failure on first runs for migration-bearing branches. Do not interpret a first-run `pre_ci.sh` failure as a blocker - it is the expected signal to perform the required governance remediation steps.

### Negative Test Ordering is Unenforceable Mechanically

The document requires writing negative tests BEFORE implementing fixes (Step 6). However, the system has no mechanical enforcement for this ordering requirement. The `negative_tests` array in meta.yml and `proof_limitations` field provide honest acknowledgment of what verifiers can and cannot prove, but nothing prevents an agent from writing the verifier and fix simultaneously. This is a process rule that relies on agent discipline, not a mechanical gate.

### Historical MIGRATION_HEAD Exception (0095_* Files)

The migration directory contains three files sharing the `0095` prefix: `0095_pre_snapshot.sql`, `0095_rls_dual_policy_architecture.sql`, and `0095_rollback.sql`. This represents a historical deviation from the monotonic MIGRATION_HEAD constraint. The current process explicitly prohibits such non-monotonic numbering, but this historical case was grandfathered in. The `migrate.sh` uses filesystem sort for ordering, so these files apply correctly, but the constraint "MIGRATION_HEAD must be monotonically increasing" applies only to new migrations. Agents encountering the `0095_*` files should understand this is a historical exception, not a pattern to follow.

### Two-Strike Rule Tracks Same-Signature Failures

The two-strike rule triggers DRD lockout after two consecutive failures at the same gate signature. If your first run fails at gate A and your second run fails at gate B (because you fixed A), the counter resets because the signature changed. The document's phrase "two full reruns without convergence" is imprecise - it actually means two consecutive failures at the same `PRE_CI_FAILURE_SIGNATURE`. Running verifiers directly (not via `pre_ci.sh`) does not increment the counter.
