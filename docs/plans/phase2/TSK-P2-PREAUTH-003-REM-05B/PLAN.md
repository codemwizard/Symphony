# TSK-P2-PREAUTH-003-REM-05B PLAN — CI wiring for the execution-records integrity verifier

Task: TSK-P2-PREAUTH-003-REM-05B
Owner: SECURITY_GUARDIAN
Depends on: TSK-P2-PREAUTH-003-REM-05
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.VERIFIER_NOT_WIRED
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Wire `scripts/db/verify_execution_truth_anchor.sh` (authored under REM-05 by DB_FOUNDATION) into the two CI entrypoints that Security Guardian owns per AGENTS.md path authority: `scripts/dev/pre_ci.sh` and `scripts/audit/run_invariants_fast_checks.sh`. Both invocations must be guarded so a verifier failure short-circuits the gate.

This task exists because the original REM-05 bundled two jobs — producing the verifier itself (DB_FOUNDATION territory, `scripts/db/**`) and wiring it into CI (SECURITY_GUARDIAN territory, `scripts/dev/pre_ci.sh` and `scripts/audit/**`). Devin Review comment `BUG_pr-review-job-c4fc938f95fc4692ac528a10081cda97_0001` flagged that as a path-authority violation. The split keeps each task under a single owner role with no work item crossing the role boundary.

---

## Architectural Context

`pre_ci.sh` is the single shell pipeline every contributor runs locally and every CI workflow invokes. Adding the verifier invocation here (guarded by `|| exit 1`) is what actually makes INV-EXEC-TRUTH-001 enforceable. `run_invariants_fast_checks.sh` is the shell-syntax-only pre-gate used to fail fast when a verifier script is missing or non-executable; adding the verifier here catches "verifier script deleted or corrupted" failures before they reach the DB-bearing gate.

The split between live-DB (`pre_ci.sh`) and no-DB (`run_invariants_fast_checks.sh`) checks is deliberate: a contributor whose local env lacks `DATABASE_URL` still trips the fast-check when the verifier script goes missing, so the gate never silently falls open.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-05` is `status=completed` and `scripts/db/verify_execution_truth_anchor.sh` is executable.
- [ ] REM-05 evidence `evidence/phase2/tsk_p2_preauth_003_rem_05.json` exists with `status=PASS`.
- [ ] Current `pre_ci.sh` has no pre-existing invocation of `verify_execution_truth_anchor.sh` (idempotency anchor).
- [ ] `run_invariants_fast_checks.sh` declares its shell-syntax-check array (existing convention).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/dev/pre_ci.sh` | MODIFY | Add verifier invocation with `\|\| exit 1` immediately after existing schema-invariants gate |
| `scripts/audit/run_invariants_fast_checks.sh` | MODIFY | Add verifier to fast-check array |
| `evidence/phase2/tsk_p2_preauth_003_rem_05b.json` | CREATE | Wiring-evidence JSON |
| `tasks/TSK-P2-PREAUTH-003-REM-05B/meta.yml` | CREATE | Task meta |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-05B/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-05B/EXEC_LOG.md` | CREATE | Append-only record |

`out_of_scope`:
- `scripts/db/**` (DB_FOUNDATION only)
- `docs/invariants/**` (INVARIANTS_CURATOR only)
- `.github/workflows/**` (defer unless explicitly in scope; current workflows already invoke pre_ci.sh)

---

## Stop Conditions

- `scripts/db/verify_execution_truth_anchor.sh` is not executable — STOP, escalate to REM-05.
- The `pre_ci.sh` invocation is guarded by `|| true` (fail-open) — STOP.
- The invocation appears multiple times in `pre_ci.sh` — STOP (non-idempotent edit).
- The fast-check reference is missing — STOP (fast-gate blind spot).
- Any edit lands in `scripts/db/**` or `docs/invariants/**` — STOP (path-authority violation).

---

## Implementation Steps

### Step 1: Add the fail-closed invocation to pre_ci.sh

**What:** `[ID tsk_p2_preauth_003_rem_05b_work_item_01]` Edit `scripts/dev/pre_ci.sh` to invoke the verifier immediately after the existing `scripts/db/verify_invariants.sh` call (the schema-invariants gate). The block must:

```bash
echo "==> execution_records truth-anchor integrity (INV-EXEC-TRUTH-001)"
if [[ -x scripts/db/verify_execution_truth_anchor.sh ]]; then
  scripts/db/verify_execution_truth_anchor.sh || exit 1
else
  echo "ERROR: scripts/db/verify_execution_truth_anchor.sh not found or not executable"
  exit 1
fi
```

Idempotency: re-running this task must not duplicate the block. Verifier asserts exactly one occurrence of `verify_execution_truth_anchor.sh` in `pre_ci.sh`.

**Acceptance:** `grep -c 'verify_execution_truth_anchor.sh' scripts/dev/pre_ci.sh` returns exactly 1, and `grep -E 'verify_execution_truth_anchor.sh.*\|\| exit 1' scripts/dev/pre_ci.sh` matches.

### Step 2: Register the verifier in the fast-check array

**What:** `[ID tsk_p2_preauth_003_rem_05b_work_item_02]` Edit `scripts/audit/run_invariants_fast_checks.sh` to include `scripts/db/verify_execution_truth_anchor.sh` in its shell-syntax-check array. This is a no-DB check that catches "verifier missing or shell-broken" before the DB-bearing pre_ci gate.

**Acceptance:** `grep -q 'verify_execution_truth_anchor.sh' scripts/audit/run_invariants_fast_checks.sh` returns 0.

### Step 3: Emit the wiring-evidence JSON

**What:** `[ID tsk_p2_preauth_003_rem_05b_work_item_03]` Produce `evidence/phase2/tsk_p2_preauth_003_rem_05b.json` with required fields: `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths` (both edited files), `observed_hashes` (SHA-256 of each), `command_outputs` (the grep results), `execution_trace`, `pre_ci_wired` (bool), `fast_checks_wired` (bool).

Status must be `PASS` only if both wiring assertions hold.

**Acceptance:** file exists; `jq -e '.status == "PASS"'` returns 0.

---

## Negative Tests (required before status leaves `planned`)

- **N1 fail-open guard removed:** delete `|| exit 1` from the `pre_ci.sh` invocation, re-run the wiring verifier; it must exit non-zero.
- **N2 fast-check reference missing:** remove the `verify_execution_truth_anchor.sh` reference from `run_invariants_fast_checks.sh`, re-run the wiring verifier; it must exit non-zero.

---

## Proof Guarantees

- `pre_ci.sh` contains exactly one fail-closed invocation of the anchor verifier.
- `run_invariants_fast_checks.sh` references the verifier path.
- Evidence JSON `status=PASS` iff both wiring assertions hold.

## Proof Limitations

- Fast-check path does not connect to the database; it asserts shell-syntax + presence of the script. Live-DB integrity enforcement is in `pre_ci.sh`.
- GitHub Actions workflow coverage relies on the existing invocations of `pre_ci.sh` in CI; this task does not edit `.github/workflows/**`.
- Binding to INV-EXEC-TRUTH-001 comes via REM-04 (invariant block) and REM-05 (verifier); this task proves only wiring presence, not enforcement semantics.

## Out of Scope

- Authoring the verifier (REM-05, DB_FOUNDATION).
- Invariant manifest registration (REM-04, INVARIANTS_CURATOR).
- `docs/architecture/**` registration (REM-04B, ARCHITECT).
- Lifecycle / retry / execution_state (deferred to REM-2026-04-20_execution-lifecycle).

---

## Evidence

- `evidence/phase2/tsk_p2_preauth_003_rem_05b.json` — required fields listed under Step 3.

---

## DRD / Remediation markers

- `failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.VERIFIER_NOT_WIRED`
- `origin_task_id: TSK-P2-PREAUTH-003-REM-05`
- `repro_command: bash scripts/dev/pre_ci.sh`
- `first_observed_utc: 2026-04-20T00:00:00Z`
- `remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md`
- Two-strike rule applies: if the wiring verifier fails on a second attempt, open a remediation branch rather than patching in place.
