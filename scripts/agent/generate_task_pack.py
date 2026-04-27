#!/usr/bin/env python3
"""
generate_task_pack.py

Permanent utility for creating Wave 5/Wave 7 compliant task packs.
Forces agents/developers to provide specific implementations (work, acceptance_criteria, verifiers)
and strictly envelopes them in the TSK-P1-240 Proof Graph format, with Wave 5 Regulated Surface
and Remediation Trace compliance markers mechanically injected.

Usage:
  python3 scripts/agent/generate_task_pack.py --config my_task.json

Example my_task.json:
{
  "task_id": "TSK-P2-PREAUTH-007-20",
  "title": "Example Task Title",
  "owner": "SECURITY_GUARDIAN",
  "phase": "2",
  "is_regulated": true,
  "blast_radius": "DATABASE",
  "work": ["[ID tsk_p2_preauth_007_20_work_01] Do the thing"],
  "acceptance_criteria": ["[ID tsk_p2_preauth_007_20_work_01] The thing is done"],
  "verifiers": ["scripts/audit/verify_tsk_p2_preauth_007_20.sh"],
  "evidence": "evidence/phase2/tsk_p2_preauth_007_20.json"
}
"""

import argparse
import json
import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))

def die(msg):
    print(f"[FAIL] {msg}", file=sys.stderr)
    sys.exit(1)

def require_field(data, field):
    if field not in data or not data[field]:
        die(f"Missing required field in JSON config: '{field}'. You must supply explicit implementation details.")
    return data[field]

def generate_plan(data, plan_dir):
    task_id = data["task_id"]
    title = data["title"]
    is_regulated = data.get("is_regulated", True)
    
    regulated_section = ""
    if is_regulated:
        regulated_section = """
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`
"""

    work_items = "\n".join([f"- {w}" for w in data["work"]])
    
    plan_content = f"""# {task_id} PLAN — {title}

Task: {task_id}
Owner: {data["owner"]}
failure_signature: PHASE{data["phase"]}.STRICT.{task_id}.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---{regulated_section}
## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Database Connection Context (CRITICAL)

- **Requirement**: All database interactions in verification scripts MUST use the `DATABASE_URL` environment variable.
- **Example Export**: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"`
- **Docker Context**: The container is `symphony-postgres`.

---

## Objective

{title}. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `{data["verifiers"][0]}` | CREATE | Verifier for this task |
| `{data["evidence"]}` | CREATE | Output artifact |
| `tasks/{task_id}/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase{data["phase"]}/{task_id}/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing migration** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
{work_items}
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `{data["verifiers"][0]}`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash {data["verifiers"][0]} > {data["evidence"]}
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh`
3. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.


---

## Verification

```bash
# 1. Task-specific verifier
bash {data["verifiers"][0]}

# 2. Local parity check
RUN_PHASE{data["phase"]}_GATES=1 bash scripts/dev/pre_ci.sh
```
"""
    plan_path = os.path.join(plan_dir, "PLAN.md")
    with open(plan_path, "w") as f:
        f.write(plan_content)
    print(f"[OK] Generated {plan_path}")

def generate_exec_log(data, plan_dir):
    task_id = data["task_id"]
    log_content = f"""# Execution Log for {task_id}

> **Append-only log.** Do not delete or modify existing entries.

**failure_signature**: PHASE{data["phase"]}.STRICT.{task_id}.PROOF_FAIL
**origin_task_id**: {task_id}
**repro_command**: bash {data["verifiers"][0]}

## Pre-Edit Documentation
- Stage A approval sidecar created.

## Implementation Notes
- (Agent to append notes here during execution)

## Post-Edit Documentation
**verification_commands_run**:
```bash
bash {data["verifiers"][0]} > {data["evidence"]}
```
**final_status**: pending
"""
    log_path = os.path.join(plan_dir, "EXEC_LOG.md")
    with open(log_path, "w") as f:
        f.write(log_content)
    print(f"[OK] Generated {log_path}")

def generate_meta(data, task_dir):
    task_id = data["task_id"]
    work_lines = "\n".join([f"  - '{w}'" for w in data["work"]])
    acc_lines = "\n".join([f"  - '{a}'" for a in data["acceptance_criteria"]])
    
    # Extract just the ID strings for the verification comment
    ids = [w.split("]")[0] + "]" for w in data["work"] if "]" in w]
    id_str = " ".join(ids)
    deliverable_files = "\n".join([f"  - {v}" for v in data["verifiers"]] + [f"  - {data['evidence']}", f"  - docs/plans/phase{data['phase']}/{task_id}/PLAN.md", f"  - docs/plans/phase{data['phase']}/{task_id}/EXEC_LOG.md"])
    
    blast_radius = data["blast_radius"]
    is_regulated = data.get("is_regulated", True)
    
    reg_enabled = "true" if is_regulated else "false"
    db_enabled = "true" if blast_radius in ["DB_SCHEMA", "DATABASE"] else "false"
    rem_enabled = "true" if is_regulated or blast_radius in ["DB_SCHEMA", "DATABASE"] else "false"

    meta_content = f"""schema_version: 1
phase: '{data["phase"]}'
task_id: {task_id}
title: "{data["title"]}"
owner_role: {data["owner"]}
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: {blast_radius}

deliverable_files:
{deliverable_files}

regulated_surface_compliance:
  enabled: {reg_enabled}
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:
    - {data["verifiers"][0]}
  must_read:
    - docs/operations/REGULATED_SURFACE_PATHS.yml
    - docs/operations/approval_metadata.schema.json

remediation_trace_compliance:
  enabled: {rem_enabled}
  required_markers:
    - failure_signature
    - origin_task_id
    - repro_command
    - verification_commands_run
    - final_status
  marker_location: EXEC_LOG.md
  append_only: true
  markers_required_at_edit: true
  must_read:
    - docs/operations/REMEDIATION_TRACE_WORKFLOW.md

database_connection:
  enabled: {db_enabled}
  connection_string_format: "postgresql://<user>:<password>@<host>:<port>/<database>"
  example_connection_string: "postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"
  container_name: symphony-postgres
  database_url_env_var: DATABASE_URL
  setup_command: "export DATABASE_URL=\\"postgresql://symphony_admin:symphony_pass@localhost:5432/symphony\\""

migration_dependencies:
  enabled: {db_enabled}
  required_migrations:
    - 0144: "Wave 5 remediation baseline"
  table_dependencies:
    - schema_migrations: "must track migrations"
  verification_step: "Confirm all referenced tables exist in earlier migrations"

out_of_scope:
  - "Any scope outside the exact IDs declared in this task."
stop_conditions:
  - "If verification negative tests do not transactionally fail."
proof_guarantees:
  - "Evidence JSON correctly demonstrates enforcement via state evaluation."
proof_limitations:
  - "Does not prove runtime API integration (deferred)."

touches:
  - {data["verifiers"][0]}
  - {data["evidence"]}
  - tasks/{task_id}/meta.yml
  - docs/plans/phase{data["phase"]}/{task_id}/PLAN.md
  - docs/plans/phase{data["phase"]}/{task_id}/EXEC_LOG.md

work:
{work_lines}

acceptance_criteria:
{acc_lines}

negative_tests:
  - id: {task_id}-N1
    description: "Verify that execution fails transactionally when boundary conditions are violated for: {data['acceptance_criteria'][0].split(']')[1].strip() if ']' in data['acceptance_criteria'][0] else data['acceptance_criteria'][0]}"
    required: true

positive_tests:
  - id: {task_id}-P1
    description: "Verify that execution exits 0 on success path for: {data['acceptance_criteria'][0].split(']')[1].strip() if ']' in data['acceptance_criteria'][0] else data['acceptance_criteria'][0]}"
    required: true

verification:
  - '# {id_str} test -x {data["verifiers"][0]} && bash {data["verifiers"][0]} > {data["evidence"]} || exit 1'

evidence:
  - path: {data["evidence"]}
    must_include:
      - task_id
      - git_sha
      - timestamp_utc
      - status
      - checks
      - observed_hashes

failure_modes:
  - "Evidence file missing => FAIL"
  - "Verifier exits 0 on negative test => CRITICAL_FAIL"

must_read:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/operations/TASK_CREATION_PROCESS.md
  - docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
implementation_plan: docs/plans/phase{data["phase"]}/{task_id}/PLAN.md
implementation_log: docs/plans/phase{data["phase"]}/{task_id}/EXEC_LOG.md
notes: 'Generated via scripts/agent/generate_task_pack.py'
client: cursor
assigned_agent: {data["owner"].lower()}
model: claude-sonnet-4-20250514
"""
    meta_path = os.path.join(task_dir, "meta.yml")
    with open(meta_path, "w") as f:
        f.write(meta_content)
    print(f"[OK] Generated {meta_path}")

def main():
    parser = argparse.ArgumentParser(description="Generate a strictly compliant task pack.")
    parser.add_argument("--config", required=True, help="Path to JSON config defining the task")
    args = parser.parse_args()

    config_path = os.path.abspath(args.config)
    if not os.path.exists(config_path):
        die(f"Config file not found: {config_path}")

    with open(config_path, "r") as f:
        try:
            data = json.load(f)
        except Exception as e:
            die(f"Failed to parse JSON config: {e}")

    # Enforce strict presence of cognitive input
    require_field(data, "task_id")
    require_field(data, "title")
    require_field(data, "owner")
    require_field(data, "phase")
    require_field(data, "blast_radius")
    require_field(data, "work")
    require_field(data, "acceptance_criteria")
    require_field(data, "verifiers")
    require_field(data, "evidence")

    if len(data["work"]) != len(data["acceptance_criteria"]):
        die("Proof graph error: 'work' items and 'acceptance_criteria' must be mapped 1:1 via IDs.")

    task_dir = os.path.join(BASE_DIR, "tasks", data["task_id"])
    plan_dir = os.path.join(BASE_DIR, f"docs/plans/phase{data['phase']}", data["task_id"])

    os.makedirs(task_dir, exist_ok=True)
    os.makedirs(plan_dir, exist_ok=True)

    generate_plan(data, plan_dir)
    generate_exec_log(data, plan_dir)
    generate_meta(data, task_dir)

    print(f"\n[SUCCESS] Task pack {data['task_id']} generated.")
    print("Next steps:")
    print(f"1. python3 scripts/audit/verify_plan_semantic_alignment.py --plan {os.path.join(plan_dir, 'PLAN.md')} --meta {os.path.join(task_dir, 'meta.yml')}")
    print(f"2. PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy {os.path.join(task_dir, 'meta.yml')}")

if __name__ == "__main__":
    main()
