#!/usr/bin/env python3
"""
generate_task_pack.py

Permanent utility for creating Wave 5/Wave 7 compliant task packs.
Forces agents/developers to provide specific implementations (work, acceptance_criteria, verifiers)
and strictly envelopes them in the TSK-P1-240 Proof Graph format, with Wave 5 Regulated Surface
and Remediation Trace compliance markers mechanically injected.

Usage:
  python3 scripts/agent/generate_task_pack.py --config my_task.json
"""

import argparse
import json
import os
import re
import sys
from datetime import date

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
TODAY_STR = date.today().isoformat()
PHASE3_ALLOWED_WAVES = {
    "ACT",
    "PRE",
    "CLEAN",
    "GOV",
    "WP",
    "SUPPORT",
    "CI",
    "W1",
    "W2",
    "W3",
    "W4",
    "W5",
    "W6",
    "W7",
    "W8",
    "W9",
    "W10",
}
PHASE3_TASK_ID_RE = re.compile(r"^TSK-P3-(ACT|PRE|CLEAN|GOV|WP|SUPPORT|CI|W(?:10|[1-9]))(?:-[A-Z0-9]+)*-\d{3}$")
PHASE3_REQUIRED_MUST_READ = [
    "docs/operations/TASK_ID_NOMENCLATURE.md",
    "docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md",
    "docs/PHASE3/PHASE3_INVARIANT_REGISTER.md",
]

PHASE3_RUNTIME_WAVES = {"WP", "SUPPORT"}

def die(msg):
    print(f"[FAIL] {msg}", file=sys.stderr)
    sys.exit(1)

def require_field(data, field):
    if field not in data or not data[field]:
        die(f"Missing required field in JSON config: '{field}'. You must supply explicit implementation details.")
    return data[field]

def get_runner(verifier):
    if verifier.endswith(".py"):
        return "python3"
    return "bash"

def get_evidence_path(evidence):
    if isinstance(evidence, dict):
        path = evidence.get("path")
        if not path:
            die("Evidence dict must contain a 'path' key.")
        return path
    return evidence

def derive_phase3_wave(task_id):
    parts = task_id.split("-")
    if len(parts) < 4:
        return None
    candidate = parts[2]
    return candidate if candidate in PHASE3_ALLOWED_WAVES else None

def determine_human_task_index(data):
    phase = str(data.get("phase"))
    if phase != "3":
        return None
    explicit = data.get("human_task_index")
    if explicit:
        return explicit
    runtime_flag = data.get("runtime_task_index")
    if runtime_flag is None:
        runtime_flag = data.get("wave") in PHASE3_RUNTIME_WAVES
    return "docs/tasks/PHASE3_RUNTIME_TASKS.md" if runtime_flag else "docs/tasks/PHASE3_TASKS.md"

def phase3_registry_path(data):
    return "docs/PHASE3/phase3_task_registry.yml" if str(data.get("phase")) == "3" else None

def baseline_date(data):
    return str(data.get("baseline_date") or TODAY_STR)

def db_closure_surfaces(data):
    if data["blast_radius"] not in ["DB_SCHEMA", "DATABASE"]:
        return []
    dated = baseline_date(data)
    surfaces = [
        "schema/migrations/MIGRATION_HEAD",
        "schema/baseline.sql",
        "schema/baselines/current/0001_baseline.sql",
        "schema/baselines/current/baseline.cutoff",
        "schema/baselines/current/baseline.meta.json",
        f"schema/baselines/{dated}/0001_baseline.sql",
        f"schema/baselines/{dated}/baseline.normalized.sql",
        f"schema/baselines/{dated}/baseline.cutoff",
        f"schema/baselines/{dated}/baseline.meta.json",
        "docs/decisions/ADR-0010-baseline-policy.md",
        "docs/contracts/sqlstate_map.yml",
    ]
    registry = phase3_registry_path(data)
    human_index = determine_human_task_index(data)
    if registry:
        surfaces.append(registry)
    if human_index:
        surfaces.append(human_index)
    return surfaces

def file_table_rows(data, verifier, evidence_path, phase):
    rows = []
    if data["blast_radius"] in ["DB_SCHEMA", "DATABASE"]:
        dated = baseline_date(data)
        rows.extend([
            ("schema/migrations/MIGRATION_HEAD", "MODIFY", "Advance canonical migration head when DB task lands"),
            ("schema/baseline.sql", "MODIFY", "Maintain stable baseline pointer after DB closure work"),
            ("schema/baselines/current/0001_baseline.sql", "MODIFY", "Refresh current baseline snapshot"),
            ("schema/baselines/current/baseline.cutoff", "MODIFY", "Refresh current baseline cutoff metadata"),
            ("schema/baselines/current/baseline.meta.json", "MODIFY", "Refresh current baseline metadata"),
            (f"schema/baselines/{dated}/0001_baseline.sql", "MODIFY", "Record dated baseline snapshot"),
            (f"schema/baselines/{dated}/baseline.normalized.sql", "MODIFY", "Record dated normalized baseline snapshot"),
            (f"schema/baselines/{dated}/baseline.cutoff", "MODIFY", "Record dated baseline cutoff"),
            (f"schema/baselines/{dated}/baseline.meta.json", "MODIFY", "Record dated baseline metadata"),
            ("docs/decisions/ADR-0010-baseline-policy.md", "MODIFY", "Document baseline-governance closure"),
            ("docs/contracts/sqlstate_map.yml", "MODIFY", "Register any new SQLSTATE codes introduced by the DB task"),
        ])
    registry = phase3_registry_path(data)
    human_index = determine_human_task_index(data)
    if registry:
        rows.append((registry, "MODIFY", "Register task in Phase 3 registry"))
    if human_index:
        rows.append((human_index, "MODIFY", "Register task in the human Phase 3 task index"))
    rows.extend([
        (verifier, "CREATE", "Verifier for this task"),
        (evidence_path, "CREATE", "Output artifact"),
        (f"tasks/{data['task_id']}/meta.yml", "MODIFY", "Update status upon success"),
        (f"docs/plans/phase{phase}/{data['task_id']}/EXEC_LOG.md", "MODIFY", "Append completion data"),
    ])
    return rows

def normalize_phase3_config(data):
    task_id = data["task_id"]
    if not PHASE3_TASK_ID_RE.match(task_id):
        die(f"Invalid Phase 3 task_id: {task_id}. Must match {PHASE3_TASK_ID_RE.pattern}")

    wave = data.get("wave") or derive_phase3_wave(task_id)
    if wave not in PHASE3_ALLOWED_WAVES:
        die(f"Invalid or missing Phase 3 wave for {task_id}: {wave}")
    data["wave"] = wave

    must_read = list(data.get("must_read", []))
    for item in PHASE3_REQUIRED_MUST_READ:
        if item not in must_read:
            must_read.append(item)
    data["must_read"] = must_read
    data["is_regulated"] = True
    return data

def require_db_task_inputs(data):
    if data["blast_radius"] not in ["DB_SCHEMA", "DATABASE"]:
        return
    if "migration_dependencies" not in data:
        die(
            "DB tasks must supply explicit 'migration_dependencies' in the JSON config. "
            "Do not rely on generator placeholders."
        )
    deps = data["migration_dependencies"]
    if not isinstance(deps, dict):
        die("'migration_dependencies' must be a dict with required_migrations, table_dependencies, and verification_step.")
    required = deps.get("required_migrations")
    tables = deps.get("table_dependencies")
    step = deps.get("verification_step")
    if not required or not isinstance(required, list):
        die("DB tasks must provide a non-empty migration_dependencies.required_migrations list.")
    if not tables or not isinstance(tables, list):
        die("DB tasks must provide a non-empty migration_dependencies.table_dependencies list.")
    if not step or not isinstance(step, str):
        die("DB tasks must provide migration_dependencies.verification_step.")

def yaml_list_block(items, indent_spaces):
    indent = " " * indent_spaces
    return "\n".join(f"{indent}- {item}" for item in items)

def generate_plan(data, plan_dir):
    task_id = data["task_id"]
    title = data["title"]
    is_regulated = data.get("is_regulated", True)
    blast_radius = data["blast_radius"]
    is_db_task = blast_radius in ["DB_SCHEMA", "DATABASE"]
    dated = baseline_date(data)
    
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

    db_context_section = ""
    if is_db_task:
        db_context_section = """
## Database Connection Context (CRITICAL)

- **Requirement**: All database interactions in verification scripts MUST use the `DATABASE_URL` environment variable.
- **Example Export**: `set -a && source infra/docker/.env && set +a && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT}/symphony"`
- **Docker Context**: The container is `symphony-postgres`.

---
"""

    phase3_preconditions = ""
    if str(data["phase"]) == "3":
        phase3_preconditions = """
- [ ] `docs/operations/TASK_ID_NOMENCLATURE.md` reviewed for task-family and wave rules.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.
"""

    work_items = "\n".join([f"- {w}" for w in data["work"]])
    verifier = data["verifiers"][0]
    runner = get_runner(verifier)
    evidence_path = get_evidence_path(data["evidence"])
    
    db_conn_step = f"- Connect to DB using `DATABASE_URL`." if is_db_task else ""
    
    rebaseline_step = ""
    if is_db_task:
        rebaseline_step = f"""
### Step 4: Rebaseline (CRITICAL for DB_SCHEMA tasks)
**What:** Regenerate the physical baseline and satisfy ADR-0010 governance.
**How:**
1. Connect to DB: `set -a && source infra/docker/.env && set +a && export DATABASE_URL="postgres://${{POSTGRES_USER}}:${{POSTGRES_PASSWORD}}@localhost:${{HOST_POSTGRES_PORT}}/symphony"`
2. Regenerate: `bash scripts/db/generate_baseline_snapshot.sh {dated}`
3. Register any new SQLSTATE codes in `docs/contracts/sqlstate_map.yml`.
4. Audit Log: Append an entry to `docs/decisions/ADR-0010-baseline-policy.md` citing the new MIGRATION_HEAD and the specific changes made.
**Done when:** `scripts/db/check_baseline_drift.sh` exits 0.
"""

    file_rows = "\n".join([f"| `{path}` | {action} | {reason} |" for path, action, reason in file_table_rows(data, verifier, evidence_path, data["phase"])])

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

---{db_context_section}
## Objective

{title}. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.
{phase3_preconditions}

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
{file_rows}

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
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
- Implement `{verifier}`.
{db_conn_step}
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
{runner} {verifier} > {evidence_path}
```
**Done when:** Commands exit 0, evidence format complies, and only then may task status move to `completed`.
{rebaseline_step}

---

## Verification

```bash
# 1. Task-specific verifier
{runner} {verifier}

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task {task_id} --evidence {evidence_path}

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task {task_id}
```
"""
    plan_path = os.path.join(plan_dir, "PLAN.md")
    with open(plan_path, "w") as f:
        f.write(plan_content)
    print(f"[OK] Generated {plan_path}")

def generate_exec_log(data, plan_dir):
    task_id = data["task_id"]
    verifier = data["verifiers"][0]
    runner = get_runner(verifier)
    evidence_path = get_evidence_path(data["evidence"])
    
    log_content = f"""# Execution Log for {task_id}

> **Append-only log.** Do not delete or modify existing entries.

Plan: docs/plans/phase{data["phase"]}/{task_id}/PLAN.md

**failure_signature**: PHASE{data["phase"]}.STRICT.{task_id}.PROOF_FAIL
**origin_task_id**: {task_id}
**repro_command**: {runner} {verifier}

## Pre-Edit Documentation
- Stage A approval sidecar created.

## Implementation Notes
- (Agent to append notes here during execution)

## Post-Edit Documentation
**verification_commands_run**:
```bash
{runner} {verifier} > {evidence_path}
```
**final_status**: pending

## final summary

Task pack generated. Implementation work has not started. `status: ready` denotes task-packed state, not completed proof.
"""
    log_path = os.path.join(plan_dir, "EXEC_LOG.md")
    with open(log_path, "w") as f:
        f.write(log_content)
    print(f"[OK] Generated {log_path}")

def generate_meta(data, task_dir):
    task_id = data["task_id"]
    work_lines = "\n".join([f"  - \"{w}\"" for w in data["work"]])
    acc_lines = "\n".join([f"  - \"{a}\"" for a in data["acceptance_criteria"]])
    
    # Extract just the ID strings for the verification comment
    ids = [w.split("]")[0] + "]" for w in data["work"] if "]" in w]
    id_str = " ".join(ids)
    evidence_path = get_evidence_path(data["evidence"])
    db_surfaces = db_closure_surfaces(data)
    registry = phase3_registry_path(data)
    human_index = determine_human_task_index(data)
    deliverable_list = list(data.get("deliverable_files", []))
    for path in db_surfaces:
        if path not in deliverable_list:
            deliverable_list.append(path)
    for verifier_path in data["verifiers"]:
        if verifier_path not in deliverable_list:
            deliverable_list.append(verifier_path)
    for path in [evidence_path, f"docs/plans/phase{data['phase']}/{task_id}/PLAN.md", f"docs/plans/phase{data['phase']}/{task_id}/EXEC_LOG.md"]:
        if path not in deliverable_list:
            deliverable_list.append(path)
    deliverable_files = "\n".join([f"  - {item}" for item in deliverable_list])
    
    blast_radius = data["blast_radius"]
    is_regulated = data.get("is_regulated", True)
    is_db_task = blast_radius in ["DB_SCHEMA", "DATABASE"]
    must_read = list(data.get("must_read", []))
    base_must_read = [
        "docs/operations/AI_AGENT_OPERATION_MANUAL.md",
        "docs/operations/TASK_CREATION_PROCESS.md",
        "docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md",
    ]
    for item in base_must_read:
        if item not in must_read:
            must_read.insert(base_must_read.index(item), item)
    must_read_lines = "\n".join([f"  - {item}" for item in must_read])

    reg_enabled = "true" if is_regulated else "false"
    rem_enabled = "true" if is_regulated or is_db_task else "false"
    wave_line = ""
    if str(data["phase"]) == "3" and data.get("wave"):
        wave_line = f"wave: '{data['wave']}'\n"

    db_section = ""
    if is_db_task:
        deps = data["migration_dependencies"]
        required_lines = yaml_list_block(deps["required_migrations"], 4)
        table_lines = yaml_list_block(deps["table_dependencies"], 4)
        db_section = f"""
database_connection:
  enabled: true
  connection_string_format: "postgresql://<user>:<password>@<host>:<port>/<database>"
  example_connection_string: "postgresql://symphony_admin:symphony_pass@localhost:${{HOST_POSTGRES_PORT}}/symphony"
  container_name: symphony-postgres
  database_url_env_var: DATABASE_URL
  setup_command: "set -a && source infra/docker/.env && set +a && export DATABASE_URL=\\"postgres://${{POSTGRES_USER}}:${{POSTGRES_PASSWORD}}@localhost:${{HOST_POSTGRES_PORT}}/symphony\\""

migration_dependencies:
  enabled: true
  required_migrations:
{required_lines}
  table_dependencies:
{table_lines}
  verification_step: "{deps['verification_step']}"
"""

    must_include_lines = ""
    if isinstance(data["evidence"], dict) and "must_include" in data["evidence"]:
        must_include_lines = "\n".join([f"      - {item}" for item in data["evidence"]["must_include"]])
    else:
        must_include_lines = "\n".join([f"      - {item}" for item in ["task_id", "git_sha", "timestamp_utc", "status", "checks", "observed_hashes"]])

    verifier = data["verifiers"][0]
    runner = get_runner(verifier)

    touches_list = list(data.get("touches", []))
    for path in db_surfaces:
        if path not in touches_list:
            touches_list.append(path)
    for path in [verifier, evidence_path, f"tasks/{task_id}/meta.yml", f"docs/plans/phase{data['phase']}/{task_id}/PLAN.md", f"docs/plans/phase{data['phase']}/{task_id}/EXEC_LOG.md"]:
        if path not in touches_list:
            touches_list.append(path)
    touches_block = "\n".join([f"  - {item}" for item in touches_list])

    regulated_paths = list(data.get("regulated_paths", []))
    if not regulated_paths:
        regulated_paths = [verifier]
    regulated_paths_block = "\n".join([f"    - {item}" for item in regulated_paths])

    verification_lines = [
        f"  - '{id_str} test -x {verifier} && {runner} {verifier} > {evidence_path} || exit 1'"
    ]
    if is_db_task:
        verification_lines.append("  - 'bash scripts/db/lint_migrations.sh || exit 1'")
    verification_lines.extend([
        f"  - 'python3 scripts/audit/validate_evidence.py --task {task_id} --evidence {evidence_path} || exit 1'",
        f"  - 'bash scripts/audit/verify_task_pack_readiness.sh --task {task_id} || exit 1'",
    ])
    verification_block = "\n".join(verification_lines)

    meta_content = f"""schema_version: 1
phase: '{data["phase"]}'
{wave_line}task_id: {task_id}
title: "{data["title"]}"
owner_role: {data["owner"]}
status: ready
priority: HIGH
risk_class: GOVERNANCE
blast_radius: {blast_radius}
depends_on: {json.dumps(data.get("depends_on", []))}
invariants: {json.dumps(data.get("invariants", []))}

deliverable_files:
{deliverable_files}

regulated_surface_compliance:
  enabled: {reg_enabled}
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:
{regulated_paths_block}
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
{db_section}
out_of_scope:
  - "Any scope outside the exact IDs declared in this task."
stop_conditions:
  - "If verification negative tests do not transactionally fail."
proof_guarantees:
  - "Evidence JSON correctly demonstrates enforcement via state evaluation."
proof_limitations:
  - "Does not prove runtime API integration (deferred)."

touches:
{touches_block}

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
{verification_block}

evidence:
  - path: {evidence_path}
    must_include:
{must_include_lines}

failure_modes:
  - "Evidence file missing => FAIL"
  - "Verifier exits 0 on negative test => CRITICAL_FAIL"

must_read:
{must_read_lines}
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
    parser.add_argument("--phase3", action="store_true", help="Apply Phase 3 defaults and validation")
    parser.add_argument("--base-dir", default=BASE_DIR, help="Override output root (useful for verifier temp dirs)")
    args = parser.parse_args()

    config_path = os.path.abspath(args.config)
    if not os.path.exists(config_path):
        die(f"Config file not found: {config_path}")

    with open(config_path, "r") as f:
        try:
            data = json.load(f)
        except Exception as e:
            die(f"Failed to parse JSON config: {e}")

    if args.phase3:
        data["phase"] = "3"
        data = normalize_phase3_config(data)
    elif str(data.get("phase")) == "3":
        data = normalize_phase3_config(data)

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
    require_db_task_inputs(data)

    if len(data["work"]) != len(data["acceptance_criteria"]):
        die("Proof graph error: 'work' items and 'acceptance_criteria' must be mapped 1:1 via IDs.")

    output_root = os.path.abspath(args.base_dir)
    task_dir = os.path.join(output_root, "tasks", data["task_id"])
    plan_dir = os.path.join(output_root, f"docs/plans/phase{data['phase']}", data["task_id"])

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
