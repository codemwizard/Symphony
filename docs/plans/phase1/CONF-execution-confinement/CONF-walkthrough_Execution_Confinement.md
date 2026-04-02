# CONF — Execution Confinement Walkthrough

**Phase Key:** CONF  
**Phase Name:** Execution Confinement  
**Completed:** 2026-03-31T08:15Z  
**Model:** claude-sonnet-4-20250514

---

## Summary

Applied Layer 1 (Containment v3) and Layer 2 (Execution Confinement) from \`_staging/symphony-enforcement-v2/execution-confinement/\` to the live repository. These layers close 4 agent exploit vectors: evidence fabrication, grep gaming, bypass env vars, and direct verifier execution.

---

## What Was Applied

### Layer 1 — Containment v3

**3 security tools installed to `scripts/audit/`:**

| Tool | Purpose | Attack Closed |
|------|---------|---------------|
| `strip_bypass_env_vars.sh` | Detects, logs, and strips env vars like `SKIP_CI_DB_PARITY_PROBE=1` | Agent sets bypass flags |
| `sign_evidence.py` | HMAC-SHA256 signs evidence with per-run key; rejects stale/hand-typed JSON | Agent hand-types evidence |
| `lint_verifier_ast.py` | Structural check that `psql` is a real command, not a comment | Agent plants `# psql` comment |

**5 enforcement blocks patched into `scripts/dev/pre_ci.sh`:**

| Marker | Purpose |
|--------|---------|
| `STRIP_BYPASS_ENV_VARS_SOURCED` | Sources env var stripper after DRD lockout |
| `AST_LINT_GATE` | Runs AST lint before GF migration scope |
| `EVIDENCE_SIGNATURE_VERIFY` | Verifies evidence HMAC before GF verifiers |
| `PRE_CI_CONTEXT_EXPORT` | Exports `PRE_CI_CONTEXT=1` and `PRE_CI_RUN_ID` |
| `PRE_CI_INTEGRITY_CHECK` | Verifies guarded script hashes before gate execution |

### Layer 2 — Execution Confinement

**17 verifier scripts guarded with `PRE_CI_CONTEXT_GUARD`:**

Scripts in `scripts/db/`:
- `verify_gf_sch_001.sh`, `verify_gf_sch_002a.sh`, `verify_gf_sch_008.sh`
- `verify_gf_fnc_001.sh` through `verify_gf_fnc_007a.sh` (9 scripts)

Scripts in `scripts/audit/`:
- `verify_agent_conformance.sh`, `verify_remediation_trace.sh`
- `verify_remediation_artifact_freshness.sh`, `verify_task_meta_schema.sh`
- `verify_task_plans_present.sh`, `verify_gf_fnc_007b.sh`, `verify_gf_w1_plt_001.sh`

**Integrity manifest:** `.toolchain/script_integrity/verifier_hashes.sha256` (17 entries, permissions 444)

---

## Deviations from Plan

1. **`apply_containment_v3.sh` failed at Step 4b** — anchor `GF verifier execution posture lint (anti-deception gate)` not found. The bash predecessor script (`lint_verifier_execution_posture.sh`) was never applied to this repo. The Python AST lint (`lint_verifier_ast.py`) is its replacement and strictly superior. Steps 4b and 4c were applied manually using existing anchors.

2. **4 `_w1_` duplicate references** were in the staging script. The human removed them before Layer 2 ran. Original 18 guarded scripts became 14, then 3 Wave 6 scripts were added post-apply for 17 total.

---

## Verification Results

| Test | Expected | Result |
|------|----------|--------|
| Direct execution of `verify_gf_fnc_001.sh` | Blocked with error message | ✅ `must run via pre_ci.sh or run_task.sh` |
| Rogue execution logged | Entry in `.toolchain/audit/rogue_execution.log` | ✅ 2 entries logged |
| Integrity manifest self-check | `sha256sum --check` passes | ✅ 17 entries verified, perms 444 |
| Wave 6 `verify_gf_fnc_007a.sh` blocked | Error message | ✅ Blocked |
| Wave 6 `verify_gf_w1_plt_001.sh` blocked | Error message | ✅ Blocked |
| All 5 pre_ci.sh markers present | Count ≥ 1 each | ✅ All 5 present (count=2 each: open+close) |

---

## What Is NOT Yet Applied (Layer 3 — Deferred)

| Script | Purpose | Requires |
|--------|---------|----------|
| `trusted_launcher.sh` | TOCTOU-safe snapshot execution | Keypair + `sudo chattr +i` |
| `add_launcher_guard_to_pre_ci.sh` | Block direct `pre_ci.sh` invocation | Trusted launcher installed first |
| `generate_trust_manifest.sh` | Cryptographically sign integrity manifest | Private key |
| `UBUNTU_ACCESS_HARDENING.md` | OS filesystem permission lockdown | `sudo` + `ci_harness_owner` user |

---

## Files in This Phase

| File | Location |
|------|----------|
| Full implementation plan (all layers) | `docs/plans/phase1/CONF-execution-confinement/CONF-implementation_plan_full.md` |
| Focused L1+L2 plan | `docs/plans/phase1/CONF-execution-confinement/CONF-implementation_plan_L1L2.md` |
| Task tracker | `docs/plans/phase1/CONF-execution-confinement/CONF-task_Execution_Confinement.md` |
| This walkthrough | `docs/plans/phase1/CONF-execution-confinement/CONF-walkthrough_Execution_Confinement.md` |
| Loophole analysis | Artifact: `CONF-loophole_analysis.md` |
