# Execution Log: Lock-Risk Lint Allowlist Mismatch

## 2026-04-28 08:00 UTC - Lock-Risk Lint Failure

**failure_signature:** PRECI.AUDIT.GATES
**origin_task_id:** TSK-P2-PREAUTH-007-14
**repro_command:** `scripts/dev/pre_ci.sh`

**Error:**
```
Lock-risk lint failed: risky DDL patterns found.
schema/migrations/0134_policy_decisions.sql:41:CREATE INDEX idx_policy_decisions_entity ON public.policy_decisions (entity_type, entity_id);
schema/migrations/0134_policy_decisions.sql:42:CREATE INDEX idx_policy_decisions_declared_by ON public.policy_decisions (declared_by);
```

**Investigation Results:**
- Discovered duplicate migration files: 0134_create_policy_decisions.sql and 0134_policy_decisions.sql
- Allowlist had entries for 0134_create_policy_decisions.sql at lines 46, 49
- Lint was checking 0134_policy_decisions.sql at lines 41, 42
- Scanned all migrations for CREATE INDEX on hot tables
- Calculated fingerprints for all identified statements
- Found that only 0134_policy_decisions.sql:41-42 were missing from allowlist

## 2026-04-28 08:20 UTC - Allowlist Updated

**Action:** Updated allowlist to point to correct migration file
**File:** scripts/security/ddl_allowlist.json
**Changes:**
- Removed entries for 0134_create_policy_decisions.sql:46, 0134_create_policy_decisions.sql:49
- Added entries for 0134_policy_decisions.sql:41 (fingerprint: 0397aceaa5221519ff37e79f56e3466671c63e779275d7617da22711281c2e7a)
- Added entries for 0134_policy_decisions.sql:42 (fingerprint: cc27f012fb31f79b55dbf64b7da55e845ad79190579cabb2a23db933b4832ee4)

## 2026-04-28 08:22 UTC - Duplicate Migration Deleted

**Action:** Deleted duplicate migration file
**File:** schema/migrations/0134_create_policy_decisions.sql
**Reason:** This was a merge conflict artifact. The correct file is 0134_policy_decisions.sql (without "create" in name, uses GF061, proper hardening)
**Result:** File deleted successfully

**final_status:** PASS
**verification_commands_run:**
- `python3 calc_fingerprints.py` - ✅ Identified missing allowlist entries
- `rm schema/migrations/0134_create_policy_decisions.sql` - ✅ Duplicate file deleted
