# CONF — Execution Confinement Task Tracker

**Phase Key:** CONF  
**Phase Name:** Execution Confinement

---

## Tasks

- [x] **T1:** Re-verify staging script (confirm `_w1_` duplicates removed)
- [x] **T2:** Run Layer 1 — `apply_containment_v3.sh`
  - [x] Step 1: Install `strip_bypass_env_vars.sh` (sha256-verified)
  - [x] Step 2: Install `sign_evidence.py` (sha256-verified)
  - [x] Step 3: Install `lint_verifier_ast.py` (sha256-verified)
  - [x] Step 4a: Patch pre_ci.sh — bypass env var strip
  - [x] Step 4b: Patch pre_ci.sh — AST lint gate (manual — bash predecessor missing)
  - [x] Step 4c: Patch pre_ci.sh — evidence signature verification (manual)
- [x] **T3:** Run Layer 2 — `apply_execution_confinement.sh`
  - [x] Step 1: PRE_CI_CONTEXT guard inserted into 14 verifier scripts
  - [x] Step 2: PRE_CI_CONTEXT=1 and PRE_CI_RUN_ID exported in pre_ci.sh
  - [x] Step 3: Integrity manifest built (17 entries, locked 444)
  - [x] Step 4: Integrity check inserted into pre_ci.sh
- [x] **T4:** Post-apply — Wave 6 verifiers
  - [x] Guard inserted into `verify_gf_fnc_007a.sh`
  - [x] Guard inserted into `verify_gf_fnc_007b.sh`
  - [x] Guard inserted into `verify_gf_w1_plt_001.sh`
  - [x] Integrity manifest regenerated with 17 entries
- [x] **T5:** Post-apply verification

---

## Unit Tests

| Test ID | Description | Result | Time |
|---------|-------------|--------|------|
| CONF-T1 | Direct verifier execution blocked | ✅ PASS — exits with `must run via pre_ci.sh` | 2026-03-31T08:14:24Z |
| CONF-T2 | Rogue execution logged | ✅ PASS — entries in `.toolchain/audit/rogue_execution.log` | 2026-03-31T08:14:24Z |
| CONF-T3 | Integrity manifest self-verifies | ✅ PASS — 17 entries, perms 444 | 2026-03-31T08:14:34Z |
| CONF-T5 | Wave 6 verifiers guarded | ✅ PASS — 007a and PLT-001 both blocked | 2026-03-31T08:14:36Z |

**Model:** claude-sonnet-4-20250514  
**All tests run at:** 2026-03-31T08:14Z

---

## Deviation from Plan

| Item | Planned | Actual | Reason |
|------|---------|--------|--------|
| Layer 1 Step 4b anchor | `GF verifier execution posture lint (anti-deception gate)` | `GF migration scope enforcement (TSK-P1-RLS-003)` | Bash posture lint predecessor was never applied; AST lint is its replacement |
| Layer 1 Step 4b+4c | Run via `apply_containment_v3.sh` | Manual patch | Script exited at 4b due to missing anchor; Steps 1-3 and 4a succeeded |
| Guarded script count | 18 (original) | 14 (Layer 2) + 3 (Wave 6) = 17 | 4 `_w1_` duplicates removed by human |
