# AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal authority-scope and delegation assumptions in Phase 3 planning
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_GLOSSARY.md
  - docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This doctrine defines the Phase 3 rules for authority scope, authority lineage,
delegated authority, and authority-to-resource binding. It prevents Phase 3
tasks from inventing authority semantics while permitting implementation of
mechanical validation and enforcement.

---

## 1. Authority Scope

Authority scope is the declared boundary within which an authority may produce a
binding decision, constraint, policy artifact, signature, approval, rejection, or
admissibility finding.

An authority scope must declare:

- authority domain;
- issuing authority or authority class;
- resource class governed;
- decision or act class governed;
- jurisdiction or regulator context, if applicable;
- effective-time interval;
- supersession or revocation lineage;
- source policy artifact or constitutional document.

An authority claim outside its declared scope is constitutionally invalid for the
out-of-scope act even if the claimant is valid for another act.

---

## 2. Authority Lineage

Authority lineage is the replayable chain from an asserted authority claim back
to the constitutional, regulator, policy, or delegated source that grants the
authority.

Authority lineage must be append-only, replay-addressable, and specific to the
act being authorized. A generic statement that an actor is "authorized" is
insufficient unless the lineage shows the actor is authorized for the specific
resource, act, time, and projection context.

---

## 3. Delegated Authority

Delegated authority exists only when a governing authority source explicitly
permits delegation and the delegation record declares:

- delegator;
- delegate;
- scope delegated;
- effective-time interval;
- non-delegable exclusions;
- revocation or supersession mechanics;
- evidence proving the delegator possessed delegable authority.

Delegation does not expand the delegator's scope. A delegate receives only the
authority the delegator possessed and explicitly delegated.

---

## 4. Mechanical Enforcement Boundary

Phase 3 may implement:

- authority-to-resource binding checks;
- authority lineage traversal;
- effective-time validation;
- delegated authority validation;
- authority scope failure records;
- fail-closed blocking of out-of-scope acts.

Phase 3 may not define:

- which real-world regulator has substantive legal authority;
- statutory meaning of a regulator's mandate;
- sovereign policy hierarchy not declared by governing doctrine;
- authority classes not declared by constitutional or regulator doctrine.

Where authority meaning is absent, task creation is blocked.

---

## 5. Conflict and Non-Collapse

Two authorities may produce different findings over the same historical record.
Phase 3 must preserve the authority domain and scope of each finding. It may not
collapse one authority into another unless a governing arbitration doctrine
declares an explicit precedence rule.

Authority conflict detection is permitted. Authority conflict resolution is
permitted only when the controlling doctrine defines the resolution rule.

---

## Task-Generation Rule

Every Phase 3 authority-scope task must identify:

- the governing authority doctrine or policy artifact;
- the authority domain;
- the act and resource class being validated;
- what the task may mechanically enforce;
- what authority meaning the task is prohibited from defining.

If any of these are missing, the task is blocked.

---

## Prohibited Misinterpretations

**PM-ASD-01 - Actor Equals Authority:** An actor identity alone is not authority.

**PM-ASD-02 - Delegation Expands Scope:** Delegation must not expand authority
beyond the delegator's scope.

**PM-ASD-03 - Runtime Permission Equals Constitutional Authority:** Access
control permission is not constitutional authority.

**PM-ASD-04 - Detection Equals Resolution:** Detecting an authority conflict does
not authorize resolving it without governing doctrine.

