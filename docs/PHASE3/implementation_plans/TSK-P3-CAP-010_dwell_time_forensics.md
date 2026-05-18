# TSK-P3-CAP-010 Dwell-Time Forensic Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-010
Execution-Surface: P3-SURF-010
DAG-Nodes: TSK-P3-WP-010
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  replay_owner: docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  verifier_owner: scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh
  persistence_owner: future Phase 3 temporal forensic records
Replay-Criticality: projection-state
State-Mutability: supersedable-projection
Ontology-Classification: admissibility-projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: operational workflow timers route to Phase 6 if user-facing; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-010` — the Dwell-Time Forensic Surface.

It refines the Wave 4 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-010`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-010` owns replay-derived dwell-time forensic reconstruction for Phase
3. The surface must establish:

- deterministic temporal anomaly reconstruction from persisted constitutional
  records and declared temporal policy inputs;
- supersedable forensic projections that flag or block dwell-time anomalies
  without retroactively mutating historical records;
- forensic outputs that remain reconstructable from historical truth and replay
  lineage;
- temporal anomaly enforcement that remains distinct from contradiction
  taxonomy, failure taxonomy, and user-facing workflow timers.

Dwell-time findings may be diagnostic or admissibility-relevant, but in all
cases remain replay-derived supersedable projections rather than historical
truth.

This surface does **not** own:

- retroactive mutation of pre-Phase-3 records;
- statutory time-limit meaning not declared by doctrine;
- contradiction class ownership;
- failure composition taxonomy ownership;
- regulator routing semantics;
- user-facing workflow timers or orchestration.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-010` | `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | Dwell-time forensics must remain replay-derived temporal reconstruction over historical truth and may use only declared temporal policy inputs. |

If later planning cannot map a `P3-SURF-010` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-010` becomes runnable only after `TSK-P3-WP-003`,
  `TSK-P3-WP-004`, and `TSK-P3-WP-005` are complete; it does not unlock its
  predecessors.
- `TSK-P3-WP-010` must consume projection, contradiction, and failure outputs
  as already-declared replay substrates; it may not reinterpret their
  semantics locally.
- This surface does not co-own `TSK-P3-SUPPORT-OBS-001` or
  `TSK-P3-SUPPORT-PERF-001` in the current master plan. Any later visibility or
  scale requirements must be consumed through already-owned shared support
  rather than inventing a new Wave 4 support slice here.
- Temporal reconstruction may not depend on wall-clock runtime state,
  in-memory-only timers, or undeclared orchestration identifiers.

## Wave 4 Obligations Bound To This Surface

The following Wave 4 obligations apply directly to `P3-SURF-010` planning:

- dwell-time forensics must remain deterministic and replay-derived;
- historical truth must remain append-only and temporally reconstructed rather
  than rewritten;
- temporal policy thresholds must be treated as declared inputs, not local
  semantic invention;
- changes to declared temporal policy thresholds may supersede prior findings
  prospectively but must never invalidate historical reconstruction of earlier
  findings;
- this surface must not absorb contradiction ownership, failure taxonomy
  ownership, regulator routing, or user-facing timer workflow.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-010` | Dwell-time forensic findings under temporal replay doctrine | 3 | runtime/db/interfaces declared later by task pack; temporal docs; verifier references | Dwell-time forensic reconstruction is deterministic, replay-derived, and grounded only in persisted historical truth plus declared temporal policy inputs. | Deterministic verifier path must ultimately align with `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` and declared Phase 3 evidence. | Stop if the task rewrites historical records, depends on wall-clock runtime state beyond declared inputs, or expands into user-facing workflow-timer semantics. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-003`, `TSK-P3-CAP-004`, and `TSK-P3-CAP-005` exist and Wave 2
  and Wave 3 substrate anchoring is explicit;
- the future task pack stays within the exact node scope;
- deterministic verifier expectations and declared temporal-policy inputs are
  explicit;
- the task pack cites this plan, the Wave 4 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-010` is refined without absorbing contradiction, failure, or
  workflow-timer ownership;
- temporal replay, historical truth primacy, and declared-policy-input
  constraints are bound to the correct node;
- the lack of direct Wave 4 support-node ownership for this surface is explicit
  rather than silently expanded;
- no atomic task pack files are created by this planning step.
