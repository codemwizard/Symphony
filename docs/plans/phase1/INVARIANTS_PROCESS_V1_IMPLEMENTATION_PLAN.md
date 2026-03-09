# Invariants Process v1 Implementation Plan

## Mission
Operationalize the new governance artifacts into a mechanically enforced invariants process that is auditable, CI-gated, and regulator-pack ready without changing runtime product scope.

## Scope
- In scope:
  - `docs/governance/invariant-register-v1.md`
  - `docs/governance/ci-gate-spec-v1.md`
  - `docs/governance/regulator-evidence-pack-template-v1.md`
  - invariant/governance parity verifiers
  - CI/pre-CI wiring for governance-drift detection
  - task/index/checklist linkage for operator use
- Out of scope:
  - new business/runtime features
  - rail/provider integration expansion
  - phase taxonomy changes outside canonical lifecycle rules

## Canonical References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/PHASE_LIFECYCLE.md`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `.github/workflows/invariants.yml`
- `scripts/dev/pre_ci.sh`

## Execution Batches
1. Baseline governance and parity contract
   - `TASK-INVPROC-01`
2. Mechanical drift verifiers
   - `TASK-INVPROC-02`
   - `TASK-INVPROC-03`
3. Regulator evidence pack normalization
   - `TASK-INVPROC-04`
4. Operator governance binding (PR/exception/checklist)
   - `TASK-INVPROC-05`
5. CI integration and closeout proof
   - `TASK-INVPROC-06`

## Dependency Graph
- `TASK-INVPROC-01` -> `TASK-INVPROC-02`
- `TASK-INVPROC-01` -> `TASK-INVPROC-03`
- `TASK-INVPROC-01` -> `TASK-INVPROC-04`
- `TASK-INVPROC-01` -> `TASK-INVPROC-05`
- `TASK-INVPROC-02,03,04,05` -> `TASK-INVPROC-06`

## Phase-1 Success Criteria
1. Governance docs are canonical and internally consistent.
2. Drift verifiers fail closed when docs/workflow diverge.
3. Regulator pack template is machine-usable with deterministic artifact references.
4. PR and exception governance are explicitly linked to invariant process.
5. CI/pre-CI include governance drift checks with evidence output.
