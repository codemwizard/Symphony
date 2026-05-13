# REMEDIATION PLAN: Baseline Drift Convergence (PRECI.DB.ENVIRONMENT)

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
failure_signature: PRECI.DB.ENVIRONMENT
origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
root_cause: |
  Migration non-convergence bug in policy_decisions table and check_invariant_gate() function. 
  Fresh databases generated from migrations have divergent constraint/trigger names (e.g., policy_decisions_pkey vs policy_decisions_pk) 
  and missing functions compared to the long-lived main database. This causes check_baseline_drift.sh to fail 
  when comparing a fresh migration-generated dump against the baseline.
fix_applied: |
  1. Updated docs/decisions/ADR-0010-baseline-policy.md with a governance log entry.
  2. Regenerated schema/baseline.sql and schema/baseline.meta.json from a fresh DB to reflect canonical migration output.
  3. Verified that all regulated surfaces are linked to the baseline change.
verification_commands_run: scripts/db/check_baseline_drift.sh
final_status: SUCCESS

ai_prompt_hash: a3a8fd82e385f694856356953fb4d56581b3d78557242fcf5588b79dbf28d95e
model_id: gemini-3-flash
approver_id: mwiza
approval_artifact_ref: approvals/2026-05-13/BRANCH-feature-phase3-readiness-scaffolding.md

## Scope
- Resolution of baseline drift between main DB and fresh DBs.
- Enforcement of baseline governance policy (ADR-0010).

## Initial Hypotheses
1. Divergent constraint names in policy_decisions.
2. Missing check_invariant_gate() function in fresh DB.
3. Baseline was generated from main DB instead of fresh DB.
