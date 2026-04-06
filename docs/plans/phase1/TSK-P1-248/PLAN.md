# TSK-P1-248 PLAN — Clamp git_sha and derived fields under deterministic mode

Task: TSK-P1-248
Owner: SECURITY_GUARDIAN
Depends on: TSK-P1-247
failure_signature: PRECI.EVIDENCE.TSK-P1-248.GIT_SHA_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Eliminate the commit-sensitive git identity loop from deterministic evidence.
When deterministic mode is enabled, every evidence producer touched by this task
must emit the zeroed git sha and the clamped pre-CI run id, even after HEAD
changes between two runs.

## Constraints

- Modify only the files listed in `touches`.
- Do not mutate the user's branch history while proving commit-between-runs.
- Use isolated worktree execution for the HEAD-change proof.
- Keep schema_fingerprint content-hash based; it is not part of this task.

## Approval References

- Apex authority: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- Prompt router: `docs/operations/AGENT_PROMPT_ROUTER.md`
- Existing deterministic timestamp prerequisite: `docs/plans/phase1/TSK-P1-247/PLAN.md`

## Implementation Steps

- [ID tsk_p1_248_work_item_01] Verify the shared helper and Python signer clamp git sha under deterministic mode.
- [ID tsk_p1_248_work_item_02] Verify pre_ci exports the clamped deterministic run id.
- [ID tsk_p1_248_work_item_03] Replace the placeholder verifier with an isolated worktree proof that changes HEAD between runs.
- [ID tsk_p1_248_work_item_04] Emit evidence recording the before/after outputs and equality checks.

## Verification Commands

```bash
# [ID tsk_p1_248_work_item_01] [ID tsk_p1_248_work_item_02] [ID tsk_p1_248_work_item_03] [ID tsk_p1_248_work_item_04] [ID tsk_p1_248_work_item_05]
bash scripts/audit/verify_tsk_p1_248.sh
# [ID tsk_p1_248_work_item_05]
python3 scripts/audit/validate_evidence.py --task TSK-P1-248 --evidence evidence/phase1/tsk_p1_248_git_sha_clamp.json
# [ID tsk_p1_248_work_item_01] [ID tsk_p1_248_work_item_02] [ID tsk_p1_248_work_item_03]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

## Evidence Paths

- `evidence/phase1/tsk_p1_248_git_sha_clamp.json`
