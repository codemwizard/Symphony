# Implementation Plan — Phase 2 Pre-Atomic Task Waves

Phase Key: PRE-PHASE2
Phase Name: Pre-Phase 2 Implementation
Source Plan: docs/plans/phase2/ATOMIC_TASK_BREAKDOWN_PLAN.md
DAG: docs/tasks/phase2_pre_atomic_dag.yml
Total Tasks: 68 atomic tasks across 9 waves

## User Review Required

**IMPORTANT**

Waves require strict sequential execution. A wave MUST NOT start until the previous wave's commit is accepted. `pre_ci.sh` runs once per wave, only after ALL tasks in that wave pass their own verification scripts. Committing tasks files only (no production code) per wave.

## WARNING

All 16 TSK-P2-REG-* tasks have empty stub directories (no meta.yml, PLAN.md, or EXEC_LOG.md). These must be scaffolded as a prerequisite step before Wave 8 begins. This is tracked in the pre-flight section below.

## CAUTION

Phantom task `tasks/TSK-P2-PREAUTH-006B-05` exists in the filesystem but is absent from the ATOMIC_TASK_BREAKDOWN_PLAN and the DAG. It must be deleted before Wave 1 starts to prevent drift contamination.

---

## Pre-Flight: One-Time Cleanup (Before Wave 1)

These are infrastructure fixes that must be applied and committed before any wave begins.

| Action | Target | Reason |
|--------|--------|--------|
| DELETE directory | tasks/TSK-P2-PREAUTH-006B-05/ | Phantom task — not in plan or DAG |
| FIX YAML syntax | docs/tasks/phase2_pre_atomic_dag.yml line 11 | Unescaped colon in title caused YAML parse failure ✅ Already fixed |

**Commit:** chore(pre-flight): remove phantom task + fix DAG YAML syntax

---

## Wave Structure Overview

**NOTE**

Stages 0-PRE and 0-PARALLEL cannot be literally merged into one wave because 0-PARALLEL tasks depend on CCG-001-01 (which itself depends on 0-SEC tasks). The most logical merge is: 0-PRE + 0-SEC + 0-CCG → Wave 1, then 0-PARALLEL → Wave 2.

| Wave | Stages Covered | Task Count | Has pre_ci? | Commit Trigger |
|------|----------------|------------|------------|----------------|
| 0 | Pre-flight cleanup | — | No | After cleanup |
| 1 | Stage 0-PRE + Stage 0-SEC + Stage 0-CCG | 11 tasks | ✅ Yes | After all 11 pass |
| 2 | Stage 0-PARALLEL | 6 tasks | ✅ Yes | After all 6 pass |
| 3 | Stage 1 — Execution Truth Anchor | 3 tasks | ✅ Yes | After all 3 pass |
| 4 | Stage 2 — Authority Binding | 3 tasks | ✅ Yes | After all 3 pass |
| 5 | Stage 3 — State Machine + Triggers | 9 tasks | ✅ Yes | After all 9 pass |
| 6 | Stage 4 — Data Authority Cross-Layer | 14 tasks | ✅ Yes | After all 14 pass |
| 7 | Stage 5 — Invariant Registration + CI | 6 tasks | ✅ Yes | After all 6 pass |
| 8 | Stage 6 — Regulatory Extensions | 16 tasks | ✅ Yes | After all 16 pass |

---

## Wave 1 — Foundations Gate (Stage 0-PRE + Stage 0-SEC + Stage 0-CCG)

**Rationale:** PREAUTH-000 (docs-only ADR) has no dependencies and can run immediately. All four SEC tasks are independent of each other (fully parallel). CCG gates them all. These 11 tasks form the true "ground zero" gate that unblocks everything downstream.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-000 | DOCS_ONLY | Architect | grep-only (no verifier script) | — |
| TSK-P2-SEC-001-00 | PLAN creation | Security Guardian | plan semantic alignment | — |
| TSK-P2-SEC-001-01 | Verifier + INV-130 | Security Guardian | verify_tsk_p2_sec_001_01.sh | SEC-001-00 |
| TSK-P2-SEC-002-00 | PLAN creation | Security Guardian | plan semantic alignment | — |
| TSK-P2-SEC-002-01 | Live test + INV-131 | Security Guardian | verify_tsk_p2_sec_002_01.sh | SEC-002-00 |
| TSK-P2-SEC-003-00 | PLAN creation | Security Guardian | plan semantic alignment | — |
| TSK-P2-SEC-003-01 | Fail-closed + INV-132 | Security Guardian | verify_tsk_p2_sec_003_01.sh | SEC-003-00 |
| TSK-P2-SEC-004-00 | PLAN creation | Security Guardian | plan semantic alignment | — |
| TSK-P2-SEC-004-01 | Default-deny + INV-133 | Security Guardian | verify_tsk_p2_sec_004_01.sh | SEC-004-00 |
| TSK-P2-CCG-001-00 | PLAN creation | DB Foundation | plan semantic alignment | All SEC-*-01 |
| TSK-P2-CCG-001-01 | Gate + INV-159/160/161/166 | DB Foundation | verify_tsk_p2_ccg_001_01.sh | CCG-001-00 |

### Execution Order

```
PREAUTH-000        ─────────────────────────────────────────────────┐
SEC-001-00 → SEC-001-01 ─┐                                          │
SEC-002-00 → SEC-002-01 ─┤                                          │
SEC-003-00 → SEC-003-01 ─┤→ CCG-001-00 → CCG-001-01 ────────[checkpoint/CCG]
SEC-004-00 → SEC-004-01 ─┘
```

### Wave 1 Verification Order

1. Run each task's own verification script (no pre_ci yet)
2. After all 11 tasks pass their own scripts → run `bash scripts/dev/pre_ci.sh`
3. Confirm checkpoint/CCG passes

### Commit Message (Wave 1)

```
feat(pre-phase2/wave-1): foundations gate — ADR, security invariant promotions INV-130/131/132/133, core contract gate INV-159/160/161/166

Tasks completed: TSK-P2-PREAUTH-000, TSK-P2-SEC-001-00/01, TSK-P2-SEC-002-00/01,
TSK-P2-SEC-003-00/01, TSK-P2-SEC-004-00/01, TSK-P2-CCG-001-00/01
Checkpoint: CCG ✅
pre_ci: PASS ✅
```

---

## Wave 2 — Schema Parallel Track (Stage 0-PARALLEL)

**Rationale:** PREAUTH-001 and PREAUTH-002 are now unblocked by CCG-001-01. They run in parallel internally (001 and 002 chains are independent of each other) but each chain is internally sequential.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-001-00 | PLAN creation | DB Foundation | plan semantic alignment | CCG-001-01 |
| TSK-P2-PREAUTH-001-01 | Migration 0116 | DB Foundation | verify_tsk_p2_preauth_001_01.sh | 001-00 |
| TSK-P2-PREAUTH-001-02 | resolve_interpretation_pack() | DB Foundation | verify_tsk_p2_preauth_001_02.sh | 001-01 |
| TSK-P2-PREAUTH-002-00 | PLAN creation | DB Foundation | plan semantic alignment | CCG-001-01 |
| TSK-P2-PREAUTH-002-01 | Migration 0117 (factor_registry) | DB Foundation | verify_tsk_p2_preauth_002_01.sh | 002-00 |
| TSK-P2-PREAUTH-002-02 | Migration 0117 (unit_conversions) | DB Foundation | verify_tsk_p2_preauth_002_02.sh | 002-01 |

### Execution Order

```
PREAUTH-001-00 → PREAUTH-001-01 → PREAUTH-001-02
                                                  } → [both complete] → pre_ci.sh → commit
PREAUTH-002-00 → PREAUTH-002-01 → PREAUTH-002-02
```

### Wave 2 Verification Order

1. Run all 6 task verification scripts in sequence per chain
2. After both chains complete → run `bash scripts/dev/pre_ci.sh`
3. Confirm MIGRATION_HEAD = 0117

### Commit Message (Wave 2)

```
feat(pre-phase2/wave-2): schema parallel track — interpretation_packs (migration 0116), factor_registry + unit_conversions (migration 0117)

Tasks completed: TSK-P2-PREAUTH-001-00/01/02, TSK-P2-PREAUTH-002-00/01/02
MIGRATION_HEAD: 0117 ✅
pre_ci: PASS ✅
```

---

## Wave 3 — Execution Truth Anchor (Stage 1)

**Rationale:** Anchors all monitoring data to real execution events. Three sequential tasks building the execution_records table and FK.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-003-00 | PLAN creation | DB Foundation | plan semantic alignment | 001-02, 002-02 |
| TSK-P2-PREAUTH-003-01 | Migration 0118 (execution_records) | DB Foundation | verify_tsk_p2_preauth_003_01.sh | 003-00 |
| TSK-P2-PREAUTH-003-02 | Add interpretation_version_id FK | DB Foundation | verify_tsk_p2_preauth_003_02.sh | 003-01 |

### Wave 3 Verification Order

1. Run all 3 task verification scripts in order
2. After all pass → run `bash scripts/dev/pre_ci.sh`
3. Confirm MIGRATION_HEAD = 0118

### Commit Message (Wave 3)

```
feat(pre-phase2/wave-3): execution truth anchor — execution_records table (migration 0118) + interpretation_version_id FK

Tasks completed: TSK-P2-PREAUTH-003-00/01/02
MIGRATION_HEAD: 0118 ✅
pre_ci: PASS ✅
```

---

## Wave 4 — Authority Binding (Stage 2)

**Rationale:** Creates policy_decisions and state_rules tables that bind execution records to policy authority.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-004-00 | PLAN creation | DB Foundation | plan semantic alignment | 003-02 |
| TSK-P2-PREAUTH-004-01 | Migration 0119 (policy_decisions) | DB Foundation | verify_tsk_p2_preauth_004_01.sh | 004-00 |
| TSK-P2-PREAUTH-004-02 | Migration 0119 (state_rules) | DB Foundation | verify_tsk_p2_preauth_004_02.sh | 004-01 |

### Wave 4 Verification Order

1. Run all 3 task verification scripts in order
2. After all pass → run `bash scripts/dev/pre_ci.sh`
3. Confirm MIGRATION_HEAD = 0119

### Commit Message (Wave 4)

```
feat(pre-phase2/wave-4): authority binding — policy_decisions + state_rules tables (migration 0119)

Tasks completed: TSK-P2-PREAUTH-004-00/01/02
MIGRATION_HEAD: 0119 ✅
pre_ci: PASS ✅
```

---

## Wave 5 — State Machine + Trigger Layer (Stage 3) [HIGHEST RISK]

**Rationale:** 9 tasks, 6 of them implementing individual triggers. Each trigger must be implemented and verified atomically before the next one begins. HIGHEST RISK stage.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-005-00 | PLAN creation | DB Foundation | plan semantic alignment | 003-02, 004-02 |
| TSK-P2-PREAUTH-005-01 | Migration 0120 (state_transitions) | DB Foundation | verify_tsk_p2_preauth_005_01.sh | 005-00 |
| TSK-P2-PREAUTH-005-02 | Migration 0120 (state_current) | DB Foundation | verify_tsk_p2_preauth_005_02.sh | 005-01 |
| TSK-P2-PREAUTH-005-03 | enforce_transition_state_rules() | DB Foundation | verify_tsk_p2_preauth_005_03.sh | 005-02 |
| TSK-P2-PREAUTH-005-04 | enforce_transition_authority() | DB Foundation | verify_tsk_p2_preauth_005_04.sh | 005-03 |
| TSK-P2-PREAUTH-005-05 | enforce_transition_signature() | DB Foundation | verify_tsk_p2_preauth_005_05.sh | 005-04 |
| TSK-P2-PREAUTH-005-06 | enforce_execution_binding() | DB Foundation | verify_tsk_p2_preauth_005_06.sh | 005-05 |
| TSK-P2-PREAUTH-005-07 | deny_state_transitions_mutation() | DB Foundation | verify_tsk_p2_preauth_005_07.sh | 005-06 |
| TSK-P2-PREAUTH-005-08 | update_current_state() | DB Foundation | verify_tsk_p2_preauth_005_08.sh | 005-07 |

### Wave 5 Verification Order

1. Each trigger task runs its verification script immediately after implementation, strictly in sequence
2. No trigger task starts until the preceding trigger task passes its verifier
3. After all 9 pass → run `bash scripts/dev/pre_ci.sh`
4. Confirm MIGRATION_HEAD = 0120 and checkpoint STATE-MACHINE passes

### Commit Message (Wave 5)

```
feat(pre-phase2/wave-5): state machine + trigger layer — state_transitions + state_current tables + 6 enforcement triggers (migration 0120)

Tasks completed: TSK-P2-PREAUTH-005-00 through 005-08
Triggers implemented: enforce_transition_state_rules, enforce_transition_authority,
enforce_transition_signature, enforce_execution_binding, deny_state_transitions_mutation,
update_current_state
MIGRATION_HEAD: 0120 ✅
Checkpoint STATE-MACHINE: ✅
pre_ci: PASS ✅
```

---

## Wave 6 — Data Authority Cross-Layer Contract (Stage 4)

**Rationale:** 14 tasks covering the ENUM definition, column additions across three tables, derive/enforce triggers, and C# read model marking. Three internal sub-tracks (006A, 006B, 006C) that must execute in strict order.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-006A-00 | PLAN creation | DB Foundation | plan semantic alignment | 005-08 |
| TSK-P2-PREAUTH-006A-01 | Migration 0121 — data_authority_level ENUM | DB Foundation | verify_tsk_p2_preauth_006a_01.sh | 006A-00 |
| TSK-P2-PREAUTH-006A-02 | Add columns → monitoring_records | DB Foundation | verify_tsk_p2_preauth_006a_02.sh | 006A-01 |
| TSK-P2-PREAUTH-006A-03 | Add columns → asset_batches | DB Foundation | verify_tsk_p2_preauth_006a_03.sh | 006A-02 |
| TSK-P2-PREAUTH-006A-04 | Add columns → state_transitions | DB Foundation | verify_tsk_p2_preauth_006a_04.sh | 006A-03 |
| TSK-P2-PREAUTH-006B-00 | PLAN creation | DB Foundation | plan semantic alignment | 006A-04 |
| TSK-P2-PREAUTH-006B-01 | Migration 0122 — derive_data_authority() | DB Foundation | verify_tsk_p2_preauth_006b_01.sh | 006B-00 |
| TSK-P2-PREAUTH-006B-02 | Migration 0122 — enforce_data_authority_integrity() | DB Foundation | verify_tsk_p2_preauth_006b_02.sh | 006B-01 |
| TSK-P2-PREAUTH-006B-03 | Write verifier with trigger ordering check | DB Foundation | verify_tsk_p2_preauth_006b.sh | 006B-02 |
| TSK-P2-PREAUTH-006B-04 | Update MIGRATION_HEAD to 0122 | DB Foundation | verify_tsk_p2_preauth_006b_04.sh | 006B-03 |
| TSK-P2-PREAUTH-006C-00 | PLAN creation | DB Foundation | plan semantic alignment | 006B-04 |
| TSK-P2-PREAUTH-006C-01 | Add data_authority fields → Pwrm0001MonitoringReportHandler.cs | DB Foundation | verify_tsk_p2_preauth_006c_01.sh | 006C-00 |
| TSK-P2-PREAUTH-006C-02 | Add data_authority fields → SupervisoryRevealReadModelHandler.cs | DB Foundation | verify_tsk_p2_preauth_006c_02.sh | 006C-01 |
| TSK-P2-PREAUTH-006C-03 | Live API validation | DB Foundation | verify_tsk_p2_preauth_006c_03.sh | 006C-02 |

### Wave 6 Verification Order

1. Complete 006A chain (5 tasks) → each passes its verifier before next starts
2. Complete 006B chain (5 tasks) → verify trigger ordering (trg_01 before trg_02)
3. Complete 006C chain (4 tasks) → live API call must return data_authority="phase1_indicative_only" and audit_grade=false
4. After all 14 pass → run `bash scripts/dev/pre_ci.sh`
5. Confirm MIGRATION_HEAD = 0122 and checkpoint DATA-AUTH passes

### Commit Message (Wave 6)

```
feat(pre-phase2/wave-6): data authority cross-layer contract — data_authority_level ENUM + columns on 3 tables + derive/enforce triggers + C# read model marking (migrations 0121/0122)

Tasks completed: TSK-P2-PREAUTH-006A-00 through 006C-03
MIGRATION_HEAD: 0122 ✅
Checkpoint DATA-AUTH: ✅
pre_ci: PASS ✅
```

---

## Wave 7 — Invariant Registration + CI Wiring (Stage 5)

**Rationale:** Registers INV-175/176/177, promotes INV-165/167, and wires new verifier scripts into pre_ci.sh. This is the gate that enables Stage 6 regulatory work.

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-PREAUTH-007-00 | PLAN creation | Invariants Curator | plan semantic alignment | 001-02, 005-08, 006C-03 |
| TSK-P2-PREAUTH-007-01 | Runtime INV ID assignment | Invariants Curator | verify_tsk_p2_preauth_007_01.sh | 007-00 |
| TSK-P2-PREAUTH-007-02 | Register INV-175 (data_authority_enforced) | Invariants Curator | verify_tsk_p2_preauth_007_02.sh | 007-01 |
| TSK-P2-PREAUTH-007-03 | Register INV-176 (state_machine_enforced) | Invariants Curator | verify_tsk_p2_preauth_007_03.sh | 007-02 |
| TSK-P2-PREAUTH-007-04 | Register INV-177 (phase1_boundary_marked) | Invariants Curator | verify_tsk_p2_preauth_007_04.sh | 007-03 |
| TSK-P2-PREAUTH-007-05 | Promote INV-165/167 + wire pre_ci.sh | Invariants Curator | verify_tsk_p2_preauth_007_05.sh | 007-04 |

### Wave 7 Verification Order

1. Run all 6 task verification scripts in sequence
2. After all pass → run `bash scripts/dev/pre_ci.sh`
3. Confirm checkpoint INV-REG passes and all three new verifiers are wired

### Commit Message (Wave 7)

```
feat(pre-phase2/wave-7): invariant registration + CI wiring — INV-175/176/177 registered, INV-165/167 promoted, verifiers wired to pre_ci.sh

Tasks completed: TSK-P2-PREAUTH-007-00 through 007-05
Checkpoint INV-REG: ✅
pre_ci: PASS ✅
```

---

## Wave 8 — Regulatory Extensions (Stage 6) [INCLUDES SCAFFOLDING]

**Rationale:** 16 tasks across 4 task groups. REG-001, REG-002, and REG-004 run in parallel with each other. REG-003 (PostGIS spatial gate) depends on all three and is the terminal task.

### IMPORTANT

**Scaffolding Required First:** All 16 REG task directories are empty stubs. Before implementation begins, the following must be created for each task: meta.yml, PLAN.md, EXEC_LOG.md. This is a prerequisite scaffold step that will be done at the start of Wave 8.

### Scaffolding Action (Start of Wave 8)

Create for all 16 tasks:

```
tasks/TSK-P2-REG-{001,002,003,004}-{00..07}/meta.yml (where applicable per range)
docs/plans/phase2/TSK-P2-REG-{001,002,003,004}-{00..07}/PLAN.md
docs/plans/phase2/TSK-P2-REG-{001,002,003,004}-{00..07}/EXEC_LOG.md
```

### Tasks

| Task ID | Kind | Owner | Verification Script | Depends On |
|---------|------|-------|---------------------|------------|
| TSK-P2-REG-001-00 | PLAN creation | DB Foundation | plan semantic alignment | 007-05 |
| TSK-P2-REG-001-01 | Migration 0123 (statutory_levy_registry) | DB Foundation | verify_tsk_p2_reg_001_01.sh | REG-001-00 |
| TSK-P2-REG-001-02 | Append-only trigger + privileges | DB Foundation | verify_tsk_p2_reg_001_02.sh | REG-001-01 |
| TSK-P2-REG-002-00 | PLAN creation | DB Foundation | plan semantic alignment | 007-05 |
| TSK-P2-REG-002-01 | Migration 0124 (exchange_rate_audit_log) | DB Foundation | verify_tsk_p2_reg_002_01.sh | REG-002-00 |
| TSK-P2-REG-002-02 | Append-only trigger + privileges | DB Foundation | verify_tsk_p2_reg_002_02.sh | REG-002-01 |
| TSK-P2-REG-004-00 | PLAN creation | Invariants Curator | plan semantic alignment | 007-05 |
| TSK-P2-REG-004-01 | Verify check_reg26_separation() + promote INV-169 | Invariants Curator | verify_tsk_p2_reg_004_01.sh | REG-004-00 |
| TSK-P2-REG-003-00 | PLAN creation | DB Foundation | plan semantic alignment | 000, 007-05, REG-001-02, REG-002-02, REG-004-01 |
| TSK-P2-REG-003-01 | Migration 0125 — Install PostGIS | DB Foundation | verify_tsk_p2_reg_003_01.sh | REG-003-00 |
| TSK-P2-REG-003-02 | Migration 0125 — protected_areas table | DB Foundation | verify_tsk_p2_reg_003_02.sh | REG-003-01 |
| TSK-P2-REG-003-03 | Migration 0125 — project_boundaries table | DB Foundation | verify_tsk_p2_reg_003_03.sh | REG-003-02 |
| TSK-P2-REG-003-04 | Add taxonomy_aligned column to projects | DB Foundation | verify_tsk_p2_reg_003_04.sh | REG-003-03 |
| TSK-P2-REG-003-05 | enforce_dns_harm() trigger | DB Foundation | verify_tsk_p2_reg_003_05.sh | REG-003-04 |
| TSK-P2-REG-003-06 | enforce_k13_taxonomy_alignment() trigger | DB Foundation | verify_tsk_p2_reg_003_06.sh | REG-003-05 |
| TSK-P2-REG-003-07 | Register INV-178 + update MIGRATION_HEAD | Invariants Curator | verify_tsk_p2_reg_003_07.sh | REG-003-06 |

### Execution Order

```
REG-001-00 → REG-001-01 → REG-001-02 ─┐
REG-002-00 → REG-002-01 → REG-002-02 ─┤→ REG-003-00 → REG-003-01 → ... → REG-003-07 → [DONE]
REG-004-00 → REG-004-01 ──────────────┘
```

### Wave 8 Verification Order

1. Scaffold all 16 task meta/plan/log files
2. Run REG-001, REG-002, and REG-004 chains (can run simultaneously, each internally sequential)
3. Once all three feed chains complete → run REG-003 chain strictly sequentially
4. REG-003-04 (taxonomy_aligned column) MUST complete before REG-003-05 (K13 trigger) per the plan's critical ordering note
5. After all 16 pass → run `bash scripts/dev/pre_ci.sh`
6. Confirm MIGRATION_HEAD = 0125, K13 Kill Criterion is enforced, checkpoint PRE-PHASE2-COMPLETE passes

### Commit Message (Wave 8)

```
feat(pre-phase2/wave-8): regulatory extensions — statutory_levy_registry (0123), exchange_rate_audit_log (0124), PostGIS spatial gate + DNSH + K13 enforcement (0125), INV-169/178 registered

Tasks completed: TSK-P2-REG-001-00/01/02, TSK-P2-REG-002-00/01/02,
TSK-P2-REG-004-00/01, TSK-P2-REG-003-00 through 003-07
MIGRATION_HEAD: 0125 ✅
K13 Kill Criterion enforced ✅
Checkpoint PRE-PHASE2-COMPLETE: ✅
pre_ci: PASS ✅
```

---

## System Invariant Gate (Post Wave 7)

**CAUTION**

Per the ATOMIC_TASK_BREAKDOWN_PLAN system invariant: The system is NOT ALLOWED to produce authoritative outputs, issue credits, or claim compliance until TSK-P2-PREAUTH-007-05 is complete and pre_ci.sh passes. This is enforced at the end of Wave 7, not Wave 8.

---

## Full Wave Summary

| # | Wave Name | Tasks | Migration Range | Commit After |
|---|-----------|-------|-----------------|-------------|
| 0 | Pre-flight cleanup | — | — | Immediately |
| 1 | Foundations Gate | 11 | — | After pre_ci |
| 2 | Schema Parallel Track | 6 | 0116–0117 | After pre_ci |
| 3 | Execution Truth Anchor | 3 | 0118 | After pre_ci |
| 4 | Authority Binding | 3 | 0119 | After pre_ci |
| 5 | State Machine + Triggers | 9 | 0120 | After pre_ci |
| 6 | Data Authority Cross-Layer | 14 | 0121–0122 | After pre_ci |
| 7 | Invariant Registration + CI | 6 | — | After pre_ci |
| 8 | Regulatory Extensions | 16 | 0123–0125 | After pre_ci |
| **Total** | | **68** | **0116–0125** | |
