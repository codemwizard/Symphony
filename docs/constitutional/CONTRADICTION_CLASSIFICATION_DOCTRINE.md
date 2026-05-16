# CONTRADICTION_CLASSIFICATION_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal contradiction categories in Phase 3 planning
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md

---

## Purpose

This doctrine defines the Phase 3 contradiction classification model and the
permitted handling outcomes for contradiction findings. It allows Phase 3 to
detect, block, quarantine, and record contradictions without inventing policy
meaning or mutating historical truth.

---

## 1. Contradiction Definition

A contradiction exists when two or more replay-addressable records, findings, or
policy artifacts cannot all be applied as authoritative within the same declared
projection universe, authority scope, resource scope, and temporal context.

Contradiction classification must preserve:

- source record identifiers;
- projection universe;
- authority lineage;
- policy artifact lineage;
- temporal context;
- affected resource or decision class;
- proof limitation.

---

## 2. Contradiction Classes

Phase 3 recognizes these contradiction classes:

| Class | Definition | Phase 3 Handling |
|---|---|---|
| Direct contradiction | Two records assert incompatible facts for the same resource and temporal context. | Block, quarantine, or escalate under governing doctrine. |
| Temporal contradiction | A later or earlier record conflicts with the valid effective-time interval of another record. | Evaluate under temporal doctrine and append finding. |
| Authority-scope contradiction | Two findings conflict because at least one authority lineage may not govern the act or resource. | Validate authority lineage and block out-of-scope claims. |
| Policy-precedence contradiction | Two policy artifacts apply incompatible rules to the same act within the same projection universe. | Apply declared precedence rule or block if absent. |
| Regulator-domain contradiction | Findings from different regulator domains are incompatible when compared for a cross-domain purpose. | Preserve non-collapse; escalate unless cross-domain doctrine governs. |
| Evidence-lineage contradiction | Required evidence lineage is missing, broken, unverifiable, or inconsistent with the claimed finding. | Fail closed and append failure composition. |
| Projection-context contradiction | A derived result is used outside the projection universe that produced it. | Reject cross-universe contamination. |

No additional contradiction class may be introduced by an implementation task
without a doctrine update.

---

## 3. Permitted Outcomes

Contradiction detection may produce only these outcome classes:

- `blocked`: the proposed operation must not proceed;
- `quarantined`: the records are preserved but excluded from reliance pending
  resolution;
- `superseded`: an explicit supersession chain controls future reliance while
  preserving historical validity;
- `compensating_lineage_required`: a correction or explanatory lineage record is
  required before reliance;
- `arbitration_escalated`: governing doctrine is insufficient and human or
  regulator arbitration is required;
- `no_contradiction`: inputs are compatible within the declared context.

The outcome is a new append-only finding. It does not erase the records that
created the contradiction.

---

## 4. Detection Versus Resolution

Contradiction detection identifies an incompatibility. Contradiction resolution
selects or applies a governing outcome under authority, policy, temporal, or
regulator doctrine.

Phase 3 tasks may implement detection mechanics for all contradiction classes.
They may implement resolution only where the governing doctrine defines the
resolution rule. If no rule exists, the task must block or escalate; it must not
choose a rule.

---

## Task-Generation Rule

Every contradiction task must declare:

- contradiction class;
- governing doctrine;
- projection universe;
- authority and policy lineage inputs;
- permitted outcome class;
- whether resolution is doctrine-defined or blocked.

---

## Prohibited Misinterpretations

**PM-CCD-01 - Conflict Means Deletion:** Contradiction findings do not authorize
deleting source records.

**PM-CCD-02 - Detection Means Resolution:** Detection does not authorize choosing
between conflicting records.

**PM-CCD-03 - Cross-Regulator Equivalence:** Contradiction across regulator
domains must not collapse regulator sovereignty.

**PM-CCD-04 - New Category by Task:** Implementation tasks must not invent new
contradiction classes.

