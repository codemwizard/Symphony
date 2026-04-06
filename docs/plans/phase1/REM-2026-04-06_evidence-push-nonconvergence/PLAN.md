# REM-2026-04-06_evidence-push-nonconvergence — REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.EVIDENCE.NONCONVERGENCE.PRE_PUSH
origin_gate_id: pre_ci.pre_push
repro_command: git push
verification_commands_run: pending
final_status: OPEN

## DRD Identity

- Template: DRD Full
- Incident Class: Systemic non-convergence
- Severity: L3
- Status: PLAN
- Owner: Security Guardian
- Branch: fix/demo-updates-and-evidence
- Phase Key: EVPUSHFIX
- Phase Name: Evidence Push Fixed-Point Recovery
- First Failing Signal: git push aborted because pre_ci rewrites tracked evidence after commit

## Problem Statement

The repository does not converge on a clean tracked-file state under the
pre-push hook. `scripts/dev/pre_ci.sh` still rewrites tracked evidence after a
commit, so push aborts locally before any network transfer completes. Remaining
drift surfaces include stale deterministic evidence, branch-diff-sensitive
governance evidence, and validation outputs that still reflect unstable runtime
or inventory state. The current parity proof is also incomplete because the repo
does not yet have an accepted end-to-end commit-between-runs verifier for the
real pre-push scenario.

## Root-Cause Buckets

1. Stale committed evidence does not match the current deterministic generators.
2. Some governance evidence still carries diff-sensitive or runtime-sensitive fields.
3. Validation and schema-validation outputs still expose unstable inventory payloads.
4. `scripts/security/lint_dotnet_quality.sh` can prevent reliable terminal-state regeneration.
5. There is no accepted verifier proving `commit -> pre_ci -> clean tree` end to end.

## Remediation Tasks

- `TSK-P1-250` stabilizes the `lint_dotnet_quality.sh` terminal state and evidence shape.
- `TSK-P1-251` stabilizes `remediation_trace.json` against changed-file churn.
- `TSK-P1-252` stabilizes `human_governance_review_signoff.json` against reviewed-file drift.
- `TSK-P1-253` stabilizes validation-family evidence outputs.
- `TSK-P1-254` rebaselines stale deterministic evidence after producers are stable.
- `TSK-P1-255` proves end-to-end fixed-point convergence with the commit-between-runs protocol.

## Stop Condition

The remediation closes only when all of the following are true:

- `bash scripts/dev/pre_ci.sh` completes successfully.
- `git status --porcelain` is clean immediately after `pre_ci`.
- A commit-between-runs verifier proves `git diff evidence/` is empty.
- `git push` succeeds without hook-generated tracked-file drift.

## Verification Strategy

- Create the task packs first and pass task-pack governance gates.
- Implement `TSK-P1-250`, `TSK-P1-251`, and `TSK-P1-252` before validation and rebaseline work.
- Implement `TSK-P1-253` to remove unstable validation inventories.
- Implement `TSK-P1-254` only after the evidence producers above are stable.
- Implement `TSK-P1-255` last and require the commit-between-runs protocol.
