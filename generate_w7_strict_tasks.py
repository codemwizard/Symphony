import os
import yaml

TASKS = [
    {
        "id": "007-06",
        "title": "Invariant Registry Schema and Append-Only Topology",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_06_work_item_01] Create invariant_registry table with verifier_type, severity, execution_layer, is_blocking, checksum fields.",
            "[ID tsk_p2_preauth_007_06_work_item_02] Implement append-only trigger to block UPDATE and DELETE on invariant_registry."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_06_work_item_01] invariant_registry table exists with correct schema.",
            "[ID tsk_p2_preauth_007_06_work_item_02] Trigger correctly rejects UPDATE and DELETE operations."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_06.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_06.json"
    },
    {
        "id": "007-07",
        "title": "Registry Supersession and Execution Constraints",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_07_work_item_01] Add unique constraints to enforce linear supersession (no forks).",
            "[ID tsk_p2_preauth_007_07_work_item_02] Add registry execution constraints for checksum and freshness."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_07_work_item_01] Attempting to fork a supersession chain fails.",
            "[ID tsk_p2_preauth_007_07_work_item_02] Constraints correctly validate freshness and checksum fields."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_07.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_07.json"
    },
    {
        "id": "007-08",
        "title": "Trust Architecture: PK Registry and Identity Binding",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_08_work_item_01] Create public_keys_registry table with temporal validity constraints."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_08_work_item_01] public_keys_registry exists and rejects overlapping temporal bounds."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_08.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_08.json"
    },
    {
        "id": "007-09",
        "title": "Trust Architecture: Delegated Grant Schema",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_09_work_item_01] Create delegated_signing_grants table to satisfy the non-masquerade invariant."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_09_work_item_01] delegated_signing_grants table exists and correctly maps actor scope to payload."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_09.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_09.json"
    },
    {
        "id": "007-10",
        "title": "Interpretation Overlap Rejection",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_10_work_item_01] Add exclusion constraints to prevent historical overlapping of interpretation packs."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_10_work_item_01] Overlapping timestamptz ranges for the same jurisdiction and domain are rejected."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_10.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_10.json"
    },
    {
        "id": "007-11",
        "title": "Phase 1 Boundary Marker Schema",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_11_work_item_01] Add phase and data_authority columns to monitoring_records.",
            "[ID tsk_p2_preauth_007_11_work_item_02] Implement BEFORE INSERT trigger to enforce Phase 1 marker rules."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_11_work_item_01] Columns exist on monitoring_records.",
            "[ID tsk_p2_preauth_007_11_work_item_02] Trigger rejects rows claiming Phase 1 but lacking phase1_indicative_only."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_11.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_11.json"
    },
    {
        "id": "007-12",
        "title": "Attestation Seam Schema",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_12_work_item_01] Add nullable attestation columns and enums to asset_batches."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_12_work_item_01] Attestation columns (invariant_attestation_hash, etc.) exist on asset_batches."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_12.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_12.json"
    },
    {
        "id": "007-13",
        "title": "Attestation Anti-Replay Contract",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_13_work_item_01] Implement anti-replay DB logic (nonce, epoch, freshness TTL constraints)."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_13_work_item_01] DB logic successfully rejects stale or replayed attestations."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_13.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_13.json"
    },
    {
        "id": "007-14",
        "title": "DB Kill Switch Gate",
        "owner": "DB_FOUNDATION",
        "work": [
            "[ID tsk_p2_preauth_007_14_work_item_01] Create BEFORE INSERT trigger on authoritative tables to query invariant registry and abort on failure."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_14_work_item_01] Trigger correctly intercepts inserts and raises exception if invariant_registry is failing."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_14.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_14.json"
    },
    {
        "id": "007-15",
        "title": "INV-175 and INV-176 DB Verifiers",
        "owner": "SECURITY_GUARDIAN",
        "work": [
            "[ID tsk_p2_preauth_007_15_work_item_01] Create dedicated scripts doing SERIALIZABLE negative inserts for data authority and state machine rules."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_15_work_item_01] Verifier executes in SERIALIZABLE, performs negative inserts, expects DB constraints to reject, and rolls back cleanly."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_15.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_15.json"
    },
    {
        "id": "007-16",
        "title": "INV-177 DB Verifier",
        "owner": "SECURITY_GUARDIAN",
        "work": [
            "[ID tsk_p2_preauth_007_16_work_item_01] Create dedicated script doing negative inserts for Phase 1 boundary rules."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_16_work_item_01] Verifier executes in SERIALIZABLE, performs negative inserts on monitoring_records, and rolls back cleanly."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_16.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_16.json"
    },
    {
        "id": "007-17",
        "title": "INV-165 and INV-167 Correction Verifiers",
        "owner": "SECURITY_GUARDIAN",
        "work": [
            "[ID tsk_p2_preauth_007_17_work_item_01] Replace orthogonal count queries with functional DB queries and fix hardcoded ID=175 bug."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_17_work_item_01] Verifiers correctly assess DB state without orthogonal string matching."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_17.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_17.json"
    },
    {
        "id": "007-18",
        "title": "CI Sequence and Execution Trace",
        "owner": "SECURITY_GUARDIAN",
        "work": [
            "[ID tsk_p2_preauth_007_18_work_item_01] Rewrite pre_ci.sh to emit PRECI_STEP logs and assert ordered execution sequence."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_18_work_item_01] pre_ci.sh structurally logs sequences and validates them without raw string greps."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_18.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_18.json"
    },
    {
        "id": "007-19",
        "title": "CI Provenance and Identity Binding",
        "owner": "SECURITY_GUARDIAN",
        "work": [
            "[ID tsk_p2_preauth_007_19_work_item_01] Implement hash-chaining logic (command digest + env fingerprint) and executor identity binding."
        ],
        "acceptance": [
            "[ID tsk_p2_preauth_007_19_work_item_01] Evidence trace contains cryptographic hash chain binding execution context to the executed script digest."
        ],
        "verifiers": [
            "scripts/audit/verify_tsk_p2_preauth_007_19.sh"
        ],
        "evidence": "evidence/phase2/tsk_p2_preauth_007_19.json"
    }
]

import textwrap

BASE_DIR = "/home/mwiza/workspaces/Symphony-Demo/Symphony"

skipped_tasks = []
created_tasks = []

for task in TASKS:
    task_id_full = f"TSK-P2-PREAUTH-{task['id']}"
    task_dir = os.path.join(BASE_DIR, f"tasks/{task_id_full}")
    plan_dir = os.path.join(BASE_DIR, f"docs/plans/phase2/{task_id_full}")

    # IDEMPOTENCY GUARD: Never overwrite an existing task.
    # If the task directory already exists, skip it entirely.
    # To regenerate an existing task, the operator must first
    # delete or rename the task directory manually.
    if os.path.exists(task_dir):
        skipped_tasks.append(task_id_full)
        print(f"SKIP: {task_id_full} — task directory already exists at {task_dir}. "
              f"Delete or rename the directory to regenerate.")
        continue

    created_tasks.append(task_id_full)
    os.makedirs(task_dir, exist_ok=True)
    os.makedirs(plan_dir, exist_ok=True)
    
    # Generate PLAN.md
    plan_content = f"""# {task_id_full} PLAN — {task['title']}

Task: {task_id_full}
Owner: {task['owner']}
failure_signature: PHASE2.STRICT.{task_id_full}.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

{task['title']} (Wave 7-STRICT). This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [x] Step 1 of Recovery Path (Freeze Wave 7-DRAFT) completed.
- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `{task['verifiers'][0]}` | CREATE | Verifier for this task |
| `{task['evidence']}` | CREATE | Output artifact |
| `tasks/{task_id_full}/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase2/{task_id_full}/EXEC_LOG.md` | MODIFY | Append completion data |

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
{chr(10).join([f"- {w}" for w in task['work']])}
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `{task['verifiers'][0]}`.
- Connect to DB using `DATABASE_URL`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash {task['verifiers'][0]} > {task['evidence']}
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
bash {task['verifiers'][0]}

# 2. Local parity check
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh
```
"""
    with open(os.path.join(plan_dir, "PLAN.md"), "w") as f:
        f.write(plan_content)
        
    with open(os.path.join(plan_dir, "EXEC_LOG.md"), "w") as f:
        f.write(f"""# Execution Log for {task_id_full}

> **Append-only log.** Do not delete or modify existing entries.

**failure_signature**: PHASE2.STRICT.{task_id_full}.PROOF_FAIL
**origin_task_id**: {task_id_full}
**repro_command**: bash {task['verifiers'][0]}

## Pre-Edit Documentation
- Stage A approval sidecar created.

## Implementation Notes
- (Agent to append notes here during execution)

## Post-Edit Documentation
**verification_commands_run**:
```bash
bash {task['verifiers'][0]} > {task['evidence']}
```
**final_status**: pending
""")
    # Generate meta.yml
    meta_content = f"""schema_version: 1
phase: '2'
task_id: {task_id_full}
title: "{task['title']}"
owner_role: {task['owner']}
status: planned
priority: HIGH
risk_class: GOVERNANCE
blast_radius: DATABASE
deliverable_files:
  - {task['verifiers'][0]}
  - {task['evidence']}
  - docs/plans/phase2/{task_id_full}/PLAN.md
  - docs/plans/phase2/{task_id_full}/EXEC_LOG.md

regulated_surface_compliance:
  enabled: true
  approval_workflow: stage_a_stage_b
  stage_a_required_before_edit: true
  regulated_paths:
    - {task['verifiers'][0]}
  must_read:
    - docs/operations/REGULATED_SURFACE_PATHS.yml
    - docs/operations/approval_metadata.schema.json

remediation_trace_compliance:
  enabled: true
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
  enabled: true
  connection_string_format: "postgresql://<user>:<password>@<host>:<port>/<database>"
  example_connection_string: "postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"
  container_name: symphony-postgres
  database_url_env_var: DATABASE_URL
  setup_command: "export DATABASE_URL=\\"postgresql://symphony_admin:symphony_pass@localhost:5432/symphony\\""

migration_dependencies:
  enabled: true
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
  - "Evidence JSON correctly demonstrates DB-level enforcement via negative testing."
proof_limitations:
  - "Does not prove runtime API integration (deferred)."

touches:
  - {task['verifiers'][0]}
  - {task['evidence']}
  - tasks/{task_id_full}/meta.yml
  - docs/plans/phase2/{task_id_full}/PLAN.md
  - docs/plans/phase2/{task_id_full}/EXEC_LOG.md

work:
{chr(10).join([f"  - '{w}'" for w in task['work']])}

acceptance_criteria:
{chr(10).join([f"  - '{a}'" for a in task['acceptance']])}

negative_tests:
  - id: {task_id_full}-N1
    description: "Verify that execution fails transactionally when boundary conditions are violated for: {task['acceptance'][0].split(']')[1].strip()}"
    required: true

positive_tests:
  - id: {task_id_full}-P1
    description: "Verify that execution exits 0 on success path for: {task['acceptance'][0].split(']')[1].strip()}"
    required: true

verification:
  - '# {" ".join([w.split("]")[0] + "]" for w in task['work']])} test -x {task['verifiers'][0]} && bash {task['verifiers'][0]} > {task['evidence']} || exit 1'

evidence:
  - path: {task['evidence']}
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
implementation_plan: docs/plans/phase2/{task_id_full}/PLAN.md
implementation_log: docs/plans/phase2/{task_id_full}/EXEC_LOG.md
notes: 'Wave 7-STRICT Enforcement Track. Replaces Wave 7-DRAFT.'
client: cursor
assigned_agent: {task['owner'].lower()}
model: claude-sonnet-4-20250514
"""
    with open(os.path.join(task_dir, "meta.yml"), "w") as f:
        f.write(meta_content)

print(f"\n{'='*60}")
print(f"Wave 7-STRICT Task Generation Summary")
print(f"{'='*60}")
print(f"  Created: {len(created_tasks)}")
for t in created_tasks:
    print(f"    + {t}")
print(f"  Skipped (already exist): {len(skipped_tasks)}")
for t in skipped_tasks:
    print(f"    ~ {t}")
print(f"{'='*60}")
if skipped_tasks:
    print(f"NOTE: To regenerate a skipped task, delete or rename its")
    print(f"      directory under tasks/ first, then re-run this script.")

