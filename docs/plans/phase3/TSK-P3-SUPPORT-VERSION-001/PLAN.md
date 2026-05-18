# TSK-P3-SUPPORT-VERSION-001 PLAN — Replay continuity and versioning compatibility contract

Task: TSK-P3-SUPPORT-VERSION-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-VERSION-001.PROOF_FAIL
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

Replay continuity and versioning compatibility contract. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: define one canonical shared replay
continuity artifact for dependency-lineage, authority-lineage, and
legitimacy-projection compatibility, without importing deployment lifecycle,
release-management, API versioning, or runtime substrate implementation
semantics.

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
| `docs/architecture/PHASE3_REPLAY_CONTINUITY_AND_VERSIONING_CONTRACT.md` | CREATE | Canonical shared replay continuity artifact for all three owning surfaces |
| `scripts/agent/verify_tsk_p3_support_version_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_version_001_replay_compatibility.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-VERSION-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-VERSION-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into deployment lifecycle, API versioning, or product-versioning semantics** -> STOP
- **If the shared versioning artifact is frozen for fewer than all three owning surfaces** -> STOP

---

## Non-Goals

- No runtime implementation of `P3-SURF-001`, `P3-SURF-002`, or `P3-SURF-003`.
- No deployment lifecycle or release-management design.
- No API versioning or public product versioning.
- No unilateral replay continuity rules for only one owning surface.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical replay continuity artifact exists.
  - The verifier can prove that the artifact declares immutable provenance
    identifiers, replay-hash regression expectations, and explicit Phase 2
    admissible-proof compatibility intent for all three owning surfaces where
    inspected.
- Limitations:
  - The verifier cannot prove runtime implementation of the owning surfaces.
  - The verifier cannot prove full replay equivalence beyond contract-level
    compatibility intent.
  - The verifier cannot prove deployment lifecycle or public API compatibility.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_version_001_w01] Define a single canonical shared versioning artifact for replay continuity across dependency lineage, policy/authority lineage, and legitimacy projection surfaces without importing deployment, release-management, API-lifecycle, or product-versioning semantics.
- [ID tsk_p3_support_version_001_w02] Bind schema, proof, policy-format, and projection compatibility to immutable provenance identifiers, replay-hash regression expectations, and explicit compatibility obligations with the admissible Phase 2 proof substrate.
- [ID tsk_p3_support_version_001_w03] Add a deterministic verifier that proves the shared versioning artifact covers all three owning surfaces, preserves historical replay continuity intent, and does not collapse replay versioning into speculative product lifecycle semantics.
- [ID tsk_p3_support_version_001_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 2 authority-enforcement or fixture scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_support_version_001.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_support_version_001.sh > evidence/phase3/tsk_p3_support_version_001_replay_compatibility.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to
`tasks/TSK-P3-SUPPORT-VERSION-001/meta.yml` as the live runtime task-pack
source.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_support_version_001.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-VERSION-001 --evidence evidence/phase3/tsk_p3_support_version_001_replay_compatibility.json

# 3. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
