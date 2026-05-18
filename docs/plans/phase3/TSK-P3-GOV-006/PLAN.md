# TSK-P3-GOV-006 PLAN — Fail-closed DB probe contract for audit-side DB-facing verifiers

Task: TSK-P3-GOV-006
Owner: QA_VERIFIER
failure_signature: PHASE3.STRICT.TSK-P3-GOV-006.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---
## Objective

Fail-closed DB probe contract for audit-side DB-facing verifiers. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

- [ ] `docs/operations/TASK_ID_NOMENCLATURE.md` reviewed for task-family and wave rules.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.


---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative audit-side DB-facing verifier |
| `scripts/audit/verify_p3_failure_composition_engine.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative audit-side DB-facing verifier |
| `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` | MODIFY | Tighten DB/bootstrap failure reporting for representative audit-side DB-facing verifier |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register task in Phase 3 registry |
| `docs/tasks/PHASE3_TASKS.md` | MODIFY | Register task in the human Phase 3 task index |
| `scripts/audit/verify_tsk_p3_gov_006_db_probe_contract.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_gov_006_db_probe_contract.json` | CREATE | Output artifact |
| `tasks/TSK-P3-GOV-006/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-006/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_gov_006_w01] Define and document the fail-closed contract for audit-side verifiers that probe live databases so connection/bootstrap failures cannot be silently downgraded into false schema-absence reports.
- [ID tsk_p3_gov_006_w02] Retrofit representative scripts/audit DB-facing verifiers to enforce the documented probe contract and emit explicit environment/bootstrap failure checks.
- [ID tsk_p3_gov_006_w03] Add a deterministic verifier that fails if representative audit-side DB verifiers still contain silent DB probe fallbacks and emits evidence proving the repaired contract.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_gov_006_db_probe_contract.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_gov_006_db_probe_contract.sh > evidence/phase3/tsk_p3_gov_006_db_probe_contract.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_gov_006_db_probe_contract.sh

# 2. Evidence validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-GOV-006 --evidence evidence/phase3/tsk_p3_gov_006_db_probe_contract.json

# 3. Task-pack readiness
bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P3-GOV-006
```
