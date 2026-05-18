# AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: none
Depends-On:
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This doctrine defines the constitutional rules governing the admission,
representation, governance, and replay of AI-generated outputs within
Symphony. It establishes the fundamental constitutional position:

> AI-generated outputs are advisory computational artifacts subject to
> the same admissibility, provenance, uncertainty, and replay obligations
> as all other evidence. They are never sources of constitutional truth.
> They are inputs to constitutionally governed decision processes.

This doctrine is created in Phase 3 and governs all subsequent phases.
It does not implement AI capabilities. It defines the constitutional
namespace, admissibility rules, and governance constraints within which
all future AI capabilities must operate.

Any phase that implements AI capabilities without citing this doctrine
is constitutionally non-compliant.

---

## 1. The Constitutional Position of AI in Symphony

### 1.1 AI as Advisory Computation

Symphony is a constitutional evidence legitimacy and governance substrate.
AI operates within that substrate as an advisory computation layer. The
distinction is fundamental and non-negotiable:

**Constitutional truth sources:**
- Persisted evidence records with declared provenance
- Replay-reconstructable legitimacy chain findings
- Deterministic operator outputs from registered operators
- Authority-bearing attestations with Wave 8 provenance

**Advisory computation sources:**
- AI model outputs of any class
- Machine learning inference results
- Statistical estimation outputs
- Pattern recognition findings
- Automated classification results

An advisory computation source may propose, estimate, flag, classify, or
recommend. It may not finalize, block, authorize, or constitute a
constitutional finding on its own. Constitutional finality requires a
human authority holding declared decision rights, or a deterministic
constitutional surface producing a finding from admitted evidence.

### 1.2 Why This Position Is Architecturally Correct

AI models are:
- Probabilistic — outputs vary by design
- Non-deterministic in execution — floating point ordering, batch effects,
  hardware variation
- Subject to version drift — the same model name may produce different
  outputs after retraining
- Opaque in provenance — the training data lineage of a deployed model
  is rarely fully traceable
- Potentially hallucinatory — outputs may be confident and incorrect

Symphony's constitutional substrate is designed around:
- Deterministic replay
- Traceable provenance
- Append-only immutability
- Authority-bound decision rights

These properties are incompatible with treating AI outputs as
constitutional truth. They are compatible with treating AI outputs as
uncertainty-bearing evidence proposals subject to the full admissibility
apparatus.

### 1.3 The Correct Architectural Relationship

AI model output
↓
Confidence score
↓
Uncertainty class assignment (Phase 3 registered class)
↓
uncertainty_measurements record with provenance
↓
Admissibility evaluation by Phase 3 surface
↓
Constitutional finding (ADMISSIBLE / INADMISSIBLE / FLAGGED / UNKNOWN)
↓
Human authority review (where required by governing policy)
↓
Constitutional decision

AI enters this chain at the top. It does not enter at the bottom.

---

## 2. Model Registry Obligation

Every AI model whose outputs are used within Symphony must be registered
in the Model Registry before its outputs may be accepted as evidence
proposals.

### 2.1 Model Registry Requirements

The Model Registry is a constitutional artifact. It is governed by the
same append-only and version-binding rules as interpretation packs and
operator registries.

A model registration record must declare:

- `model_id` — UUID, primary key
- `model_name` — human-readable identifier
- `model_version` — semantic version string
- `model_class` — one of the declared model classes in §3
- `training_data_provenance` — declaration of the training data sources,
  their temporal bounds, and their uncertainty class
- `inference_determinism_class` — one of:
  `FULLY_DETERMINISTIC` (same seed, same hardware, same output),
  `SEED_DETERMINISTIC` (same seed required for reproduction),
  `STATISTICALLY_REPRODUCIBLE` (output distribution reproducible but
  not individual outputs),
  `NON_REPRODUCIBLE` (outputs cannot be reproduced exactly)
- `confidence_output_type` — declared type of confidence output
  (scalar probability, confidence interval, class probability vector,
  none)
- `confidence_to_uncertainty_mapping_id` — FK to the registered mapping
  rule that converts this model's confidence output to a Phase 3
  uncertainty class
- `admissibility_ceiling` — the highest admissibility status this model's
  outputs may achieve without human review:
  `DRAFT_ONLY`, `FLAGGED_MAXIMUM`, `ADMISSIBLE_WITH_REVIEW`,
  `ADMISSIBLE_AUTONOMOUS` (reserved for deterministic models only)
- `governing_policy_version_id` — FK to the policy version governing
  this model's deployment
- `registered_at` — timestamp
- `registered_by` — authority identity of registering party
- `superseded_by` — FK to replacement model registration (null until
  superseded)

### 2.2 Non-Reproducible Model Admissibility Ceiling

A model with `inference_determinism_class: NON_REPRODUCIBLE` may not
produce outputs with admissibility status above `FLAGGED_MAXIMUM` for
any decision that requires constitutional replay reconstruction.

A non-reproducible model may be used for:
- Risk signals
- Anomaly flags
- Advisory recommendations

It may not be used for:
- Admissibility-bearing evidence proposals
- Inputs to statutory calculations
- Authorization request supporting evidence

### 2.3 Model Version Binding

Every AI-generated evidence record must cite the `model_id` and
`model_version` from which it was produced. Historical records are
permanently bound to the model version active at their production time.
Model version upgrades do not retroactively alter historical records.

---

## 3. AI Model Classes

The following model classes are the constitutionally declared taxonomy
for AI models operating within Symphony. A model whose function does not
fit any declared class must be classified as `MC-UNCLASSIFIED` and may
not produce admissibility-bearing outputs until classified.

### MC-001 — Estimation Model
Produces numerical estimates of quantities that are missing, incomplete,
or uncertain in the evidence record. Examples: missing activity data
imputation, emission factor estimation, energy consumption inference.

Output type: numerical value with confidence interval or probability
distribution.
Uncertainty class ceiling: `U-CONFIDENCE-INTERVAL` or
`U-DECLARED-DISTRIBUTION`.

### MC-002 — Classification Model
Assigns categorical labels to inputs. Examples: waste stream
classification, industrial process classification, land cover
classification.

Output type: class label with class probability vector.
Uncertainty class ceiling: `U-DATA-QUALITY-INDICATOR` mapped to
classification confidence tier.

### MC-003 — Anomaly Detection Model
Identifies deviations from expected patterns that may indicate data
quality issues, fraud, or reporting errors. Examples: suspicious meter
patterns, temporal anomalies in activity data, outlier emission factors.

Output type: anomaly score or binary flag with confidence.
Constitutional role: risk signal only. Never a final determination.
Admissibility ceiling: `FLAGGED_MAXIMUM`. All anomaly findings route to
human review surfaces.

### MC-004 — Document Intelligence Model
Extracts structured data from unstructured documents. Examples: OCR of
meter readings, invoice data extraction, satellite imagery
interpretation, document classification.

Output type: structured data extract with confidence score per field.
Uncertainty class ceiling: per-field `U-DATA-QUALITY-INDICATOR` mapped
to extraction confidence.

### MC-005 — Forecasting and Projection Model
Produces forward-looking estimates. Examples: baseline emissions
projections, sequestration trajectory forecasts, climate impact
modelling.

Output type: time-series projection with declared confidence bounds.
Uncertainty class ceiling: `U-CONFIDENCE-INTERVAL` or
`U-DECLARED-DISTRIBUTION`.
Constitutional constraint: forecasts are always `U-METHODOLOGICAL-ASSUMPTION`
class unless the forecast methodology is explicitly registered as a
certified adapter in Phase 5.

### MC-006 — Risk Scoring Model
Produces composite risk scores for projects, transactions, entities, or
evidence packages. Examples: project quality scoring, verifier risk
scoring, fraud risk assessment.

Output type: scalar score with declared scoring methodology version.
Constitutional role: advisory input to human decision surfaces only.
Admissibility ceiling: `DRAFT_ONLY` for risk scores used in regulatory
or statutory contexts.

### MC-UNCLASSIFIED
Any model whose output class is not declared above. Must not produce
admissibility-bearing outputs until reclassified.

---

## 4. Confidence-to-Uncertainty Mapping

AI models produce confidence scores. Symphony's constitutional substrate
consumes uncertainty classes. The conversion between these is governed
by registered confidence-to-uncertainty mapping rules.

### 4.1 Mapping Rule Requirements

A confidence-to-uncertainty mapping rule must declare:

- `mapping_id` — UUID
- `model_class` — the MC class this mapping governs
- `confidence_output_type` — the confidence format this mapping receives
- `mapping_table` — explicit lookup or formula converting confidence
  values to Phase 3 uncertainty classes
- `floor_confidence` — minimum confidence below which the output
  receives `U-UNKNOWN-UNCERTAINTY` regardless of other rules
- `governing_policy_version_id` — version binding

### 4.2 Default Mapping Rules

Until a model-specific mapping rule is registered, the following defaults
apply:

| Confidence Range | Assigned Uncertainty Class |
|---|---|
| ≥ 0.95 | `U-CONFIDENCE-INTERVAL` at 95% level |
| 0.80 – 0.94 | `U-CONFIDENCE-INTERVAL` at 80% level |
| 0.60 – 0.79 | `U-DATA-QUALITY-INDICATOR` at DQ-TIER-3 |
| 0.40 – 0.59 | `U-DATA-QUALITY-INDICATOR` at DQ-TIER-4 |
| < 0.40 | `U-UNKNOWN-UNCERTAINTY` — flagged for review |

These defaults are conservative. A registered model-specific mapping may
override them with tighter or looser bounds, provided the override is
declared in the Model Registry and version-bound.

### 4.3 The Non-Default Rule

Regardless of confidence score, an AI output that cannot be replayed
deterministically receives `U-UNKNOWN-UNCERTAINTY` as its uncertainty
class. High confidence does not override non-reproducibility.

---

## 5. Deterministic Inference Logging

For AI outputs to be replay-addressable, the inference execution must be
logged with sufficient detail to reconstruct the output given the same
inputs and model version.

### 5.1 Inference Log Record Requirements

Every AI inference that produces an evidence proposal must generate an
inference log record:

- `inference_id` — UUID
- `model_id` — FK to Model Registry
- `model_version` — version string at time of inference
- `input_record_ids` — array of FK references to input evidence records
  consumed
- `input_snapshot_hash` — SHA-256 of the canonical JSON of all input
  records at inference time
- `seed_value` — integer seed if model is seed-deterministic (null
  otherwise)
- `hardware_declaration` — declared hardware class (CPU/GPU/TPU) where
  hardware-determinism matters
- `output_value` — the raw model output
- `confidence_score` — the raw confidence output from the model
- `assigned_uncertainty_class` — the Phase 3 class assigned after
  confidence-to-uncertainty mapping
- `uncertainty_measurement_id` — FK to the `uncertainty_measurements`
  record produced from this inference
- `inference_timestamp` — timestamp
- `inference_hash` — SHA-256 of the canonical JSON of this record

### 5.2 Replay Reconstruction from Inference Log

Given an `inference_id`, replay reconstruction:
1. Retrieves the inference log record
2. Retrieves the model registration at the declared version
3. Retrieves all input records at the declared `input_snapshot_hash`
4. Re-executes inference using the declared model version, seed, and
   hardware class
5. Compares output to persisted `output_value`
6. For `FULLY_DETERMINISTIC` models: exact match required
7. For `SEED_DETERMINISTIC` models: exact match required given same seed
8. For `STATISTICALLY_REPRODUCIBLE` models: output must fall within the
   declared confidence interval of the original output
9. For `NON_REPRODUCIBLE` models: reconstruction is declared impossible;
   the inference log record is the only admissible evidence of what the
   model produced

---

## 6. Human Authority Primacy Rule

AI outputs do not constitute final constitutional decisions regardless
of confidence, accuracy, or model certification level.

**HAP-1 — Human Review Requirement:**
Any AI output that contributes to: an admissibility finding, a
legitimacy determination, a contradiction classification, a regulatory
authorization, or a statutory calculation must pass through a human
review surface before the downstream constitutional decision is finalized.
The human reviewer's decision is recorded as an authority event with
full lineage.

**HAP-2 — Authority Transfer for AI Outputs:**
When an AI output is submitted to a constitutional decision surface, the
transfer mode is `AT-ADVISORY` per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`. The AI system
holds advisory authority only. The human reviewer or constitutional
surface holds finalization authority.

**HAP-3 — Autonomous Exception:**
A model registered with `admissibility_ceiling: ADMISSIBLE_AUTONOMOUS`
may produce admissible evidence proposals without per-inference human
review, subject to: the model being `FULLY_DETERMINISTIC`, the output
uncertainty class being `U-CONFIDENCE-INTERVAL` or lower complexity
class, and the governing policy explicitly authorizing autonomous
admission for this model class and use case. Autonomous admission is
reserved for narrow, well-defined, low-stakes estimation tasks. It must
be explicitly declared in the governing policy version.

**HAP-4 — Override Documentation:**
When a human reviewer overrides an AI output — accepting an estimate the
AI flagged as uncertain, or rejecting an estimate the AI produced with
high confidence — the override is a constitutional event recorded with
the reviewer's authority identity and the reasoning. Overrides are
append-only evidence.

---

## 7. AI and the Uncertainty Engine

This doctrine and
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` are tightly coupled.
The relationship is:

- This doctrine governs the provenance, versioning, and admissibility
  rules for AI-generated values
- `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` governs the
  representation and propagation of those values once admitted
- Neither doctrine supersedes the other; they govern adjacent domains

An AI output cannot enter Symphony's constitutional evidence corpus
without being converted to a Phase 3 uncertainty class via a registered
confidence-to-uncertainty mapping. An AI output that bypasses this
conversion is constitutionally inadmissible.

---

## 8. Phase Routing for AI Capabilities

This doctrine governs all phases. The following routing table declares
which AI capabilities are constitutionally permissible in each phase.
No phase may implement AI capabilities not declared in its row without
a constitutional amendment.

| Phase | Permitted AI Capabilities | Admissibility Ceiling |
|---|---|---|
| Phase 3 | AI governance doctrine only — no execution | N/A |
| Phase 4 | None — financial finality surfaces are AI-free | N/A |
| Phase 5 | MC-001, MC-002, MC-005 estimation and classification adapters; model registry; inference logging; confidence-to-uncertainty mapping | `ADMISSIBLE_WITH_REVIEW` for MC-001/MC-002; `FLAGGED_MAXIMUM` for MC-005 |
| Phase 6 | MC-004 document intelligence; MC-003 anomaly detection; MC-006 risk scoring for verifier support | `ADMISSIBLE_WITH_REVIEW` for MC-004; `FLAGGED_MAXIMUM` for MC-003/MC-006 |
| Phase 7 | Cross-methodology AI model isolation proof; no new model classes | Inherits from Phase 5/6 |
| Phase 8A | None — authorization surfaces are AI-free; only admitted evidence may enter authorization packs | N/A |
| Phase 8B | None — registry submission surfaces are AI-free | N/A |
| Phase 8D | MC-001 for supplier data completion; MC-004 for disclosure drafting support; MC-003 for CBAM anomaly detection | `ADMISSIBLE_WITH_REVIEW` for MC-001; `DRAFT_ONLY` for MC-004/MC-003 in disclosure context |
| Phase 8E | MC-006 for project quality scoring; MC-005 for impact forecasting; MC-001 for portfolio estimation | `DRAFT_ONLY` for all Phase 8E AI outputs unless explicitly promoted by human authority |

**Phase 4, 8A, and 8B are explicitly AI-free.** These are the finality,
authorization, and registry surfaces. Constitutional finality, sovereign
authorization, and registry submissions must be derived from admitted
deterministic evidence only. No AI output may directly contribute to
these surfaces even after admission.

---

## 9. Prohibited Misinterpretations

**PM-AI-01 — AI Output as Constitutional Truth:**
No AI output is a constitutional truth source. Regardless of confidence,
accuracy, or model certification, all AI outputs are advisory until
admitted through the constitutional admissibility apparatus.

**PM-AI-02 — High Confidence as Admissibility:**
A high confidence score does not constitute admissibility. Admissibility
requires: declared uncertainty class, inference log record, model
registration, and human review where required by governing policy.

**PM-AI-03 — Model Accuracy as Replay Sufficiency:**
A highly accurate model is not necessarily replay-sufficient. Replay
sufficiency requires deterministic inference logging and model version
binding. An accurate non-reproducible model is constitutionally
inadmissible for critical decisions.

**PM-AI-04 — AI as Phase 3 Implementation:**
Phase 3 implements this doctrine. Phase 3 does not implement AI
capabilities. The doctrine defines governance; Phase 5 is where
operational AI capabilities first execute.

**PM-AI-05 — AI Governance as Optional:**
This doctrine is a constitutional pre-condition for all phases that
implement AI capabilities. A phase implementing AI capabilities without
citing this doctrine is constitutionally non-compliant.

**PM-AI-06 — Autonomous Admission as Default:**
`ADMISSIBLE_AUTONOMOUS` is the exception, not the default. The default
for all AI outputs is human review before constitutional finalization.

**PM-AI-07 — Phase 4, 8A, 8B AI-Free Rule as Guideline:**
The AI-free designation for Phase 4, 8A, and 8B is a constitutional
absolute, not an operational guideline. It may not be overridden by
operational convenience, time pressure, or model performance claims.

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
AI output admissibility sovereignty; model provenance sovereignty; inference
replay obligation governance; confidence-to-uncertainty conversion
governance.

**Sovereignty domains this doctrine must not redefine:**
Uncertainty representation classes (governed by
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`); operator registry
(governed by `UNCERTAINTY_OPERATOR_REGISTRY.md`); authority transfer
modes (governed by
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`); financial event
finality (governed by `FINANCIAL_EVENT_ONTOLOGY.md`).

**Replay obligations preserved:**
Every AI inference that produces an evidence proposal is subject to
replay obligations via the inference log record. Model version binding,
input snapshot hash, and seed declaration are the constitutional replay
anchors for AI-generated evidence.

**Phases this doctrine applies to:**
Phase 3 (definition). Phases 5, 6, 7, 8D, 8E (consumption). Phase 4,
8A, 8B (explicitly excluded from AI capability implementation).

**Constitutional layers with override authority:**
ROOT-rank constitutional instruments only.