# Atomic Task Breakdown Plan for Pre-Phase 2 Implementation

**Created:** 2026-04-15
**Source:** Pre-Phase2-Tasks.md
**Purpose:** Break down 19 tasks into 52 atomic tasks following Symphony anti-hallucination and drift enforcement mechanisms

---

## Overview

This plan breaks down the 19 tasks in Pre-Phase2-Tasks.md into 52 atomic tasks (+173% increase), addressing all identified anti-drift and hallucination risks from the forensic review.

**Original task count:** 19
**Atomic task count:** 52
**Increase:** +33 tasks (+173%)

---

## Universal Fixes Applied to All Tasks

Every task includes:
- **Work Item 00**: PLAN.md creation and verification (before any code)
- **MIGRATION_HEAD** in touches for migration tasks
- **pre_ci.sh** in verification blocks
- **Exact SQL/grep patterns** in verifier work items
- **Runtime INV ID assignment** where applicable
- **Explicit temp file paths** for negative tests with cleanup

---

## Task Breakdown

### STAGE 0-PRE — BLOCKING ADR

#### 1. TSK-P2-PREAUTH-000 (No breakdown needed - DOCS_ONLY, already atomic)

**Status:** Atomic - No changes required
**Purpose:** Author and merge ADR for Spatial Capability Model
**Blocks:** TSK-P2-REG-003

---

### STAGE 0-PARALLEL — Independent Schema Tasks

#### 2. TSK-P2-PREAUTH-001 → Split into 3 tasks

**2a. TSK-P2-PREAUTH-001-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md at docs/plans/phase2/TSK-P2-PREAUTH-001/PLAN.md, run verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-001/PLAN.md --meta tasks/TSK-P2-PREAUTH-001/meta.yml
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-CCG-001

**2b. TSK-P2-PREAUTH-001-01: Create interpretation_packs table with temporal uniqueness**
- **Work:** Write migration 0116 creating interpretation_packs table with temporal uniqueness constraints, echo 0116 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_001_01.sh
- **Verification:** verify_tsk_p2_preauth_001_01.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_tables WHERE tablename='interpretation_packs'" | grep -q '1 row'
- **Depends on:** TSK-P2-PREAUTH-001-00

**2c. TSK-P2-PREAUTH-001-02: Implement resolve_interpretation_pack() function with exact signature**
- **Work:** Write function with exact signature: `FUNCTION resolve_interpretation_pack(p_project_id UUID, p_effective_at TIMESTAMPTZ) RETURNS UUID`, add interpretation_version_id FK to execution_records, write verify_tsk_p2_preauth_001_02.sh
- **Verification:** verify_tsk_p2_preauth_001_02.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='resolve_interpretation_pack' AND prorettype='uuid'::regtype" | grep -q '1 row'
- **Depends on:** TSK-P2-PREAUTH-001-01

#### 3. TSK-P2-PREAUTH-002 → Split into 3 tasks

**3a. TSK-P2-PREAUTH-002-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-CCG-001

**3b. TSK-P2-PREAUTH-002-01: Create factor_registry table**
- **Work:** Write migration 0117 (factor_registry only), echo 0117 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_002_01.sh
- **Verification:** verify_tsk_p2_preauth_002_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-002-00

**3c. TSK-P2-PREAUTH-002-02: Create unit_conversions table**
- **Work:** Write migration 0117 (unit_conversions in same migration), write verify_tsk_p2_preauth_002_02.sh
- **Verification:** verify_tsk_p2_preauth_002_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-002-01

---

### STAGE 0-SEC — Security Invariant Promotions

#### 4. TSK-P2-SEC-001 → Split into 2 tasks

**4a. TSK-P2-SEC-001-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** []

**4b. TSK-P2-SEC-001-01: Fix verifier scope and promote INV-130**
- **Work:** Audit verify_supervisor_bind_localhost.sh, add exact grep pattern `grep -E 'HTTPServer\s*\(\s*["\x27]127\.0\.0\.1["\x27]' supervisor_api/server.py`, run verifier, update INV-130 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_sec_001_01.sh
- **Verification:** verify_tsk_p2_sec_001_01.sh, pre_ci.sh
- **Negative test:** Create temp file /tmp/supervisor_bind_test_$$.py with trap "rm -f /tmp/supervisor_bind_test_$$.py" EXIT
- **Depends on:** TSK-P2-SEC-001-00
- **Blocks:** TSK-P2-CCG-001

#### 5. TSK-P2-SEC-002 → Split into 2 tasks

**5a. TSK-P2-SEC-002-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** []

**5b. TSK-P2-SEC-002-01: Run live service test and promote INV-131**
- **Work:** Run test_admin_endpoints_require_key.sh, update INV-131 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_sec_002_01.sh
- **Verification:** verify_tsk_p2_sec_002_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-SEC-002-00
- **Blocks:** TSK-P2-CCG-001

#### 6. TSK-P2-SEC-003 → Split into 2 tasks

**6a. TSK-P2-SEC-003-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** []

**6b. TSK-P2-SEC-003-01: Verify fail-closed behavior and promote INV-132**
- **Work:** Run scan_secrets.sh, run test_missing_signing_key_fails_closed.sh, update INV-132 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_sec_003_01.sh
- **Verification:** verify_tsk_p2_sec_003_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-SEC-003-00
- **Blocks:** TSK-P2-CCG-001

#### 7. TSK-P2-SEC-004 → Split into 2 tasks

**7a. TSK-P2-SEC-004-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** []

**7b. TSK-P2-SEC-004-01: Verify default-deny and promote INV-133**
- **Work:** Run test_tenant_allowlist_deny_all.sh, update INV-133 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_sec_004_01.sh
- **Verification:** verify_tsk_p2_sec_004_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-SEC-004-00
- **Blocks:** TSK-P2-CCG-001

---

### STAGE 0-CCG — Core Contract Gate

#### 8. TSK-P2-CCG-001 → Split into 2 tasks

**8a. TSK-P2-CCG-001-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** [TSK-P2-SEC-001-01, TSK-P2-SEC-002-01, TSK-P2-SEC-003-01, TSK-P2-SEC-004-01]

**8b. TSK-P2-CCG-001-01: Run gate and promote INV-159/160/161/166**
- **Work:** Run verify_core_contract_gate.sh with all sub-checks (neutrality, adapter-boundary, function-names, payload-neutrality), update INV-159, INV-160, INV-161, INV-166 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_ccg_001_01.sh
- **Verification:** verify_tsk_p2_ccg_001_01.sh, pre_ci.sh
- **Negative test:** Create temp file /tmp/symphony_ccg_test_$$.sql with trap "rm -f /tmp/symphony_ccg_test_$$.sql" EXIT
- **Depends on:** TSK-P2-CCG-001-00
- **Blocks:** [TSK-P2-PREAUTH-001-00, TSK-P2-PREAUTH-002-00]

---

### STAGE 1 — Execution Truth Anchor

#### 9. TSK-P2-PREAUTH-003 → Split into 3 tasks

**9a. TSK-P2-PREAUTH-003-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** [TSK-P2-PREAUTH-001-02, TSK-P2-PREAUTH-002-02]

**9b. TSK-P2-PREAUTH-003-01: Create execution_records table**
- **Work:** Write migration 0118 creating execution_records table, echo 0118 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_003_01.sh
- **Verification:** verify_tsk_p2_preauth_003_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-003-00

**9c. TSK-P2-PREAUTH-003-02: Add interpretation_version_id FK to execution_records**
- **Work:** ALTER TABLE execution_records ADD COLUMN interpretation_version_id UUID REFERENCES interpretation_packs(interpretation_pack_id), write verify_tsk_p2_preauth_003_02.sh
- **Verification:** verify_tsk_p2_preauth_003_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-003-01
- **Blocks:** TSK-P2-PREAUTH-004-00

---

### STAGE 2 — Authority Binding

#### 10. TSK-P2-PREAUTH-004 → Split into 3 tasks

**10a. TSK-P2-PREAUTH-004-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-003-02

**10b. TSK-P2-PREAUTH-004-01: Create policy_decisions table**
- **Work:** Write migration 0119 (policy_decisions only), echo 0119 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_004_01.sh
- **Verification:** verify_tsk_p2_preauth_004_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-004-00

**10c. TSK-P2-PREAUTH-004-02: Create state_rules table**
- **Work:** Write migration 0119 (state_rules in same migration), write verify_tsk_p2_preauth_004_02.sh
- **Verification:** verify_tsk_p2_preauth_004_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-004-01
- **Blocks:** TSK-P2-PREAUTH-005-00

---

### STAGE 3 — State Machine + Trigger Layer (HIGHEST RISK)

#### 11. TSK-P2-PREAUTH-005 → Split into 8 tasks (6 triggers split individually)

**11a. TSK-P2-PREAUTH-005-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** [TSK-P2-PREAUTH-003-02, TSK-P2-PREAUTH-004-02]

**11b. TSK-P2-PREAUTH-005-01: Create state_transitions table**
- **Work:** Write migration 0120 (state_transitions only), echo 0120 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_005_01.sh
- **Verification:** verify_tsk_p2_preauth_005_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-00

**11c. TSK-P2-PREAUTH-005-02: Create state_current table**
- **Work:** Write migration 0120 (state_current in same migration), write verify_tsk_p2_preauth_005_02.sh
- **Verification:** verify_tsk_p2_preauth_005_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-01

**11d. TSK-P2-PREAUTH-005-03: Implement enforce_transition_state_rules() trigger**
- **Work:** Write trigger function with exact signature: check state_rules table, raise GF032, attach as BEFORE INSERT OR UPDATE on state_transitions, write verify_tsk_p2_preauth_005_03.sh
- **Verification:** verify_tsk_p2_preauth_005_03.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_transition_state_rules'" | grep -q '1 row'
- **Depends on:** TSK-P2-PREAUTH-005-02

**11e. TSK-P2-PREAUTH-005-04: Implement enforce_transition_authority() trigger**
- **Work:** Write trigger function, attach as BEFORE INSERT OR UPDATE on state_transitions, write verify_tsk_p2_preauth_005_04.sh
- **Verification:** verify_tsk_p2_preauth_005_04.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-03

**11f. TSK-P2-PREAUTH-005-05: Implement enforce_transition_signature() trigger**
- **Work:** Write trigger function, attach as BEFORE INSERT OR UPDATE on state_transitions, write verify_tsk_p2_preauth_005_05.sh
- **Verification:** verify_tsk_p2_preauth_005_05.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-04

**11g. TSK-P2-PREAUTH-005-06: Implement enforce_execution_binding() trigger**
- **Work:** Write trigger function, attach as BEFORE INSERT OR UPDATE on state_transitions, write verify_tsk_p2_preauth_005_06.sh
- **Verification:** verify_tsk_p2_preauth_005_06.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-05

**11h. TSK-P2-PREAUTH-005-07: Implement deny_state_transitions_mutation() trigger**
- **Work:** Write trigger function, attach as BEFORE UPDATE OR DELETE on state_transitions, write verify_tsk_p2_preauth_005_07.sh
- **Verification:** verify_tsk_p2_preauth_005_07.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-06

**11i. TSK-P2-PREAUTH-005-08: Implement update_current_state() trigger**
- **Work:** Write trigger function, attach as AFTER INSERT OR UPDATE on state_transitions, write verify_tsk_p2_preauth_005_08.sh
- **Verification:** verify_tsk_p2_preauth_005_08.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-005-07
- **Blocks:** TSK-P2-PREAUTH-006A-00

---

### STAGE 4 — Data Authority Cross-Layer Contract

#### 12. TSK-P2-PREAUTH-006A → Split into 4 tasks

**12a. TSK-P2-PREAUTH-006A-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-005-08

**12b. TSK-P2-PREAUTH-006A-01: Create data_authority_level ENUM type**
- **Work:** Write migration 0121 (ENUM only): CREATE TYPE public.data_authority_level AS ENUM ('phase1_indicative_only', 'non_reproducible', 'derived_unverified', 'policy_bound_unsigned', 'authoritative_signed', 'superseded', 'invalidated'), write verify_tsk_p2_preauth_006a_01.sh
- **Verification:** verify_tsk_p2_preauth_006a_01.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT enumlabel FROM pg_enum WHERE enumtypid='data_authority_level'::regtype" | grep -c 'phase1_indicative_only'
- **Depends on:** TSK-P2-PREAUTH-006A-00

**12c. TSK-P2-PREAUTH-006A-02: Add data_authority columns to monitoring_records**
- **Work:** ALTER TABLE monitoring_records ADD COLUMN data_authority public.data_authority_level NOT NULL DEFAULT 'phase1_indicative_only', ADD COLUMN audit_grade BOOLEAN NOT NULL DEFAULT false, ADD COLUMN authority_explanation TEXT NOT NULL DEFAULT 'Phase 1 data - no execution binding', UPDATE monitoring_records SET data_authority='phase1_indicative_only' WHERE data_authority IS DISTINCT FROM 'phase1_indicative_only', write verify_tsk_p2_preauth_006a_02.sh
- **Verification:** verify_tsk_p2_preauth_006a_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006A-01

**12d. TSK-P2-PREAUTH-006A-03: Add data_authority columns to asset_batches**
- **Work:** Same as 12c for asset_batches table, write verify_tsk_p2_preauth_006a_03.sh
- **Verification:** verify_tsk_p2_preauth_006a_03.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006A-02

**12e. TSK-P2-PREAUTH-006A-04: Add data_authority columns to state_transitions**
- **Work:** Same as 12c for state_transitions table with default 'non_reproducible', echo 0121 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_006a_04.sh
- **Verification:** verify_tsk_p2_preauth_006a_04.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006A-03
- **Blocks:** TSK-P2-PREAUTH-006B-00

#### 13. TSK-P2-PREAUTH-006B → Split into 4 tasks

**13a. TSK-P2-PREAUTH-006B-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-006A-04

**13b. TSK-P2-PREAUTH-006B-01: Implement derive_data_authority() trigger**
- **Work:** Write migration 0122 (derive function only) with exact logic: IF NEW.execution_id IS NULL THEN NEW.data_authority := 'non_reproducible'; NEW.audit_grade := false; ELSIF NEW.execution_id IS NOT NULL AND NEW.policy_decision_id IS NULL THEN NEW.data_authority := 'derived_unverified'; NEW.audit_grade := false; ELSIF NEW.policy_decision_id IS NOT NULL AND NEW.signature IS NULL THEN NEW.data_authority := 'policy_bound_unsigned'; NEW.audit_grade := false; ELSE NEW.data_authority := 'authoritative_signed'; NEW.audit_grade := true; END IF; RETURN NEW. Attach as BEFORE INSERT trigger named trg_01_derive_data_authority on state_transitions, write verify_tsk_p2_preauth_006b_01.sh
- **Verification:** verify_tsk_p2_preauth_006b_01.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='derive_data_authority' AND prosecdef=true" | grep -q '1 row'
- **Depends on:** TSK-P2-PREAUTH-006B-00

**13c. TSK-P2-PREAUTH-006B-02: Implement enforce_data_authority_integrity() trigger**
- **Work:** Write migration 0122 (enforce function) with exact logic: Allow phase1_indicative_only and non_reproducible unconditionally. Raise GF040 if execution_id IS NULL and data_authority NOT IN ('phase1_indicative_only','non_reproducible'). Raise GF041 if data_authority IN ('policy_bound_unsigned','authoritative_signed') AND policy_decision_id IS NULL. Raise GF042 if data_authority = 'authoritative_signed' AND signature IS NULL. RETURN NEW. Attach as BEFORE INSERT trigger named trg_02_enforce_data_authority on state_transitions, write verify_tsk_p2_preauth_006b_02.sh
- **Verification:** verify_tsk_p2_preauth_006b_02.sh, pre_ci.sh
- **Trigger ordering check:** psql -c "SELECT tgname FROM pg_trigger WHERE tgrelid='state_transitions'::regclass ORDER BY tgname" | grep -B1 'trg_02'
- **Depends on:** TSK-P2-PREAUTH-006B-01

**13d. TSK-P2-PREAUTH-006B-03: Write verifier with exact SQL patterns**
- **Work:** Write verify_tsk_p2_preauth_006b.sh with exact psql queries for pg_proc, pg_trigger, trigger ordering verification
- **Verification:** verify_tsk_p2_preauth_006b.sh, pre_ci.sh
- **Exact verifier spec:**
  ```bash
  psql -c "SELECT 1 FROM pg_proc WHERE proname='derive_data_authority' AND prosecdef=true" | grep -q '1 row'
  psql -c "SELECT tgname FROM pg_trigger WHERE tgrelid='state_transitions'::regclass ORDER BY tgname" > /tmp/trigger_order_$$.txt
  grep -q 'trg_01_derive_data_authority' /tmp/trigger_order_$$.txt && grep -A1 'trg_01' /tmp/trigger_order_$$.txt | grep -q 'trg_02_enforce_data_authority'
  rm -f /tmp/trigger_order_$$.txt
  ```
- **Depends on:** TSK-P2-PREAUTH-006B-02

**13e. TSK-P2-PREAUTH-006B-04: Update MIGRATION_HEAD**
- **Work:** echo 0122 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_preauth_006b_04.sh
- **Verification:** verify_tsk_p2_preauth_006b_04.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006B-03
- **Blocks:** TSK-P2-PREAUTH-006C-00

#### 14. TSK-P2-PREAUTH-006C → Split into 3 tasks

**14a. TSK-P2-PREAUTH-006C-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-006B-04

**14b. TSK-P2-PREAUTH-006C-01: Add data_authority fields to Pwrm0001MonitoringReportHandler.cs**
- **Work:** Add to top-level report output object: DataAuthority = "phase1_indicative_only", AuditGrade = false, AuthorityExplanation = "Phase 1 data — no execution_id or policy_decision_id binding", ExecutionId = (string?)null, PolicyDecisionId = (string?)null. In zgft_waste_sector_alignment block, add DataAuthority = "phase1_indicative_only" and AuditGrade = false. Write verify_tsk_p2_preauth_006c_01.sh
- **Verification:** verify_tsk_p2_preauth_006c_01.sh, pre_ci.sh
- **Exact verifier spec:** grep -c 'DataAuthority = "phase1_indicative_only"' services/ledger-api/dotnet/src/LedgerApi/ReadModels/Pwrm0001MonitoringReportHandler.cs
- **Depends on:** TSK-P2-PREAUTH-006C-00

**14c. TSK-P2-PREAUTH-006C-02: Add data_authority fields to SupervisoryRevealReadModelHandler.cs**
- **Work:** Add to top-level payload output object: DataAuthority = "non_reproducible", AuditGrade = false, AuthorityExplanation = "Phase 1 supervisory data — execution context not recorded". In each item in proof_rows, add ExecutionId = (string?)null, PolicyDecisionId = (string?)null. Write verify_tsk_p2_preauth_006c_02.sh
- **Verification:** verify_tsk_p2_preauth_006c_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006C-01

**14d. TSK-P2-PREAUTH-006C-03: Live API validation**
- **Work:** Make live API call to monitoring report endpoint, verify response JSON contains data_authority = "phase1_indicative_only" and audit_grade = false, write verify_tsk_p2_preauth_006c_03.sh
- **Verification:** verify_tsk_p2_preauth_006c_03.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-006C-02
- **Blocks:** TSK-P2-PREAUTH-007-00

---

### STAGE 5 — Invariant Registration + CI Wiring

#### 15. TSK-P2-PREAUTH-007 → Split into 5 tasks

**15a. TSK-P2-PREAUTH-007-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** [TSK-P2-PREAUTH-001-02, TSK-P2-PREAUTH-005-08, TSK-P2-PREAUTH-006C-03]

**15b. TSK-P2-PREAUTH-007-01: Runtime INV ID assignment**
- **Work:** Determine next INV IDs at runtime: `NEXT_ID=$(grep "^- id: INV-" docs/invariants/INVARIANTS_MANIFEST.yml | grep -oP '\d+' | sort -n | tail -1)`, write verify_tsk_p2_preauth_007_01.sh
- **Verification:** verify_tsk_p2_preauth_007_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-007-00

**15c. TSK-P2-PREAUTH-007-02: Register INV-175 (data_authority_enforced)**
- **Work:** Add INV-175 to INVARIANTS_MANIFEST.yml with id: INV-175, title: 'data_authority is schema-enforced via ENUM and triggers', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_preauth_006a.sh, write verify_tsk_p2_preauth_007_02.sh
- **Verification:** verify_tsk_p2_preauth_007_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-007-01

**15d. TSK-P2-PREAUTH-007-03: Register INV-176 (state_machine_enforced)**
- **Work:** Add INV-176 to INVARIANTS_MANIFEST.yml with id: INV-176, title: 'state_transitions is enforced via trigger layer', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_preauth_005_08.sh, write verify_tsk_p2_preauth_007_03.sh
- **Verification:** verify_tsk_p2_preauth_007_03.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-007-02

**15e. TSK-P2-PREAUTH-007-04: Register INV-177 (phase1_boundary_marked)**
- **Work:** Add INV-177 to INVARIANTS_MANIFEST.yml with id: INV-177, title: 'Phase 1 C# outputs carry non-authoritative markers', status: implemented, severity: P0, enforcement: scripts/audit/verify_tsk_p2_preauth_006c.sh, write verify_tsk_p2_preauth_007_04.sh
- **Verification:** verify_tsk_p2_preauth_007_04.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-007-03

**15f. TSK-P2-PREAUTH-007-05: Promote INV-165/167 and wire pre_ci.sh**
- **Work:** Update INV-165 and INV-167 status to implemented in INVARIANTS_MANIFEST.yml, verify pre_ci.sh includes verify_tsk_p2_preauth_006a.sh, verify_tsk_p2_preauth_005_08.sh, verify_tsk_p2_preauth_006c.sh, write verify_tsk_p2_preauth_007_05.sh
- **Verification:** verify_tsk_p2_preauth_007_05.sh, pre_ci.sh
- **Depends on:** TSK-P2-PREAUTH-007-04
- **Blocks:** [TSK-P2-REG-001-00, TSK-P2-REG-002-00, TSK-P2-REG-004-00]

---

### STAGE 6 — Regulatory Extensions

#### 16. TSK-P2-REG-001 → Split into 3 tasks

**16a. TSK-P2-REG-001-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-007-05

**16b. TSK-P2-REG-001-01: Create statutory_levy_registry table**
- **Work:** Write migration 0123 creating statutory_levy_registry table with UNIQUE constraint on (levy_code, jurisdiction_code, effective_from), echo 0123 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_reg_001_01.sh
- **Verification:** verify_tsk_p2_reg_001_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-REG-001-00

**16c. TSK-P2-REG-001-02: Add append-only trigger and privileges**
- **Work:** Add append-only trigger (UPDATE/DELETE raises GF050), revoke-first privileges (SELECT to symphony_command, ALL to symphony_control), write verify_tsk_p2_reg_001_02.sh
- **Verification:** verify_tsk_p2_reg_001_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-REG-001-01

#### 17. TSK-P2-REG-002 → Split into 3 tasks

**17a. TSK-P2-REG-002-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-007-05

**17b. TSK-P2-REG-002-01: Create exchange_rate_audit_log table**
- **Work:** Write migration 0124 creating exchange_rate_audit_log table with rate_value as NUMERIC(18,8), echo 0124 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_reg_002_01.sh
- **Verification:** verify_tsk_p2_reg_002_01.sh, pre_ci.sh
- **Depends on:** TSK-P2-REG-002-00

**17c. TSK-P2-REG-002-02: Add append-only trigger and privileges**
- **Work:** Add append-only trigger (UPDATE/DELETE raises GF051), revoke-first privileges (SELECT to symphony_command, ALL to symphony_control), write verify_tsk_p2_reg_002_02.sh
- **Verification:** verify_tsk_p2_reg_002_02.sh, pre_ci.sh
- **Depends on:** TSK-P2-REG-002-01

#### 18. TSK-P2-REG-004 → Split into 2 tasks

**18a. TSK-P2-REG-004-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** TSK-P2-PREAUTH-007-05

**18b. TSK-P2-REG-004-01: Verify function exists and promote INV-169**
- **Work:** Query pg_proc for check_reg26_separation() with exact psql query, run verify_gf_sch_008.sh, update INV-169 in INVARIANTS_MANIFEST.yml, write verify_tsk_p2_reg_004_01.sh
- **Verification:** verify_tsk_p2_reg_004_01.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='check_reg26_separation'" | grep -q '1 row'
- **Depends on:** TSK-P2-REG-004-00

#### 19. TSK-P2-REG-003 → Split into 7 tasks (HIGHEST RISK - complex multi-operation)

**19a. TSK-P2-REG-003-00: Create PLAN.md and verify alignment**
- **Work:** Create PLAN.md from PLAN_TEMPLATE.md, run verify_plan_semantic_alignment.py
- **Verification:** verify_plan_semantic_alignment.py exits 0
- **Depends on:** [TSK-P2-PREAUTH-000, TSK-P2-PREAUTH-007-05, TSK-P2-REG-001-02, TSK-P2-REG-002-02, TSK-P2-REG-004-01]

**19b. TSK-P2-REG-003-01: Install PostGIS extension**
- **Work:** Write migration 0125 with CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public, verify SELECT PostGIS_version() returns non-null, write verify_tsk_p2_reg_003_01.sh
- **Verification:** verify_tsk_p2_reg_003_01.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT PostGIS_version()" | grep -v '(0 rows)'
- **Depends on:** TSK-P2-REG-003-00

**19c. TSK-P2-REG-003-02: Create protected_areas table**
- **Work:** Write migration 0125 (protected_areas only) with geom geometry(POLYGON, 4326) NOT NULL, source_version_id UUID NOT NULL REFERENCES factor_registry(factor_id), append-only trigger (raises GF055), GIST index on geom, revoke-first privileges, write verify_tsk_p2_reg_003_02.sh
- **Verification:** verify_tsk_p2_reg_003_02.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT attname, typname FROM pg_attribute JOIN pg_type ON pg_attribute.atttypid=pg_type.oid WHERE attrelid='protected_areas'::regclass AND attname='geom'" | grep -q 'geometry'
- **Depends on:** TSK-P2-REG-003-01

**19d. TSK-P2-REG-003-03: Create project_boundaries table**
- **Work:** Write migration 0125 (project_boundaries) with geom geometry(POLYGON, 4326) NOT NULL, dns_check_version_id UUID NOT NULL REFERENCES protected_areas(area_id), spatial_check_execution_id UUID NOT NULL REFERENCES execution_records(execution_id), GIST index on geom, append-only trigger (raises GF056), revoke-first privileges, write verify_tsk_p2_reg_003_03.sh
- **Verification:** verify_tsk_p2_reg_003_03.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT attname FROM pg_attribute WHERE attrelid='project_boundaries'::regclass AND attname IN ('dns_check_version_id', 'spatial_check_execution_id')" | grep -c '2'
- **Depends on:** TSK-P2-REG-003-02

**19e. TSK-P2-REG-003-04: Add taxonomy_aligned column to projects (explicit separate step)**
- **Work:** ALTER TABLE IF NOT EXISTS public.projects ADD COLUMN IF NOT EXISTS taxonomy_aligned BOOLEAN NOT NULL DEFAULT false (MUST be BEFORE K13 trigger in migration order), write verify_tsk_p2_reg_003_04.sh
- **Verification:** verify_tsk_p2_reg_003_04.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT attname FROM pg_attribute WHERE attrelid='projects'::regclass AND attname='taxonomy_aligned'" | grep -q 'taxonomy_aligned'
- **Depends on:** TSK-P2-REG-003-03
- **Critical ordering:** This must complete before work_item_05

**19f. TSK-P2-REG-003-05: Implement enforce_dns_harm() trigger**
- **Work:** Write enforce_dns_harm() as SECURITY DEFINER PL/pgSQL with hardened search_path: IF EXISTS (SELECT 1 FROM public.protected_areas pa WHERE ST_Intersects(NEW.geom, pa.geom) AND pa.effective_to IS NULL) THEN RAISE EXCEPTION 'DNSH violation: project boundary overlaps protected area' USING ERRCODE = 'GF057'; END IF; RETURN NEW. Attach as BEFORE INSERT OR UPDATE trigger on project_boundaries, write verify_tsk_p2_reg_003_05.sh
- **Verification:** verify_tsk_p2_reg_003_05.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_dns_harm' AND prosecdef=true" | grep -q '1 row'
- **Depends on:** TSK-P2-REG-003-04

**19g. TSK-P2-REG-003-06: Implement enforce_k13_taxonomy_alignment() trigger**
- **Work:** Write enforce_k13_taxonomy_alignment() as SECURITY DEFINER PL/pgSQL: IF NEW.taxonomy_aligned = true AND (SELECT spatial_check_execution_id FROM public.project_boundaries WHERE project_id = NEW.project_id LIMIT 1) IS NULL THEN RAISE EXCEPTION 'K13: taxonomy_aligned requires spatial_check_execution_id' USING ERRCODE = 'GF060'; END IF; RETURN NEW. Attach as BEFORE INSERT OR UPDATE trigger on projects table, write verify_tsk_p2_reg_003_06.sh
- **Verification:** verify_tsk_p2_reg_003_06.sh, pre_ci.sh
- **Exact verifier spec:** psql -c "SELECT 1 FROM pg_proc WHERE proname='enforce_k13_taxonomy_alignment' AND prosecdef=true" | grep -q '1 row'
- **Depends on:** TSK-P2-REG-003-05

**19h. TSK-P2-REG-003-07: Register INV-178 and update MIGRATION_HEAD**
- **Work:** Add INV-178 to INVARIANTS_MANIFEST.yml with id: INV-178, title: 'Project DNSH spatial check is DB-enforced via PostGIS with versioned dataset and execution binding', status: implemented, severity: P0, enforcement: scripts/db/verify_tsk_p2_reg_003.sh, echo 0125 > schema/migrations/MIGRATION_HEAD, write verify_tsk_p2_reg_003_07.sh
- **Verification:** verify_tsk_p2_reg_003_07.sh, pre_ci.sh
- **Depends on:** TSK-P2-REG-003-06

---

## DAG File

```yaml
# Task DAG for Pre-Phase 2 Atomic Task Breakdown
# Format: task_id: [dependencies]

# STAGE 0-PRE
TSK-P2-PREAUTH-000: []

# STAGE 0-PARALLEL
TSK-P2-PREAUTH-001-00: [TSK-P2-CCG-001-01]
TSK-P2-PREAUTH-001-01: [TSK-P2-PREAUTH-001-00]
TSK-P2-PREAUTH-001-02: [TSK-P2-PREAUTH-001-01]

TSK-P2-PREAUTH-002-00: [TSK-P2-CCG-001-01]
TSK-P2-PREAUTH-002-01: [TSK-P2-PREAUTH-002-00]
TSK-P2-PREAUTH-002-02: [TSK-P2-PREAUTH-002-01]

# STAGE 0-SEC
TSK-P2-SEC-001-00: []
TSK-P2-SEC-001-01: [TSK-P2-SEC-001-00]

TSK-P2-SEC-002-00: []
TSK-P2-SEC-002-01: [TSK-P2-SEC-002-00]

TSK-P2-SEC-003-00: []
TSK-P2-SEC-003-01: [TSK-P2-SEC-003-00]

TSK-P2-SEC-004-00: []
TSK-P2-SEC-004-01: [TSK-P2-SEC-004-00]

# STAGE 0-CCG
TSK-P2-CCG-001-00: [TSK-P2-SEC-001-01, TSK-P2-SEC-002-01, TSK-P2-SEC-003-01, TSK-P2-SEC-004-01]
TSK-P2-CCG-001-01: [TSK-P2-CCG-001-00]

# STAGE 1
TSK-P2-PREAUTH-003-00: [TSK-P2-PREAUTH-001-02, TSK-P2-PREAUTH-002-02]
TSK-P2-PREAUTH-003-01: [TSK-P2-PREAUTH-003-00]
TSK-P2-PREAUTH-003-02: [TSK-P2-PREAUTH-003-01]

# STAGE 2
TSK-P2-PREAUTH-004-00: [TSK-P2-PREAUTH-003-02]
TSK-P2-PREAUTH-004-01: [TSK-P2-PREAUTH-004-00]
TSK-P2-PREAUTH-004-02: [TSK-P2-PREAUTH-004-01]

# STAGE 3
TSK-P2-PREAUTH-005-00: [TSK-P2-PREAUTH-003-02, TSK-P2-PREAUTH-004-02]
TSK-P2-PREAUTH-005-01: [TSK-P2-PREAUTH-005-00]
TSK-P2-PREAUTH-005-02: [TSK-P2-PREAUTH-005-01]
TSK-P2-PREAUTH-005-03: [TSK-P2-PREAUTH-005-02]
TSK-P2-PREAUTH-005-04: [TSK-P2-PREAUTH-005-03]
TSK-P2-PREAUTH-005-05: [TSK-P2-PREAUTH-005-04]
TSK-P2-PREAUTH-005-06: [TSK-P2-PREAUTH-005-05]
TSK-P2-PREAUTH-005-07: [TSK-P2-PREAUTH-005-06]
TSK-P2-PREAUTH-005-08: [TSK-P2-PREAUTH-005-07]

# STAGE 4
TSK-P2-PREAUTH-006A-00: [TSK-P2-PREAUTH-005-08]
TSK-P2-PREAUTH-006A-01: [TSK-P2-PREAUTH-006A-00]
TSK-P2-PREAUTH-006A-02: [TSK-P2-PREAUTH-006A-01]
TSK-P2-PREAUTH-006A-03: [TSK-P2-PREAUTH-006A-02]
TSK-P2-PREAUTH-006A-04: [TSK-P2-PREAUTH-006A-03]

TSK-P2-PREAUTH-006B-00: [TSK-P2-PREAUTH-006A-04]
TSK-P2-PREAUTH-006B-01: [TSK-P2-PREAUTH-006B-00]
TSK-P2-PREAUTH-006B-02: [TSK-P2-PREAUTH-006B-01]
TSK-P2-PREAUTH-006B-03: [TSK-P2-PREAUTH-006B-02]
TSK-P2-PREAUTH-006B-04: [TSK-P2-PREAUTH-006B-03]

TSK-P2-PREAUTH-006C-00: [TSK-P2-PREAUTH-006B-04]
TSK-P2-PREAUTH-006C-01: [TSK-P2-PREAUTH-006C-00]
TSK-P2-PREAUTH-006C-02: [TSK-P2-PREAUTH-006C-01]
TSK-P2-PREAUTH-006C-03: [TSK-P2-PREAUTH-006C-02]

# STAGE 5
TSK-P2-PREAUTH-007-00: [TSK-P2-PREAUTH-001-02, TSK-P2-PREAUTH-005-08, TSK-P2-PREAUTH-006C-03]
TSK-P2-PREAUTH-007-01: [TSK-P2-PREAUTH-007-00]
TSK-P2-PREAUTH-007-02: [TSK-P2-PREAUTH-007-01]
TSK-P2-PREAUTH-007-03: [TSK-P2-PREAUTH-007-02]
TSK-P2-PREAUTH-007-04: [TSK-P2-PREAUTH-007-03]
TSK-P2-PREAUTH-007-05: [TSK-P2-PREAUTH-007-04]

# STAGE 6
TSK-P2-REG-001-00: [TSK-P2-PREAUTH-007-05]
TSK-P2-REG-001-01: [TSK-P2-REG-001-00]
TSK-P2-REG-001-02: [TSK-P2-REG-001-01]

TSK-P2-REG-002-00: [TSK-P2-PREAUTH-007-05]
TSK-P2-REG-002-01: [TSK-P2-REG-002-00]
TSK-P2-REG-002-02: [TSK-P2-REG-002-01]

TSK-P2-REG-004-00: [TSK-P2-PREAUTH-007-05]
TSK-P2-REG-004-01: [TSK-P2-REG-004-00]

TSK-P2-REG-003-00: [TSK-P2-PREAUTH-000, TSK-P2-PREAUTH-007-05, TSK-P2-REG-001-02, TSK-P2-REG-002-02, TSK-P2-REG-004-01]
TSK-P2-REG-003-01: [TSK-P2-REG-003-00]
TSK-P2-REG-003-02: [TSK-P2-REG-003-01]
TSK-P2-REG-003-03: [TSK-P2-REG-003-02]
TSK-P2-REG-003-04: [TSK-P2-REG-003-03]
TSK-P2-REG-003-05: [TSK-P2-REG-003-04]
TSK-P2-REG-003-06: [TSK-P2-REG-003-05]
TSK-P2-REG-003-07: [TSK-P2-REG-003-06]
```

---

## Critical Anti-Drift Measures Enforced

1. **Every task has Work Item 00**: PLAN.md creation before any code
2. **Every migration task has MIGRATION_HEAD**: Explicit touch and update
3. **Every verification includes pre_ci.sh**: Full CI parity
4. **Every verifier has exact SQL/grep patterns**: No "greps for X" ambiguity
5. **Every multi-function item split**: 6 triggers in PREAUTH-005 → 8 tasks, REG-003 → 7 tasks
6. **Runtime INV ID assignment**: TSK-P2-PREAUTH-007 uses grep to determine next ID
7. **Trigger ordering verified**: TSK-P2-PREAUTH-006B checks alphabetical trigger name ordering
8. **Temp files with cleanup**: All negative tests use `$$` suffix and trap cleanup
9. **Function signatures specified**: Every function has exact parameter and return types
10. **Column ordering enforced**: TSK-P2-REG-003 explicitly separates taxonomy_aligned column addition before K13 trigger

---

## Migration Sequence

- 0116 — interpretation_packs temporal uniqueness (PREAUTH-001-01)
- 0117 — factor_registry + unit_conversions (PREAUTH-002-01/02)
- 0118 — execution_records (PREAUTH-003-01)
- 0119 — policy_decisions + state_rules (PREAUTH-004-01/02)
- 0120 — state_transitions + trigger layer (PREAUTH-005-01/02)
- 0121 — data_authority ENUM + schema columns (PREAUTH-006A-01/04)
- 0122 — derive + enforce triggers (PREAUTH-006B-01/04)
- 0123 — statutory_levy_registry (REG-001-01)
- 0124 — exchange_rate_audit_log (REG-002-01)
- 0125 — PostGIS spatial invariant gate (REG-003-01/07)

---

## System Invariants

The system is NOT ALLOWED to:
- Produce authoritative outputs
- Issue credits
- Claim compliance

Until TSK-P2-PREAUTH-007-05 is complete and pre_ci.sh passes.

---

## Kill Criterion K13

Enforced by TSK-P2-REG-003-06:
- Any project marked taxonomy_aligned = true WITHOUT spatial_check_execution_id AND dns_check_version_id → SYSTEM INVALID (SQLSTATE GF060)
