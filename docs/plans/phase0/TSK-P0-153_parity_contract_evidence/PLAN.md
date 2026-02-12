# Implementation Plan (TSK-P0-153)

failure_signature: CI.LOCAL_CONTRACT_EVIDENCE_PARITY
origin_task_id: TSK-P0-153
first_observed_utc: 2026-02-12T15:00:00Z

## Goal
Eliminate any divergence between the local `scripts/dev/pre_ci.sh` run and the CI pipeline so that the Phase-0 contract evidence status check is executed under identical preconditions, inputs, and environment variables from start to finish. The parity must span script order, environment flags, evidence artifacts, and success/failure behavior.

## Discovery
- CI runs `.github/workflows/invariants.yml`, which executes `scripts/audit/run_phase0_ordered_checks.sh`, gathers evidence, then runs `scripts/audit/verify_phase0_contract_evidence_status.sh` (via downstream job) with `CI_ONLY=1`/`EVIDENCE_ROOT="evidence/phase0"`. There is no `SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS` in CI.
- Locally, `scripts/audit/run_phase0_ordered_checks.sh` exports `SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1` before invoking the contract check, and `scripts/dev/pre_ci.sh` never runs the contract check explicitly.
- As a result, CI can fail due to missing GOV-G02 evidence that the local run never exercises.

## Scope
- Align the local scripts with CI end-to-end: script ordering, environment variables, and gate execution must be identical. No local skip flags may exist. Document the parity requirements and demonstrate they hold for the full pipeline.
- Ensure the same evidence artifacts (OpenBao bootstrap, security lints, Phase-0 evidence JSONs) are generated in pre-CI as CI produces.
- Provide an audit trail (plan/log + update to `docs/PHASE0/PHASE0_CONTRACT_EVIDENCE_STATUS_PLAN.md`) describing the parity verification steps.

## Tasks
1. Remove `SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS` export from `scripts/audit/run_phase0_ordered_checks.sh` so the contract check executes regardless of environment. Document the failure scenario when evidence is missing. 
2. Update `scripts/dev/pre_ci.sh` to run `CI_ONLY=1 EVIDENCE_ROOT="evidence/phase0" scripts/audit/verify_phase0_contract_evidence_status.sh` after the ordered checks and fail if it reports errors; capture the command, env vars, and required artifacts. 
3. Produce a parity checklist (new section in `docs/PHASE0/PHASE0_CONTRACT_EVIDENCE_STATUS_PLAN.md` or similar) that enumerates every script/step, the env vars/flags they receive, and the evidence files they generate so reviewers can confirm nothing differs from CI.
4. Add a short verification script or section in `scripts/dev/pre_ci.sh` that copies/aggregates evidence files into `evidence/phase0` exactly as CI does before running the contract check.
5. Link all changes back to the new plan/log and `tasks/TSK-P0-153/meta.yml` so the remediation trace gate sees this work.

## Acceptance Criteria
- Local ordered checks no longer skip the contract evidence status check; both pre-CI and CI run the same script with identical environment settings.
- `scripts/dev/pre_ci.sh` calls `CI_ONLY=1 EVIDENCE_ROOT="evidence/phase0" scripts/audit/verify_phase0_contract_evidence_status.sh` and exits non-zero when that check fails.
- The parity checklist documents every script invoked in CI (`run_phase0_ordered_checks.sh`, `verify_phase0_contract_evidence_status.sh`, remediation trace gate, etc.), the env vars they use, and how evidence is aggregated locally to match CI.
- New plan/log entries reference this parity work and the verification commands executed.

## Verification Commands
- `bash scripts/dev/pre_ci.sh`
- `CI_ONLY=1 EVIDENCE_ROOT="evidence/phase0" scripts/audit/verify_phase0_contract_evidence_status.sh` (run independently if desired)

verification_commands_run:
- bash scripts/dev/pre_ci.sh

final_status: OPEN
