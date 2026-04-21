---
failure_signature: P2.REM.entity-binding-structural-enforcement.architectural-risk
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
---

# REM-2026-04-21_entity-binding-structural-enforcement PLAN — Wave 5 Structural Entity Binding Casefile

Task: REM-2026-04-21_entity-binding-structural-enforcement
Owner: ARCHITECT
Depends on: TSK-P2-PREAUTH-004-01
failure_signature: P2.REM.entity-binding-structural-enforcement.architectural-risk
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create a remediation casefile to upgrade cryptographic-only entity binding to structural enforcement before Wave 5 ships. This casefile documents the architectural risk in Wave 4's policy_decisions table and defines candidate approaches for structural enforcement to be implemented in Wave 5. Done when: casefile PLAN.md exists with two candidate approaches, meta.yml is fully populated with anti-drift fields, execution log exists, task is registered in PHASE2_TASKS.md, and all validation scripts pass.

---

## Architectural Context

Wave 4's policy_decisions table enforces entity binding cryptographically: entity_type and entity_id are included in decision_payload, and decision_hash = sha256(canonical_json(decision_payload)). If payload is reconstructed differently, hash verification could false-positive/negative. Wave 5's state machine will call enforce_authority_transition_binding(uuid, uuid). For this call to be structurally safe (not cryptographic-only), execution_records must already carry entity_type/entity_id columns by the time Wave 5 ships. Deferring to Wave 6 would extend the accepted-risk window by an entire wave with no architectural justification.

---

## Pre-conditions

- [ ] TSK-P2-PREAUTH-004-01 is status=completed and evidence validates
- [ ] TASK_CREATION_PROCESS.md has been reviewed
- [ ] This PLAN.md has been reviewed for anti-drift compliance

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md` | CREATE | Casefile with architectural risk analysis and candidate approaches |
| `tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml` | MODIFY | Populate with all required fields including anti-drift fields |
| `docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/EXEC_LOG.md` | CREATE | Append-only execution history table |
| `docs/tasks/PHASE2_TASKS.md` | MODIFY | Register task with required fields |
| `tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If verify_plan_semantic_alignment.py fails** -> STOP
- **If verify_task_meta_schema.sh fails** -> STOP
- **If verify_task_pack_readiness.sh fails** -> STOP

---

## Implementation Steps

### Step 1: Create casefile PLAN.md
**What:** `[ID rem_entity_binding_01]` Create casefile PLAN.md at docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md with required sections including mission, constraints, verification commands, approval references, evidence paths, out_of_scope, stop_conditions, proof_guarantees, proof_limitations
**How:** Write PLAN.md following TASK_CREATION_PROCESS.md and PLAN_TEMPLATE.md format, including architectural context and two candidate approaches (a) extend execution_records with entity columns, (b) enforce binding at transition-application layer
**Done when:** PLAN.md file exists and contains all required sections

### Step 2: Populate meta.yml with anti-drift fields
**What:** `[ID rem_entity_binding_02]` Populate meta.yml with all required fields per TASK_CREATION_PROCESS.md Step 4, including anti-drift fields (out_of_scope, stop_conditions, proof_guarantees, proof_limitations), ID-tagged work items, acceptance criteria, verification commands, evidence paths, failure modes
**How:** Edit tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml to add depends_on, touches, invariants, work, acceptance_criteria, verification, evidence, failure_modes, must_read, implementation_plan, implementation_log, client, assigned_agent, model
**Done when:** Meta.yml contains all required fields and passes schema validation

### Step 3: Create execution log
**What:** `[ID rem_entity_binding_03]` Create execution log at docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/EXEC_LOG.md with empty execution history table
**How:** Create EXEC_LOG.md with append-only execution history table structure
**Done when:** EXEC_LOG.md file exists with empty table

### Step 4: Register task in human task index
**What:** `[ID rem_entity_binding_04]` Register task in docs/tasks/PHASE2_TASKS.md with required fields (task id, title, owner, depends on, touches, invariants, work, acceptance criteria, verification, evidence, failure modes)
**How:** Edit docs/tasks/PHASE2_TASKS.md to add task entry with all required metadata
**Done when:** Task is listed in PHASE2_TASKS.md with all required fields

### Step 5: Verify proof graph integrity
**What:** `[ID rem_entity_binding_05]` Run verify_plan_semantic_alignment.py and ensure it passes with NO_ORPHANS=true and GRAPH_CONNECTED=true
**How:** Execute python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md --meta tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml
**Done when:** Command exits with code 0 and output shows NO_ORPHANS=true and GRAPH_CONNECTED=true

### Step 6: Verify task meta schema
**What:** `[ID rem_entity_binding_06]` Run verify_task_meta_schema.sh and ensure it passes with no errors
**How:** Execute bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy
**Done when:** Command exits with code 0

### Step 7: Verify task pack readiness
**What:** `[ID rem_entity_binding_07]` Run verify_task_pack_readiness.sh and ensure it passes with status=ready
**How:** Execute bash scripts/audit/verify_task_pack_readiness.sh --task REM-2026-04-21_entity-binding-structural-enforcement
**Done when:** Command exits with code 0 and status=ready

### Step 8: Emit evidence
**What:** `[ID rem_entity_binding_08]` Run verification commands and validate evidence schema
**How:**
```bash
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md --meta tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml > evidence/phase2/rem_entity_binding_casefile_creation.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON evidence is written to disk

---

## Verification

```bash
# [ID rem_entity_binding_05] [ID rem_entity_binding_06] [ID rem_entity_binding_07] [ID rem_entity_binding_08]
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md --meta tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml > evidence/phase2/rem_entity_binding_casefile_creation.json || exit 1

# [ID rem_entity_binding_06]
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy || exit 1

# [ID rem_entity_binding_07]
bash scripts/audit/verify_task_pack_readiness.sh --task REM-2026-04-21_entity-binding-structural-enforcement || exit 1

# [ID rem_entity_binding_08]
test -f evidence/phase2/rem_entity_binding_casefile_creation.json && cat evidence/phase2/rem_entity_binding_casefile_creation.json | grep "graph_validation_enabled" || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/rem_entity_binding_casefile_creation.json`

Required fields:
- `task_id`: "REM-2026-04-21_entity-binding-structural-enforcement"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including graph validation, schema validation, pack readiness)
- `plan_path`: "docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md"
- `meta_path`: "tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml"
- `log_path`: "docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/EXEC_LOG.md"
- `task_index_path`: "docs/tasks/PHASE2_TASKS.md"
- `graph_validation_enabled`: true

---

## Rollback

If this task must be reverted:
1. Delete docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/PLAN.md
2. Delete docs/plans/phase2/REM-2026-04-21_entity-binding-structural-enforcement/EXEC_LOG.md
3. Delete tasks/REM-2026-04-21_entity-binding-structural-enforcement/meta.yml
4. Remove task entry from docs/tasks/PHASE2_TASKS.md
5. Update status back to 'planned' in meta.yml if it was advanced

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| verify_plan_semantic_alignment.py fails | CRITICAL_FAIL | Fix PLAN.md structure to match template |
| verify_task_meta_schema.sh fails | CRITICAL_FAIL | Fix meta.yml to include all required fields |
| verify_task_pack_readiness.sh fails | CRITICAL_FAIL | Fix task pack to satisfy readiness checks |
| Casefile missing required sections | FAIL | Add all required sections per TASK_CREATION_PROCESS.md |
| Anti-drift fields missing | FAIL | Add out_of_scope, stop_conditions, proof_guarantees, proof_limitations |
| Task not registered in index | FAIL | Add task to PHASE2_TASKS.md with required fields |

---

## Approval

This task does not modify regulated surfaces (schema, scripts, operations docs), so no approval metadata is required.

---

## Candidate Approaches

### Approach (a): Extend execution_records with entity columns

**Schema changes:**
- Add entity_type TEXT NOT NULL to execution_records
- Add entity_id UUID NOT NULL to execution_records
- Add coherence CHECK/trigger on policy_decisions INSERT to ensure entity_type/entity_id match between policy_decisions and execution_records

**Pros:**
- Structural enforcement at database level
- Coherence check prevents cross-entity replay
- Expand-only change (non-breaking)

**Cons:**
- Requires migration on execution_records (high-impact table)
- May require data migration for existing rows
- Increases execution_records row size

### Approach (b): Enforce binding at transition-application layer

**Implementation:**
- Add entity_type/entity_id validation in state machine service before calling enforce_authority_transition_binding
- Service reads entity_type/entity_id from policy_decisions and validates against execution_records context
- Reject transition if entity mismatch detected

**Pros:**
- No schema changes to execution_records
- Can be implemented in application layer without database migration
- Easier to rollback if needed

**Cons:**
- Enforcement is application-layer, not database-layer
- Requires service-level changes in Wave 5
- May have performance impact (additional reads)
