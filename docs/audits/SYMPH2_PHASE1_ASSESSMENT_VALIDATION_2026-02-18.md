# SYMPH2 Audit Assessment Validation (2026-02-18)

## Scope
This document validates the external assessment against the **current codebase state** in `Symphony` and recorded evidence artifacts.

Reference assessment topic: zip-based audit claims around Sections A-G, F2 blocker, MCP status, and offline pre-CI behavior.

## Verdict Summary
- Overall assessment quality: **partially accurate**.
- Accurate portions: most evidence-based PASS/FAIL interpretation for A/B/C/D/E and zip-only `.git` limitations.
- Inaccurate/outdated portions: current F2 status, approval metadata PASS interpretation, and MCP interpretation.
- Current repo status: Phase-1 contract and closeout are currently passing in evidence.

## Point-by-point validation

### 1) Constraint claim: zip has no `.git`, diff-base logic is fragile
**Assessment claim:** accurate.

**Direct code evidence (diff/base-ref dependency):**
```bash
scripts/lib/git_diff_range_only.sh
  19: printf '%s\n' "refs/remotes/origin/main"
  41-43: if ! git_ensure_ref "$base_ref"; then
            echo "ERROR: base_ref_not_found:$base_ref"
            return 1
```

```python
scripts/audit/lib/approval_requirement.py
  111-118: try _run_diff_helper(...)
            except: changed_files = _fallback_changed_files(...)
                    if changed_files: diff_mode = "fallback"
                    else: error = str(exc)
  134: "approval_required": bool(regulated_hits) if not error else True
```

**Remediation status:** **Implemented** for common local/CI cases.
- `scripts/dev/pre_ci.sh` now resolves fallback base refs (`origin/main`, `refs/heads/origin/main`, `FETCH_HEAD`) before running parity gates.

```bash
scripts/dev/pre_ci.sh
  114-119: BASE_REF_CANDIDATES=(refs/remotes/origin/main origin/main refs/heads/origin/main FETCH_HEAD)
  126-128: fail only if none resolve
```

**Remaining action:**
- For bare zip/no-git audits, add a dedicated `ZIP_AUDIT_MODE` (or required `BASE_REF`) in `verify_phase1_contract.sh` to avoid ambiguous fail-closed behavior when no refs and no local diff context exist.

---

### 2) Constraint claim: no network/no Docker blocks some scripts
**Assessment claim:** mostly accurate.

**Direct code evidence (network path):**
```bash
scripts/audit/bootstrap_local_ci_toolchain.sh
  40-47: need_rg computed
  49-57: curl GitHub ripgrep release only if need_rg==1
```

**Interpretation:**
- Not an unconditional failure.
- It fails offline **when pinned `rg` is missing/mismatched**.

**Remediation status:** **Partially implemented**.
- Conditional download already reduces failures when pinned toolchain is preinstalled.

**Remaining action:**
- Add explicit offline mode for toolchain bootstrap (`SYMPHONY_OFFLINE=1`) with deterministic fail message or pre-vendored binaries.

---

### 3) Section A (A1/A2/A3) PASS claims by evidence
**Assessment claim:** accurate.

**Direct evidence (current files):**
- `evidence/phase0/db_timeout_posture.json` => `status: PASS`
- `evidence/phase1/ingress_hotpath_indexes.json` => `status: PASS`
- `evidence/phase1/anchor_sync_resume_semantics.json` => `status: PASS`
- `evidence/phase1/anchor_sync_operational_invariant.json` => `status: PASS`
- `evidence/phase0/anchor_sync_hooks.json` => `status: PASS`

**Remediation status:** **Implemented and wired**.
- `scripts/dev/pre_ci.sh` runs timeout and ingress/anchor checks in current flow.

---

### 4) A4 claim: approval metadata PASS artifact but Phase-1 contract FAIL
**Assessment claim:** **partially inaccurate (current state)**.

**What is correct:**
- `approval_metadata.json` is part of required contract validation.

**What is incorrect:**
- `approval_metadata.json` is not a `status: PASS` artifact; it is schema-validated metadata.
- Current `phase1_contract_status.json` is **PASS**, not FAIL.

**Direct evidence:**
- `evidence/phase1/approval_metadata.json` has no `status` field.
- `evidence/phase1/phase1_contract_status.json`:
  - `check_id: PHASE1-CONTRACT-STATUS`
  - `status: PASS`
  - `run_phase1_gates: true`
  - `errors: []`

**Contract verifier behavior proof:**
```python
scripts/audit/verify_phase1_contract.sh
  160-167: approval_metadata.json validated against approval schema (fallback to default schema)
  180-187: overall PASS/FAIL written to phase1_contract_status.json
```

**Remediation status:** **Implemented and passing**.

---

### 5) Section B/C/D/E PASS claims
**Assessment claim:** accurate.

**Direct evidence (all PASS):**
- `evidence/phase1/instruction_finality_runtime.json`
- `evidence/phase1/pii_decoupling_runtime.json`
- `evidence/phase1/rail_sequence_runtime.json`
- `evidence/phase1/evidence_pack_api_contract.json`
- `evidence/phase1/exception_case_pack_generation.json`
- `evidence/phase1/pilot_harness_replay.json`
- `evidence/phase1/regulator_demo_pack.json`
- `evidence/phase1/tier1_pilot_demo_pack.json`
- `evidence/phase1/sandbox_deploy_manifest_posture.json`

**Closeout gate proof:**
```python
scripts/audit/verify_phase1_closeout.sh
  44-55: required_phase1 evidence list includes runtime, pilot, demo, KPI artifacts
  88-97: phase1_contract_status must be PASS and run_phase1_gates==true
```

**Remediation status:** **Implemented and enforced**.

---

### 6) F1 claim: control-plane drift PASS
**Assessment claim:** accurate.

**Direct evidence:**
- `evidence/phase0/control_planes_drift.json` => `status: PASS`

**Remediation status:** **Implemented and passing**.

---

### 7) F2 claim: main blocker is Phase-1 contract FAIL due base-ref resolution
**Assessment claim:** accurate for zip-only edge cases, **not accurate for current repo state**.

**Current state evidence:**
- `evidence/phase1/phase1_contract_status.json` => `status: PASS`
- `evidence/phase1/phase1_closeout.json` => `status: PASS`

**Code-level remediation in place:**
- `pre_ci` base-ref candidate fallback (`refs/remotes/origin/main`, `origin/main`, `refs/heads/origin/main`, `FETCH_HEAD`).
- approval-requirement fallback to local diff probes when helper fails.

**Remaining action:**
- Harden standalone zip audit path with explicit mode/override for contract verifier as noted in Point 1.

---

### 8) G claim: pre_ci fails due network bootstrap
**Assessment claim:** partially accurate.

**Direct code evidence:** conditional network fetch only when pinned rg not already present.

```bash
scripts/audit/bootstrap_local_ci_toolchain.sh
  41: need_rg=1
  44-45: need_rg=0 when pinned rg already installed
  49-57: curl only when need_rg==1
```

**Current repo state evidence:**
- pre-CI has recently completed PASS in this workspace with full Phase-1 gates enabled.
- PASS artifacts include:
  - `evidence/phase1/phase1_contract_status.json` (`PASS`)
  - `evidence/phase1/phase1_closeout.json` (`PASS`)

**Remaining action:**
- add documented offline bootstrap policy and/or vendored pinned binaries.

---

### 9) MCP claim: “MCP still in Phase-1 contract therefore Option A not applied”
**Assessment claim:** conflated.

**Direct evidence:**
- `docs/PHASE1/phase1_contract.yml` includes required `INV-105` entries for agent conformance evidence.
- Phase-1 pipeline also enforces explicit no-MCP guard:

```bash
scripts/dev/pre_ci.sh
  430-444: runs verify_no_mcp_phase1.sh and its fixture tests when RUN_PHASE1_GATES=1
```

```python
scripts/audit/verify_no_mcp_phase1.sh
  53-67: bans MCP config/flags/evidence references (with narrow allowlist)
  92-103: emits PASS/FAIL evidence
```

- `evidence/phase1/no_mcp_phase1_guard.json` => `status: PASS`

**Conclusion:**
- Agent conformance evidence requirements (`INV-105`) are governance checks and do **not** imply MCP runtime enablement.
- No-MCP runtime posture is actively enforced.

## Remediation completeness statement
Fixes already in place and verified:
1. Base-ref fallback strategy in `pre_ci` for CI parity gate robustness.
2. Approval requirement helper fallback behavior for non-standard git contexts.
3. Full restored Phase-1 closeout chain is green (`phase1_contract_status` + `phase1_closeout` PASS).
4. Explicit no-MCP enforcement and fixture tests are wired into Phase-1 gate path.

## Additional actions queued
1. Add explicit zip/no-git contract verification mode for `verify_phase1_contract.sh` (clear deterministic behavior without remote refs).
2. Add official offline toolchain mode in `bootstrap_local_ci_toolchain.sh` with clear fail semantics or vendored toolchain package.
3. Clarify governance docs to distinguish “agent conformance required” from “MCP allowed”, removing ambiguity in future audits.

## 2026-03-09 Addendum
- Re-ran `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh` -> PASS.
- Re-ran `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_closeout.sh` -> PASS.
- Fixed deterministic self-test isolation in `LedgerApi` so file-mode Phase-1 self-tests no longer reuse shared global projection files under `/tmp`.
- This removed a non-semantic local failure mode that could mask the actual Phase-1 contract state.

