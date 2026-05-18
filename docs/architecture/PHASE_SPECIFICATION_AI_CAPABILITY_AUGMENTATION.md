# PHASE_SPECIFICATION_AI_CAPABILITY_AUGMENTATION.md

Constitutional-Status: INTERPRETIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 6
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/architecture/PHASE_SPECIFICATION_CBAM_CAPABILITY_AUGMENTATION.md
  - docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md

---

## Purpose

This document augments the Phase Specification with AI capability
additions across Phases 3 through 8E. It was produced through
constitutional review of AI's role in Symphony as an advisory computation
layer operating on a deterministic evidence substrate.

This augmentation is structured as addenda to each affected phase's
specification. It does not replace or contradict the original phase
specification or the CBAM capability augmentation. Where this document
adds AI capabilities, those capabilities operate within the governance
framework established by
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md`.

---

## Cross-Phase AI Invariants

These rules govern all phases from Phase 3 through Phase 8E for all
AI capabilities. They take precedence over any phase-specific
implementation convenience.

**AI-XI-1 — Advisory Position:**
AI outputs are advisory in all phases. No AI output constitutes a
constitutional finding without passing through the admissibility
apparatus defined in
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md`.

**AI-XI-2 — Model Registry Binding:**
Every AI inference that produces an evidence proposal must cite a
registered model ID and version from the Model Registry. Unregistered
model outputs are constitutionally inadmissible.

**AI-XI-3 — Inference Log Obligation:**
Every AI inference that produces an evidence proposal must generate an
inference log record. Inference without a log record is constitutionally
non-replayable and inadmissible for critical decisions.

**AI-XI-4 — Uncertainty Class Conversion:**
Every AI output must be converted to a Phase 3 uncertainty class via a
registered confidence-to-uncertainty mapping before entering the evidence
corpus. Raw confidence scores are not constitutional evidence.

**AI-XI-5 — Human Authority Primacy:**
AI outputs are `AT-ADVISORY` transfer mode per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`. Human authority
holds finalization rights in all phases except where
`ADMISSIBLE_AUTONOMOUS` is explicitly declared in the governing policy.

**AI-XI-6 — Phase 4 / 8A / 8B AI-Free:**
Financial settlement finality (Phase 4), sovereign authorization
(Phase 8A), and registry submission (Phase 8B) are constitutionally
AI-free surfaces. No AI output may directly contribute to these surfaces.

**AI-XI-7 — No New Model Classes per Phase:**
After Phase 3 registers the six model classes (MC-001 through MC-006),
no downstream phase may introduce a new model class without a Phase 3
constitutional amendment to
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md`.

---

## Phase 3 Augmentation — AI Governance

### New §3.10 — AI Governance and Model Provenance

**Constitutional Purpose:** Establish the complete constitutional
namespace, admissibility rules, and governance constraints for
AI-generated outputs before any phase implements AI capabilities.

**What this builds:**
- `AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` — canonical
  constitutional doctrine governing all AI capabilities across all phases
- Model Registry persistence schema with six model classes
  (MC-001 through MC-006 plus MC-UNCLASSIFIED)
- Inference log persistence schema with replay reconstruction path
- Confidence-to-uncertainty mapping rule schema and default mapping table
- INV-313 — AI output admissibility gate invariant
- Verifier `scripts/audit/verify_p3_ai_output_admissibility.sh`

**What this explicitly does not build:**
AI model execution, inference pipelines, ML training infrastructure,
or any operational AI capability.

**Exit criteria addition to Phase 3:**
Phase 3 is not complete until: the AI governance doctrine is canonical;
Model Registry and inference log schemas are DB-layer enforced; INV-313
is promoted to `status: implemented`; the confidence-to-uncertainty
default mapping table is declared and version-bound.

---

## Phase 4 Augmentation — AI Explicitly Excluded

### Addition to §4 — AI-Free Surface Declaration

**Phase 4 is constitutionally AI-free.**

This is not an operational guideline. It is a constitutional constraint
derived from the absolute finality requirement for settlement surfaces.

No AI output may directly contribute to:
- Statutory kill criterion evaluation
- Financial calculation uncertainty gates (inputs must be admitted
  deterministic evidence, not AI proposals)
- BoZ rate binding
- Settlement finality determination
- Statutory deduction calculation

AI outputs that have been admitted through the full admissibility
apparatus — with human review, uncertainty class assignment, and
legitimacy chain validation — may serve as inputs to Phase 4 evidence
records in the same way any other admitted evidence may. The constraint
is against direct AI contribution, not against evidence that originally
had an AI-assisted component.

---

## Phase 5 Augmentation — Primary AI Execution Layer

### New §5.16 — AI-Assisted Methodology Intelligence

**Constitutional Purpose:** Implement operational AI capabilities as
certified methodology adapters, governed by the Phase 3 AI governance
doctrine, consuming Phase 3 uncertainty primitives.

**What this builds:**

*Model Registry Runtime:*
- DB-layer enforcement of the Model Registry schema
- Version binding enforcement: inference records citing unregistered
  model versions are rejected at DB layer (SQLSTATE P5001)
- Model supersession chain: deprecated model versions are not deleted;
  they are superseded with preserved accessibility for historical replay

*Deterministic Inference Execution Runtime:*
- Inference sandbox: AI models execute within the same isolated adapter
  sandbox as methodology computation adapters
- Seed enforcement: `SEED_DETERMINISTIC` models must declare their seed
  before execution; execution without a declared seed is constitutionally
  prohibited
- Hardware declaration enforcement: where hardware affects determinism,
  the hardware class must be declared and recorded in the inference log
- Inference log record production: every inference produces a complete
  inference log record before any output enters the evidence corpus

*Confidence-to-Uncertainty Mapping Runtime:*
- Mapping rule registry enforcement: only registered mapping rules may
  be applied
- Floor confidence enforcement: outputs below the floor confidence
  threshold automatically receive `U-UNKNOWN-UNCERTAINTY` regardless of
  other rules
- Version binding: mapping rules are version-bound; historical records
  remain governed by the mapping version active at their production time

*AI Estimation Adapters (MC-001):*
- Missing activity data imputation: estimates consumption, production,
  or activity quantities from historical patterns and declared priors
- Emission factor estimation: estimates sector-specific emission factors
  from comparable facilities or published ranges where direct measurement
  is unavailable
- Energy consumption inference: estimates energy use from process
  parameters, throughput, and technology class

*AI Classification Adapters (MC-002):*
- Industrial process classification: assigns facilities to process
  categories for ontology mapping
- Waste stream classification: categorises waste inputs for methane
  generation calculations
- Land cover classification: assigns land use categories for spatial
  and DNSH evaluation support

*AI Forecasting Adapters (MC-005):*
- Baseline emissions projection: produces forward-looking emissions
  estimates for project baseline calculations
- Sequestration trajectory: estimates future sequestration rates from
  current conditions and declared methodology assumptions
- All MC-005 outputs receive `FLAGGED_MAXIMUM` admissibility ceiling
  pending methodology-specific promotion

*Adapter Certification Extensions for AI:*
- An adapter using AI capabilities must declare: which model class is
  used, which model IDs are permitted, the confidence-to-uncertainty
  mapping rule applied, and the admissibility ceiling for its outputs
- An adapter that invokes a non-registered model is constitutionally
  uncertifiable
- An adapter that produces outputs above its declared admissibility
  ceiling without human review authorization fails certification

**Concrete Example — Copper Smelter Missing Data (§5.16.1):**
A copper smelter lacks one month of electricity consumption records.
The MC-001 estimation adapter:
1. Retrieves historical consumption patterns from admitted evidence
2. Executes inference using the registered model version and declared seed
3. Produces a confidence interval output
4. Confidence-to-uncertainty mapping converts to `U-CONFIDENCE-INTERVAL`
   at the appropriate confidence level
5. Inference log record is created before the uncertainty measurement
   record
6. The `uncertainty_measurements` record carries the inference_log FK
7. The admissibility gate routes to human review per the declared
   admissibility ceiling
8. Human reviewer admits or rejects the estimate
9. If admitted, the estimate enters the evidence corpus with full
   provenance chain traceable to the model version, input snapshot,
   and reviewer authority

**What Phase 5 AI does not build:**
New model classes; new confidence-to-uncertainty mapping types; AI
capabilities in finality-adjacent surfaces; autonomous admission without
policy authorization.

---

## Phase 6 Augmentation — Operational AI Intelligence

### New §6.10 — AI-Assisted Field and Verification Intelligence

**Constitutional Purpose:** Implement operational AI capabilities that
support field data capture, document processing, verification workflows,
and risk assessment at the UI and operational surface layer.

**What this builds:**

*Document Intelligence (MC-004):*
- OCR for meter readings, invoices, and measurement certificates:
  extracts numerical values with per-field confidence scores
- Satellite imagery interpretation: classifies land cover change with
  confidence score for spatial and DNSH gate support
- Document classification: assigns document type and relevance class
  to uploaded evidence artifacts
- Translation: converts non-English field documentation to English
  with confidence score (translation confidence maps to
  `U-DATA-QUALITY-INDICATOR` DQ-TIER-3 or better)

All MC-004 outputs receive per-field `U-DATA-QUALITY-INDICATOR`
uncertainty class via the default confidence-to-uncertainty mapping.
All OCR-extracted values are `ADMISSIBLE_WITH_REVIEW` at maximum —
a human reviewer must confirm extracted values before they become
admitted evidence.

*Anomaly Detection (MC-003):*
- Meter reading anomaly detection: flags statistically unusual readings
  relative to historical baseline
- Temporal pattern anomaly: identifies unusual submission timing patterns
  that may indicate backdating or front-loading
- Spatial anomaly: flags activity data that is inconsistent with
  declared facility location or process type

All MC-003 outputs are `FLAGGED_MAXIMUM`. They produce risk signal
records, not admissibility findings. Anomaly flags route to:
- Contradiction detection surface (`P3-SURF-004`) for pattern
  evaluation
- VVB review queue for human assessment
- They do not automatically block, reject, or reclassify evidence

*Risk Scoring (MC-006):*
- Verifier risk scoring: composite score assessing verifier workload,
  historical accuracy, and conflict-of-interest proximity
- Project quality pre-screening: advisory score for VVB triage purposes
- Submission risk score: advisory assessment of evidence package
  completeness and internal consistency

All MC-006 outputs are `DRAFT_ONLY`. They are operational tools for
VVBs and field operators, not constitutional findings.

**Governance Rule for Phase 6 AI:**
Phase 6 AI outputs are advisory inputs to human decision surfaces.
They do not modify uncertainty class declarations, produce admissibility
findings, or route directly to constitutional enforcement surfaces.
A Phase 6 AI output that is accepted by a human reviewer becomes a
human-authored evidence record citing the AI output as a provenance
source — not an AI-authored evidence record.

---

## Phase 7 Augmentation — AI Methodology Neutrality Proof

### Addition to §7.7 — AI Model Isolation Proof

**Proof Obligation Extension:**
In addition to the existing uncertainty methodology neutrality proof,
Phase 7 must prove that:

- AI model outputs for the second methodology are processed through the
  same Model Registry, inference log schema, and confidence-to-uncertainty
  mapping framework as the first methodology — with no new schemas,
  model classes, or mapping rules required
- AI anomaly detection for the second methodology uses the same MC-003
  framework without methodology-specific anomaly class invention
- Cross-methodology AI isolation: an AI inference performed for
  Methodology A must not consume evidence records produced for
  Methodology B
- The Phase 3 `verify_p3_ai_output_admissibility.sh` verifier passes
  for both methodologies' AI inference records without modification

Failure of the AI isolation proof is a Phase 7 exit criteria failure.

---

## Phase 8A Augmentation — AI-Free Confirmation

### Addition to §8A — AI-Free Surface Confirmation

Phase 8A's authorization surfaces are constitutionally AI-free per
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` §8.

Evidence that entered the authorization pack from an AI-assisted
estimation pathway is permissible only if: the AI output was admitted
through the full admissibility apparatus including human review,
converted to a Phase 3 uncertainty class, and resolved to a definite
value via a registered decision policy before Phase 8A processing.

The authorization pack itself, the LoA ingestion surface, and the
corresponding adjustment binding surface do not invoke AI capabilities
at any point.

---

## Phase 8B Augmentation — AI-Free Confirmation

### Addition to §8B — AI-Free Surface Confirmation

Phase 8B's registry submission surfaces are constitutionally AI-free.
The same rule applies as Phase 8A: evidence with an AI-assisted
provenance history is permissible only after full admission and
uncertainty resolution. The registry bridge and reconciliation surfaces
themselves do not invoke AI.

---

## Phase 8D Augmentation — Disclosure Intelligence

### New §8D.10 — AI-Assisted Disclosure Intelligence

**Constitutional Purpose:** Implement AI capabilities that support CBAM
evidence completion, supplier data gap filling, and disclosure drafting
within the constitutional admissibility framework.

**What this builds:**

*Supplier Data Completion (MC-001 in disclosure context):*
- Where an upstream supplier omits embedded emissions data, an MC-001
  estimation adapter estimates likely values from process class, energy
  mix, and comparable facility data
- Estimation produces a `U-CONFIDENCE-INTERVAL` or
  `U-DATA-QUALITY-INDICATOR` uncertainty class
- The estimation assumptions are recorded in `uncertainty_assumptions`
  with the governing methodology artifact cited
- Conservative resolution (DP-UPPER-BOUND) is applied before the
  estimate enters a CBAM evidence package
- The full inference chain — model version, input snapshot, confidence
  score, mapping rule, resolution operator — is included in the
  shipment-level replay record

*CBAM Anomaly Detection (MC-003 in disclosure context):*
- Identifies unusual patterns in embedded emissions filings that may
  indicate misclassification, omission, or data quality issues
- Produces risk signals only — `FLAGGED_MAXIMUM` admissibility ceiling
- Routes to human review before the evidence package is finalized

*Disclosure Drafting Support (MC-004 in disclosure context):*
- Assists in populating ESRS E1, ISSB S2, and CBAM disclosure fields
  from admitted evidence records
- Drafting outputs are `DRAFT_ONLY` — they require human review and
  approval before becoming part of the disclosure package
- The human reviewer's approval is the constitutional event that
  finalizes the disclosure content, not the AI drafting output

**Concrete Example — CBAM Supplier Gap (§8D.10.1):**
A Zambian copper smelter's upstream electricity supplier omits their
generation mix data. The Phase 8D supplier data completion adapter:
1. Retrieves grid mix data from admitted national grid records and
   comparable facility evidence
2. MC-001 estimates the likely generation mix with confidence interval
3. Inference log record created; uncertainty class assigned
4. DP-UPPER-BOUND resolution applied (conservative maximum emissions)
5. Resolution record added to uncertainty_propagation_steps
6. The resolved definite value enters the CBAM evidence package
7. The full inference-to-resolution chain is included in the shipment
   replay record for future dispute reconstruction

---

## Phase 8E Augmentation — Climate Finance Intelligence

### New §8E.6 — AI-Assisted Climate Finance Intelligence

**Constitutional Purpose:** Implement AI capabilities that support
project quality assessment, impact forecasting, and underwriter due
diligence within the constitutional admissibility framework.

**What this builds:**

*Project Quality Scoring (MC-006 in climate finance context):*
- Composite advisory score for green bond eligible projects assessing
  evidence completeness, methodology quality, verifier track record,
  and uncertainty profile
- `DRAFT_ONLY` admissibility ceiling — advisory input to underwriters
  only, not a constitutional finding
- Score components are traceable to their Phase 3 evidence source
  records

*Impact Forecasting (MC-005 in climate finance context):*
- Forward-looking impact estimates for bond period performance
  projections
- `FLAGGED_MAXIMUM` ceiling — requires methodology expert review before
  inclusion in any bond documentation
- All forecasts carry `U-CONFIDENCE-INTERVAL` or
  `U-DECLARED-DISTRIBUTION` uncertainty class; no point estimate
  forecasts permitted without declared bounds

*Underwriter Portfolio Risk Modelling (MC-001 + MC-006 combined):*
- Estimates portfolio-level emissions exposure and credit risk from
  individual project uncertainty profiles
- Aggregation uses Phase 3 registered operators (OP-010 worst-case
  aggregation as the conservative default)
- Advisory output to underwriters; `DRAFT_ONLY` ceiling

**Governance Rule for Phase 8E AI:**
All Phase 8E AI outputs are advisory to human underwriter and
regulatory review surfaces. No AI output in Phase 8E constitutes a
green bond eligibility determination, an impact certification, or a
regulatory compliance finding. Those determinations are made by
constitutionally declared human authorities citing admitted evidence.

---

## AI Phase Routing Summary (Complete)

| Capability | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 | Phase 8A | Phase 8B | Phase 8D | Phase 8E |
|---|---|---|---|---|---|---|---|---|---|
| AI governance doctrine | Owns | — | Consumes | Consumes | Consumes | Consumes | Consumes | Consumes | Consumes |
| Model Registry schema | Owns | — | Runtime | — | Proof | — | — | — | — |
| Inference log schema | Owns | — | Runtime | Runtime | Proof | — | — | Runtime | Runtime |
| Confidence-to-uncertainty mapping | Owns schema | — | Runtime | Runtime | — | — | — | Runtime | Runtime |
| INV-313 verifier | Owns | — | Extends | — | — | — | — | — | — |
| AI finality exclusion | — | AI-FREE | — | — | — | AI-FREE | AI-FREE | — | — |
| MC-001 estimation adapters | — | — | Owns | — | — | — | — | Supplier completion | Portfolio estimation |
| MC-002 classification adapters | — | — | Owns | — | — | — | — | — | — |
| MC-003 anomaly detection | — | — | — | Owns | — | — | — | CBAM anomaly | — |
| MC-004 document intelligence | — | — | — | Owns (OCR, classification) | — | — | — | Disclosure drafting | — |
| MC-005 forecasting | — | — | Owns (baseline) | — | — | — | — | — | Impact forecasting |
| MC-006 risk scoring | — | — | — | Owns (verifier risk) | — | — | — | CBAM anomaly triage | Project scoring |
| Cross-methodology AI isolation proof | — | — | — | — | Owns | — | — | — | — |
| Disclosure intelligence | — | — | — | — | — | — | — | Owns | — |
| Climate finance intelligence | — | — | — | — | — | — | — | — | Owns |

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
AI capability phase routing across Phases 3 through 8E; AI output
admissibility sovereignty; model provenance sovereignty for all phases.

**Sovereignty domains this document must not redefine:**
Phase constitutional boundaries (governed by
`Symphony-Phase-Specification-Document_v1.md`); AI admissibility rules
(governed by
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md`); uncertainty
representation classes (governed by
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`).

**Phases this document applies to:**
Phases 3 through 8E. Global for AI capabilities.

**Constitutional layers with override authority:**
`Symphony-Phase-Specification-Document_v1.md` (Authority-Rank 7),
`AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md`
(Authority-Rank 8), and the constitutional corpus. This augmentation
(Authority-Rank 6) operates within those constraints.

**Lower-layer documents prohibited from reinterpretation:**
Phase-specific implementation plans, wave plans, and task packs may not
reassign AI capability phase ownership without an amendment to this
augmentation document.