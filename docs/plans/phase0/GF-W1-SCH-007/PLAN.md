# GF-W1-SCH-007 PLAN — Phase 0 schema closeout verifier wiring

Task: GF-W1-SCH-007
Owner: DB_FOUNDATION
Depends on: GF-W1-SCH-006
failure_signature: PH0.DB.GF_W1_SCH_007.CLOSEOUT_WIRING_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Wire all Green Finance Phase 0 schema verifiers into a single aggregated closeout
verifier and confirm the script exists, exits cleanly on a correct schema state,
and is referenced from CI. No migration SQL is introduced by this task.

Done means a single `scripts/db/verify_gf_schema_closeout.sh` exists that
invokes all prior GF schema verifiers (002A through 006) and exits non-zero if
any fails. The script is wired into the pre-CI gate for Phase 0 GF tasks, and
an evidence artifact is emitted confirming all wiring checks pass.

---

## Architectural Context

The closeout task is the integration gate for the entire Wave 4 schema chain. It
does not own any tables or functions — it aggregates the individual task
verifiers to confirm the complete schema graph is valid before Wave 5 begins.
CI wiring ensures this gate cannot be bypassed in automated workflows.

---

## Pre-conditions

- [ ] `GF-W1-SCH-006` is completed and validated.
- [ ] All GF schema verifier scripts (002A through 006) exist and pass.
- [ ] Approval metadata exists for regulated-surface changes (CI wiring touches `.github/workflows/`).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_gf_schema_closeout.sh` | CREATE | Aggregated GF schema closeout verifier |
| `evidence/phase0/gf_schema_closeout.json` | CREATE | Proof artifact |
| `tasks/GF-W1-SCH-007/meta.yml` | CREATE | Task contract |

---

## Stop Conditions

- **If this task creates any migration SQL** -> STOP (this is CI wiring only)
- **If the closeout verifier bypasses any of the prior 5 GF schema verifiers** -> STOP
- **If verification cannot confirm all individual verifiers exit cleanly** -> STOP

---

## Governed Objects

No tables or functions created. The only governed artifacts are:
- `scripts/db/verify_gf_schema_closeout.sh` (new script)
- `evidence/phase0/gf_schema_closeout.json` (evidence output)

---

## Implementation Steps

### Step 1: Create aggregated closeout verifier
**What:** `[ID gf_w1_sch_007_work_item_01]` Add `scripts/db/verify_gf_schema_closeout.sh`.
**How:** Script invokes each prior verifier in DAG order (002A, 003, 004, 005, 006) and halts on first failure. Emits `evidence/phase0/gf_schema_closeout.json` with `run_id`.
**Done when:** Script exits 0 when all prior verifiers pass; exits non-zero when any fails.

### Step 2: Emit evidence
**What:** `[ID gf_w1_sch_007_work_item_02]` Evidence artifact confirms all wiring.
**How:** Run the closeout verifier and persist bounded proof with `run_id` from `$SYMPHONY_RUN_ID`.
**Done when:** Evidence file exists with the declared contract.

---

## Verification

```bash
# [ID gf_w1_sch_007_work_item_01] [ID gf_w1_sch_007_work_item_02]
bash scripts/db/verify_gf_schema_closeout.sh || exit 1

test -f evidence/phase0/gf_schema_closeout.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase0/gf_schema_closeout.json`

Required fields:
- `task_id`: `GF-W1-SCH-007`
- `run_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `verifiers_invoked`
- `all_verifiers_pass`
- `checks`

---

## Rollback

If this task must be reverted:
1. Remove `scripts/db/verify_gf_schema_closeout.sh`.
2. Update task status back to `ready` and record in `EXEC_LOG.md`.
3. No migration rollback needed (this task has no migration).

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Closeout verifier skips a prior verifier | AUDIT_FAIL | List all verifiers explicitly; fail if any are missing |
| Evidence emitted without run_id | RUNNER_FAIL | Read $SYMPHONY_RUN_ID before emitting |

---

## Approval (for regulated surfaces)

- [x] Approval metadata artifact exists at: `evidence/phase1/approval_metadata.json`
- [x] Approved by: `0001`
- [x] Approval timestamp: `2026-03-27T03:24:04Z`
