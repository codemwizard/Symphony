# TSK-P3-GOV-005 PLAN — AI governance doctrine, model registry and inference log schemas, and confidence-to-uncertainty admissibility mappings

Task: TSK-P3-GOV-005
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-GOV-005.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---
## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any regulated file without prior approval metadata.
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

AI governance doctrine, model registry and inference log schemas, and
confidence-to-uncertainty admissibility mappings. This task forms a closed
proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: establish only the canonical AI
governance contract required by Phase 3, covering advisory-only admissibility,
model provenance, inference logging, and subordinate confidence-to-uncertainty
mapping, without importing AI runtime execution, model training, or
downstream-phase intelligence behavior.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.
- [ ] `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md` reviewed for scope boundaries.
- [ ] `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` reviewed for invariant references.
- [ ] `docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` reviewed for AI governance rules.
- [ ] `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` reviewed for mapping dependencies.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/architecture/PHASE3_AI_GOVERNANCE_AND_MODEL_PROVENANCE_CONTRACT.md` | CREATE | Canonical AI governance contract |
| `scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_gov_005_ai_governance.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-GOV-005/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-GOV-005/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task introduces AI execution runtime, model training, or inference pipelines** -> STOP
- **If the AI artifact cannot remain a single canonical advisory-only governance contract for Phase 3** -> STOP

---

## Non-Goals

- No AI model execution runtime or model serving.
- No ML training infrastructure or inference pipelines.
- No document intelligence, anomaly detection, disclosure intelligence, or climate-finance intelligence execution.
- No constitutional truth delegation to AI outputs.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical AI governance artifact exists and
    is machine-inspectable where inspected.
  - The verifier can prove that the artifact declares advisory-only
    admissibility, anti-truth-delegation rules, model provenance, and
    replay-addressable inference logging under the declared scope.
- Limitations:
  - The verifier cannot prove any AI model runtime, training, or inference
    behavior.
  - The verifier cannot prove downstream Phase 5, Phase 6, Phase 8D, or Phase
    8E AI capability execution.
  - The verifier cannot prove uncertainty computation beyond consuming the
    declared uncertainty substrate.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_gov_005_w01] Define one canonical AI governance artifact for advisory-only admissibility, model provenance, inference-log schema, and confidence-to-uncertainty mapping without importing AI runtime execution or model-training semantics.
- [ID tsk_p3_gov_005_w02] Bind the artifact to explicit anti-truth-delegation rules, registry-bound model identity, replay-addressable inference logging, and confidence-to-uncertainty mapping subordinate to the uncertainty substrate.
- [ID tsk_p3_gov_005_w03] Add a deterministic verifier that proves the artifact is mechanically inspectable, advisory-only, and explicit about AI-free Phase 3 runtime boundaries under the declared structural contract.
- [ID tsk_p3_gov_005_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 5 uncertainty or documentation-closeout scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh`.
- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit Evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh > evidence/phase3/tsk_p3_gov_005_ai_governance.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active Phase 3 runtime index and registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to `tasks/TSK-P3-GOV-005/meta.yml` as the live runtime task-pack source.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-GOV-005 --evidence evidence/phase3/tsk_p3_gov_005_ai_governance.json
```
