- Tiered autonomy matched to risk:
  - Tier 1: invariant-constrained (schema/security/compliance)
  - Tier 2: contract-guided (APIs/service boundaries)
  - Tier 3: pattern-based (internal utilities/business logic)
- Task format shifts from “exact steps” to “mission + constraints + success criteria”.
- More explicit agent freedom, plus “forbidden approaches”.
- Better feedback loops and parallelization for implementation-heavy Phase-1 work.

## What the Repo Does Today (Phase-0 Audit and Recording)

The repo’s Phase-0 discipline is built around mechanical enforcement and evidence:
- Hard constraints and agent scopes: `AGENTS.md`
- Task contract model (human + machine):
  - `docs/operations/TASK_CREATION_PROCESS.md`
  - `tasks/<TASK_ID>/meta.yml`
  - `docs/plans/phase0/<task-folder>/{PLAN.md,EXEC_LOG.md}`
- Proof over prose:
  - Required gates/scripts are registered: `docs/control_planes/CONTROL_PLANES.yml`
  - CI executes those gates: `.github/workflows/invariants.yml`
  - Evidence artifacts are emitted: `evidence/phase0/*.json`
- Fix discipline (audit trace for production-affecting changes):
  - Workflow and requirements: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
  - Enforcement: `scripts/audit/verify_remediation_trace.sh`

This makes Phase-0 changes deterministic and auditable, but can be expensive to apply to application/runtime work if tasks are written as “exact edits”.

## Side-by-Side Comparison

### Control Philosophy

Phase-1 strategy:
- “Outcome-focused tasks, bounded autonomy.”

Repo Phase-0 process:
- “Mechanically verifiable tasks, evidence-based completion.”

Compatible if:
- Phase-1 missions are treated as tasks with explicit verification and evidence, not as narrative-only work.

### Task Shape

Phase-1 strategy tasks:
- Mission
- Non-negotiable contract/invariants
- Constraints
- Success criteria (tests + gates)
- Agent freedom (choose implementation)
- Forbidden approaches

Repo Phase-0 tasks:
- Machine meta: `tasks/<TASK_ID>/meta.yml`
- Casefile: `docs/plans/phase0/.../PLAN.md` and `EXEC_LOG.md`
- Verification commands and evidence artifacts required for “completed”.

Mapping (recommended):
- Phase-1 “MISSION.md” content becomes the `PLAN.md` for the task, but keep:
  - explicit `verification_commands`
  - declared `evidence_artifacts`
  - evidence emission wired into CI

### Enforcement and Auditability

Phase-1 strategy:
- Mentions evidence and gates, but is not explicit about the repo’s remediation-trace requirement and “watch-the-watcher” rules.

Repo Phase-0:
- Production-affecting changes require remediation casefiles (`REM-*`) or task casefiles with required markers.
- Gate scripts are themselves linted for bypass patterns (e.g., `|| true`, `2>/dev/null`) by the evidence harness integrity gate.

Delta:
- Phase-1 strategy should explicitly incorporate:
  - remediation-trace as mandatory for production-affecting changes
  - evidence harness integrity as a non-bypass control over gate scripts

### Parallelization and Feedback Loops

Phase-1 strategy:
- Encourages parallelizable tasks and explicit iteration (“try alternative approach”).

Repo Phase-0:
- Parallelization exists at execution-time (scripts) but the task model tends toward serial, over-specified work.

Suggested adaptation:
- Keep dependencies explicit in `tasks/<TASK_ID>/meta.yml`, but allow “implementation choice” within the task so the agent can iterate without requiring task rewrites for minor changes.

## Gaps to Close If Adopting Phase-1 Strategy

If the repo adopts Tier 1/2/3 autonomy in Phase-1, the following should be explicitly documented so the audit trail remains intact:
- A single canonical statement of “what counts as completion” for each tier:
  - Tier 1: must have an invariant + gate + evidence + CI wiring
  - Tier 2: must have contract tests + integration evidence + CI wiring
  - Tier 3: must have unit tests + lint/static checks + CI wiring
- How mission-style tasks translate into:
  - `tasks/<TASK_ID>/meta.yml`
  - `docs/plans/<phase>/<TASK>/PLAN.md` + `EXEC_LOG.md`
- Mandatory remediation trace markers for all production-affecting fixes (carry Phase-0 discipline forward).

## Concrete “Bridge” Recommendation

Adopt Phase-1’s task format, but keep Phase-0’s enforcement primitives:
- Keep the “tiered autonomy” decision in task meta as a field or convention (Tier 1/2/3).
- Require every task to state:
  - which gates must pass
  - which evidence files must be emitted
  - which tests are authoritative (unit/integration)
- Keep remediation-trace mandatory for production-affecting changes regardless of tier.

This preserves Tier-1 auditability while allowing Phase-1 velocity.
