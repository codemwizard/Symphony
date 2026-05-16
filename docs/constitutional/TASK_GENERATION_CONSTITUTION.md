# TASK GENERATION CONSTITUTION

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ENFORCEMENT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 6
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md
  - docs/constitutional/CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/constitutional/regulatory/REGULATORY_ALIGNMENT_CONSTITUTION.md
  - docs/constitutional/regulatory/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - docs/process/EVIDENCE_DRIVEN_TASK_PROCESS.md

---

## Purpose

This document defines the constitutional legality of implementation task generation
within Symphony. It governs every act of task creation, task scaffolding, task
amendment, and task retirement as a constitutional engineering act — not as a
project management act.

Symphony's implementation task generation is not analogous to feature-ticket
creation in a conventional software project. A task in Symphony constitutes a
proposed mutation of a sovereign constitutional trust coordination substrate.
Every task, if executed, produces migration records, enforcement artifacts,
declarative substrate, or operational configurations that operate within Symphony's
constitutional authority hierarchy. Tasks that violate constitutional boundaries —
whether through prohibited authority assumptions, sovereignty collapse, replay
degradation, admissibility invalidation, or phase-illegal scope — constitute
constitutional defects from the moment of their generation, prior to execution.

This document defines the rules that make a task constitutionally legal before
it is assigned, scaffolded, or executed. It defines the mandatory constitutional
declarations that every task must carry. It defines the prohibited assumption
patterns that render a task constitutionally void regardless of its technical
correctness. It defines the review obligations that must be satisfied before a
task may proceed. It defines the anti-drift requirements that prevent constitutional
erosion through accumulated task generation.

Task generation is constitutional engineering governance. Generators of tasks —
whether human agents, AI agents, or automated scaffolding systems — are bound by
this document without exception.

---

## Constitutional Scope

This document governs:

1. The constitutional legality standards applicable to every implementation task
   generated within Symphony.
2. The mandatory constitutional declaration requirements that every task must
   satisfy before it may be marked `status: planned`.
3. The prohibited assumption patterns that constitute constitutional defects in
   task definitions.
4. The sovereignty boundaries that may never be collapsed within a task's scope,
   intent, or implementation.
5. The phase legality constraints that determine which task scopes are constitutionally
   legal within each constitutional phase.
6. The task legality review obligations that must be satisfied prior to task
   execution.
7. The constitutional admissibility check requirements applicable to task-generated
   artifacts.
8. The anti-drift requirements preventing incremental constitutional erosion through
   accumulated task generation.
9. The NotebookLM synthesis safeguards preventing AI-generated task definitions from
   asserting constitutional authority.

This document does NOT govern:

- The internal implementation logic of any specific task, provided that implementation
  complies with the constitutional boundaries defined herein.
- The scheduling, priority ordering, or resource allocation of tasks within a
  project management context.
- The substantive content of individual migration records, enforcement triggers, or
  operational configurations, except insofar as those artifacts make or imply
  constitutional claims.
- The amendment procedures for this document, which are governed by
  CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

---

## Authority Boundaries

This document operates at Authority-Rank 6 (Enforcement Doctrine). It defines
the constitutional requirements for task generation as an enforcement surface. It
operates within and may not redefine the constraints established by superior-rank
documents:

- Root Constitutional Doctrine (Rank 10): CONSTITUTIONAL_AUTHORITY_HIERARCHY.md,
  CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md,
  TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md, CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.
- Wave Sovereignty Doctrine (Rank 9): Wave 4 and Wave 8 sovereignty doctrine;
  EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md.
- Phase Constitutional Doctrine (Rank 8): Phase capability boundary doctrine for
  all active and deferred phases.
- Regulator Partition Doctrine (Rank 7): REGULATORY_ALIGNMENT_CONSTITUTION.md;
  REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md.

Where any provision of this document appears to conflict with a superior-rank
document, the superior-rank document is authoritative. The apparent conflict must
be documented and escalated to the appropriate constitutional authority for
resolution; it may not be silently resolved in favor of this document.

This document possesses enforcement authority over all lower-rank artifacts
(Ranks 0–5), including: migration records, CI gate definitions, operational
enforcement artifacts, declarative substrate, repository observations, and AI
syntheses. Task definitions that produce artifacts at these ranks must comply
with this document.

---

## Part I: The Constitutional Status of Task Generation

### 1.1 Task Generation as Constitutional Act

Every implementation task generated within Symphony constitutes a proposed
constitutional act. The act is proposed at the moment of task generation; it is
executed at the moment of implementation. The constitutional legality of the
proposed act is evaluated at the moment of generation — not deferred to the moment
of execution.

A task that is constitutionally illegal at generation remains constitutionally
illegal regardless of how it is subsequently implemented. Constitutional defects
in task generation cannot be remediated by technically correct implementation.
The implementation of a constitutionally defective task produces a constitutionally
defective artifact, regardless of the implementation's technical quality.

This principle is the constitutional enforcement basis for all review obligations
defined in Part IV of this document.

### 1.2 Constitutional Artifact Classes Produced by Tasks

Tasks, when executed, produce artifacts at the following constitutional authority
ranks (per CONSTITUTIONAL_AUTHORITY_HIERARCHY.md):

| Task Output Type | Constitutional Authority Rank | Examples |
|---|---|---|
| Constitutional doctrine amendments | Rank 10 / Rank 9 / Rank 8 | Phase doctrine, wave doctrine, root doctrine |
| Migration records | Rank 5 | `schema/migrations/NNNN_*.sql` |
| CI gate definitions | Rank 4 | `.github/workflows/*.yml` gate additions |
| Operational enforcement artifacts | Rank 3 | Triggers, SECURITY DEFINER functions, RLS RESTRICTIVE policies |
| Declarative substrate | Rank 2 | Scaffolded tables, dormant registries |
| Repository observations | Rank 1 | Audit reports, analysis documents registered in docs/ |

A task's constitutional obligations are determined by the highest-rank artifact
it produces or modifies. A task that modifies a migration record AND modifies
a SECURITY DEFINER function operates at the combined constitutional scope of
Rank 5 and Rank 3, and is subject to all constitutional requirements applicable
to both ranks.

### 1.3 Task Generation Is Not Project Management

Task generation within Symphony must not be approached as a project management
activity. The following project management concepts are constitutionally inapplicable
to Symphony task generation and are prohibited as primary organizing principles:

**Prohibited project management framings:**
- "This task adds a feature."
- "This task closes a ticket."
- "This task completes a sprint."
- "This task addresses technical debt."
- "This task cleans up legacy code."
- "This task improves performance."

These framings are constitutionally inapplicable because they do not address the
constitutional dimensions of the task's proposed act: the sovereignty domains it
affects, the replay obligations it preserves or degrades, the admissibility
implications of its artifacts, the phase legality of its scope, and the regulator
boundaries it must not collapse.

**Required constitutional framing for every task:**
Every task must be framed in terms of:
- The constitutional capability it establishes, extends, or enforces.
- The sovereignty domains it touches and their boundaries.
- The replay obligations it preserves, extends, or creates.
- The admissibility implications of every artifact it produces.
- The phase capability boundary within which it operates.
- The regulator domain implications of its artifacts, if any.

---

## Part II: Mandatory Constitutional Declarations

Every task definition — whether expressed in `meta.yml`, `PLAN.md`, DOD YAML,
or any equivalent task specification format — MUST include explicit declarations
in ALL of the following categories. A task that omits any mandatory declaration
is constitutionally incomplete and MUST NOT advance beyond `status: draft`.

### 2.1 Affected Sovereignty Domain Declaration

Every task MUST explicitly declare which sovereignty domains it affects. The
declaration must identify each affected domain from the following enumeration
and characterize the nature of the effect:

**Enumerated sovereignty domains:**
- `WAVE4_OPERATIONAL` — Wave 4 operational/runtime sovereignty; `state_transitions`,
  `execution_records`, `policy_decisions`, `state_rules`, enforcement triggers
  on operational write paths.
- `WAVE8_PROVENANCE` — Wave 8 provenance/cryptographic sovereignty; `asset_batches`,
  `wave8_signer_resolution`, `delegated_signing_grants`, `public_keys_registry`,
  signing enforcement paths, HSM attestation surfaces.
- `PHASE_CAPABILITY` — Phase constitutional capability boundary; any task that
  expands, contracts, or crosses phase capability boundaries.
- `REGULATOR_PARTITION` — Regulator sovereignty domain; any task that touches
  evidence surfaces with regulatory admissibility obligations.
- `EXTERNAL_VERIFIER` — External verifier independence; any task that modifies
  signed payload schema, canonicalization procedures, key registry surfaces, or
  archive key store obligations.
- `REPLAY_INFRASTRUCTURE` — Replay survivability infrastructure; any task that
  modifies the historical evidentiary record, migration sequence, canonicalization
  registry, or signer lineage.
- `PROVENANCE_CHAIN` — Evidence provenance chain; any task that modifies fields
  included in authority tuples, transition hashes, data-authority fingerprints,
  or signing payloads.
- `DECLARATIVE_SUBSTRATE` — Dormant/scaffolded constitutional substrate; any task
  that activates, deactivates, modifies, or eliminates declarative substrate.
- `PII_BOUNDARY` — Personal information architectural boundary; any task that
  modifies fields that may contain or reference personal information.

**Declaration format:**
```yaml
affected_sovereignty_domains:
  - domain: WAVE4_OPERATIONAL
    nature: EXTENDS          # EXTENDS | ENFORCES | MODIFIES | ACTIVATES | DEACTIVATES | READS_ONLY
    surfaces_touched:
      - state_transitions
      - execution_records
    boundary_preserved: true # explicit assertion that domain boundary is not crossed or collapsed
```

**Prohibition:** A task MUST NOT declare `boundary_preserved: true` unless the
task generator has explicitly verified that the task scope does not cross, merge,
or collapse the declared domain's boundary with any other sovereignty domain.
Defaulting this field to `true` without verification is a prohibited assumption.

### 2.2 Replay Implications Declaration

Every task MUST explicitly declare its replay implications across the following
dimensions:

**REP-D1. Historical record alteration:** Does this task modify any field, table,
or index that is part of any existing historically admitted record? If yes, the
constitutional basis for the modification must be declared, and the replay-safe
migration path must be specified.

**REP-D2. Replay obligation extension:** Does this task create new record classes
that are subject to replay obligations? If yes, the replay retention period,
archive mechanism, and replay reconstruction path must be declared.

**REP-D3. Replay infrastructure modification:** Does this task modify
`canonicalization_registry`, `wave8_signer_resolution`, `delegated_signing_grants`,
`public_keys_registry`, or `historical_verification_runs`? If yes, the task must
declare the replay continuity attestation: that all prior replay obligations are
preserved under the modified infrastructure.

**REP-D4. Signing payload schema modification:** Does this task modify any table
field, field ordering, or field naming that is included in any signed payload per
ED25519_SIGNING_CONTRACT.md? If yes, the task must declare:
  - the canonicalization version transition required,
  - the replay treatment of records signed under the prior payload schema,
  - the archive key store implications.

**REP-D5. Migration sequence effect:** Every task that produces a migration record
must declare the migration number, the constitutional state transition it represents,
and confirmation that the migration is forward-only and does not alter any prior
committed migration.

**Declaration format:**
```yaml
replay_implications:
  historical_record_alteration: false         # bool; if true, must provide basis
  replay_obligation_created: true             # bool; if true, must specify retention
  replay_retention_period: "statutory_max"    # applicable retention period
  replay_infrastructure_modified: false       # bool; if true, must provide attestation
  signing_payload_schema_modified: false      # bool; if true, must specify transition
  migration_number: 0136                      # if applicable
  migration_forward_only: true                # bool; must be true or task is illegal
  replay_continuity_attestation: "All prior replay obligations are preserved.
    This task adds enforcement surface; no historical records are altered."
```

### 2.3 Admissibility Implications Declaration

Every task MUST explicitly declare the admissibility implications of every
artifact it produces, across both Wave 4 operational admissibility and Wave 8
provenance admissibility, and across any applicable regulator domain.

**ADM-D1. Wave 4 admissibility class:** What Wave 4 operational admissibility
class governs the records produced by this task's enforcement surfaces? The
declaration must reference the applicable data-authority level:
`phase1_indicative_only`, `non_reproducible`, `execution_bound`, or
`policy_authoritative`.

**ADM-D2. Wave 8 admissibility gate:** Does this task's implementation path cross
the Wave 8 attestation gate at `asset_batches`? If yes, the task must declare the
Wave 8 signing enforcement path it activates, modifies, or extends.

**ADM-D3. External verifier admissibility:** Does this task produce artifacts
that will be presented to external verifiers, regulators, or auditors? If yes,
the task must declare the external verifier independence compliance of each such
artifact per EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md, §3.2.

**ADM-D4. Historical admissibility impact:** Does this task modify any enforcement
surface, schema, or policy that affects the historical admissibility of any prior
records? If yes, the task must declare the temporal admissibility continuity
attestation: that records produced before this task's implementation retain their
historical admissibility status under the constitutional state operative at their
production time.

**ADM-D5. Proof limitations declaration:** Every task MUST declare its proof
limitations — the constitutional admissibility properties it does NOT establish,
even where it might superficially appear to do so. Proof limitation declaration
is mandatory and is not optional even where the task generator believes the task
establishes complete proof.

**Declaration format:**
```yaml
admissibility_implications:
  wave4_data_authority_class: execution_bound
  wave8_attestation_gate_crossed: false
  external_verifier_artifacts_produced: false
  historical_admissibility_impact: none       # none | extends | preserves | requires_attestation
  temporal_admissibility_continuity_attestation: "No prior records are affected.
    This task adds forward-only enforcement."
  proof_limitations:
    - "This task does not verify Ed25519 signature authenticity.
       Signature structural binding is enforced; public-key resolution is deferred."
    - "This task does not establish ZEMA authorization for any project.
       It creates enforcement infrastructure for ZEMA-related records."
```

### 2.4 Regulator Boundary Declaration

Every task MUST declare whether its implementation touches any evidence surface
with regulatory admissibility obligations, and if so, which regulator domains
are implicated.

**REG-D1. Regulator domain identification:** For each regulator domain implicated,
the task must declare the domain identifier from the REGULATORY_ALIGNMENT_CONSTITUTION.md
domain register (REG-ZM-001 through REG-ZM-005; REG-INT-001 through REG-INT-004).

**REG-D2. Admissibility condition effect:** Does this task alter the admissibility
conditions for any regulator domain? If yes, the task must declare the nature of
the alteration and confirm it does not reduce admissibility conditions below the
domain's constitutional floor.

**REG-D3. Cross-domain isolation confirmation:** The task must explicitly confirm
that its implementation does not cause evidence from one regulator domain to be
co-mingled with, made dependent on, or used to satisfy evidence obligations in
any other domain. This is the operational expression of regulator sovereignty
non-collapse (REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md).

**REG-D4. Evidence survivability impact:** Does this task modify the evidence
retention architecture for any regulator-domain evidence? If yes, the task must
confirm that the applicable statutory retention period is preserved or extended,
and that no evidence survivability obligation is reduced.

**Declaration format:**
```yaml
regulator_boundary_declaration:
  regulatory_domains_implicated: []           # empty if none; or list of domain IDs
  admissibility_conditions_altered: false
  cross_domain_isolation_confirmed: true
  evidence_survivability_impact: none         # none | extends | requires_attestation
  regulator_non_collapse_attestation: "This task creates no regulatory evidence surfaces.
    Regulator domain isolation is unaffected."
```

If `regulatory_domains_implicated` is non-empty, each domain MUST be independently
declared. A single attestation covering multiple domains is constitutionally
insufficient because regulator domains are orthogonal and their independence cannot
be established by a collective statement.

### 2.5 Phase Legality Declaration

Every task MUST declare its constitutional phase legality: the phase capability
boundary within which it operates and the constitutional basis for asserting that
the task's scope is legal within that boundary.

**PHL-D1. Active phase identification:** The task must declare the constitutional
phase that is active at the time of task generation. A task generated in Phase 2
must declare Phase 2 as its operative phase.

**PHL-D2. Capability boundary compliance:** The task must declare which Phase 2
(or applicable phase) capability boundaries define the scope of its implementation.
It must explicitly confirm that the task scope does not exceed the capability
boundaries of the active phase.

**PHL-D3. Cross-phase scope prohibition:** A task whose implementation scope
crosses phase capability boundaries — that is, a task that simultaneously requires
capabilities defined in different phases — is constitutionally illegal as a
single task. Such a scope must be decomposed into phase-legal individual tasks
with explicit dependency sequencing.

**PHL-D4. Deferred phase capability declaration:** Where a task creates declarative
substrate for capabilities that will be activated in a future phase, the task must
declare the target phase for activation and confirm that the substrate does not
constitute a present-phase activation of that capability.

**PHL-D5. Phase-retroactivity prohibition:** A task must not assert, imply, or
require retroactive application of current phase capabilities to records produced
in prior phases. Policy-at-time-of-execution semantics (TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md,
Part VIII) are constitutionally absolute.

**Declaration format:**
```yaml
phase_legality:
  operative_phase: "PHASE-2"
  phase_capability_boundary_reference: "docs/phases/PHASE2_CAPABILITY_BOUNDARIES.md"
  capability_boundary_exceeded: false         # must be false; if true, task is illegal
  cross_phase_scope: false                    # must be false; if true, decompose task
  deferred_activation_substrate: false
  target_activation_phase: null              # declare if deferred_activation_substrate: true
  retroactivity_asserted: false              # must be false; retroactivity is prohibited
```

### 2.6 Historical Survivability Impact Declaration

Every task MUST declare its impact on Symphony's historical survivability
infrastructure — the infrastructure that ensures records produced in any prior
constitutional moment remain replayable, verifiable, and admissible in perpetuity.

**HSI-D1. Schema field deletion prohibition:** A task MUST NOT delete any schema
field that appears in any historically admitted record. A task that proposes field
deletion must be constitutionally rejected and decomposed: the new schema
requirement must be achieved through field addition and constraint modification,
not through deletion of historically referenced fields.

**HSI-D2. Migration alteration prohibition:** A task MUST NOT alter any previously
committed migration record. The migration sequence is a constitutional record.
Alteration of committed migrations constitutes destruction of the constitutional
history record.

**HSI-D3. Canonicalization schema retirement:** A task that retires a canonicalization
schema version must declare the retirement in `canonicalization_registry` with
a `deprecated_at` timestamp and confirm that the retired schema version remains
permanently accessible for replay verification of records signed under that version.
Schema retirement is NOT schema deletion.

**HSI-D4. Signer lineage retirement:** A task that retires a Wave 8 signer lineage
entry must confirm that the entry is retired (not deleted) in `wave8_signer_resolution`
with a retirement timestamp, and that the corresponding archive key store entry is
preserved for replay verification of records signed by the retired signer.

**HSI-D5. Append-only surface modification:** A task that modifies any append-only
enforcement surface (e.g., `enforce_policy_decisions_append_only`, `deny_final_instruction_mutation`)
must declare the constitutional basis for the modification and the admissibility
continuity attestation for all records produced under the prior enforcement state.

**Declaration format:**
```yaml
historical_survivability_impact:
  schema_field_deletion_proposed: false       # must be false; field deletion is prohibited
  migration_alteration_proposed: false        # must be false; migration alteration is prohibited
  canonicalization_schema_retired: false
  signer_lineage_retired: false
  append_only_surface_modified: false
  historical_survivability_attestation: "This task adds new schema fields and
    enforcement surfaces. No historical fields are deleted. No prior migrations are
    altered. Historical replay survivability is unaffected."
```

### 2.7 Provenance Implications Declaration

Every task MUST declare its implications for Symphony's evidence provenance chain
— the chain from `state_transitions` through `execution_records` through
`interpretation_packs` through `policy_decisions` that constitutes the operational
provenance of every authority determination.

**PROV-D1. Authority tuple modification:** Does this task modify any field that is
included in the authority tuple used to compute `transition_hash` or `data_authority`?
If yes, the canonicalization version transition required and the replay treatment
of records with prior-version authority tuples must be declared.

**PROV-D2. Provenance chain interruption:** Does this task create conditions under
which any link in the provenance chain could be absent, null, or unverifiable for
any record class? If yes, the task must either be rejected as constitutionally
illegal or must include an explicit constitutional authorization for the gap,
defined as a named proof_limitation.

**PROV-D3. Runtime/provenance boundary compliance:** The task must confirm that
its implementation does not merge, collapse, or conflate the Wave 4 operational
authority surface with the Wave 8 provenance/cryptographic authority surface.
These surfaces are constitutionally orthogonal and must be treated as such in
every task's implementation scope.

**PROV-D4. SECURITY DEFINER function compliance:** Every task that introduces or
modifies a SECURITY DEFINER function must declare:
  - `SET search_path = pg_catalog, public` is explicitly set.
  - The function does not grant runtime roles the ability to access Wave 8
    provenance surfaces directly.

**Declaration format:**
```yaml
provenance_implications:
  authority_tuple_modified: false             # bool; if true, declare transition path
  provenance_chain_interruption_possible: false  # must be false; or declare authorization
  runtime_provenance_boundary_preserved: true # must be true; false renders task illegal
  security_definer_functions_introduced: true
  security_definer_compliance:
    search_path_set: true
    runtime_role_escalation_prevented: true
```

### 2.8 Cross-Border Implications Declaration

Every task that produces evidence artifacts with potential cross-border regulatory
admissibility — including ITMO provenance records, CBAM-relevant embedded carbon
records, Article 6 authorization records, and payment settlement records with
cross-jurisdiction correspondent banking implications — MUST declare its
cross-border implications explicitly.

**CB-D1. Cross-border admissibility claim:** Does this task's implementation
enable or modify cross-border evidence claims? If yes, each target jurisdiction
and the applicable regulatory framework must be identified.

**CB-D2. Ed25519 algorithm confirmation:** Cross-border admissibility requires
that signed artifacts use Ed25519 (RFC 8032), the jurisdiction-neutral algorithm.
A task that introduces or modifies a signing path must confirm Ed25519 compliance.

**CB-D3. Trust chain reference population:** Cross-border evidence artifacts must
carry a populated `trust_chain_ref` field (per SIGNATURE_METADATA_STANDARD.md)
sufficient for the target jurisdiction's verifiers to reconstruct the trust root
without requiring a live connection to Symphony's runtime.

**CB-D4. Offline verification compliance:** The task must confirm that all
cross-border evidence artifacts it introduces satisfy the offline verification
legal standing requirements of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md, §5.

**Declaration format:**
```yaml
cross_border_implications:
  cross_border_evidence_produced: false
  target_jurisdictions: []
  ed25519_algorithm_confirmed: true
  trust_chain_ref_populated: false           # required true if cross_border_evidence_produced
  offline_verification_compliant: true
```

---

## Part III: Prohibited Constitutional Assumptions in Task Generation

The following assumption patterns, when present in any task definition, render
that task constitutionally defective regardless of its technical content. Task
generators — human and AI — are bound by these prohibitions. The presence of any
prohibited pattern constitutes a constitutional defect that must be remediated
before the task may advance beyond `status: draft`.

### 3.1 Sovereignty Collapse Assumptions

**PCA-1 — Wave 4/Wave 8 Unity Assumption (PROHIBITED):**
Any task that assumes Wave 4 operational authority and Wave 8 provenance/
cryptographic authority are unified, interchangeable, or mutually governing
is constitutionally defective. These are orthogonal sovereignty surfaces.
A task scope that applies to "all authority enforcement" without distinguishing
between operational and provenance authority is exhibiting this prohibited
assumption.

*Detection signals:* Task intent language that treats `execution_records`
and `asset_batches` as belonging to the same authority enforcement domain;
task scope that applies a single signing mechanism to both Wave 4 and Wave 8
write paths; task verification that uses Wave 4 evidence to establish Wave 8
compliance or vice versa.

**PCA-2 — Regulator Equivalence Assumption (PROHIBITED):**
Any task that assumes evidence satisfying one regulator domain simultaneously
satisfies any other regulator domain is constitutionally defective. Regulator
domains are orthogonal. A task that produces evidence for "regulatory compliance"
without identifying the specific domain and its domain-specific requirements
is exhibiting this prohibited assumption.

*Detection signals:* Task intent language referring to "regulatory compliance"
without domain-specific reference; task verification commands that test for
compliance with multiple regulator domains without separate, domain-specific
verification; task acceptance criteria that equate ZGFT alignment with Verra VCS
validation, or BoZ admissibility with CBAM evidence sufficiency.

**PCA-3 — Runtime Supremacy Assumption (PROHIBITED):**
Any task that assumes Wave 4 operational runtime behavior constitutes the
authoritative definition of Symphony's constitutional state is constitutionally
defective. Runtime behavior expresses constitutional enforcement; it does not
define constitutional doctrine.

*Detection signals:* Task intent language stating that a feature "works because
the trigger enforces it" without reference to the constitutional doctrine the
trigger expresses; task verification that accepts trigger behavior as the
constitutional admissibility standard without reference to governing enforcement
doctrine.

**PCA-4 — Provenance Subordination Assumption (PROHIBITED):**
Any task that treats Wave 8 provenance/cryptographic sovereignty as derived from,
validated by, or subordinate to Wave 4 operational sovereignty is constitutionally
defective. These sovereignty surfaces are constitutionally non-hierarchical within
their own domains.

*Detection signals:* Task scope that conditions Wave 8 attestation on Wave 4
enforcement surface output; task verification that uses Wave 4 trigger execution
records to establish Wave 8 cryptographic validity.

**PCA-5 — Inactive-Implies-Eliminable Assumption (PROHIBITED):**
Any task that proposes to eliminate, deactivate, remove, or reduce the scope of
any constitutionally declared but currently inactive (dormant, scaffolded, deferred)
substrate on the grounds that it is inactive is constitutionally defective.
Dormancy does not constitute technical debt; unwired substrate does not constitute
accidental design. See NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, Patterns PI-2
and PI-3.

*Detection signals:* Task title or intent language containing "clean up legacy",
"remove unused", "eliminate dead code", "remove orphaned tables" targeting any
constitutional substrate; task scope that proposes deletion of any scaffolded table
(Rank 2) without Root constitutional amendment authorization.

**PCA-6 — Parallel-Implies-Conflict Assumption (PROHIBITED):**
Any task that proposes to consolidate, merge, or unify two parallel constitutional
surfaces on the grounds that parallelism implies conflict, redundancy, or design
error is constitutionally defective. See NON_INFERENCE_AND_INTERPRETATION_LIMITS.md,
Pattern PI-1.

*Detection signals:* Task intent language referring to "consolidating" two
enforcement functions that serve different sovereignty domains; task scope that
merges Wave 4 and Wave 8 signing paths into a single unified signing mechanism.

### 3.2 Replay Degradation Assumptions

**PCA-7 — Replay Irrelevance Assumption (PROHIBITED):**
Any task that treats replay survivability as an optional audit accommodation,
a low-priority concern, or a post-implementation consideration is constitutionally
defective. Replay survivability is Priority 1 in CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.
Every task that touches any surface relevant to replay survivability must address
replay implications in its mandatory declarations before any implementation
consideration.

*Detection signals:* Task definitions with empty or absent `replay_implications`
declarations; task scope that modifies canonicalization surfaces without declaring
schema version transitions; task optimizations that propose compaction, archiving,
or deletion of any historically admitted record class.

**PCA-8 — Present-Policy Retroactivity Assumption (PROHIBITED):**
Any task that assumes or requires that its implementation's new enforcement
surfaces, admissibility standards, or constitutional requirements apply
retroactively to records produced before the task's implementation is
constitutionally defective. Policy-at-time-of-execution semantics are
constitutionally absolute.

*Detection signals:* Task scope that proposes "back-filling" historical records
with new fields; task verification that tests whether historical records comply
with present-time standards; task acceptance criteria that require all existing
records to satisfy new enforcement surfaces.

**PCA-9 — Key Rotation Invalidation Assumption (PROHIBITED):**
Any task that assumes, requires, or enables the invalidation of historical
records on the grounds that the signing key used to produce them has since been
rotated, superseded, or deactivated is constitutionally defective. Key rotation
survivability is constitutionally required.

*Detection signals:* Task scope that includes logic to "invalidate records signed
by deactivated keys"; task verification that rejects replay of records signed by
keys with `is_active = false`.

**PCA-10 — Migration Alteration Assumption (PROHIBITED):**
Any task that proposes to alter, amend, or reorder any committed migration record
as part of its implementation is constitutionally defective. The migration sequence
is a constitutional record. Alteration constitutes destruction of the historical
constitutional record.

*Detection signals:* Task implementation steps that include editing any file in
`schema/migrations/` other than introducing new migration files at the tip of the
sequence.

### 3.3 Admissibility Invalidation Assumptions

**PCA-11 — Universal Admissibility Assumption (PROHIBITED):**
Any task that assumes evidence satisfying one verification or enforcement gate is
admissible in all regulatory contexts, before all regulators, or under all
constitutional standards is constitutionally defective. Admissibility is
domain-specific, phase-specific, and wave-specific. No universal admissibility
exists in Symphony's constitutional architecture.

*Detection signals:* Task acceptance criteria stating that a record is "fully
compliant" without specifying the compliance domain; task verification commands
that assert "admissible" without qualifying the admissibility dimension.

**PCA-12 — CI Gate Validation Completeness Assumption (PROHIBITED):**
Any task that treats passage of all CI gates as establishing complete constitutional
validity of the task's artifacts is constitutionally defective. CI gate passage
establishes merge-path admissibility (Rank 4). It does not establish constitutional
validity in all sovereignty dimensions, all regulator domains, or all admissibility
classes.

*Detection signals:* Task completion criteria that equate CI gate passage with
task constitutional compliance; task definitions that omit sovereignty declarations
on the grounds that CI will catch any issues.

**PCA-13 — Phase-1 Evidence as Attribution Evidence (PROHIBITED):**
Any task that presents or treats evidence carrying `data_authority = 'phase1_indicative_only'`
as satisfying the cryptographic attribution requirements of any regulator domain
is constitutionally defective. Phase-1 indicative evidence establishes that an
event was recorded; it does not establish cryptographic attribution.

*Detection signals:* Task acceptance criteria that present phase-1 evidence to
a regulatory surface without declaring the phase-1 limitation; task verification
commands that pass phase-1 evidence through regulatory admissibility gates.

### 3.4 Phase-Illegality Assumptions

**PCA-14 — Phase Capability Overreach Assumption (PROHIBITED):**
Any task whose implementation scope requires constitutional capabilities that are
defined in a future phase but not yet constitutionally active is constitutionally
defective. Phase capability boundaries define what is constitutionally legal in
each phase.

*Detection signals:* Task implementation that invokes enforcement functions
defined as future-phase capabilities; task scope that activates Wave 8 cryptographic
enforcement paths during a Phase 2 execution context where Wave 8 enforcement is
constitutionally deferred.

**PCA-15 — Single-Task Cross-Phase Scope (PROHIBITED):**
Any task that encompasses implementation scope spanning multiple constitutional
phase capability boundaries within a single task boundary is constitutionally
defective as a single task. Cross-phase scope must be decomposed into separate,
phase-legal tasks with explicit dependency declarations.

*Detection signals:* Task work items that include both Phase 2 deliverables and
Phase 3 or Wave 8 deliverables in a single task boundary; task acceptance criteria
that require simultaneous satisfaction of capabilities belonging to different
constitutional phases.

---

## Part IV: Task Legality Review

### 4.1 Constitutional Task Review Obligation

Every task MUST undergo constitutional task review before its status may be
advanced from `draft` to `planned`. Constitutional task review is not a quality
assurance activity; it is a constitutional enforcement obligation. A task that
passes constitutional task review has been assessed as constitutionally legal for
the proposed act it represents.

Constitutional task review MUST be performed by a constitutional review agent with
authority over the sovereignty domains the task affects. No task may self-certify
constitutional review. A task generated by an AI synthesis agent must be reviewed
by a human constitutional custodian or a designated human-supervised constitutional
review agent.

### 4.2 Constitutional Task Review Checklist

The following checklist constitutes the minimum scope of constitutional task
review. All items marked MANDATORY must be satisfied before a task may advance
from `draft` to `planned`. Failure to satisfy any MANDATORY item is a
constitutional defect in the task definition.

| ID | Review Item | Mandatory | Constitutional Basis |
|---|---|---|---|
| CTR-01 | All mandatory constitutional declarations present and complete | MANDATORY | Part II of this document |
| CTR-02 | No prohibited assumption patterns identified (PCA-1 through PCA-15) | MANDATORY | Part III of this document |
| CTR-03 | Sovereignty domain boundary assertions verified (not defaulted) | MANDATORY | Part II, §2.1 |
| CTR-04 | Replay implications accurately declared and non-degrading | MANDATORY | Part II, §2.2 |
| CTR-05 | Admissibility implications accurately declared per affected domains | MANDATORY | Part II, §2.3 |
| CTR-06 | Regulator boundaries independently declared per domain | MANDATORY | Part II, §2.4 |
| CTR-07 | Phase legality confirmed within active phase capability boundary | MANDATORY | Part II, §2.5 |
| CTR-08 | Historical survivability impact non-destructive | MANDATORY | Part II, §2.6 |
| CTR-09 | Proof limitations explicitly declared | MANDATORY | Part II, §2.3, ADM-D5 |
| CTR-10 | Single-boundary enforcement: one primary constitutional objective | MANDATORY | §4.3 of this document |
| CTR-11 | `verify_plan_semantic_alignment.py` passes (NO_ORPHANS=true, GRAPH_CONNECTED=true) | MANDATORY | EVIDENCE_DRIVEN_TASK_PROCESS.md |
| CTR-12 | Negative tests declared for each enforcement surface introduced | MANDATORY | EVIDENCE_DRIVEN_TASK_PROCESS.md |
| CTR-13 | All verification commands end with `\|\| exit 1` | MANDATORY | AI_AGENT_OPERATION_MANUAL.md |
| CTR-14 | `psql "$DATABASE_URL"` form used; bare `psql -c` prohibited | MANDATORY | WAVE4_SINGLE_SOURCE_OF_TRUTH.md, §9 |
| CTR-15 | Migration is forward-only; no alteration of prior committed migrations | MANDATORY | Part III, PCA-10 |
| CTR-16 | SECURITY DEFINER functions declare `SET search_path = pg_catalog, public` | MANDATORY | AI_AGENT_OPERATION_MANUAL.md |
| CTR-17 | Evidence path appropriate for task type (PLAN.md for -00; JSON for migration) | MANDATORY | WAVE4_SINGLE_SOURCE_OF_TRUTH.md, §9 |
| CTR-18 | Cross-border implications declared if applicable | CONDITIONAL | Part II, §2.8 |
| CTR-19 | Cross-phase scope absent; if present, task must be decomposed | MANDATORY | Part III, PCA-15 |
| CTR-20 | `canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md` present in PLAN.md | MANDATORY | AI_AGENT_OPERATION_MANUAL.md |

### 4.3 Single-Boundary Enforcement Rule

Every task MUST have ONE primary constitutional objective. A task that spans
multiple primary constitutional objectives is a multi-boundary task and is
constitutionally prohibited as a single task definition.

**Single-boundary categories:**
- `SINGLE_TYPE` — Defines or modifies a single database type (ENUM, domain).
- `SINGLE_TABLE` — Creates or modifies a single database table.
- `SINGLE_FUNCTION` — Creates or modifies a single database function.
- `SINGLE_TRIGGER_SET` — Creates or modifies the trigger set for a single table.
- `SINGLE_INVARIANT` — Registers a single constitutional invariant with its
  verifier and evidence.
- `SINGLE_VERIFIER` — Creates a single audit or verification script.
- `SINGLE_INPUT_CONTRACT` — Defines a single API input validation boundary.
- `SINGLE_RUNTIME_CHECK` — Creates a single runtime parity or consistency check.
- `DOCS_ONLY` — Creates or modifies constitutional or operational documentation
  only; no schema or code changes.

A task whose scope spans more than one of these categories MUST be decomposed.
The decomposition must preserve the constitutional dependency ordering:
constitutional prerequisites must complete before the tasks that depend on them.

The single-boundary enforcement rule exists because multi-boundary tasks make
sovereignty boundary assertions impossible to verify, proof limitations impossible
to declare completely, and rollback semantics impossible to define cleanly.

### 4.4 Constitutional Admissibility Check

In addition to the constitutional task review, every task that produces Rank 3
or higher artifacts MUST satisfy a constitutional admissibility check before
the task may be marked `status: completed`. The constitutional admissibility
check verifies that the implemented artifacts satisfy the constitutional
declarations made during task generation.

**Constitutional admissibility check components:**

**CAC-1. Sovereignty boundary verification:** Verify that the implemented artifacts
do not cross or collapse any sovereignty domain boundary declared in the task's
`affected_sovereignty_domains`.

**CAC-2. Replay obligation satisfaction:** Verify that all replay implications
declared in the task's `replay_implications` are satisfied by the implemented
artifacts. Forward-only migration compliance must be verified by inspection of
the migration tip.

**CAC-3. Negative test execution:** Every enforcement surface introduced by the
task must be tested by at least one negative test that demonstrates the surface
rejects the class of events it is constitutionally required to reject. Negative
tests are not optional. A task with no negative tests is constitutionally
unverified.

**CAC-4. Evidence artifact production:** Every task must produce evidence artifacts
at the paths declared in `evidence.path`. Evidence artifacts must contain the
fields declared in `evidence.must_include`. Missing evidence constitutes
constitutional non-completion.

**CAC-5. Proof limitation confirmation:** The evidence artifact must explicitly
record the proof limitations declared in the task definition. Evidence artifacts
that claim broader admissibility than their declared proof limitations constitute
false evidence of constitutional compliance.

---

## Part V: Anti-Drift Requirements

Constitutional drift is the gradual erosion of Symphony's constitutional
architecture through accumulated task definitions that each individually appear
compliant but collectively collapse sovereignty boundaries, degrade replay
obligations, flatten regulator domains, or permit inadmissible assumptions.
Anti-drift requirements are the constitutional mechanisms that prevent this
collective erosion.

### 5.1 The Accumulated Effect Doctrine

Every task generator MUST consider not only the constitutional legality of the
individual task being generated, but also its accumulated constitutional effect
when added to the corpus of all previously generated and future-planned tasks.

The accumulated effect doctrine requires that task generators:

**AED-1.** Verify that no combination of planned tasks, when taken together,
effectively merges, collapses, or subordinates any sovereignty domain.

**AED-2.** Verify that no series of individually replay-preserving tasks, taken
together, reduces the overall replay survivability of any evidence class.

**AED-3.** Verify that no series of individually domain-scoped tasks, taken
together, creates de facto cross-domain evidence coupling that violates regulator
sovereignty non-collapse doctrine.

**AED-4.** Verify that no series of individually phase-legal tasks, taken together,
constitutes a de facto phase capability expansion that has not been constitutionally
authorized.

### 5.2 Anti-Drift Mandatory Fields

Every task definition MUST include the following anti-drift fields in its
`meta.yml` or equivalent specification:

```yaml
out_of_scope:
  - "[Description of what this task explicitly does NOT do]"
  - "[Description of the sovereignty boundary this task does NOT cross]"
  - "[Description of the regulator domain this task does NOT touch]"

stop_conditions:
  - "[Condition that must be satisfied before the task is considered complete]"
  - "[Condition whose absence indicates the task should stop rather than proceed]"

proof_guarantees:
  - "[Constitutional property that the task's evidence artifact positively establishes]"

proof_limitations:
  - "[Constitutional property the task does NOT establish, even where it might appear to do so]"
  - "[Admissibility claim the task's evidence does NOT support]"
```

The `out_of_scope` field is the primary anti-drift mechanism. Explicit scope
exclusion prevents future tasks from assuming that an earlier task established
a constitutional property that it explicitly did not establish.

### 5.3 Failure Signature Requirement

Every task MUST declare a `failure_signature` in the format:
`<PHASE>.<TRACK>.<TASK-SLUG>.<FAILURE-CLASS>`

The failure signature enables automated detection of repeated failure patterns
across task executions. It is the basis for DRD (Debug Remediation Doctrine)
process triggers. Tasks without a declared failure signature cannot be assigned
to DRD remediation processes without ambiguity.

```yaml
failure_signature: "PHASE2.PREAUTH.TSK-P2-PREAUTH-006A-01.ENUM_DRIFT"
```

### 5.4 Constitutional Drift Detection Signals

The following signals, when detected across the task corpus, indicate potential
constitutional drift requiring review:

**CDD-1.** More than one task in a wave modifies the same sovereignty domain
boundary assertion without an explicit sovereignty boundary clarification
constitutional event.

**CDD-2.** A series of tasks progressively narrows the replay retention period
or replay verification scope without a Root constitutional amendment.

**CDD-3.** Multiple tasks produce evidence for the same regulator domain using
different admissibility standards, creating inconsistent regulatory admissibility
claims.

**CDD-4.** A task's `out_of_scope` declarations conflict with the `intent` or
`acceptance_criteria` of another task, suggesting an unresolved scope overlap.

**CDD-5.** Multiple tasks share the same migration number or produce migrations
that target the same tables without explicit constitutional coordination.

**CDD-6.** A task's proof_limitations are not referenced as explicit prerequisites
in any subsequent task that relies on the properties the prior task could not
establish. This creates a provenance gap where downstream tasks assume completed
constitutional properties that are, in fact, incomplete.

---

## Part VI: NotebookLM Synthesis Safeguards

### 6.1 AI Synthesis Constitutional Standing

AI syntheses of Symphony's constitutional corpus — including NotebookLM-generated
summaries, agent-generated task proposals, and automated scaffolding outputs —
possess zero constitutional standing (Authority-Rank 0 per CONSTITUTIONAL_AUTHORITY_HIERARCHY.md,
§ Rank 0).

An AI-generated task proposal is constitutionally a draft. It requires human
constitutional review before it may advance to `status: planned`. No AI synthesis
may:

- Assert that a proposed task is constitutionally compliant without human review.
- Declare that a sovereignty domain boundary is preserved without human verification.
- Generate a proof limitation declaration that is empty or generic.
- Produce a `boundary_preserved: true` assertion without explicit human verification.
- Claim that a task's evidence artifact establishes constitutional properties
  beyond what the task's enforcement surfaces operationally enforce.

### 6.2 Prohibited AI Synthesis Patterns in Task Generation

**NLS-1 — Implicit Sovereignty Assertion (PROHIBITED):**
AI-generated tasks must not omit sovereignty domain declarations on the grounds
that the relevant sovereignty domains are "obvious" from the task intent. All
sovereignty declarations are mandatory regardless of apparent obviousness.

**NLS-2 — Generic Proof Limitation (PROHIBITED):**
AI-generated tasks must not use generic or placeholder proof limitation language
such as "standard limitations apply" or "not all properties verified." Every proof
limitation must be specific: it must name the constitutional property not
established and the reason it is not established.

**NLS-3 — Assumed Regulatory Compliance (PROHIBITED):**
AI-generated tasks must not assert regulatory compliance for any domain without
an explicit domain-specific admissibility declaration. The phrase "regulatorily
compliant" without a domain-specific reference is a prohibited assumption per
PCA-2 (Regulator Equivalence Assumption).

**NLS-4 — Historical Record Assumed Safe (PROHIBITED):**
AI-generated tasks must not omit the `historical_survivability_impact` declaration
on the grounds that the task "obviously" does not affect historical records.
Every task must declare its historical survivability impact explicitly. "Obviously
non-destructive" is not a constitutional declaration.

**NLS-5 — Replay Implication Assumed Absent (PROHIBITED):**
AI-generated tasks must not declare `replay_implications: none` without explicit
analysis. A task that introduces any enforcement surface, modifies any schema
field, or creates any evidence artifact has replay implications that must be
assessed and declared.

**NLS-6 — Phase Legality Assumed from Task Order (PROHIBITED):**
AI-generated tasks must not assume phase legality on the grounds that the task
is positioned in the task sequence after other phase-legal tasks. Each task
must independently establish its phase legality through explicit declaration
against the active phase capability boundary.

### 6.3 AI Synthesis Anti-Hallucination Requirements

All AI synthesis tools generating task definitions within Symphony MUST be
configured or instructed with the following prohibitions:

**AHR-1.** Do not invent sovereignty domain boundaries not established by
existing constitutional doctrine. If a sovereignty domain is not recognized in
the enumerated list in §2.1 of this document, it does not exist and must not
be declared.

**AHR-2.** Do not assume that prior AI-generated documents in the constitutional
corpus are constitutionally authoritative. Their authority rank is zero. Task
definitions that depend on AI-synthesized constitutional claims rather than
Rank 6-10 constitutional doctrine are constitutionally defective.

**AHR-3.** Do not generate `acceptance_criteria` that cannot be satisfied by
the verification commands declared in the same task. Every acceptance criterion
must be testable by a declared verification command.

**AHR-4.** Do not generate verification commands that depend on runtime state
that is not persistently available. All verification commands must be executable
against persisted evidence artifacts, not against transient runtime state.

**AHR-5.** Do not generate task definitions that propose to implement capabilities
deferred to future waves or phases. Phase capability boundary compliance is not
optional for AI-generated tasks; it is constitutionally required.

---

## Part VII: Phase Interaction Rules

### 7.1 Phase Capability Boundaries as Constitutional Constraints

Phase capability boundaries define what task scopes are constitutionally legal
in each constitutional phase. These boundaries are not implementation roadmap
decisions; they are constitutional definitions of what the platform is authorized
to do in each phase.

**PR-1.** Tasks generated during Phase 2 must operate within Phase 2 capability
boundaries. Tasks requiring Phase 3 or Wave 8 capabilities must be declared as
future-phase tasks and must not be scaffolded in a way that constitutes a
present-phase activation of those capabilities.

**PR-2.** The deferred activation of constitutional capabilities (declarative
substrate at Rank 2) is constitutionally protected. Tasks that modify dormant
substrate must not activate that substrate unless the activation is constitutionally
authorized by the applicable phase or wave doctrine.

**PR-3.** Phase capability boundary expansion requires Root constitutional amendment.
Tasks that propose to expand phase capability boundaries without Root constitutional
amendment are constitutionally illegal.

**PR-4.** Phase closure tasks — tasks that formally close a constitutional phase
and register its closing conditions in the constitutional history record — are
themselves constitutional acts subject to all mandatory declarations in Part II.

### 7.1A Phase 3 Doctrine-Routed Task-Plan Rules

**PR-4A. Phase 3 Doctrine-Routed Task-Plan Rule.** Every Phase 3 task plan must
identify an authorized capability domain from `PHASE3_CAPABILITY_BOUNDARY.md`,
cite at least one governing canonical doctrine, declare the allowed
implementation surface, declare the prohibited doctrine surface, and state
whether any doctrine blocker remains unresolved.

**PR-4B. Agents Implement Doctrine; Agents Do Not Define Doctrine.** A task plan
or atomic implementation task may implement behavior defined by canonical
doctrine. It may not introduce legitimacy, replay, authority, contradiction,
spatial, policy, regulator, or failure semantics not already defined by
governing doctrine.

**PR-4C. Doctrine Gaps Block Implementation Tasks.** If a Phase 3 capability
requires doctrine that does not exist or is insufficient, task generation must
produce doctrine-gap work rather than implementation work. The absence of
doctrine is not permission for local inference.

### 7.2 Wave Sovereignty and Phase Legality Interaction

Wave 4 and Wave 8 operate as constitutionally orthogonal sovereignty surfaces
across all phases. The activation of Wave 4 enforcement surfaces in a given phase
does not constitute activation of Wave 8 enforcement surfaces for the same phase.
Tasks must declare Wave 4 and Wave 8 implications independently.

**PR-5.** A Phase 2 task that introduces Wave 4 enforcement surfaces (e.g., a
trigger on `state_transitions`) must not simultaneously claim to satisfy Wave 8
admissibility requirements, because Wave 8 admissibility operates on an orthogonal
sovereignty surface not fully activated in Phase 2.

**PR-6.** A task that scaffolds Wave 8 substrate in Phase 2 (declarative substrate
for future Wave 8 activation) must declare the deferred activation phase and must
include a proof limitation explicitly stating that Wave 8 cryptographic enforcement
is not yet active.

---

## Part VIII: Admissibility Implications of Task Generation

### 8.1 Task Artifacts Are Constitutional Records

Every artifact produced by a task's execution — migration records, enforcement
triggers, evidence JSON files, PLAN.md documents, EXEC_LOG.md entries — is a
constitutional record at its applicable authority rank. As a constitutional record,
it must be treated as append-only in the historical constitutional record.

**AI-1.** Migration records, once committed, are part of the constitutional
migration sequence and may not be altered or deleted.

**AI-2.** EXEC_LOG.md files are append-only execution histories. They may not
be edited to remove prior entries. They are evidentiary records of the task's
implementation process.

**AI-3.** Evidence JSON artifacts, once produced and registered in CI gate
evidence validation, are constitutional evidence. They may be superseded by
subsequent evidence artifacts but may not be deleted from the evidence store.

**AI-4.** The PLAN.md of a completed task is a constitutional record of the
task's governing intent at the time of execution. Subsequent modifications to
a completed task's PLAN.md must be recorded as amendments, not silent edits.

### 8.2 Evidence Artifact Constitutional Requirements

Every task's evidence artifact MUST include the following fields to constitute
constitutionally valid evidence:

```json
{
  "task_id": "<canonical task identifier>",
  "git_sha": "<commit SHA at time of evidence production>",
  "timestamp_utc": "<ISO 8601 UTC timestamp>",
  "status": "completed | failed",
  "checks": [
    {
      "id": "<check ID>",
      "result": "PASS | FAIL",
      "command": "<exact command executed>",
      "output_summary": "<non-empty summary of command output>"
    }
  ],
  "negative_test_results": [
    {
      "id": "<negative test ID>",
      "result": "PASS | FAIL",
      "description": "<what the negative test proved>"
    }
  ],
  "verifier_results": "<path or inline output of verifier commands>",
  "proof_limitations": [
    "<exact text of each proof limitation declared in task definition>"
  ],
  "sovereignty_domains_affected": ["<domain IDs from §2.1>"],
  "replay_continuity_attestation": "<exact attestation text from task definition>",
  "historical_admissibility_impact": "<none | extends | preserves | requires_attestation>"
}
```

Evidence artifacts that omit `negative_test_results`, `proof_limitations`,
`sovereignty_domains_affected`, or `replay_continuity_attestation` are
constitutionally incomplete and must not be accepted by CI gate evidence
validation.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the enforcement surface of task generation itself. It
governs the process by which proposed constitutional acts (tasks) are evaluated
for constitutional legality before execution. It governs the mandatory declaration
requirements, prohibited assumption patterns, review obligations, anti-drift
requirements, and NotebookLM synthesis safeguards applicable to all task
generation within Symphony.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine Wave 4 operational sovereignty (governed by Wave 4
Sovereignty Doctrine and CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md), Wave 8
provenance/cryptographic sovereignty (governed by Wave 8 Sovereignty Doctrine and
EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md), individual regulator sovereignty
domains (governed by REGULATORY_ALIGNMENT_CONSTITUTION.md and
REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md), phase capability boundaries
(governed by Phase Constitutional Doctrine), or Root constitutional doctrine
(governed by CONSTITUTIONAL_AUTHORITY_HIERARCHY.md and
CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md). This document governs task
generation process; it does not redefine the substantive constitutional content
of any sovereignty domain.

**Replay obligations preserved by this document:**
This document preserves replay obligations by: (a) requiring explicit replay
implication declarations in every task (§2.2); (b) prohibiting task assumptions
that degrade replay survivability (PCA-7 through PCA-10); (c) requiring historical
survivability impact declarations that prohibit schema field deletion and migration
alteration (§2.6); (d) requiring that evidence artifacts include replay continuity
attestations; (e) requiring that task definitions declare proof limitations that
accurately characterize which replay obligations the task does and does not
establish.

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator
orthogonality as established in REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md.
Its regulator boundary declaration requirements (§2.4) must be applied
independently per domain. This document may not authorize a task generation
process that produces cross-domain admissibility claims, merged regulator evidence,
or single-domain-evidence used to satisfy multi-domain requirements.

**Phases this document applies to:**
GLOBAL. This document applies across all constitutional phases. Task generation
occurs in every phase; the constitutional legality standards defined herein are
phase-invariant. The specific phase capability boundaries that constrain task
scope are phase-specific; the obligation to declare and comply with those
boundaries is phase-invariant.

**Constitutional layers possessing override authority over this document:**
Root Constitutional Doctrine (Rank 10) overrides this document in all respects.
Wave Sovereignty Doctrine (Rank 9) overrides this document within wave sovereignty
scope. Phase Constitutional Doctrine (Rank 8) overrides this document within phase
capability scope. Regulator Partition Doctrine (Rank 7) overrides this document
within regulator domain scope. No lower-rank artifact — migration record (Rank 5),
CI gate (Rank 4), operational artifact (Rank 3), declarative substrate (Rank 2),
repository observation (Rank 1), or AI synthesis (Rank 0) — possesses override
authority over this document.

**Lower-layer documents prohibited from reinterpretation:**
The following lower-layer documents are prohibited from reinterpreting the task
generation constitutional legality standards, mandatory declaration requirements,
prohibited assumption patterns, review obligations, single-boundary enforcement
rule, anti-drift requirements, and NotebookLM synthesis safeguards defined herein:
- All migration records (Rank 5) in `schema/migrations/`.
- All CI gate definitions (Rank 4) in `.github/workflows/`.
- All operational enforcement artifacts (Rank 3): triggers, SECURITY DEFINER
  functions, RLS policies.
- All declarative substrate (Rank 2): scaffolded tables, dormant registries.
- All repository observations (Rank 1): audit reports, inspection summaries.
- All AI syntheses (Rank 0): NotebookLM outputs, agent-generated analyses,
  automated scaffolding outputs.
In particular: no agent instruction, implementation guide, or operational runbook
may reinterpret the mandatory declarations in Part II, the prohibited assumptions
in Part III, or the review obligations in Part IV to reduce their scope, make
them optional, or defer them to post-implementation verification.

---

## Prohibited Misinterpretations

**PM-TGC-01 — Task Generation as Project Management (PROHIBITED):**
It is prohibited to interpret task generation within Symphony as a project
management activity governed by sprint velocity, ticket throughput, or resource
allocation optimization. Task generation is constitutional engineering governance.
Each task is a proposed constitutional act subject to the full constitutional
review obligations defined in Part IV. Efficiency of task generation does not
override constitutional legality of task definition.

**PM-TGC-02 — Mandatory Declarations as Boilerplate (PROHIBITED):**
It is prohibited to treat the mandatory constitutional declarations defined in
Part II as template boilerplate to be populated with default values. Each
declaration is a substantive constitutional assertion. Defaulting `boundary_preserved: true`
without verification, declaring an empty `proof_limitations` list, or populating
`replay_continuity_attestation` with generic language constitutes a false
constitutional assertion, which is a constitutional defect more severe than an
absent declaration.

**PM-TGC-03 — Single-Boundary Rule as Bureaucratic Formality (PROHIBITED):**
It is prohibited to interpret the single-boundary enforcement rule (§4.3) as
a bureaucratic formality that can be satisfied by subdividing a multi-boundary
task into nominal sub-tasks that are then executed as a single implementation
unit. The single-boundary rule is a sovereignty isolation mechanism. Its
purpose is to ensure that the constitutional implications of each boundary
crossing are independently declared, reviewed, and verified.

**PM-TGC-04 — AI-Generated Task as Constitutionally Authoritative (PROHIBITED):**
It is prohibited to treat any AI-generated task definition — including task
definitions generated by Claude, Devin, Copilot, NotebookLM, or any other AI
synthesis tool — as constitutionally authoritative without human constitutional
review. AI syntheses are Rank 0. An AI-generated task that has not been reviewed
by a human constitutional custodian is constitutionally a draft regardless of its
technical sophistication.

**PM-TGC-05 — CTR Checklist as CI Gate Substitute (PROHIBITED):**
It is prohibited to treat the Constitutional Task Review checklist (§4.2) as
substitutable by CI gate passage. CI gates enforce a subset of constitutional
requirements. The CTR checklist enforces the complete constitutional legality
scope, including sovereignty boundary assertions, replay implications, proof
limitations, and regulator boundary declarations that CI gates do not validate.
CTR and CI gate passage are both required; neither substitutes for the other.

**PM-TGC-06 — Proof Limitation Absence as Proof Completeness (PROHIBITED):**
It is prohibited to interpret the absence of declared proof limitations as
evidence that the task establishes complete constitutional proof of all relevant
properties. Empty proof limitations indicate either that the task genuinely
establishes complete proof for its narrowly scoped objective (constitutionally
possible for very narrow single-boundary tasks) or that the task generator
failed to perform proof limitation analysis (a constitutional defect). The
default interpretation of empty proof limitations is the latter; the burden of
establishing the former rests on the task generator.

**PM-TGC-07 — Phase-Ordered Tasks as Phase-Legal Tasks (PROHIBITED):**
It is prohibited to assume that a task is phase-legal on the grounds that it
follows another phase-legal task in the implementation sequence. Phase legality
is an individual task property established by explicit declaration against the
active phase capability boundary. Task sequence ordering does not transfer
phase legality from one task to another.

**PM-TGC-08 — Anti-Drift Requirements as Optional Enhancement (PROHIBITED):**
It is prohibited to treat the anti-drift requirements of Part V — specifically
the `out_of_scope`, `stop_conditions`, `proof_guarantees`, and `proof_limitations`
fields — as optional enhancements for complex tasks only. These fields are
mandatory for every task regardless of perceived simplicity. Simple tasks have
simple anti-drift declarations; the simplicity of the declarations is not grounds
for omitting them.

**PM-TGC-09 — NotebookLM Synthesis as Constitutional Review (PROHIBITED):**
It is prohibited to treat a NotebookLM synthesis that characterizes a task as
"constitutionally compliant" as substituting for constitutional task review by
a human constitutional custodian. NotebookLM syntheses are Rank 0 artifacts with
zero constitutional standing. A NotebookLM output that asserts constitutional
compliance of a task definition does not constitute constitutional compliance.
It constitutes a Rank 0 description of what the task claims. Human review is
constitutionally required.

**PM-TGC-10 — Rollback as Constitutional Remediation (PROHIBITED):**
It is prohibited to treat the rollback of a constitutionally defective task's
implementation as complete constitutional remediation. Rollback addresses the
operational state; it does not address the constitutional defect in the task
definition that permitted the implementation to proceed. Constitutional
remediation of a defective task requires: (a) identification of the prohibited
assumption or omitted declaration that constituted the defect, (b) explicit
correction of the task definition, (c) repetition of the full constitutional
task review, and (d) re-execution under the corrected, constitutionally reviewed
task definition.
