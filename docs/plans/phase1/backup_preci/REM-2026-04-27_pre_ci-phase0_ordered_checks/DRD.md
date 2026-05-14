# DRD: DDL Lock Risk Lint Failure Remediation

**failure_signature:** PRECI.AUDIT.GATES  
**origin_gate_id:** pre_ci.phase0_ordered_checks  
**repro_command:** scripts/dev/pre_ci.sh  
**verification_commands_run:** pending  
**final_status:** OPEN  

## Failing Layer

audit/governance - Phase-0 audit and schema gates

## Root Cause

The current `scripts/security/lint_ddl_lock_risk.sh` script flags all ALTER TABLE statements as risky, including legitimate operations required for Wave 6/7/8 remediation:

- **Trigger disable/enable for backfill operations** (0158, 0160)
- **NOT NULL constraint enforcement after backfill** (0159, 0161)
- **Adding columns to tables** (0157, 0164, 0165, 0168, 0169, 0170, 0171)

The script lacks:
1. Hot-table awareness (distinguishing critical tables from less critical ones)
2. Fingerprinted allowlist mechanism for approved DDL patterns
3. Expiry tracking for temporary exceptions
4. Evidence emission for allowlist usage

## Affected Migrations

- 0154_enforce_last_transition_id_not_null.sql:21
- 0157_add_project_id_to_policy_decisions.sql:5
- 0158_backfill_interpretation_version_id.sql:27, 64
- 0159_enforce_interpretation_version_id_not_null.sql:12
- 0160_backfill_policy_decisions_project_id.sql:24, 34
- 0161_enforce_policy_decisions_project_id_not_null.sql:18
- 0164_registry_supersession_constraints.sql:27
- 0165_create_public_keys_registry.sql:24
- 0168_attestation_seam_schema.sql:32, 48, 62
- 0169_add_phase1_boundary_markers.sql:18, 33
- 0170_attestation_anti_replay.sql:18, 32
- 0171_attestation_kill_switch_gate.sql:18, 24, 27, 29, 33, 35

## Remediation Plan (per docs/PLANS-addendum_1.md)

### Step 1: Create Hot Tables List
Create `scripts/security/hot_tables.txt` as the single source of hot tables requiring strict DDL controls.

**Hot tables (based on INV-022/INV-040):**
- state_transitions
- state_current
- policy_decisions
- outbox

### Step 2: Create Fingerprinted Allowlist
Create `scripts/security/ddl_allowlist.json` with:
- migration_file
- statement_fingerprint (SHA256)
- reason
- expires_on or sunset_migration_id

### Step 3: Update Lint Script
Update `scripts/security/lint_ddl_lock_risk.sh` to:
- Read hot tables list
- Match allowlist by fingerprint only (not table name)
- Fail on expired allowlist entries
- Emit evidence including allowlist hits to `evidence/phase0/ddl_blocking_policy.json`

### Step 4: Security Review Enforcement
Update `.github/CODEOWNERS` to require Security Guardian review for `ddl_allowlist.json`.

## Implementation Sequence

1. Create `scripts/security/hot_tables.txt`
2. Create `scripts/security/ddl_allowlist.json` with all affected migrations
3. Update `scripts/security/lint_ddl_lock_risk.sh` with hot-table awareness and allowlist logic
4. Update `.github/CODEOWNERS` for allowlist security review
5. Run `scripts/security/lint_ddl_lock_risk.sh` to verify
6. Remove DRD lockout: `bash scripts/audit/verify_drd_casefile.sh --clear`

## Verification Commands

```bash
# Test hot tables list exists
test -f scripts/security/hot_tables.txt

# Test allowlist exists and is valid JSON
test -f scripts/security/ddl_allowlist.json && jq empty scripts/security/ddl_allowlist.json

# Test lint script passes
bash scripts/security/lint_ddl_lock_risk.sh

# Verify evidence emitted
test -f evidence/phase0/ddl_blocking_policy.json
```

## Non-Weakening Proof

Per INV-022/INV-040 (DDL lock-risk linting):
- **Before:** Lint blocked all ALTER TABLE statements on all tables
- **After:** Lint blocks ALTER TABLE on hot tables unless fingerprinted in allowlist
- **Non-weakening:** Hot-table awareness increases security focus on critical tables. Fingerprinted allowlist provides audit trail. Expiry tracking prevents permanent exceptions. Evidence emission maintains transparency.

## References

- docs/PLANS-addendum_1.md (Addendum Plan 1 — Baseline Drift, Lint Policy, Docs Drift)
- docs/operations/WAVE5_TASK_CREATION_LESSONS_LEARNED.md
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
