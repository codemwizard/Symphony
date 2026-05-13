# Phase 3 Readiness — Implementation Plan

**Phase Key:** P3-PRE
**Phase Name:** Phase 3 Readiness
**Lifecycle Phase:** 3

---

## Goal

Complete the 4 pre-implementation prerequisites identified during the Phase 3 Evolution Summary review, enabling Phase 3 implementation to begin. This work produces the task infrastructure, nomenclature standard, and governance registry required before any Phase 3 IMPL task can be created.

## Background

The Phase 3 Constitutional Audit identified that the following must exist before implementation begins:
1. Phase 2 constitutional status reconciled in `PHASE_CAPABILITY_LEGALITY_MATRIX.md`
2. Phase 3 task infrastructure created (template + generator + validator)
3. Task ID nomenclature formalized
4. `phase3_task_registry.yml` materialized with verified task IDs

These are governance/documentation tasks — not runtime implementation. Blast radius is `DOCS_ONLY` or `SCRIPTS` for all tasks.

## User Review Required

> [!IMPORTANT]
> **Task ID Suffixes**: This plan proposes `PRE` as the group suffix for all pre-implementation tasks (e.g., `TSK-P3-PRE-001`). This suffix is itself provisional — it becomes canonical only after TSK-P3-PRE-003 (nomenclature formalization) is completed. Do you approve `PRE` as the group suffix for this prerequisite work?

> [!IMPORTANT]
> **Scope Boundary**: This plan produces the *scaffolding* for Phase 3 tasks — templates, validators, registry schema, nomenclature. It does NOT create the actual 119 Phase 3 implementation tasks. Those will be created using the infrastructure this plan builds.

## Open Questions

1. **Phase 3 human task index location**: Should it be `docs/tasks/PHASE3_TASKS.md` (following existing pattern) or a new structure? Current convention uses `docs/tasks/PHASE0_TASKS.md`, `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`.

2. **Registry approval**: Should `phase3_task_registry.yml` live in `docs/PHASE3/` (constitutional territory) or `tasks/` (operational territory)?

---

## Proposed Changes

### Dependency Graph

```
TSK-P3-PRE-001 (Phase 2 Status)     TSK-P3-PRE-003 (Nomenclature)
         │                                    │
         │                              ┌─────┴──────┐
         │                              │            │
         ▼                              ▼            │
    [independent]              TSK-P3-PRE-004        │
                              (meta.yml adapt)       │
                                    │                │
                              TSK-P3-PRE-005         │
                             (generator update)      │
                                    │                │
                              TSK-P3-PRE-006         │
                             (validator update)      │
                                    │                ▼
                              TSK-P3-PRE-007    TSK-P3-PRE-008
                             (registry schema)  (registry populate)
                                    │                │
                                    └────────┬───────┘
                                             │
                                       TSK-P3-PRE-009
                                      (exit gate check)

TSK-P3-PRE-002 (CI tier model) ──────────────┘
```

---

### Prerequisite 1: Phase 2 Status Reconciliation

#### [MODIFY] [PHASE_CAPABILITY_LEGALITY_MATRIX.md](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md)

**TSK-P3-PRE-001 — Reconcile Phase 2 Constitutional Status**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | None |
| Invariants | None (governance documentation) |
| Regulated surface | Yes — `docs/constitutional/**` |

Work items (5):
1. `[ID tsk_p3_pre_001_w01]` Read `PHASE_CAPABILITY_LEGALITY_MATRIX.md` §3.3 and identify all references to "FORMALLY UNOPENED" for Phase 2.
2. `[ID tsk_p3_pre_001_w02]` Update §3.3 constitutional posture from "FORMALLY UNOPENED" to "CLOSED" with citation to `approvals/2026-05-10/PHASE2_CLOSEOUT_APPROVAL.json` and `approvals/2026-05-03/PHASE2-RATIFICATION.md`.
3. `[ID tsk_p3_pre_001_w03]` Update PROHIB-05 (line 651-656) to reflect Phase 2 is now closed, not unopened.
4. `[ID tsk_p3_pre_001_w04]` Update §3.4 (Phase 3 entry condition) to confirm Phase 2 closeout dependency is now satisfied.
5. `[ID tsk_p3_pre_001_w05]` Verify no other section of the document contains stale Phase 2 status references.

Acceptance criteria:
- `grep -c "FORMALLY UNOPENED" docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md` returns 0 for Phase 2 references.
- §3.3 cites both approval artifacts with dates.
- §3.4 entry condition reads as satisfied.
- `pre_ci.sh` passes (no admissibility violations introduced).

Negative test:
- `TSK-P3-PRE-001-N1`: Temporarily revert §3.3 to "FORMALLY UNOPENED" — `verify_phase_claim_admissibility.sh` must NOT reject Phase 3 claims (because Opening Act supersedes), confirming the update is documentation hygiene, not a gate-breaker.

Evidence: `evidence/phase3/tsk_p3_pre_001_status_reconciliation.json`

---

### Prerequisite 4 (Execution Order 2): Task ID Nomenclature

#### [NEW] [TASK_ID_NOMENCLATURE.md](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/docs/operations/TASK_ID_NOMENCLATURE.md)

**TSK-P3-PRE-003 — Formalize Task ID Nomenclature Standard**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | None |
| Invariants | None (new governance document) |
| Regulated surface | Yes — `docs/operations/**` |

Work items (6):
1. `[ID tsk_p3_pre_003_w01]` Inventory all existing task ID suffixes from Phases 0-2 by scanning `tasks/*/meta.yml` and extracting unique group patterns. Document each with usage count and inferred meaning.
2. `[ID tsk_p3_pre_003_w02]` Define the canonical task ID format specification: `TSK-P<phase>-<group>-<sequence>` with rules for each segment (phase = single digit, group = 2-8 uppercase alphanumeric, sequence = 3-digit zero-padded).
3. `[ID tsk_p3_pre_003_w03]` Define the Phase 3 approved group registry derived from Phase 3 capability boundary (Waves 1-10 map to W1-W10, Domains G-P map to DG-DP, prerequisites map to PRE, CI/Verification maps to CI).
4. `[ID tsk_p3_pre_003_w04]` Document retroactive suffixes from Phases 0-2 as "legacy-approved" (PREAUTH, GOV, SEC, PLT, REG, RLS, INT, HIER, DEMO, UI, FNC, SCH, etc.) with explicit note that these are not valid for Phase 3 unless re-approved.
5. `[ID tsk_p3_pre_003_w05]` Define validation rules: Phase 3 task IDs MUST use an approved Phase 3 group suffix; legacy suffixes are rejected for `phase: '3'` tasks.
6. `[ID tsk_p3_pre_003_w06]` Write `docs/operations/TASK_ID_NOMENCLATURE.md` containing the format spec, Phase 3 registry, legacy inventory, and validation rules.

Acceptance criteria:
- `docs/operations/TASK_ID_NOMENCLATURE.md` exists and contains all sections.
- Phase 3 group registry contains ≥12 approved suffixes (W1-W10, PRE, CI + domains).
- Legacy inventory contains ≥15 documented suffixes with usage counts.
- Format specification is machine-parseable (regex pattern provided).

Negative test:
- `TSK-P3-PRE-003-N1`: Verify that the format spec regex rejects malformed IDs: `TSK-P3-lowercase-001`, `TSK-P3-TOOLONGSUFFIX-001`, `TSK-P3-W2-1` (unpadded sequence).

Evidence: `evidence/phase3/tsk_p3_pre_003_nomenclature.json`

---

### Prerequisite 2 (Execution Order 3-7): Task Infrastructure

#### [MODIFY] [tasks/_template/meta.yml](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/tasks/_template/meta.yml)

**TSK-P3-PRE-004 — Adapt meta.yml Template for Phase 3**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | `TSK-P3-PRE-003` |
| Invariants | None |
| Regulated surface | No |

Work items (5):
1. `[ID tsk_p3_pre_004_w01]` Add `wave` field to the `meta.yml` template with comment documenting valid values (W1-W10 for waves, DG-DP for domains, PRE for prerequisites).
2. `[ID tsk_p3_pre_004_w02]` Update default `must_read` entries to include Phase 3 constitutional documents: `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md`, `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`.
3. `[ID tsk_p3_pre_004_w03]` Update path mapping comments to include `phase: '3'` → `docs/plans/phase3/<TASK_ID>/PLAN.md`.
4. `[ID tsk_p3_pre_004_w04]` Add `docs/operations/TASK_ID_NOMENCLATURE.md` to `must_read` for all Phase 3 tasks.
5. `[ID tsk_p3_pre_004_w05]` Verify template remains backward compatible — existing Phase 0-2 tasks must not break. Run `PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode inventory` to confirm.

Acceptance criteria:
- `wave` field present in template with valid-value documentation.
- Phase 3 `must_read` defaults are present.
- Path mapping includes `phase: '3'`.
- `verify_task_meta_schema.sh --mode inventory` exits 0 (no regressions).

Negative test:
- `TSK-P3-PRE-004-N1`: Create a test `meta.yml` with `wave: INVALID` — should be flagged by updated validator (deferred to TSK-P3-PRE-006).

Evidence: `evidence/phase3/tsk_p3_pre_004_template_adaptation.json`

---

#### [MODIFY] [scripts/agent/generate_task_pack.py](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/scripts/agent/generate_task_pack.py)

**TSK-P3-PRE-005 — Update Task Generator for Phase 3 Mode**

| Field | Value |
|-------|-------|
| Blast radius | `SCRIPTS` |
| Owner | `SECURITY_GUARDIAN` |
| Depends on | `TSK-P3-PRE-004` |
| Invariants | None |
| Regulated surface | Yes — `scripts/agent/**` |

Work items (5):
1. `[ID tsk_p3_pre_005_w01]` Add `wave` as an optional field in the JSON config schema. When `phase == '3'`, validate that `wave` is from the Phase 3 approved group registry (from `TASK_ID_NOMENCLATURE.md`).
2. `[ID tsk_p3_pre_005_w02]` Add Phase 3 task ID pattern validation: when `phase == '3'`, `task_id` must match `^TSK-P3-[A-Z0-9]{2,8}-\d{3}$` (or the canonical regex from TSK-P3-PRE-003).
3. `[ID tsk_p3_pre_005_w03]` Inject Phase 3 `must_read` entries into generated `meta.yml`: `PHASE3_CAPABILITY_BOUNDARY.md`, `PHASE3_INVARIANT_REGISTER.md`, `TASK_ID_NOMENCLATURE.md`.
4. `[ID tsk_p3_pre_005_w04]` Update PLAN.md generation to reference Phase 3 constitutional documents in the Pre-conditions section.
5. `[ID tsk_p3_pre_005_w05]` Add `--phase3` convenience flag that sets `phase=3`, `is_regulated=true`, and injects Phase 3 defaults automatically.

Acceptance criteria:
- `python3 scripts/agent/generate_task_pack.py --config test_p3.json` produces valid Phase 3 task pack.
- Generator rejects `task_id: TSK-P3-lowercase-001` with clear error.
- Generated `meta.yml` contains Phase 3 `must_read` entries.
- Generated `PLAN.md` references Phase 3 capability boundary.
- Existing Phase 1/2 task generation is unaffected.

Negative test:
- `TSK-P3-PRE-005-N1`: Run generator with `phase: '3'` and `task_id: TSK-P3-TOOLONGSUFFIX-001` — must exit non-zero with validation error.

Evidence: `evidence/phase3/tsk_p3_pre_005_generator_update.json`

---

#### [MODIFY] [scripts/audit/verify_task_meta_schema.sh](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/scripts/audit/verify_task_meta_schema.sh)

**TSK-P3-PRE-006 — Update Task Schema Validator for Phase 3**

| Field | Value |
|-------|-------|
| Blast radius | `SCRIPTS` |
| Owner | `SECURITY_GUARDIAN` |
| Depends on | `TSK-P3-PRE-005` |
| Invariants | None |
| Regulated surface | Yes — `scripts/audit/**` |

> [!CAUTION]
> **Backward Compatibility Constraint**: The schema validator evaluates tasks across ALL phases. All Phase 3 validation rules (`wave` presence, task ID format, invariant range, `must_read` contents) **MUST** be conditionally gated behind `if obj.get("phase") == "3":`. Do not add new fields to the global `required` list, as this will instantly invalidate all Phase 0-2 tasks.

Work items (5):
1. `[ID tsk_p3_pre_006_w01]` Add Phase 3 task ID format validation: when `phase: '3'`, enforce the canonical regex from `TASK_ID_NOMENCLATURE.md`.
2. `[ID tsk_p3_pre_006_w02]` Add `wave` field validation: when present and `phase: '3'`, value must be from approved Phase 3 group list.
3. `[ID tsk_p3_pre_006_w03]` Add `invariants` range validation: when `phase: '3'`, invariant references must match `^INV-3\d{2}$` pattern (INV-300 through INV-399).
4. `[ID tsk_p3_pre_006_w04]` Add Phase 3 `must_read` validation: when `phase: '3'`, `must_read` must include `PHASE3_CAPABILITY_BOUNDARY.md` and `PHASE3_INVARIANT_REGISTER.md`.
5. `[ID tsk_p3_pre_006_w05]` Run full validation suite against existing tasks to confirm no regressions: `PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode inventory`.

Acceptance criteria:
- Validator rejects Phase 3 tasks with invalid task ID format.
- Validator rejects Phase 3 tasks with invalid `wave` values.
- Validator rejects Phase 3 tasks with out-of-range invariant references.
- All existing Phase 0-2 tasks continue to pass validation.

Negative test:
- `TSK-P3-PRE-006-N1`: Create a test `meta.yml` with `phase: '3'`, `task_id: TSK-P3-W2-ENG-001`, `wave: INVALID`, `invariants: [INV-999]` — validator must report all three violations.

Evidence: `evidence/phase3/tsk_p3_pre_006_validator_update.json`

---

#### [NEW] [docs/PHASE3/phase3_task_registry.yml](file:///home/mwiza/workspaces/Symphony-Demo/Symphony/docs/PHASE3/phase3_task_registry.yml)

**TSK-P3-PRE-007 — Define Phase 3 Task Registry Schema**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | `TSK-P3-PRE-006` |
| Invariants | None |
| Regulated surface | No |

Work items (5):
1. `[ID tsk_p3_pre_007_w01]` Define the `phase3_task_registry.yml` YAML schema: top-level fields (`registry_version`, `phase`, `phase_name`, `generated_at`, `task_count`), per-task fields (`task_id`, `wave`, `task_type`, `invariants_enforced`, `ci_tier`, `verifies`, `depends_on`).
2. `[ID tsk_p3_pre_007_w02]` Define the approved `task_type` values: `IMPL`, `VERIFY`, `CERT`, `GOV`, `PERSIST`, `API`, `DOC`, `OPS`.
3. `[ID tsk_p3_pre_007_w03]` Define the approved `ci_tier` values with semantic meaning: `T0` (every commit), `T1` (every PR), `T2` (PR + label), `T3` (nightly), `T4` (pre-release). Label as "proposed — to be validated."
4. `[ID tsk_p3_pre_007_w04]` Create `docs/PHASE3/phase3_task_registry.yml` with the schema as header comments and 3 example tasks (one IMPL, one VERIFY with `verifies` linkage, one CERT).
5. `[ID tsk_p3_pre_007_w05]` Document the governance contract: this registry is a read-only planning index; individual tasks do NOT reference it; planners and CI orchestrators consume it.

Acceptance criteria:
- `phase3_task_registry.yml` exists with schema header and 3 example tasks.
- Schema is valid YAML (parseable by `python3 -c "import yaml; yaml.safe_load(open('...'))"`)
- VERIFY example task has `verifies` field pointing to IMPL example.
- Governance contract is documented in header comments.

Negative test:
- `TSK-P3-PRE-007-N1`: Attempt to parse the registry with a missing required field — YAML parser must report the omission (validated by a simple Python script).

Evidence: `evidence/phase3/tsk_p3_pre_007_registry_schema.json`

---

### Prerequisite 2b: CI Tier Model

**TSK-P3-PRE-002 — Define Phase 3 CI Tier Model**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | None |
| Invariants | None |
| Regulated surface | No |

Work items (5):
1. `[ID tsk_p3_pre_002_w01]` Define the 5 CI tiers (T0-T4) with trigger conditions, target execution time, and contents.
2. `[ID tsk_p3_pre_002_w02]` For each tier, list which Phase 3 invariants (INV-301 through INV-310) will be checked, marked as "proposed — to be validated during implementation."
3. `[ID tsk_p3_pre_002_w03]` Define the tier assignment rules: how new tasks are assigned to tiers based on `task_type` and `wave`.
4. `[ID tsk_p3_pre_002_w04]` Document the tier escalation policy: what happens when a T0 test fails vs a T3 test fails.
5. `[ID tsk_p3_pre_002_w05]` Write `docs/PHASE3/PHASE3_CI_TIER_MODEL.md` containing the full specification.

Acceptance criteria:
- `docs/PHASE3/PHASE3_CI_TIER_MODEL.md` exists with all 5 tiers defined.
- Each tier has trigger condition, time target, and invariant assignments (marked as proposed).
- Tier assignment rules are documented.
- Escalation policy is documented.

Negative test:
- `TSK-P3-PRE-002-N1`: Verify that every INV-301 through INV-310 appears in at least one tier — no invariant may be unassigned.

Evidence: `evidence/phase3/tsk_p3_pre_002_ci_tier_model.json`

---

### Prerequisite 3: Registry Population

**TSK-P3-PRE-008 — Populate Phase 3 Task Registry**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `ARCHITECT` |
| Depends on | `TSK-P3-PRE-003`, `TSK-P3-PRE-007` |
| Invariants | None |
| Regulated surface | No |

Work items (6):
1. `[ID tsk_p3_pre_008_w01]` Extract all task IDs from `phase_3_constraint_legitimacy_engine_task_plan.md`, applying nomenclature rules from `TASK_ID_NOMENCLATURE.md`.
2. `[ID tsk_p3_pre_008_w02]` Assign each task a `task_type` from the approved taxonomy (IMPL/VERIFY/CERT/GOV/PERSIST/API/DOC/OPS).
3. `[ID tsk_p3_pre_008_w03]` Assign each task a `wave` from the approved group registry.
4. `[ID tsk_p3_pre_008_w04]` Assign each task a `ci_tier` from the CI tier model (mark all as proposed).
5. `[ID tsk_p3_pre_008_w05]` Link VERIFY tasks to their IMPL parents via `verifies` field.
6. `[ID tsk_p3_pre_008_w06]` Populate `docs/PHASE3/phase3_task_registry.yml` with all tasks, replacing the 3 example tasks with the verified inventory.

Acceptance criteria:
- Registry contains a verified count of tasks (confirming or correcting the "119" narrative number).
- Every task has a valid `task_id`, `wave`, `task_type`, and `ci_tier`.
- Every VERIFY task has a `verifies` field pointing to an existing IMPL task.
- Registry is valid YAML.
- `task_count` field matches actual count of tasks in the file.

Negative test:
- `TSK-P3-PRE-008-N1`: Run a script that checks every `task_id` in the registry against the nomenclature regex — all must match.

Evidence: `evidence/phase3/tsk_p3_pre_008_registry_population.json`

---

### Exit Gate

**TSK-P3-PRE-009 — Phase 3 Readiness Exit Gate**

| Field | Value |
|-------|-------|
| Blast radius | `DOCS_ONLY` |
| Owner | `QA_VERIFIER` |
| Depends on | `TSK-P3-PRE-001`, `TSK-P3-PRE-002`, `TSK-P3-PRE-008` |
| Invariants | None |
| Regulated surface | No |

Work items (5):
1. `[ID tsk_p3_pre_009_w01]` Verify Phase 2 status is reconciled: `grep -c "FORMALLY UNOPENED"` returns 0 for Phase 2 in capability matrix.
2. `[ID tsk_p3_pre_009_w02]` Verify task infrastructure is functional: generate a test Phase 3 task pack using `generate_task_pack.py --phase3` and confirm it passes `verify_task_meta_schema.sh`.
3. `[ID tsk_p3_pre_009_w03]` Verify nomenclature is formalized: `docs/operations/TASK_ID_NOMENCLATURE.md` exists and contains Phase 3 group registry.
4. `[ID tsk_p3_pre_009_w04]` Verify registry is populated: `docs/PHASE3/phase3_task_registry.yml` exists, is valid YAML, and `task_count` matches actual entry count.
5. `[ID tsk_p3_pre_009_w05]` Run full `pre_ci.sh` to confirm no regressions.

Acceptance criteria:
- All 4 prerequisite checks pass.
- Test task pack generation succeeds end-to-end.
- `pre_ci.sh` exits 0.

Negative test:
- `TSK-P3-PRE-009-N1`: Temporarily corrupt the registry YAML — exit gate must fail.

Evidence: `evidence/phase3/tsk_p3_pre_009_readiness_gate.json`

---

## Verification Plan

### Automated Tests

Each task produces its own evidence artifact. The exit gate (TSK-P3-PRE-009) validates all prerequisites in aggregate.

```bash
# Per-task verification (run after each task)
PRE_CI_CONTEXT=1 bash scripts/audit/verify_task_meta_schema.sh --mode strict tasks/<TASK_ID>/meta.yml

# Exit gate (run after all tasks)
bash scripts/audit/verify_tsk_p3_pre_009.sh > evidence/phase3/tsk_p3_pre_009_readiness_gate.json

# Full parity check
RUN_PHASE3_GATES=1 bash scripts/dev/pre_ci.sh
```

### Manual Verification

- Human review of `TASK_ID_NOMENCLATURE.md` for completeness and accuracy of legacy suffix inventory.
- Human review of `phase3_task_registry.yml` for correct task classification.

---

## Execution Sequence

| Order | Task ID | Title | Parallel? |
|-------|---------|-------|-----------|
| 1a | TSK-P3-PRE-001 | Reconcile Phase 2 Status | Yes (with 1b, 1c) |
| 1b | TSK-P3-PRE-002 | Define CI Tier Model | Yes (with 1a, 1c) |
| 1c | TSK-P3-PRE-003 | Formalize Task ID Nomenclature | Yes (with 1a, 1b) |
| 2 | TSK-P3-PRE-004 | Adapt meta.yml Template | After 1c |
| 3 | TSK-P3-PRE-005 | Update Task Generator | After 2 |
| 4 | TSK-P3-PRE-006 | Update Schema Validator | After 3 |
| 5 | TSK-P3-PRE-007 | Define Registry Schema | After 4 |
| 6 | TSK-P3-PRE-008 | Populate Task Registry | After 1c + 5 |
| 7 | TSK-P3-PRE-009 | Exit Gate | After 1a + 1b + 6 |

**Estimated total: 9 atomic tasks, ~3-4 work sessions.**

---

## Unit Tests Required (per gravity-weighted-rules)

| Task | Unit Tests |
|------|-----------|
| TSK-P3-PRE-001 | grep-based Phase 2 status assertion |
| TSK-P3-PRE-002 | Invariant-to-tier coverage check (all INV-301-310 assigned) |
| TSK-P3-PRE-003 | Regex validation against known-good and known-bad task IDs |
| TSK-P3-PRE-004 | Template backward compatibility check via `verify_task_meta_schema.sh` |
| TSK-P3-PRE-005 | Generator Phase 3 mode — valid input succeeds, invalid input fails |
| TSK-P3-PRE-006 | Validator Phase 3 rules — valid task passes, invalid task reports violations |
| TSK-P3-PRE-007 | YAML parsability + schema completeness check |
| TSK-P3-PRE-008 | Registry `task_count` matches actual entry count; all IDs match nomenclature |
| TSK-P3-PRE-009 | Full exit gate — all prerequisites verified in single run |
