# TSK-P3-SUPPORT-FIXTURE-001 PLAN — Canonical replay fixtures for lineage, authority, and legitimacy

Task: TSK-P3-SUPPORT-FIXTURE-001
Owner: ARCHITECT
failure_signature: PHASE3.STRICT.TSK-P3-SUPPORT-FIXTURE-001.PROOF_FAIL
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

Canonical replay fixtures for lineage, authority, and legitimacy. This task forms a closed proof graph from work items to acceptance criteria to execution trace.

Mission scope is intentionally narrow: define one canonical shared replay
fixture artifact for lineage, authority, delegation, revocation, and
legitimacy-projection cases across the four owning surfaces, without importing
regulator, settlement, product-authorization, or future-phase workflow
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
| `docs/architecture/PHASE3_CANONICAL_REPLAY_FIXTURE_CONTRACT.md` | CREATE | Canonical shared replay-fixture artifact for all four owning surfaces |
| `scripts/agent/verify_tsk_p3_support_fixture_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_support_fixture_001_replay_fixtures.json` | CREATE | Output artifact |
| `docs/tasks/PHASE3_RUNTIME_TASKS.md` | MODIFY | Register runtime task in active human index |
| `docs/PHASE3/phase3_task_registry.yml` | MODIFY | Register runtime task pack as live Phase 3 inventory |
| `tasks/TSK-P3-SUPPORT-FIXTURE-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-SUPPORT-FIXTURE-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing regulated surfaces** -> STOP
- **If EXEC_LOG.md does not contain all required markers** -> STOP
- **If the verifier fails to execute negative tests transactionally** -> STOP
- **If evidence is statically faked instead of derived** -> STOP
- **If the task expands into regulator, settlement, product-authorization, or future-phase workflow semantics** -> STOP
- **If the fixture artifact stops being additive-only across the four owning surfaces** -> STOP

---

## Non-Goals

- No runtime implementation of lineage, authority, projection, or delegation surfaces.
- No regulator partition, settlement, or product-authorization semantics.
- No future-phase workflow semantics.
- No scenario prose detached from mechanical verifier closure.
- No silent rewriting of Wave 1 lineage or authority meaning.

---

## Proof Boundaries

- Guarantees:
  - The verifier can prove that one canonical shared fixture artifact exists.
  - The verifier can prove that the artifact covers all four owning surfaces and
    declares additive-only reconciliation, deterministic valid/invalid replay
    cases, and explicit prohibition on silently redefining Wave 1 lineage or
    authority semantics where inspected.
- Limitations:
  - The verifier cannot prove runtime implementation of any owning surface.
  - The verifier cannot prove substantive correctness of legitimacy or
    authority doctrines beyond declared fixture coverage.
  - The verifier cannot prove regulator, settlement, or future-phase workflow
    semantics because those are outside task scope.

---

## Implementation Steps

### Step 1: Implement Work Items
**What:** Execute the work items linked via ID.
**How:**
- [ID tsk_p3_support_fixture_001_w01] Define one canonical shared fixture artifact for valid and invalid lineage, authority, delegation, revocation, and legitimacy-projection cases across P3-SURF-001, P3-SURF-002, P3-SURF-003, and P3-SURF-006 without importing regulator, settlement, or future-phase workflow semantics.
- [ID tsk_p3_support_fixture_001_w02] Bind fixture definitions to additive-only reconciliation rules, immutable provenance expectations, deterministic positive and negative replay cases, and explicit prohibitions on rewriting Wave 1 lineage or authority meaning.
- [ID tsk_p3_support_fixture_001_w03] Add a deterministic verifier that proves the shared fixture artifact covers all four owning surfaces, preserves additive-only reconciliation, and supports replay-safe verifier closure without inventing projection or authority doctrine locally.
- [ID tsk_p3_support_fixture_001_w04] Register the task in the active Phase 3 runtime task index and registry without altering unrelated Wave 2 runtime-node scope.
**Done when:** All items are implemented.

### Step 2: Implement Verifier
**What:** Build the strictly mapped verifier script.
**How:**
- Implement `scripts/agent/verify_tsk_p3_support_fixture_001.sh`.

- Enforce failure domains.
**Done when:** Script correctly evaluates acceptance criteria and exits 0 on success.

### Step 3: Emit evidence
**What:** Run verifier and check evidence schema.
**How:**
```bash
bash scripts/agent/verify_tsk_p3_support_fixture_001.sh > evidence/phase3/tsk_p3_support_fixture_001_replay_fixtures.json
```
**Done when:** Commands exit 0 and evidence format complies.

### Step 4: Runtime Index And Registry
**What:** Register the generated runtime task pack in the active human index and
Phase 3 runtime registry.
**How:**
- Update `docs/tasks/PHASE3_RUNTIME_TASKS.md`.
- Update `docs/PHASE3/phase3_task_registry.yml`.
**Done when:** Both files point to
`tasks/TSK-P3-SUPPORT-FIXTURE-001/meta.yml` as the live runtime task-pack
source.


---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/agent/verify_tsk_p3_support_fixture_001.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py --task TSK-P3-SUPPORT-FIXTURE-001 --evidence evidence/phase3/tsk_p3_support_fixture_001_replay_fixtures.json

# 3. Local parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```
