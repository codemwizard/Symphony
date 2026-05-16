# FAILURE_COMPOSITION_TAXONOMY.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal failure terminology in Phase 3 planning
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This taxonomy defines the failure categories and composition rules Phase 3 must
use when legitimacy, authority, contradiction, replay, spatial, or evidence
checks fail. It prevents implementation tasks from generating opaque, improvised,
or non-replayable failure language.

---

## 1. Failure Record Requirements

Every persisted Phase 3 failure must be:

- machine-readable;
- append-only;
- source-linked to the records evaluated;
- linked to the governing doctrine;
- linked to the projection universe when applicable;
- explicit about severity, blocked operation, and proof limitations;
- replayable from persisted inputs.

Opaque error text is permitted only as supplemental human-readable detail. It is
not the authoritative failure representation.

---

## 2. Failure Categories

| Category | Meaning |
|---|---|
| `dependency_missing` | Required upstream dependency is absent or not replay-addressable. |
| `dependency_illegitimate` | Upstream dependency exists but has a blocking legitimacy finding. |
| `authority_scope_violation` | Claimed authority does not govern the act, resource, time, or context. |
| `delegation_invalid` | Delegation chain is absent, expired, revoked, non-delegable, or out of scope. |
| `contradiction_detected` | A defined contradiction class applies. |
| `policy_artifact_invalid` | Required policy artifact is missing, expired, superseded without lineage, or not versioned. |
| `projection_context_invalid` | Projection universe inputs are missing, ambiguous, contaminated, or cross-universe. |
| `replay_reconstruction_failed` | Historical reconstruction cannot be reproduced from persisted canonical inputs. |
| `spatial_constraint_violation` | Mechanical spatial rule fails under governing spatial doctrine. |
| `verifier_independence_violation` | Verifier, submitter, beneficiary, or authority roles are not structurally independent. |
| `evidence_lineage_break` | Required provenance or evidentiary lineage is missing or inconsistent. |
| `phase_scope_violation` | Proposed work or operation belongs outside Phase 3. |
| `doctrine_gap_blocker` | Governing doctrine required for implementation does not exist or is insufficient. |

No implementation task may add a failure category without amending this taxonomy.

---

## 3. Failure Composition

Failures may be composed when one failed finding depends on another. Composition
must preserve the dependency structure instead of flattening failures into a
single message.

Composition rules:

1. A root failure is the earliest replay-visible failure that independently
   blocks the evaluated act.
2. A derived failure depends on one or more root or intermediate failures.
3. A failure tree must remain traversable from the final rejection to each
   source record and doctrine.
4. Multiple independent root failures must be preserved as siblings.
5. A later correction must append a compensating or superseding failure-lineage
   record; it must not delete the original failure.

---

## 4. Severity Classes

| Severity | Meaning |
|---|---|
| `blocking` | Operation must fail closed. |
| `quarantine` | Source records are preserved but not relied on pending resolution. |
| `escalation_required` | Doctrine or authority resolution is required before implementation or operation. |
| `warning_non_blocking` | Finding is replay-visible but does not block under governing doctrine. |

Warning severity may be used only when governing doctrine explicitly permits
non-blocking handling.

---

## Task-Generation Rule

Every Phase 3 task that can reject, block, quarantine, or escalate an operation
must declare which failure categories and severity classes it may emit. If the
needed category is absent, task creation is blocked pending taxonomy amendment.

---

## Prohibited Misinterpretations

**PM-FCT-01 - Error Text as Authority:** Human-readable error text is not the
authoritative failure record.

**PM-FCT-02 - Flattened Failure:** A composed failure must not hide its root
failure lineage.

**PM-FCT-03 - Warning by Default:** Non-blocking warnings require explicit
doctrine authorization.

**PM-FCT-04 - New Failure by Implementation:** Tasks must not invent failure
categories locally.

