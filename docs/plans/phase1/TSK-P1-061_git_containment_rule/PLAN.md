# TSK-P1-061 Plan

Failure_Signature: PHASE1.GIT.CONTAINMENT.RULE.MISSING
Origin_Task_ID: TSK-P1-061

## Mission
Codify the repository-wide Git containment rule for fixtures and scripts that mutate Git state.

## Constraints
- No new mutable Git fixture may rely on `git -C` alone for containment.
- Canonical references must remain anchored to `docs/operations/AI_AGENT_OPERATION_MANUAL.md`.

## Verification Commands
- `rg -n "Git containment|GIT_DIR|GIT_WORK_TREE|repository identity" docs/audits/FORENSIC_REPORT_DIFF_PARITY_FIXTURE_2026-03-09.md docs/tasks/PHASE1_SECURITY_AND_GIT_CONTAINMENT_REMEDIATION_2026-03-09.md docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `bash scripts/audit/run_invariants_fast_checks.sh`

## Repro_Command
- `bash scripts/audit/test_diff_semantics_parity.sh`
- `bash scripts/audit/test_diff_semantics_parity_hostile_env.sh`

## Evidence Paths
- `evidence/phase1/agent_conformance_architect.json`
- `evidence/phase1/agent_conformance_implementer.json`
- `evidence/phase1/agent_conformance_policy_guardian.json`
