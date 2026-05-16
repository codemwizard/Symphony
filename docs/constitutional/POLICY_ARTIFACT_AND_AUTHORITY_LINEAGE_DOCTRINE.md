# POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: informal policy-artifact, policy-lineage, and authority-lineage assumptions
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_GLOSSARY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md

---

## Purpose

This doctrine defines the policy artifact classes and lineage requirements that
Phase 3 uses when routing capability work to governing doctrine. It prevents
tasks from using mutable runtime state or informal summaries as policy authority.

---

## 1. Policy Artifact

A policy artifact is a versioned, replay-addressable constitutional, regulator,
jurisdictional, methodology, or governance input that defines a rule used by
Phase 3 evaluation.

Every policy artifact used by Phase 3 must declare:

- artifact identifier;
- artifact class;
- source authority;
- version;
- effective-time interval;
- supersession or revocation lineage;
- jurisdiction or regulator scope, if applicable;
- resource and act scope;
- replay reconstruction requirements.

Unversioned policy text, runtime configuration, task prose, AI synthesis, and
dashboard state are not policy artifacts.

---

## 2. Policy Artifact Classes

Phase 3 recognizes these policy artifact classes:

| Class | Function |
|---|---|
| Constraint Policy | Defines a rule that permits, blocks, quarantines, or conditions an act. |
| Authority Policy | Defines which authority may govern which resource, act, time, or domain. |
| Precedence Policy | Defines ordering between otherwise applicable policy artifacts or authorities. |
| Contradiction Policy | Defines contradiction classification or handling rules. |
| Replay Policy | Defines reconstruction inputs, algorithms, and historical treatment. |
| Projection Policy | Defines projection universe inputs and derived-view boundaries. |
| Spatial Policy | Defines spatial predicates, datasets, DNSH gates, overlap rules, or uniqueness checks. |
| Failure Policy | Defines failure category, severity, and composition handling. |

No implementation task may introduce a new policy artifact class without doctrine
amendment.

---

## 3. Policy Lineage

Policy lineage is the replayable chain that proves which policy artifact governed
an act at the relevant time and context.

Policy lineage must preserve:

- source artifact;
- version;
- effective-time interval;
- supersession chain;
- authority source;
- context of application;
- hash or stable identifier where available.

Policy lineage must be sufficient for a future replay to determine why a rule was
applied without relying on live runtime configuration.

---

## 4. Authority Lineage Linkage

Where a policy artifact derives force from an authority source, the policy
lineage must link to authority lineage. Policy cannot be applied as authority
unless its authority source is declared and within scope.

Policy artifact validity and authority scope validity are distinct. A valid
policy artifact may still be inapplicable if the asserting authority lacks scope
for the act.

---

## 5. Prohibited Policy Sources

The following must not be treated as policy artifacts:

- mutable runtime configuration without version and effective-time lineage;
- implementation task descriptions;
- AI-generated summaries or draft analyses;
- dashboards, cached read models, or reports;
- undocumented operator decisions;
- current service behavior;
- archived draft files marked non-canonical.

---

## Task-Generation Rule

Every Phase 3 task that applies a rule must identify the policy artifact class,
source authority, versioning model, and lineage path. If the governing policy
artifact does not exist, task creation is blocked.

---

## Prohibited Misinterpretations

**PM-PAL-01 - Runtime Config as Policy:** Runtime configuration is not a policy
artifact unless versioned and authority-linked.

**PM-PAL-02 - Summary as Policy:** Summaries and assessments do not become policy
artifacts by being accurate.

**PM-PAL-03 - Policy Validity Equals Authority Scope:** A policy artifact can be
valid but inapplicable when authority scope is absent.

**PM-PAL-04 - Current Policy Rewrites Past:** Current policy does not rewrite
historical policy lineage.

