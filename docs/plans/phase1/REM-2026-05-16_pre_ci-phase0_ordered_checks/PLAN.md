# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.AUDIT.GATES

origin_gate_id: pre_ci.phase0_ordered_checks
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: PRE_CI_CONTEXT=1 bash scripts/audit/verify_agent_conformance.sh; SYMPHONY_ENV=development PRE_CI_CONTEXT=1 scripts/security/lint_dotnet_quality.sh; PRE_CI_CONTEXT=1 bash scripts/audit/verify_human_governance_review_signoff.sh; bash scripts/audit/verify_phase_claim_admissibility.sh; bash scripts/audit/verify_drd_casefile.sh --clear; scripts/dev/pre_ci.sh
final_status: OPEN
root_cause: pre_ci advanced past the Phase 3 PRE scaffold repairs and branch approval-truth remediation, then failed in verify_phase_claim_admissibility.sh because the semantic overclaim scan treated negative-test token strings inside scripts/agent Phase 3 verifier fixtures as live repository claims. This produced false-positive phase-complete overclaims even though no docs or runtime surfaces were asserting completed future-phase delivery.

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Root Cause Analysis
- The original scaffold hypothesis is stale. After implementing the Phase 3 PRE scaffold and re-running the pipeline, `pre_ci.sh` passes governance preflight, strict task schema, YAML conventions, and the earlier Phase 3 readiness-specific repairs.
- The branch approval-truth mismatch was repaired; `verify_human_governance_review_signoff.sh` now passes.
- The current first-fail artifact is `evidence/phase2/phase_claim_admissibility.json`, emitted by `scripts/audit/verify_phase_claim_admissibility.sh` during the Phase-1 DB/environment verifier block in `scripts/dev/pre_ci.sh`.
- The failure is a verifier false positive. The scan counted six "phase complete" matches, all originating from `scripts/agent/verify_tsk_p3_act_002.sh` and `scripts/agent/verify_tsk_p3_act_005.sh`, where prohibited phrases are quoted as verifier tokens rather than asserted as repository claims.

## Remediation Path
- Treat the PRE scaffold as repaired and closed; do not reopen the Phase 3 task metadata work unless a new first-fail artifact proves it is still broken.
- Preserve the repaired branch approval markdown, sidecar JSON, and `evidence/phase1/approval_metadata.json` alignment for `chore/phase3-planning-followup`.
- Narrow `scripts/audit/verify_phase_claim_admissibility.sh` so it excludes `scripts/agent/*.sh` verifier fixtures from semantic claim scanning, matching the existing exclusions for `scripts/audit/*.sh` and task metadata.
- Verify `bash scripts/audit/verify_phase_claim_admissibility.sh`, then re-run `scripts/dev/pre_ci.sh`.
- Clear the DRD lockout by verifying the casefile.
- Re-run `scripts/dev/pre_ci.sh` to confirm pipeline convergence.

## Initial Hypotheses
- rejected: The branch is no longer failing on `scripts/audit/lint_yaml_conventions.sh` or the Phase 3 `wave` metadata.
- rejected: The immediate blocker is not the standalone `.NET` quality lint.
- rejected: The current blocker is no longer the human governance review signoff verifier.
- current: The current blocker is a false-positive phase-complete overclaim in `verify_phase_claim_admissibility.sh` caused by scanning agent-side verifier fixtures as repository claims.
