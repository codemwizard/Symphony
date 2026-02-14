# Remediation Plan: pre_ci parity origin ref + structural gate parity

## Context
- origin_gate_id: GOV-G02
- origin_task_id: TSK-P1-013

## Failure Signature
- failure_signature: `pre_ci` failed before parity checks with ambiguous `origin/main` ref and then diverged from CI-first Rule-1 behavior.

## Reproduction
- repro_command: `scripts/dev/pre_ci.sh`

## Remediation
- Normalize parity-critical base refs to `refs/remotes/origin/main`.
- Run the CI-equivalent Rule-1 gate in `pre_ci` before downstream checks.
- Keep evidence gates fail-closed; add upstream status summary in CI evidence aggregation job.

## Verification
- verification_commands_run:
  - `BASE_REF=refs/remotes/origin/main HEAD_REF=HEAD scripts/audit/enforce_change_rule.sh`
  - `scripts/dev/pre_ci.sh`

## Rollback
- rollback: Revert parity-ref and pre_ci gate-order commits if regression appears in diff-based enforcement scripts.

## Owner
- owner: Supervisor (Codex)

## Ticket
- ticket: FOLLOWUP-P1-PARITY-ORIGIN-REF

## Tests
- tests: change-rule range diff parity validated, remediation gate satisfied by this casefile pair.

## Final Status
- final_status: in_progress
