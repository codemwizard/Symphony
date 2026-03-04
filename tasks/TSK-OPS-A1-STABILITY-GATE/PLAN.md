# TSK-OPS-A1-STABILITY-GATE PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-OPS-A1-STABILITY-GATE

- task_id: TSK-OPS-A1-STABILITY-GATE
- title: Program A1 Stability Gate
- phase: Hardening
- wave: 1
- depends_on: none  [runs in parallel; must pass before any runtime hardening task
  is marked done]
- goal: Enforce program-level A1 stability: k8s manifests valid, sandbox deploy
  dry-run passes. This gate is a precondition for all Wave-1 runtime tasks
  (TSK-HARD-012 through TSK-HARD-013B). It does not depend on those tasks; rather,
  those tasks depend on it.
- required_deliverables:
  - scripts/audit/verify_program_a1_stability_gate.sh
  - evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
  - evidence/phase1/program_a1_stability_gate.json
  - evidence/phase1/sandbox_deploy_dry_run.json
- verifier_command: bash scripts/audit/verify_program_a1_stability_gate.sh
- evidence_path: evidence/phase1/program_a1_stability_gate.json
- schema_path: evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
- acceptance_assertions:
  - evidence/phase1/k8s_manifests_validation.json exists and pass=true
  - evidence/phase1/sandbox_deploy_dry_run.json exists and contains all required
    fields: task_id, git_sha, namespace, images, migration_job_ran,
    services_ready, timestamp_utc, pass
  - sandbox_deploy_dry_run.json validates against
    evidence/schemas/hardening/sandbox_deploy_dry_run.schema.json
  - verify_program_a1_stability_gate.sh exits non-zero if either input is missing
    or pass=false
- failure_modes:
  - k8s_manifests_validation.json missing or pass=false => FAIL_CLOSED
  - sandbox_deploy_dry_run.json missing required fields => FAIL
  - schema not registered => FAIL

---
