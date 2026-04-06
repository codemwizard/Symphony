# TSK-P1-247 PLAN — Unify Deterministic Evidence Timestamps

Task: TSK-P1-247
Owner: SECURITY_GUARDIAN
Depends on: none
failure_signature: PRECI.PIPELINE.TSK-P1-247.INTEGRITY
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
Eradicate local tracking drift by unifying all Phase 1 evidence generators to honor the `SYMPHONY_EVIDENCE_DETERMINISTIC` flag. We will intercept the Python verification track (`sign_evidence.py`) and the 18 standalone Track-3 bash verifiers to utilize Unix Epoch Zero when driven deterministically. This will ensure that after a successful `pre_ci.sh` hook pass, `git status` remains completely untampered and clean. Supported by `evidence/phase1/tsk_p1_247_deterministic_timestamps.json`.

---

## Architectural Context
The verification pipeline currently contains three non-synchronized clocks representing three diverse tracks (legacy bash, hardened python, and standalone strings). If not reconciled immediately, these three clocks will continually fight the commit tree history, falsely attributing branch modification logic mid-hook. By consolidating under one determinism gate located at the peak of `pre_ci.sh`, we guarantee identical pre-execution and post-execution tree signatures.

---

## Pre-conditions

- [x] Repository is currently on a safe remediation/fix branch (`fix/demo-updates-and-evidence`).
- [x] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/dev/pre_ci.sh` | MODIFY | Export SYMPHONY_EVIDENCE_DETERMINISTIC=1 natively. |
| `scripts/audit/sign_evidence.py` | MODIFY | Detect determinism override and clamp `datetime` to Unix Epoch Zero. |
| `scripts/audit/verify_tsk_p1_*.sh` | MODIFY | Dynamically compute EVIDENCE_TS checking determinism context. |
| `scripts/audit/verify_tsk_p1_247.sh` | CREATE | Construct the negative constraints and verify determinism adherence. |
| `tasks/TSK-P1-247/meta.yml` | MODIFY | Update status to completed. |

---

## Stop Conditions

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If >=3 weak signals are detected without hard failing** -> STOP

---

## Implementation Steps

### Step 1: Enforce Determinism in Python Gate
**What:** `[ID tsk_p1_247_work_item_01]` Modify `sign_evidence.py`.
**How:** Apply `datetime.fromtimestamp(0, tz=timezone.utc)` when `SYMPHONY_EVIDENCE_DETERMINISTIC` is set to "1" in `cmd_write`.
**Done when:** Running `sign_evidence.py --write` with the ENV variable produces a file strictly stamped with `1970-01-01T00:00:00Z`.

### Step 2: Unify Track-3 Standalone Bash Scripts
**What:** `[ID tsk_p1_247_work_item_02]` Correct `date -u` generation across 18 verifiers.
**How:** Wrap the variable mapping using shell logic to verify the presence of the `SYMPHONY_EVIDENCE_DETERMINISTIC` parameter, defaulting back to `date -u` otherwise.
**Done when:** Standalone bash tasks generate the standalone-1970 string when prompted by determinism mode.

### Step 3: Anchor Determinism Flag on Pre-CI
**What:** `[ID tsk_p1_247_work_item_03]` Export determinism to the primary harness.
**How:** Inject `export SYMPHONY_EVIDENCE_DETERMINISTIC=1` alongside `export PRE_CI_CONTEXT=1` at the peak of `pre_ci.sh`.
**Done when:** Code review confirms `SYMPHONY_EVIDENCE_DETERMINISTIC` is properly hoisted securely.

### Step 4: Write the Negative Test Constraints
**What:** `[ID tsk_p1_247_work_item_04]` Implement the standalone validation script `verify_tsk_p1_247.sh`.
**How:** Assert mathematically that no file written by Python ignores the bash env. Perform string-grepping tests over the 18 bash scripts to ensure `date -u` fallback handles `DETERMINISTIC` properly without breaking fallback parameters.
**Done when:** The script fails securely against the untampered repo and passes against our applied fixes.

### Step 5: Emit evidence
**What:** `[ID tsk_p1_247_work_item_05]` Run verifier.
**How:**
```bash
test -x scripts/audit/verify_tsk_p1_247.sh && bash scripts/audit/verify_tsk_p1_247.sh > evidence/phase1/tsk_p1_247_deterministic_timestamps.json || exit 1
```
**Done when:** Natively generated JSON successfully hits the evidence track.

---

## Verification

```bash
# [ID tsk_p1_247_work_item_04]
test -x scripts/audit/verify_tsk_p1_247.sh && bash scripts/audit/verify_tsk_p1_247.sh > evidence/phase1/tsk_p1_247_deterministic_timestamps.json || exit 1

# [ID tsk_p1_247_work_item_05]
test -f evidence/phase1/tsk_p1_247_deterministic_timestamps.json && cat evidence/phase1/tsk_p1_247_deterministic_timestamps.json | grep "\"status\": \"PASS\"" || exit 1

# [ID tsk_p1_247_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_247_deterministic_timestamps.json`

Required fields:
- `task_id`: "TSK-P1-247"
- `git_sha`: <commit sha>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `verified_python_override`: true
- `verified_track3_parity`: true

---

## Rollback

If this task must be reverted:
1. Revert modifications on `sign_evidence.py`.
2. Delete `pre_ci.sh` global export line.
3. Unpatch the 18 bash files explicitly using git diff reverting.
4. Update status back to 'ready' in `meta.yml`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Overlapping date logic breaks independent CI verification arrays | FAIL / BLOCKED | Strictly enforce default rollback (`date -u`) if ENV=0. |
| Anti-pattern: Silent timestamp modifications | FAIL_REVIEW | Structural validation tests strictly searching target files for unprotected parameters. |
