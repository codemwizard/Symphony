# TSK-P3-CAP-012 Phase 3 Activation And Alignment Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-012
Execution-Surface: P3-SURF-000
DAG-Nodes: TSK-P3-ACT-001 through TSK-P3-ACT-005
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/operations/PHASE_EXECUTION_ENVELOPE.md
  - docs/operations/PHASE_LIFECYCLE.md
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md
Ownership-Binding:
  constitutional_owner: docs/operations/PHASE_EXECUTION_ENVELOPE.md
  verifier_owner: scripts/audit/verify_phase3_contract.sh
  policy_owner: docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md
Replay-Criticality: operational-exhaust
State-Mutability: derived-cache
Ontology-Classification: projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: preserved

---

## Purpose

This document is the surface-specific implementation plan for the Phase 3
activation and governance-alignment sweep on `P3-SURF-000`. It defines the
planning work needed to make Phase 3 the active execution phase without leaving
the lifecycle, legality, envelope, and evidence layers in contradiction.

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
approval artifacts, evidence files, migrations, or runtime implementation.

## Activation Preconditions

Phase 3 activation is blocked until the repo's lifecycle-required opening set is
complete and internally aligned.

The minimum required activation prerequisites are:

- `docs/PHASE3/PHASE3_CONTRACT.md`
- `docs/PHASE3/phase3_contract.yml`
- `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`
- `scripts/audit/verify_phase3_contract.sh`
- `approvals/YYYY-MM-DD/PHASE3-OPENING.md`
- `approvals/YYYY-MM-DD/PHASE3-OPENING.approval.json`

`docs/PHASE3/PHASE3_OPENING_ACT.md` is an input to Phase 3 activation, but it
is not a substitute for the lifecycle-required opening approval artifact set.

## Sequencing Rule

`depends_on` and `blocked_by` are separate fields.

- `depends_on` defines the structural DAG order. These are normal predecessor
  tasks that must be completed before the current task can start.
- `blocked_by` defines active impediments, root gates, governance conflicts,
  missing doctrine, failed readiness checks, or remediation blockers.
- `blocked_by` must not duplicate normal predecessors already listed in
  `depends_on`.
- The activation sweep begins only after the existing Wave 0 governance cleanup
  is treated as complete in the Phase 3 planning corpus.

## Activation Sequence

| Node | Direct `depends_on` | Active `blocked_by` | Sequencing Note |
|---|---|---|---|
| TSK-P3-ACT-001 | TSK-P3-CLEAN-001 through TSK-P3-CLEAN-008 | None | Build the missing Phase 3 lifecycle artifact set. |
| TSK-P3-ACT-002 | TSK-P3-ACT-001 | None | Create the formal Phase 3 opening approval artifact set. |
| TSK-P3-ACT-003 | TSK-P3-ACT-001, TSK-P3-ACT-002 | None | Rewrite the root execution envelope to name Phase 3 as active. |
| TSK-P3-ACT-004 | TSK-P3-ACT-003 | None | Reconcile the legality layer and dependent Phase 3 planning posture. |
| TSK-P3-ACT-005 | TSK-P3-ACT-004 | None | Classify or regenerate existing Phase 3 plans and evidence for opened-phase use. |

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode. Atomic task packs
must be generated with `scripts/agent/generate_task_pack.py` and must satisfy
`docs/operations/TASK_CREATION_PROCESS.md`, including proof-graph alignment,
evidence contracts, failure modes, stop conditions, and readiness verification.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| TSK-P3-ACT-001 | Build the missing Phase 3 lifecycle artifact set | 3 | `docs/PHASE3/PHASE3_CONTRACT.md`, `docs/PHASE3/phase3_contract.yml`, `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`, `scripts/audit/verify_phase3_contract.sh` | Human contract, machine contract, policy guard, and verifier all exist and agree on phase name, gate flag, evidence namespace, and status semantics. | Deterministic contract verifier proving the Phase 3 artifact set exists and is internally aligned. | Stop if the task introduces runtime implementation, leaves artifact semantics inconsistent, or skips approval requirements for regulated surfaces. |
| TSK-P3-ACT-002 | Create the formal Phase 3 opening approval artifact set | 3 | `approvals/YYYY-MM-DD/PHASE3-OPENING.md`, `approvals/YYYY-MM-DD/PHASE3-OPENING.approval.json` | Opening approval markdown and sidecar exist, validate against repo approval rules, and cite the exact regulated-surface scope of the activation sweep. | Approval validation check plus a consistency check that the opening set matches the activation scope. | Stop if the artifact set backdates approval, omits regulated surfaces, or claims runtime completion instead of phase opening. |
| TSK-P3-ACT-003 | Rewrite the root execution envelope for active Phase 3 status | 3 | `docs/operations/PHASE_EXECUTION_ENVELOPE.md` | The envelope no longer says Phase 2 is the only legal execution surface, no longer rejects `evidence/phase3/**` solely because Phase 3 is unopened, and names the active Phase 3 execution surface and allowed operations. | Consistency check comparing envelope claims against the lifecycle artifacts, opening approval set, and Phase 3 contract. | Stop if the rewrite leaves Phase 2 closeout claims overstated, contradicts the lifecycle document, or opens non-Phase-3 surfaces implicitly. |
| TSK-P3-ACT-004 | Reconcile legality and dependent planning posture | 3 | `docs/constitutional/PHASE_CAPABILITY_LEGALITY_MATRIX.md`, `docs/PHASE3/README.md`, `docs/PHASE3/PHASE3_SOURCE_PACK.md`, `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md`, `docs/PHASE3/PHASE3_OPENING_ACT.md` | The legality matrix no longer says Phase 3 absence is legally required, and the dependent Phase 3 planning docs no longer describe a planning-only or unresolved-envelope posture. | Static consistency check proving the legality layer and dependent planning docs agree with the updated envelope. | Stop if the task invents new doctrine, mutates future-phase boundaries, or leaves contradictory activation posture across planning docs. |
| TSK-P3-ACT-005 | Normalize existing Phase 3 plans and evidence for opened-phase use | 3 | `docs/plans/phase3/**`, `evidence/phase3/**`, related governance notes as needed | The repo has an explicit rule for whether existing Phase 3 artifacts are ratified as admissible, marked historical/non-authoritative, or required to be regenerated after opening. | Classification check proving no pre-opening Phase 3 artifact can be mistaken for opened-phase delivery proof. | Stop if historical planning evidence is silently treated as admissible opened-phase proof or if classification rules remain implicit. |

## Regulated-Surface Alignment

The future activation tasks touch regulated surfaces. Every generated atomic task
pack must require approval metadata before the first regulated edit.

The minimum regulated targets expected in the activation sweep are:

- `docs/operations/**`
- `scripts/audit/**`
- `approvals/YYYY-MM-DD/**`

## Evidence And Verifier Policy

The activation sweep must use deterministic verifier output rather than
narrative-only proof.

At minimum, the later implementation tasks must define:

- one Phase 3 contract verifier proving the required artifact set exists and is
  internally aligned;
- one activation evidence artifact under `evidence/phase3/**` emitted by a
  verifier rather than hand-authored;
- one explicit classification rule for any pre-opening `evidence/phase3/**`
  artifacts, with the default posture that they are historical or
  non-authoritative unless regenerated under the opened-phase verifier set.

## Atomic Task Handoff Requirements

No activation node may enter `IMPLEMENT-TASK` directly from this plan. The next
step for each eligible node is `CREATE-TASK` mode.

Every generated atomic task pack must include:

- exactly one primary objective;
- direct `depends_on` values from this plan and the DAG;
- active `blocked_by` values only when a live impediment exists;
- `touches` limited to the future task row;
- observable acceptance criteria;
- deterministic verifier commands;
- concrete evidence output paths in the Phase 3 namespace;
- failure mode `Evidence file missing`;
- stop conditions for scope drift, regulated-surface approval gaps, and
  envelope or legality contradictions;
- `must_read` references to `AGENT_ENTRYPOINT.md`,
  `docs/operations/TASK_CREATION_PROCESS.md`,
  `docs/operations/IMPLEMENTATION_PLAN_CREATION_PROCESS.md`, and this plan.

## Readiness Checks For This Plan

This implementation plan is complete when:

- all five `TSK-P3-ACT-00*` nodes are represented;
- the activation prerequisites are listed explicitly;
- the future atomic tasks narrow the touch surfaces and verification
  expectations without implementing them;
- the implementation-plan registry records `TSK-P3-CAP-012`;
- no atomic task pack files are created by this planning step.
