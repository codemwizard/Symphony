# SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal spatial-legality and DNSH assumptions in Phase 3 planning
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  - docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md
  - docs/invariants/INVARIANTS_MANIFEST.yml
  - schema/migrations/0129_enforce_dns_harm_trigger.sql

---

## Purpose

This doctrine defines the Phase 3 boundary for mechanical spatial constraint
evaluation, DNSH gates, protected-area intersection handling, and
anti-double-counting checks. It does not define sovereign environmental law or
jurisdiction-specific statutory meaning.

---

## 1. Spatial Constraint

A spatial constraint is a replay-addressable rule that evaluates geometry,
geography, boundary, coordinate, or protected-area inputs against a declared
policy artifact.

Every spatial constraint used by Phase 3 must declare:

- spatial policy artifact identifier and version;
- source dataset lineage;
- geometry type and coordinate reference expectations;
- effective-time interval;
- regulator or jurisdiction context, if any;
- mechanical predicate used for evaluation;
- failure category and severity.

---

## 2. DNSH Gate

A DNSH gate is a mechanical spatial or environmental constraint that blocks or
quarantines an operation when declared inputs intersect or otherwise violate a
declared DNSH policy artifact.

Phase 3 may generalize the existing protected-area intersection pattern from
`schema/migrations/0129_enforce_dns_harm_trigger.sql`, including fail-closed
mechanical predicates such as intersection checks. Phase 3 may not infer the
legal meaning of DNSH beyond the governing policy artifact.

---

## 3. Protected-Area Intersection Handling

Protected-area intersection handling must preserve:

- project or asset boundary record;
- protected-area dataset version;
- spatial predicate;
- evaluated geometry identifiers or hashes;
- policy artifact version;
- failure outcome.

If source datasets change, later evaluations must append new findings rather
than mutating prior historical findings.

---

## 4. Anti-Double-Counting Boundary

Phase 3 may implement mechanical anti-double-counting checks only where the
governing policy artifact defines the resource identity, spatial uniqueness
rule, overlap tolerance, registry context, and temporal interval.

Phase 3 may not claim cross-registry or cross-jurisdiction anti-double-counting
completeness unless the governing policy artifacts and regulator doctrines
define that scope.

---

## 5. Mechanical Versus Sovereign Meaning

Phase 3 spatial tasks may implement:

- geometry validation;
- protected-area intersection checks;
- overlap detection;
- spatial uniqueness checks;
- spatial failure composition;
- replay-visible spatial findings.

Phase 3 spatial tasks must not define:

- statutory environmental interpretation;
- jurisdiction-specific protected-area legal effect;
- regulator acceptance of a spatial result;
- cross-registry legal uniqueness unless doctrine supplies it.

---

## Task-Generation Rule

Every Phase 3 spatial task must cite the spatial policy artifact or doctrine
that defines the rule being mechanically enforced. A task without a governing
spatial policy artifact is blocked.

---

## Prohibited Misinterpretations

**PM-SD-01 - Spatial Gate as Legal Opinion:** A mechanical spatial result is not
a statutory legal interpretation.

**PM-SD-02 - DNSH as Universal Meaning:** DNSH meaning is policy-artifact and
jurisdiction dependent.

**PM-SD-03 - Intersection Equals Global Invalidity:** A protected-area
intersection finding blocks only under the governing policy artifact.

**PM-SD-04 - Double Counting by Assertion:** Anti-double-counting completeness
must not be claimed without declared resource identity and scope.

