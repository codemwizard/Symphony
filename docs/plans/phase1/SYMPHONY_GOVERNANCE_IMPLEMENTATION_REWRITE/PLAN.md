# Symphony Governance Implementation Rewrite (Execution-Ready)

Date: 2026-03-07
Status: Execution-ready
Scope: Rewrite of tasks/plans previously captured in `Symphony_Governance_Implementation_Plan.docx`

## Canonical Clarifications Applied

1. Status semantics:
- "Resolution Implemented" is treated as: `Content landed; governance completion pending`.
- No task is closed until branch remediation, approvals, verifier pass, and evidence artifacts are complete.

2. Precedence rule (domain-canonical refinement):
- Rank order resolves broad authority conflicts.
- Domain-canonical documents own their scoped rules and must be referenced, not restated.
- Examples: lifecycle taxonomy (`PHASE_LIFECYCLE.md`), remediation trace thresholds (`REMEDIATION_TRACE_WORKFLOW.md`), git format (`GIT_CONVENTIONS.md`).

3. DRD trigger correction:
- DRD is required when thresholds fire on severity axis **or** time/attempt axis.
- A task may require Change Trace only, DRD only, or both.

4. Plan path mapping:
- `lifecycle_phase: '1'` maps to `docs/plans/phase1/<TASK_ID>/...`
- `lifecycle_phase: '0'` maps to `docs/plans/phase0/<TASK_ID>/...`

5. Verification semantics correction:
- String checks for forbidden tokens are scoped to normative/allowlist sections, not explanatory sections.

6. Branch remediation handling:
- Work previously landed on `main` is treated as governance-invalid until re-established via proper branch/task/approval flow.
- This rewrite defines the corrective task set and evidence model; merge strategy (revert vs supersede) must be explicitly approved per task.

## Execution Batches

### Batch A: Branch and Approval Remediation
- TASK-OI-01
- TASK-OI-03
- TASK-OI-08
- TASK-OI-09

### Batch B: Retroactive Governance Task Scaffolds
- TASK-GOV-C1
- TASK-GOV-C2C3
- TASK-GOV-C4O4
- TASK-GOV-C5
- TASK-GOV-C6
- TASK-GOV-C7
- TASK-GOV-O1
- TASK-GOV-O2
- TASK-GOV-O3
- TASK-INV-134
- TASK-OI-02
- TASK-OI-11

### Batch C: Net-New Enforcement Work
- TASK-OI-04
- TASK-OI-05
- TASK-OI-06
- TASK-OI-07

### Batch D: Human Assurance and Closeout
- TASK-OI-10

## Definition of Done (Governance Rewrite)

A task is complete only when all are true:
1. `meta.yml`, `PLAN.md`, and `EXEC_LOG.md` exist and are non-empty.
2. Stage-A approval artifacts exist for branch work on regulated paths.
3. Task verification commands pass.
4. Declared evidence artifacts exist and are non-empty.
5. Task is indexed in the phase task list used by the executing workflow.
6. Human review sign-off exists for regulated-surface changes.
