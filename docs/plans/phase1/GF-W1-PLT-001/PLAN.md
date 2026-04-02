# GF-W1-PLT-001 PLAN — Register PWRM0001 adapter

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification command MUST be explicitly mapped using tracking IDs (e.g., `[ID <task_id>_work_item_01]`).
-->

Task: GF-W1-PLT-001
Owner: DB Foundation Agent
Depends on: GF-W1-FNC-005
failure_signature: PHASE1.APP.PLT001.REGISTRATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

Register the PWRM0001 adapter configuration so that the first pilot payload can dynamically activate against the agnostic ledger functions without modifying any foundational SQL tables. This involves creating a data insertion script that populates the adapter_registrations table with PWRM0001 methodology details, payload schemas, and jurisdiction profiles. Done when verifier script confirms adapter registration exists, schema validation is active, jurisdiction profiles are configured, and the adapter can be referenced by the issuance functions.

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

This task provides the concrete adapter registration that proves the neutral host architecture works by onboarding a real pilot without schema changes. It must run after FNC-005 (asset batch issuance) because the adapter needs to reference the issuance functions, and it's the final task in Wave 6 demonstrating that the complete pipeline can register a pilot. This prevents the anti-pattern of requiring pilot-specific schema modifications and proves the second pilot test by showing PWRM0001 can run entirely on neutral host tables.

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] GF-W1-FNC-005 is status=completed and evidence validates.
- [ ] DATABASE_URL is set to a fresh test DB for migration testing.
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).
- [ ] Agent conformance passes: `scripts/audit/verify_agent_conformance.sh`

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/register_pwrm0001_adapter.sh` | CREATE | Data insertion script for PWRM0001 adapter registration |
| `scripts/audit/verify_gf_w1_plt_001.sh` | CREATE | Verify adapter registration and configuration |
| `tasks/GF-W1-PLT-001/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/GF-W1-PLT-001/PLAN.md` | MODIFY | This plan document |
| `docs/plans/phase1/GF-W1-PLT-001/EXEC_LOG.md` | MODIFY | Append-only execution log |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If adapter registration uses DDL instead of DML** -> STOP
- **If any core schema tables are modified** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: Create adapter registration script
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID gf_w1_plt_001_work_item_01]` Implement `register_pwrm0001_adapter.sh` with DML insertions
**How:** Write bash script that inserts PWRM0001 configuration into adapter_registrations, methodology_versions, and jurisdiction_profiles tables using only INSERT statements (no DDL)
**Done when:** Registration script exists and is executable

```bash
#!/bin/bash
# Example structure for register_pwrm0001_adapter.sh
set -euo pipefail

# Register PWRM0001 methodology adapter
psql -v ON_ERROR_STOP=1 << 'SQL'
INSERT INTO public.adapter_registrations (
    adapter_registration_id,
    tenant_id,
    adapter_code,
    methodology_code,
    methodology_authority,
    version_code,
    is_active,
    payload_schema_refs,
    checklist_refs,
    entrypoint_refs,
    issuance_semantic_mode,
    retirement_semantic_mode
) VALUES (
    gen_random_uuid(),
    (SELECT tenant_id FROM public.tenants WHERE tenant_code = 'SYSTEM' LIMIT 1),
    'PWRM0001',
    'PLASTIC_WASTE_V1',
    'GLOBAL_PLASTIC_REGISTRY',
    '1.0',
    true,
    '["pwrm0001_collection_schema_v1.json"]',
    '["pwrm0001_verification_checklist_v1.json"]',
    '["pwrm0001_calculation_engine_v1.py"]',
    'IMMEDIATE_UPON_CONFIDENCE',
    'IMMEDIATE_UPON_REQUEST'
) ON CONFLICT (adapter_code, methodology_code, version_code) DO UPDATE SET
    is_active = EXCLUDED.is_active,
    payload_schema_refs = EXCLUDED.payload_schema_refs,
    checklist_refs = EXCLUDED.checklist_refs,
    entrypoint_refs = EXCLUDED.entrypoint_refs;

-- Register Global South jurisdiction profile for PWRM0001
INSERT INTO public.jurisdiction_profiles (
    jurisdiction_profile_id,
    jurisdiction_code,
    methodology_code,
    confidence_threshold,
    verification_requirements,
    active_at
) VALUES (
    gen_random_uuid(),
    'GLOBAL_SOUTH',
    'PLASTIC_WASTE_V1',
    0.95,
    '["field_verification", "digital_traceability", "mass_balance"]',
    now()
) ON CONFLICT (jurisdiction_code, methodology_code) DO UPDATE SET
    confidence_threshold = EXCLUDED.confidence_threshold,
    verification_requirements = EXCLUDED.verification_requirements;
SQL

echo "PWRM0001 adapter registration completed"
```

### Step 2: Implement comprehensive verification script
**What:** `[ID gf_w1_plt_001_work_item_02]` Create `verify_gf_w1_plt_001.sh` with registration checks
**How:** Write bash script that verifies adapter registration exists, methodology configuration is correct, jurisdiction profiles are set, payload schemas are referenced, and no DDL was executed
**Done when:** Verification script exists and is executable

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID gf_w1_plt_001_work_item_03]` Implement verification integration with negative tests
**How:** Define execution failure tests (N1...N3) that simulate missing adapter registration, malformed configuration, and DDL usage. Ensure verifier script explicitly rejects these conditions
**Done when:** The integration wrapper script exits non-zero against unfixed code, and exits 0 against the target implementation

### Step 4: Emit evidence and validate
**What:** `[ID gf_w1_plt_001_work_item_04]` Run verifier and validate evidence schema
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/audit/verify_gf_w1_plt_001.sh && bash scripts/audit/verify_gf_w1_plt_001.sh > evidence/phase1/gf_w1_plt_001.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON schema is written to disk

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID gf_w1_plt_001_work_item_01] [ID gf_w1_plt_001_work_item_02] [ID gf_w1_plt_001_work_item_04]
test -x scripts/audit/verify_gf_w1_plt_001.sh && bash scripts/audit/verify_gf_w1_plt_001.sh > evidence/phase1/gf_w1_plt_001.json || exit 1

# [ID gf_w1_plt_001_work_item_04]
test -f evidence/phase1/gf_w1_plt_001.json && cat evidence/phase1/gf_w1_plt_001.json | grep "observed_hashes" || exit 1

# [ID gf_w1_plt_001_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/phase1/gf_w1_plt_001.json`

Required fields:
- `task_id`: "GF-W1-PLT-001"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `adapter_registered`: "PWRM0001"
- `methodology_code`: "PLASTIC_WASTE_V1"
- `jurisdiction_profile_active`: "GLOBAL_SOUTH"
- `ddl_operations_count`: 0
- `negative_tests_passed`: ["N1", "N2", "N3"]

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. Remove adapter registration: `DELETE FROM public.adapter_registrations WHERE adapter_code = 'PWRM0001';`
2. Remove jurisdiction profile: `DELETE FROM public.jurisdiction_profiles WHERE methodology_code = 'PLASTIC_WASTE_V1';`
3. Remove registration script: `rm scripts/db/register_pwrm0001_adapter.sh`
4. Update status back to 'planned' in meta.yml
5. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk
<!-- REQUIRED. Name what can go wrong in this specific task.
     These must match or extend the failure_modes in meta.yml. -->

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Evidence file missing | FAIL | Verify script writes JSON evidence directly |
| Verification script panics or exits > 0 | FAIL | Comprehensive error handling in verifier |
| DDL operations used | CRITICAL_FAIL | Verification ensures only DML operations |
| Core schema modifications | CRITICAL_FAIL | Script limited to adapter tables only |
| Adapter conflicts with core invariants | CRITICAL_FAIL | Registration uses neutral host schema only |
| Anti-pattern: pilot-specific tables | FAIL_REVIEW | Registration uses existing adapter_registrations table |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/phase1/approvals/GF-W1-PLT-001.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
