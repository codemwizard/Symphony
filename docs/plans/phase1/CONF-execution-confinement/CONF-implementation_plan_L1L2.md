# Execution Confinement — Layer 1 + Layer 2 Implementation Plan

**Phase Key:** CONF  
**Phase Name:** Execution Confinement  
**Scope:** Layer 1 + Layer 2 ONLY (Layer 3 deferred to human session)  
**Canonical Reference:** `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

---

## Objective

Apply the two agent-executable layers of the execution confinement package to close evidence fabrication, grep gaming, bypass env vars, and direct verifier execution.

---

## Pre-Conditions (All Verified ✅)

| Condition | Status |
|-----------|--------|
| `/usr/bin/python3` exists and is executable | ✅ |
| Anchor: `pre_ci_check_drd_lockout` in pre_ci.sh | ✅ |
| Anchor: `GF verifier execution posture lint` in pre_ci.sh | ✅ |
| Anchor: `Green Finance Schema + Function Verification` in pre_ci.sh | ✅ |
| 14 guarded scripts exist (original 18 minus 4 removed `_w1_` duplicates) | ✅ |
| `verify_gf_sch_002a.sh` exists | ✅ |

> [!WARNING]
> **Blocker:** The 4 `_w1_` duplicate references (`verify_gf_w1_fnc_001..004.sh`) are STILL present in `apply_execution_confinement.sh`. The human stated they removed them, but they still appear in the file. The apply script will **fail-closed** if they remain. The agent must verify again at runtime and STOP if they're still present.

---

## Tasks

### Task 1: Re-verify staging script fix
- **Action:** Check that `apply_execution_confinement.sh` no longer references `verify_gf_w1_fnc_*`
- **STOP if:** References still present — report to human
- **Success:** Proceed to Task 2

### Task 2: Run Layer 1 — `apply_containment_v3.sh`
- **Action:** Execute `bash _staging/symphony-enforcement-v2/execution-confinement/apply_containment_v3.sh`
- **What it does:**
  1. Copies `strip_bypass_env_vars.sh` → `scripts/audit/` (sha256-verified)
  2. Copies `sign_evidence.py` → `scripts/audit/` (sha256-verified)
  3. Copies `lint_verifier_ast.py` → `scripts/audit/` (sha256-verified)
  4. Patches `pre_ci.sh`:
     - Sources `strip_bypass_env_vars.sh` after DRD lockout
     - Adds AST lint gate after bash posture lint
     - Adds evidence signature verification before GF verifiers
- **Verification after:**
  - `test -f scripts/audit/strip_bypass_env_vars.sh` → exists
  - `test -f scripts/audit/sign_evidence.py` → exists
  - `test -f scripts/audit/lint_verifier_ast.py` → exists
  - `grep -c STRIP_BYPASS_ENV_VARS_SOURCED scripts/dev/pre_ci.sh` → 1+
  - `grep -c AST_LINT_GATE scripts/dev/pre_ci.sh` → 1+
  - `grep -c EVIDENCE_SIGNATURE_VERIFY scripts/dev/pre_ci.sh` → 1+

### Task 3: Run Layer 2 — `apply_execution_confinement.sh`
- **Action:** Execute `bash _staging/symphony-enforcement-v2/execution-confinement/apply_execution_confinement.sh`
- **What it does:**
  1. Inserts `PRE_CI_CONTEXT` guard into 14 verifier scripts
  2. Patches `pre_ci.sh`: exports `PRE_CI_CONTEXT=1` + `PRE_CI_RUN_ID`
  3. Strips bypass env vars (`SKIP_VALIDATION`, `CI_BYPASS`, etc.)
  4. Builds integrity manifest at `.toolchain/script_integrity/verifier_hashes.sha256` (locked 444)
  5. Inserts integrity check block into `pre_ci.sh`
- **Verification after:**
  - `grep -c PRE_CI_CONTEXT_GUARD scripts/db/verify_gf_fnc_001.sh` → 1+
  - `grep -c PRE_CI_CONTEXT_EXPORT scripts/dev/pre_ci.sh` → 1+
  - `grep -c PRE_CI_INTEGRITY_CHECK scripts/dev/pre_ci.sh` → 1+
  - `test -f .toolchain/script_integrity/verifier_hashes.sha256` → exists
  - `stat -c %a .toolchain/script_integrity/verifier_hashes.sha256` → 444
  - `bash scripts/db/verify_gf_fnc_001.sh 2>&1 | grep "must run via"` → blocked

### Task 4: Post-Apply — Add Wave 6 verifiers to guard list
- **Scripts to add:**
  - `scripts/db/verify_gf_fnc_007a.sh` (FNC-007A confidence enforcement)
  - `scripts/audit/verify_gf_fnc_007b.sh` (FNC-007B CI wiring)
  - `scripts/db/verify_gf_fnc_005.sh` (FNC-005 — already guarded by Layer 2, verify)
- **Actions:**
  1. Insert `PRE_CI_CONTEXT` guard into `verify_gf_fnc_007a.sh` and `verify_gf_fnc_007b.sh`
  2. Regenerate integrity manifest (unlock 444 → write → re-lock 444)
  3. Verify guards work: direct execution must be blocked
- **Verification after:**
  - `grep -c PRE_CI_CONTEXT_GUARD scripts/db/verify_gf_fnc_007a.sh` → 1+
  - `grep -c PRE_CI_CONTEXT_GUARD scripts/audit/verify_gf_fnc_007b.sh` → 1+
  - `bash scripts/db/verify_gf_fnc_007a.sh 2>&1 | grep "must run via"` → blocked

### Task 5: Post-Apply Verification
- **Action:** Run comprehensive post-apply checks
  - All 3 installed tools exist and are executable
  - All 5 pre_ci.sh patches are present (markers found)
  - All guarded scripts have the PRE_CI_CONTEXT guard
  - Integrity manifest exists, is read-only, and self-verifies
  - Direct verifier execution is blocked with error message
  - Rogue execution logging works

---

## Files Modified

| File | Action | Task |
|------|--------|------|
| `scripts/audit/strip_bypass_env_vars.sh` | [NEW] from staging | T2 |
| `scripts/audit/sign_evidence.py` | [NEW] from staging | T2 |
| `scripts/audit/lint_verifier_ast.py` | [NEW] from staging | T2 |
| `scripts/dev/pre_ci.sh` | [MODIFY] 5 patch blocks | T2+T3 |
| 14 verifier scripts in `scripts/db/` + `scripts/audit/` | [MODIFY] guard inserted | T3 |
| `scripts/db/verify_gf_fnc_007a.sh` | [MODIFY] guard inserted | T4 |
| `scripts/audit/verify_gf_fnc_007b.sh` | [MODIFY] guard inserted | T4 |
| `.toolchain/script_integrity/verifier_hashes.sha256` | [NEW] integrity manifest | T3+T4 |

---

## NOT in Scope (Deferred)

| Item | Reason |
|------|--------|
| Layer 3: `trusted_launcher.sh` | Human-only session (requires keypair + sudo + chattr) |
| Layer 3: `add_launcher_guard_to_pre_ci.sh` | Blocks direct pre_ci.sh — deferred |
| Layer 3: `generate_trust_manifest.sh` | Requires private key |
| `UBUNTU_ACCESS_HARDENING.md` | Human-only OS-level hardening |

---

## Stop Conditions

- **STOP** if `apply_containment_v3.sh` exits non-zero (anchor missing)
- **STOP** if `apply_execution_confinement.sh` exits non-zero (missing script or anchor)
- **STOP** if any post-apply verification check fails
- **STOP** if the `_w1_` references are still in the staging script

---

## Unit Tests

| Test ID | Description | Script | Status |
|---------|-------------|--------|--------|
| CONF-T1 | Direct verifier execution blocked | `bash scripts/db/verify_gf_fnc_001.sh` → exit 1 + error msg | Pending |
| CONF-T2 | Rogue execution logged | Check `.toolchain/audit/rogue_execution.log` after T1 | Pending |
| CONF-T3 | Integrity manifest self-verifies | `sha256sum --check .toolchain/script_integrity/verifier_hashes.sha256` | Pending |
| CONF-T4 | PRE_CI_CONTEXT override works | `PRE_CI_CONTEXT=1 bash scripts/db/verify_gf_fnc_001.sh` → runs normally | Pending |
| CONF-T5 | Wave 6 verifier guarded | `bash scripts/db/verify_gf_fnc_007a.sh` → exit 1 + error msg | Pending |
