# PHASE3_CAPABILITY_BOUNDARY.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: PHASE3_CAPABILITY_BOUNDARY.md (initial draft — defective scope)
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md
  - docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md
  - docs/constitutional/REGULATORY_ALIGNMENT_CONSTITUTION.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  - docs/constitutional/CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/governance/PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md

Effective-Date: 2026-05-10
Supersession-Authority: ROOT (human constitutional custodian decree, 2026-05-10)

---

## Supersession Notice

This document supersedes the initial PHASE3_CAPABILITY_BOUNDARY.md, which was
found to be defective by human constitutional custodian decree on 2026-05-10.
The defect was a scope misalignment: the prior draft defined Phase 3 as a
regulatory sovereignty integration phase (ZEMA, BoZ, ZDPA, MADD/MAIN, Article 6,
Verra, Gold Standard, EU CBAM). This characterization contradicts the canonical
Phase Specification Document (docs/architecture/Symphony-Phase-Specification-Document_v1.md),
which defines Phase 3 as the **Constraint and Legitimacy Engine** — an internal
enforcement and decision-legitimacy layer, not an external regulatory integration layer.

External regulatory integration is the constitutional domain of Phase 8A (Sovereign
Authorization Layer), Phase 8B (Registry Bridge Layer), and the carry-forward
obligations correctly reassigned in this document.

No Phase 3 task generated under the defective prior boundary definition is
constitutionally valid. All Phase 3 tasks must be regenerated under this
corrected boundary.

---

## Purpose

This document defines the explicit constitutional capability boundary for Phase 3
of Symphony, derived exclusively from the canonical Phase Specification Document
(Symphony-Phase-Specification-Document_v1.md §Phase 3: Constraint and Legitimacy
Engine).

Phase 3's constitutional purpose is: **Ensure decisions are not just cryptographically
sound but formally legitimate under applicable rule sets.**

This boundary document defines what Phase 3 is authorized to build, what it is
prohibited from building, which sovereignty domains it touches, its entry conditions,
its exit criteria, and the carry-forward obligations that have been reassigned away
from Phase 3 to their correct phases.

---

## Authorized Capability Domains

Phase 3 is authorized to implement exclusively the following capabilities, as
defined in Symphony-Phase-Specification-Document_v1.md §Phase 3:

### 3.1 — Typed Dependency Graph
Machine-traversable dependency structures for every decision and fact within the
platform. Every decision record must declare its upstream dependencies. The graph
must be machine-readable and traversable without human interpretation.

### 3.2 — Recursive Legitimacy Engine
A legitimacy chain tracer that follows decision ancestry upward and rejects any
decision whose legitimacy chain contains an illegitimate ancestor. Legitimacy
is evaluated against applicable rule sets, not against runtime assertions.

### 3.3 — Contradiction Detection
Active blocking of conflicting decisions. Conflicts are classified as:
- Direct contradiction (two decisions assert incompatible facts)
- Temporal contradiction (two decisions conflict across time)
- Authority-based contradiction (two decisions conflict in authority scope)

### 3.4 — Failure Composition Engine
Machine-readable failure decomposition. Rejections must produce structured,
traversable failure records rather than opaque error states. Failure records
are constitutional evidence and must be append-only.

### 3.5 — Authority Scope Engine
Enforcement of authority-to-resource binding. Every authority claim must be
explicitly scoped to the resource it governs. Authority delegation must be
traceable through the dependency graph.

### 3.6 — Regulator Override Rules
Precedence rules for conflicting regulator determinations. Fraud detection at
the authority boundary. Override rules are statically declared, not runtime-
configurable.

### 3.7 — Conflict-of-Interest Enforcement
Role-based separation of duties. Specifically: submitters cannot be verifiers
for the same asset or decision. This enforcement is DB-layer, not application-
layer only. The existing INV-169 (Regulation 26 separation of duties — GF-W1-SCH-008)
is a precursor enforcement surface; Phase 3 generalises this to all decision types.

### 3.8 — Spatial Legality and DNSH Gates
Geospatial validation against Do No Significant Harm (DNSH) criteria and
statutory restrictions. Spatial legality checks run at decision time, not at
intake time. Phase 3 generalises the DNSH spatial check (INV-178) into a
platform-wide spatial legality gate applicable to all constraint evaluation.

---

## Constitutional Augmentations Required Within Phase 3

Per the Phase Specification Constitutional Augmentation (Symphony-Phase-Specification-Document_v1.md
§Phase-by-Phase Constitutional Augmentations — Phase 3), Phase 3 must also deliver:

- Explicit regulatory sovereignty arbitration within the legitimacy engine
- Replay-aware legitimacy: legitimacy chains must be replayable from persisted records
- Historical policy replay: decisions evaluated against the policy version active at
  decision time, not the current version
- Evidence admissibility lineage: each decision record must carry its admissibility
  chain derivable from persisted fields
- Temporal legitimacy reconstruction: the legitimacy status of any historical decision
  must be reconstructable without live runtime
- Regulator-specific admissibility chains within the contradiction detection engine
- Historical contradiction replay: contradiction findings must be replayable from
  persisted records

---

## Sovereignty Domains Affected

Phase 3 affects the following sovereignty domains:

| Domain | Nature of Effect |
|---|---|
| `WAVE4_OPERATIONAL` | EXTENDS — adds legitimacy enforcement on the operational write path |
| `REPLAY_INFRASTRUCTURE` | EXTENDS — adds replay-aware legitimacy chain storage |
| `PHASE_CAPABILITY` | DEFINES — establishes Phase 3 as the legitimacy enforcement phase |
| `PROVENANCE_CHAIN` | EXTENDS — adds typed dependency graph to provenance records |

Phase 3 does NOT affect:
- `WAVE8_PROVENANCE` — cryptographic sovereignty surface is complete; Phase 3 does not modify it
- `REGULATOR_PARTITION` — Phase 3 does not implement regulatory integration; it enforces
  internal legitimacy rules that are regulator-aware but do not constitute integration
- `EXTERNAL_VERIFIER` — Phase 3 does not modify signed payload schemas or key registry surfaces

---

## Explicitly Prohibited Capabilities

Phase 3 MUST NOT implement any of the following. These are capabilities assigned to
other phases by the Phase Specification Document:

| Prohibited Capability | Correct Phase |
|---|---|
| MADD/MAIN integration with MGEE | Phase 8A — Sovereign Authorization Layer |
| ZEMA registry bridge or API integration | Phase 8B — Registry Bridge Layer |
| BoZ statutory deduction enforcement | Phase 4 — Financial Integrity |
| ZDPA data residency or erasure controls | Phase 6 — UI and Field Reality Layer |
| Article 6 authorization pack generation | Phase 8A — Sovereign Authorization Layer |
| Verra issuance export packages | Phase 8B — Registry Bridge Layer |
| Gold Standard certification interfaces | Phase 8B — Registry Bridge Layer |
| EU CBAM evidence packages | Phase 8D — Corporate Disclosure Layer |
| Methodology adapter framework | Phase 5 — Adapter Refactor and Methodology Runtime |
| VVB portal or external audit interfaces | Phase 6 — UI and Field Reality Layer |
| Settlement finality enforcement | Phase 4 — Financial Integrity |
| Cross-registry credit reconciliation | Phase 8B — Registry Bridge Layer |
| Tokenization or on-chain export | Phase 8C — Tokenization |

Phase 3 MUST NOT:
- Replace or collapse Wave 4 and Wave 8 into a single authority surface.
- Remove historical verification capability from any prior phase's evidence.
- Introduce unverifiable regulatory shortcuts in place of mechanical enforcement.
- Perform work constitutionally reserved for Phase 4, 5, 6, 7, or 8A-8E.
- Introduce hardcoded methodology logic into the platform core.
- Grant VVB portals or external audit roles any internal administration privileges.

---

## Carry-Forward Obligations — Phase Assignment Determination

The following carry-forward obligations from Phase 2 (PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md)
have been assessed against the Phase Specification Document and assigned to their
correct implementation phases:

### CF-1: Methodology Adapter Extraction
**Correct Phase: Phase 5 — Adapter Refactor and Methodology Runtime**

Rationale: The Phase Specification Document §Phase 5 defines the Adapter Refactor
and Methodology Runtime as the phase that "shifts the platform from hardcoded
methodology logic to an adapter-governed methodology runtime." CF-1 requires
extraction of registry methodology from core application logic into a modular
adapter. This is the canonical scope of Phase 5 (§5.1–5.4 Contract and Input
Normalization). Assigning CF-1 to Phase 3 was the defect in the prior boundary
document. Phase 3 must not implement any methodology adapter work.

Escalation trigger (unchanged): Fires if a new registry methodology is introduced
into the core without adapter abstraction before Phase 5 is open.

### CF-2: Dwell-Time Forensic Enforcement
**Correct Phase: Phase 3 — Constraint and Legitimacy Engine**

Rationale: Dwell-time forensic enforcement is a legitimacy and constraint enforcement
concern — it detects temporal anomalies in the decision timeline and enforces that
decisions have not dwelled in intermediate states beyond authorized periods. This
falls within Phase 3 §3.2 (Recursive Legitimacy Engine) and §3.3 (Contradiction
Detection), specifically the temporal contradiction classification. Phase 3 is the
correct implementation phase for CF-2.

Entry condition: CF-2 must be addressed as a Phase 3 security verifier task. Its
Phase 3 entry condition is: a dedicated dwell-time forensic verifier task must be
scaffolded and evidenced within Phase 3 before Phase 3 exit criteria can be claimed.

### CF-3: Sovereign Authorization Schema (MADD/MAIN)
**Correct Phase: Phase 8A — Sovereign Authorization Layer**

Rationale: The Phase Specification Document §Phase 8A defines the Sovereign
Authorization Layer as the phase that builds "machine-readable host-country
authorization request packs, LoA ingestion/recording workflows, corresponding
adjustment bindings, and first-transfer proof attachments." CF-3 requires a
specialized authorization schema for Article 6 sovereign contexts — this is
precisely the scope of Phase 8A. The MADD/MAIN integration doctrine is constitutionally
defined in docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md (Authority-Rank 8,
ROOT authority) and is operative as a doctrine document; the implementation of the
MADD/MAIN integration boundary is Phase 8A work.

Note: Phase 3's legitimacy engine (§3.2) will need to be aware of MADD/MAIN
conceptual boundaries for its authority scope rules (§3.5), but it must NOT
implement the MADD/MAIN integration itself. It uses the constitutional definitions
from MADD_MAIN_INTEGRATION_DOCTRINE.md as authority boundary references, not as
integration targets.

Escalation trigger (unchanged): Fires if sovereign credit issuance is attempted
without the Phase 8A authorization schema being implemented.

---

## Phase 3 Entry Conditions

Phase 3 may begin implementation only when ALL of the following conditions are met:

1. Phase 2 is confirmed closed (status: "closed" in phase2_contract.yml). ✅ SATISFIED
2. Wave 8 is confirmed True-Complete (23/23 tasks). ✅ SATISFIED
3. CF-1 escalation trigger is confirmed non-fired (methodology adapter not yet required). ✅ SATISFIED
4. CF-3 escalation trigger is confirmed non-fired (sovereign credit issuance not yet attempted). ✅ SATISFIED
5. CF-2 is acknowledged as a Phase 3 obligation (dwell-time forensic enforcement). ✅ SATISFIED — this document declares it.
6. Phase 3 capability boundary (this document) is in repository. ✅ SATISFIED upon commit.
7. Phase 3 invariant register is in repository with verifier paths declared. ⬜ PENDING
8. Phase 3 opening act is ratified and registered in constitutional history. ⬜ PENDING

---

## Phase 3 Exit Criteria

Phase 3 is complete only when ALL of the following are satisfied, as defined in
Symphony-Phase-Specification-Document_v1.md §Phase 3 Exit Criteria:

- Decisions are entirely traceable through the typed dependency graph.
- Contradictions (direct, temporal, authority-based) are actively blocked.
- Authority scope violations are mechanically enforced.
- Conflict-of-interest constraints are DB-layer enforced.
- DNSH spatial gates are generalized and operational for all decision types.
- CF-2 (Dwell-Time Forensic Enforcement) verifier task is evidenced and CI-wired.
- All Phase 3 contract rows (P3-001 through P3-006) are satisfied per the updated
  phase3_contract.yml.
- All Phase 3 invariants (INV-301 through INV-310) have mechanical verifiers and evidence.
- Phase 3 constitutional history entry is complete.

---

## Constitutional Self-Validation

**Sovereignty domains governed:** Phase 3 capability boundary — what is and is not
constitutionally legal within Phase 3. Governance of Wave4_Operational extensions
for legitimacy enforcement, replay infrastructure extensions, and provenance chain
extensions.

**Sovereignty domains this document MUST NOT redefine:** Wave 8 provenance sovereignty
(complete, untouchable by Phase 3). Regulator partition doctrine (Phase 3 enforces
internal legitimacy rules; it does not define or integrate with regulator domains).
Root constitutional doctrine (Ranks 9–10). MADD/MAIN integration doctrine (defined
at Rank 8 in MADD_MAIN_INTEGRATION_DOCTRINE.md; Phase 3 references but does not
implement).

**Replay obligations preserved:** Phase 3 must add replay-aware legitimacy chain
storage. Legitimacy determinations must be replayable from persisted records. This
document preserves all prior-phase replay obligations and extends them to Phase 3
decision records.

**Regulator boundaries constraining this document:** Phase 3 is an internal
legitimacy engine. It is regulator-aware (§3.6, §3.7, §3.8) but does not constitute
external regulatory integration. Regulator sovereignty partitioning (REG-ZM-001
through REG-INT-004) constrains the legitimacy engine's rule declarations but is
not modified by Phase 3.

**Phases this document applies to:** PHASE-3 exclusively.

**Override authority:** Root Constitutional Doctrine (Rank 10), Wave Sovereignty
Doctrine (Rank 9), and Symphony-Phase-Specification-Document_v1.md (Rank 7 within
phase scope) possess override authority over this document.

**Lower-layer documents prohibited from reinterpretation:** All Phase 3 task
definitions (meta.yml, PLAN.md), Phase 3 migration records, Phase 3 CI gate
additions, and Phase 3 operational artifacts are prohibited from reinterpreting
the capability boundary defined herein to expand Phase 3 scope into Phase 4, 5,
6, 7, or 8A-8E domains.

---

## Prohibited Misinterpretations

**PM-CB-01 — Phase 3 as Regulatory Integration Phase (PROHIBITED):**
Phase 3 is not a regulatory integration phase. It is an internal constraint and
legitimacy enforcement phase. No Phase 3 task may implement ZEMA integration,
BoZ statutory deductions, ZDPA erasure controls, Article 6 authorization packs,
Verra export packages, Gold Standard certification interfaces, or EU CBAM evidence
packages. These belong to later phases as specified in Symphony-Phase-Specification-Document_v1.md.

**PM-CB-02 — MADD/MAIN Implementation as Phase 3 Scope (PROHIBITED):**
The MADD/MAIN integration is Phase 8A scope. Phase 3 may reference the MADD/MAIN
constitutional definitions for authority scope rule declarations, but must not
implement any MADD or MAIN integration surface, data exchange, or authorization
schema. Any task that proposes MADD/MAIN implementation within Phase 3 is
constitutionally defective.

**PM-CB-03 — CF-3 as Phase 3 Entry Blocker (PROHIBITED):**
CF-3 (Sovereign Authorization Schema) is not a Phase 3 entry blocker. It is a
Phase 8A obligation. Its escalation trigger (sovereign credit issuance without
schema) is currently non-fired. Phase 3 may proceed without CF-3 being resolved.

**PM-CB-04 — Prior Defective Boundary as Authoritative (PROHIBITED):**
The initial PHASE3_CAPABILITY_BOUNDARY.md (pre-2026-05-10) defined Phase 3 as a
regulatory sovereignty integration phase. That definition is constitutionally void
and is superseded by this document. Any task or analysis citing the prior boundary
document as authoritative for Phase 3 scope is constitutionally defective.
