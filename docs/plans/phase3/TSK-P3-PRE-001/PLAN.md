# TSK-P3-PRE-001 PLAN — Verify wave8_crypto extension operational status for Phase 3 entry

Task: TSK-P3-PRE-001
Owner: SECURITY_GUARDIAN
failure_signature: PHASE3.STRICT.TSK-P3-PRE-001.PROOF_FAIL
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

Verify wave8_crypto extension operational status for Phase 3 entry. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_ed25519_available.sh` | CREATE | Verifier for this task |
| `evidence/phase3/wave8_crypto_operational_status.json` | CREATE | Output artifact |
| `tasks/TSK-P3-PRE-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-PRE-001/EXEC_LOG.md` | MODIFY | Append completion data |

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
- [ID tsk_p3_pre_001_work_item_01] Create scripts/audit/verify_ed25519_available.sh that confirms ed25519_verify() is callable in the Postgres runtime environment by executing a known-bad signature test and verifying it returns FALSE rather than a function-not-found error.
- [ID tsk_p3_pre_001_work_item_02] Emit evidence to evidence/phase3/wave8_crypto_operational_status.json recording function existence in pg_proc, extension load status, call result, git_sha, and timestamp_utc.
- [ID tsk_p3_pre_001_work_item_03] Wire the script as a Tier 0 CI gate that blocks all Phase 3 work if ed25519_verify() is not callable.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_ed25519_available.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_ed25519_available.sh > evidence/phase3/wave8_crypto_operational_status.json
```
**Done when:** Commands exit 0 and evidence format complies.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_ed25519_available.sh

# 2. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
