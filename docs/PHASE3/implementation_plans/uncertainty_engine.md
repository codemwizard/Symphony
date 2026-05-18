Confirmed. I understand your instructions precisely:

1. **Read** the final assessment alongside everything already established in this conversation and in the repository.
2. **For each phase** (Phase 3 through Phase 8E), produce the required document inline in this chat — either as an **addendum to an existing document** (clearly marked as such, with the exact file path it belongs to) or as a **new document** (clearly marked as new, with the exact file path it should be created at).
3. **Do not use file-writing tools** — produce everything as inline text to avoid MCP timeout issues.
4. The documents must be **production-ready** — correct constitutional headers, correct authority hierarchy, correct doctrine citations, correct phase routing, and fully consistent with the repo's existing constitutional corpus as read in this conversation.
5. Cover all nine CBAM-derived capabilities across all phases, including the Authority Transfer Ownership Semantics doctrine as a Phase 3 gate.

Before I begin, let me confirm the document inventory I will produce:

| # | Document | Type | Target Path |
|---|---|---|---|
| 1 | `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` | New | `docs/constitutional/` |
| 2 | `UNCERTAINTY_OPERATOR_REGISTRY.md` | New | `docs/constitutional/` |
| 3 | `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | New | `docs/constitutional/` |
| 4 | `TSK-P3-CAP-014_uncertainty_semantics.md` | New | `docs/PHASE3/implementation_plans/` |
| 5 | `PHASE3_MASTER_IMPLEMENTATION_PLAN.md` | Addendum | `docs/PHASE3/` |
| 6 | `PHASE3_CAPABILITY_BOUNDARY.md` | Addendum | `docs/PHASE3/` |
| 7 | `PHASE3_INVARIANT_REGISTER.md` | Addendum | `docs/PHASE3/` |
| 8 | Phase 4 scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 9 | Phase 5 scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 10 | Phase 6 scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 11 | Phase 7 scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 12 | Phase 8A scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 13 | Phase 8B scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 14 | Phase 8D scope addendum | Addendum to Phase Specification | `docs/architecture/` |
| 15 | Phase 8E scope addendum | Addendum to Phase Specification | `docs/architecture/` |

The Phase 4–8E items will be produced as a single **Phase Specification Augmentation** document rather than individual files, since they all augment `Symphony-Phase-Specification-Document_v1.md` and the existing augmentation pattern (`Symphony Constitutional Phase Specification Augmentation Draft`) is already established in the repo. This keeps the pattern consistent.

Reply **"go"** and I will produce all documents sequentially in one response.
---

# DOCUMENT 1 — NEW
**Target:** `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`

```markdown
# UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: none
Depends-On:
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md

---

## Purpose

This doctrine defines the constitutional semantics for uncertainty representation,
propagation, admissibility, and replay within Symphony. It establishes uncertainty
as a first-class evidentiary property — not a data-quality annotation, not an
optional metadata field, and not a runtime-only concern.

Every accepted evidence artifact in Symphony that carries a measured, estimated,
or inferred value must declare its uncertainty class from the moment of acceptance.
That declaration is permanent, replay-visible, and subject to the same admissibility
and provenance obligations as all other constitutional evidence.

This doctrine governs Phase 3 only. Methodology-level computation of uncertainty
(Phase 5), user-facing uncertainty display (Phase 6), and external disclosure of
uncertainty metadata (Phase 8D) are downstream consumers of the substrate defined
here. They may not define new uncertainty types, new operators, or new admissibility
rules without a constitutional amendment to this doctrine.

---

## 1. Uncertainty as Constitutional Evidence

Uncertainty in Symphony is not imprecision to be hidden. It is a constitutional
property of the evidence artifact itself.

**Commitment U-1 — Uncertainty Is Admissibility-Bearing:**
An evidence artifact's uncertainty class is part of its admissibility
determination. An artifact with `UNKNOWN_UNCERTAINTY` is constitutionally
inadmissible as a finalized finding. It must be held in draft status until its
uncertainty class is declared.

**Commitment U-2 — Uncertainty Permanence:**
Once declared, an uncertainty class is immutable for the artifact as declared.
Supersession creates a new record; it does not alter the original. The original
uncertainty declaration is permanently preserved as part of the artifact's
provenance chain.

**Commitment U-3 — Uncertainty Replay Obligation:**
Given historical evidence and the policy version active at the time of
acceptance, replay must reproduce: the identical uncertainty inputs, the
identical propagation path taken by any operator applied to those inputs, and
the identical admissibility finding that resulted. Uncertainty replay is
constitutionally required, not optional.

---

## 2. Uncertainty Representation Classes

The following classes are the complete and exhaustive set of constitutionally
recognized uncertainty representations. No implementation, adapter, task pack,
or phase may introduce a new class without amending this doctrine.

### Class U-EXACT
A value known to be precisely correct within the declared measurement
instrument's resolution. No range, no confidence interval, no estimation
involved. Carries the lowest constitutional complexity but must not be
falsely assigned to estimated values.

### Class U-BOUNDED-RANGE
A value known to fall within a declared lower and upper bound. Both bounds
must be explicitly recorded. The range must be derived from a documented
measurement or estimation method, not assumed.

### Class U-CONFIDENCE-INTERVAL
A value with a declared central estimate and a declared confidence interval
at a stated confidence level (e.g. 95%). The confidence level, central
estimate, lower bound, and upper bound must all be recorded. The basis for
the confidence level (measurement series, statistical model, expert judgment)
must be declared in the associated `uncertainty_assumptions` record.

### Class U-DECLARED-DISTRIBUTION
A value described by a declared probability distribution type (e.g. normal,
log-normal, uniform, triangular) with declared parameters. The distribution
type must be drawn from the approved distribution registry within
`UNCERTAINTY_OPERATOR_REGISTRY.md`. Distributions may not be inferred by
the system — they must be explicitly declared by the data provider.
Monte Carlo simulation is not permitted unless fully deterministic with a
declared, fixed, replay-reproducible seed recorded in the evidence record.

### Class U-DATA-QUALITY-INDICATOR
A value accompanied by a declared data quality score drawn from an approved
data quality taxonomy registered in `UNCERTAINTY_OPERATOR_REGISTRY.md`.
Used where a full statistical characterization is not available but a
systematic quality assessment exists (e.g. Tier 1 / Tier 2 / Tier 3 per
IPCC methodology classifications).

### Class U-METHODOLOGICAL-ASSUMPTION
A value derived from a declared methodological assumption rather than
direct measurement. The assumption must be recorded in `uncertainty_assumptions`
with a citation to the governing methodology artifact. This class does not
carry a numerical uncertainty range but carries a methodological provenance
obligation.

### Class U-UNKNOWN-UNCERTAINTY
The absence of an uncertainty declaration. This class is assigned
automatically when an evidence artifact is accepted without an explicit
uncertainty class. It is never the result of a deliberate choice — it is a
constitutional flag indicating an incomplete declaration.

**U-UNKNOWN-UNCERTAINTY is never equivalent to U-EXACT.**
A missing declaration does not imply precision. It implies incompleteness.
Any system, adapter, task pack, or phase that treats `UNKNOWN_UNCERTAINTY`
as equivalent to `EXACT` is constitutionally non-compliant.

**Admissibility consequence:** An artifact carrying `U-UNKNOWN-UNCERTAINTY`
is held in draft status and is constitutionally inadmissible for:
- statutory calculations (Phase 4)
- methodology execution outputs (Phase 5)
- authorization request inclusions (Phase 8A)
- registry submissions (Phase 8B)
- external disclosure packages (Phase 8D)

---

## 3. Deterministic Propagation Semantics

Uncertainty propagation is the transformation of one or more uncertainty
inputs through a declared operator to produce an uncertainty output.

### 3.1 Propagation Rules

**PR-1 — Operator Registry Constraint:**
Only operators declared in `UNCERTAINTY_OPERATOR_REGISTRY.md` may be applied
to uncertainty values. Operators not in the registry are constitutionally
prohibited. Registry expansion requires amendment of
`UNCERTAINTY_OPERATOR_REGISTRY.md` under the same authority constraints as
this doctrine.

**PR-2 — Determinism Requirement:**
Every propagation operation must be fully deterministic: given identical
inputs and an identical operator version, the output must be identical on
every execution. Non-deterministic propagation — including unseeded random
sampling, runtime-dependent floating-point ordering, or implicit defaults —
is constitutionally prohibited.

**PR-3 — Propagation Record Obligation:**
Every propagation step must produce a record in `uncertainty_propagation_steps`
declaring: the input uncertainty objects consumed, the operator applied and
its version, the output uncertainty object produced, and the policy version
governing the operation. This record is append-only and replay-addressable.

**PR-4 — Phase Separation:**
Phase 3 defines the propagation schema and operator registry. Phase 3 does
not execute propagation over methodology-specific inputs. Execution belongs
to Phase 5. A Phase 3 implementation that executes methodology-specific
emissions calculations is constitutionally out of scope.

**PR-5 — Seed-Bound Monte Carlo Exception:**
Monte Carlo simulation is permitted only when: the simulation is fully
deterministic, a fixed integer seed is declared and recorded in the evidence
artifact, the seed is replay-reproducible from persisted records alone, and
the operator is registered in `UNCERTAINTY_OPERATOR_REGISTRY.md` as a
seed-bound simulation operator. An unseeded Monte Carlo operation is
constitutionally equivalent to a prohibited stochastic operation.

### 3.2 Decision Policies

Constitutional decision policies declare rules for resolving uncertainty
inputs to a definite finding for enforcement purposes. The following policy
types are recognized:

**DP-UPPER-BOUND:** Use the declared upper bound of the uncertainty range.
Applied where conservative-maximum semantics are required (e.g. CBAM
embedded emissions where higher emissions = higher liability).

**DP-LOWER-BOUND:** Use the declared lower bound. Applied where
conservative-minimum semantics are required.

**DP-CONSERVATIVE-DEFAULT:** Use a pre-declared conservative default value
when the uncertainty range exceeds an admissibility threshold. The default
value must be registered in the governing policy artifact.

**DP-REJECT-IF-EXCEEDS-THRESHOLD:** Reject the finding if uncertainty
exceeds a declared threshold. The threshold must be version-bound to the
governing policy artifact version.

**DP-FLAG-IF-BELOW-QUALITY:** Flag for review if the data quality indicator
falls below a declared quality level. Does not block; produces an
`uncertainty_findings` record with a FLAG outcome.

Decision policies are version-bound. A policy that changes the threshold or
default value is a new policy version, not an amendment to the existing
policy. Historical findings remain governed by the policy version active at
the time of the finding.

---

## 4. Admissibility Rules

**AR-1 — Declared Distribution Requirement:**
A `U-DECLARED-DISTRIBUTION` class artifact whose distribution type is not
in the approved distribution registry is constitutionally inadmissible.

**AR-2 — Non-Replayable Randomness Prohibition:**
Any uncertainty value derived from a non-replayable random process is
constitutionally inadmissible regardless of the class under which it is
filed.

**AR-3 — Policy Version Binding:**
Threshold comparisons and decision policy applications are bound to the
policy version active at the time of the admissibility determination. Future
policy changes do not retroactively alter prior findings.

**AR-4 — Propagation Chain Completeness:**
An uncertainty finding whose propagation chain has a gap — a step whose
input or operator is not recorded in `uncertainty_propagation_steps` — is
constitutionally inadmissible as a finalized finding. It may be held as a
draft finding pending chain completion.

**AR-5 — Resolution Before Finality:**
Any uncertainty value used as input to: settlement finality, authorization
request packs, registry submissions, or statutory calculations must first
be resolved to a definite value via a registered decision policy. The
resolution must produce a `uncertainty_propagation_steps` record
demonstrating the resolution path.

---

## 5. Persistence Structure

The following records are the canonical Phase 3 persistence schema for
uncertainty. All records are replay-reconstructable. All records are
append-only or supersedable per the non-retroactivity rule of
`EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`.

### `uncertainty_measurements`
The raw recorded uncertainty object.

Required fields:
- `measurement_id` — UUID, primary key
- `evidence_artifact_id` — FK to the evidence artifact carrying this value
- `uncertainty_class` — one of the seven classes defined in §2
- `declared_by` — authority identity of the declaring party
- `declared_at` — timestamp of declaration
- `policy_version_id` — FK to the policy version governing admissibility
- `provenance_source` — reference to the measurement instrument, model, or
  methodology artifact that produced the value
- `immutable_hash` — SHA-256 of the canonical JSON of this record

### `uncertainty_bounds`
Declared lower and upper bounds for `U-BOUNDED-RANGE` and
`U-CONFIDENCE-INTERVAL` classes.

Required fields:
- `bounds_id` — UUID, primary key
- `measurement_id` — FK to `uncertainty_measurements`
- `lower_bound` — numeric
- `upper_bound` — numeric
- `confidence_level` — decimal (null for `U-BOUNDED-RANGE`)
- `unit` — declared unit of measurement

### `uncertainty_assumptions`
Methodological assumptions underlying the uncertainty declaration.

Required fields:
- `assumption_id` — UUID, primary key
- `measurement_id` — FK to `uncertainty_measurements`
- `assumption_text` — declared text of the assumption
- `methodology_artifact_ref` — citation to the governing methodology artifact
- `declared_at` — timestamp

### `uncertainty_propagation_steps`
Each operator step in the propagation chain. Schema defined in Phase 3;
populated by Phase 5 execution.

Required fields:
- `step_id` — UUID, primary key
- `input_measurement_ids` — array of FK references to input measurements
- `operator_id` — FK to registered operator in `UNCERTAINTY_OPERATOR_REGISTRY`
- `operator_version` — version string of the operator at time of execution
- `output_measurement_id` — FK to the output `uncertainty_measurements` record
- `policy_version_id` — FK to the policy version governing this step
- `executed_at` — timestamp
- `seed_value` — integer seed if operator is seed-bound Monte Carlo (null otherwise)
- `step_hash` — SHA-256 of the canonical JSON of this step record

### `uncertainty_findings`
The constitutional output of an uncertainty evaluation.

Required fields:
- `finding_id` — UUID, primary key
- `measurement_id` — FK to the evaluated measurement
- `finding_outcome` — one of: `ADMISSIBLE`, `INADMISSIBLE`, `FLAGGED`,
  `UNKNOWN_UNCERTAINTY`, `DRAFT_PENDING_RESOLUTION`
- `decision_policy_id` — FK to the decision policy applied (null if outcome
  is `UNKNOWN_UNCERTAINTY`)
- `policy_version_id` — FK to the policy version active at finding time
- `authority_transfer_record_id` — FK to `authority_transfer_records` where
  authority over this finding was transferred to a downstream surface
  (null if no transfer occurred)
- `found_at` — timestamp
- `finding_hash` — SHA-256 of the canonical JSON of this finding

### `authority_transfer_records`
Replay-visible record of authority handoffs involving uncertainty findings.
Schema defined by `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`.
Referenced here as a required FK target for `uncertainty_findings`.

---

## 6. Replay Reconstruction Flow

Given an `uncertainty_findings.finding_id`, historical reconstruction proceeds:

1. Retrieve the `uncertainty_findings` record.
2. Retrieve the associated `uncertainty_measurements` record.
3. If the finding involved propagation, retrieve all `uncertainty_propagation_steps`
   records whose `output_measurement_id` equals the evaluated measurement ID.
4. For each propagation step, retrieve the input measurements and verify
   the registered operator at the declared operator version.
5. Re-execute the operator deterministically over the input measurements
   using the declared seed (if applicable) and verify the output matches
   the persisted output measurement.
6. Retrieve the decision policy at the declared `policy_version_id`.
7. Apply the decision policy to the final measurement and verify the
   finding outcome matches the persisted outcome.
8. If an `authority_transfer_record_id` is present, retrieve the transfer
   record and verify the transfer mode and receiving authority are as declared.

Successful completion of all steps constitutes complete historical
reconstruction of the uncertainty finding's evidentiary record.

---

## 7. Authority Transfer Gate

This doctrine depends on `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`
for the definition of transfer modes applicable to uncertainty finding handoffs.

No task pack that involves an uncertainty finding triggering authority action
on a downstream Phase 3 surface may proceed until that doctrine exists and
is cited in the task pack.

The surfaces immediately affected within Phase 3 are:

- `P3-SURF-003` (Recursive Legitimacy): when an uncertainty finding makes a
  projection inadmissible, the transfer mode governing decision authority must
  be declared.
- `P3-SURF-004` (Contradiction Detection): when uncertainty contributes to a
  contradiction finding, the transfer mode for quarantine authority must be
  declared.
- `P3-SURF-007` (Regulator Partition): when uncertainty findings differ by
  regulator regime, the transfer mode for per-regime admissibility authority
  must be declared.
- `P3-SURF-009` (Spatial/DNSH): when a spatial finding carries uncertainty,
  the transfer mode for resolution authority must be declared.
- `P3-SURF-010` (Dwell-Time Forensic): when a temporal anomaly straddles a
  threshold due to uncertainty, the transfer mode for flag/block authority
  must be declared.

---

## 8. Prohibited Misinterpretations

**PM-U-01 — Unknown Uncertainty as Exact:**
It is constitutionally prohibited to treat `U-UNKNOWN-UNCERTAINTY` as
equivalent to `U-EXACT` or as a default-pass state. Unknown uncertainty is
an incomplete declaration requiring review.

**PM-U-02 — Propagation as Phase 3 Execution:**
Phase 3 defines the propagation schema and operator registry. It does not
execute methodology-specific propagation. Executing CBAM, Verra, or any
sector-specific emissions propagation inside Phase 3 is a phase-boundary
violation.

**PM-U-03 — New Operator Invention at Phase 5 or Later:**
No phase after Phase 3 may introduce a new propagation operator. The operator
registry is a Phase 3 constitutional artifact. Phase 5 executes registered
operators; it does not register new ones.

**PM-U-04 — Uncertainty as Non-Evidence:**
Uncertainty records are constitutional evidence. They carry the same
permanence, provenance, and replay obligations as all other evidence classes
defined in `EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`.

**PM-U-05 — Resolution as Deletion of Uncertainty Record:**
Resolving an uncertainty to a definite value for finality purposes does not
delete or supersede the original uncertainty measurement record. The
resolution produces a new `uncertainty_propagation_steps` record. The
original measurement remains permanently in the evidence corpus.

**PM-U-06 — Missing Declaration as Acceptable State:**
`U-UNKNOWN-UNCERTAINTY` is a constitutional alert, not an acceptable
production state. Any system that accepts evidence at scale with
`UNKNOWN_UNCERTAINTY` without triggering review workflows is constitutionally
non-compliant with this doctrine.

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
Uncertainty admissibility sovereignty over all uncertainty-bearing evidence
produced by Symphony; propagation determinism sovereignty; uncertainty replay
obligation sovereignty.

**Sovereignty domains this doctrine must not redefine:**
External verifier independence (governed by
`EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md`); authority transfer modes
(governed by `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`); operator
execution mechanics (governed by Phase 5 adapter framework).

**Replay obligations preserved:**
All uncertainty records are subject to Commitment U-3 (replay obligation).
The reconstruction flow in §6 is the canonical replay path for uncertainty
findings.

**Phases this doctrine applies to:**
Phase 3 (ownership). Phases 4, 5, 6, 7, 8A, 8B, 8D, 8E (consumption).
No consuming phase may override or extend this doctrine without a Phase 3
constitutional amendment.

**Constitutional layers with override authority:**
ROOT-rank constitutional instruments only. No PHASE, REGULATORY, or
ENFORCEMENT layer may override this doctrine.
```

---

# DOCUMENT 2 — NEW
**Target:** `docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md`

```markdown
# UNCERTAINTY_OPERATOR_REGISTRY.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: none
Depends-On:
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This registry defines the complete and exclusive set of operators that may be
applied to uncertainty values within Symphony. Only operators declared in this
registry may be used in `uncertainty_propagation_steps` records.

An operator not listed here is constitutionally prohibited regardless of
mathematical validity or operational convenience. Registry expansion requires
a constitutional amendment to this document under the same authority
constraints as `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`.

---

## Registry Governance Rules

**RG-01 — Immutability of Registered Operators:**
Once an operator is registered, its semantic definition is immutable. A
change to an operator's semantics constitutes a new operator version, not
an amendment to the existing registration.

**RG-02 — Version Binding:**
Every `uncertainty_propagation_steps` record must cite the operator version
active at the time of execution. Historical records remain governed by the
operator version cited in them regardless of subsequent version changes.

**RG-03 — Determinism Requirement:**
Every registered operator must be fully deterministic. Given identical inputs
and an identical operator version, the output must be identical on every
execution.

**RG-04 — Phase Separation:**
This registry defines operators. Phase 5 executes them. Phase 3 does not
execute operators over methodology-specific inputs.

---

## Approved Uncertainty Classes for Each Operator

The `Input Classes` column declares which uncertainty classes an operator
may legally consume. An operator applied to an input of an undeclared class
is constitutionally prohibited.

---

## Operator Definitions

### OP-001 — Interval Addition
**Version:** 1.0
**Input Classes:** `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`
**Output Class:** Same as input (preserves class)
**Semantic:** Adds two uncertainty ranges by adding lower bounds and adding
upper bounds independently. `[a_lo, a_hi] + [b_lo, b_hi] = [a_lo+b_lo, a_hi+b_hi]`
**Determinism:** Fully deterministic. No seed required.
**Use case:** Summing embedded emissions contributions from multiple inputs.

### OP-002 — Interval Subtraction
**Version:** 1.0
**Input Classes:** `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`
**Output Class:** Same as input
**Semantic:** Subtracts a range from another by subtracting opposing bounds.
`[a_lo, a_hi] - [b_lo, b_hi] = [a_lo-b_hi, a_hi-b_lo]`
**Determinism:** Fully deterministic.
**Use case:** Net emissions calculations.

### OP-003 — Interval Multiplication
**Version:** 1.0
**Input Classes:** `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`, `U-EXACT`
**Output Class:** `U-BOUNDED-RANGE`
**Semantic:** Multiplies a range by an exact scalar or by another range
using natural interval arithmetic. For two ranges:
`[a_lo, a_hi] × [b_lo, b_hi] = [min(products), max(products)]`
**Determinism:** Fully deterministic.
**Use case:** Applying an emissions factor (possibly exact) to an activity
quantity (possibly a range).

### OP-004 — Interval Division
**Version:** 1.0
**Input Classes:** `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`, `U-EXACT`
**Output Class:** `U-BOUNDED-RANGE`
**Semantic:** Divides a range by a non-zero exact scalar or by a range that
does not contain zero.
**Determinism:** Fully deterministic. Division by a range containing zero
is constitutionally prohibited and must produce an `INADMISSIBLE` finding.
**Use case:** Intensity normalisation.

### OP-005 — Conservative Maximum Selection
**Version:** 1.0
**Input Classes:** All classes except `U-UNKNOWN-UNCERTAINTY`
**Output Class:** `U-EXACT`
**Semantic:** Selects the upper bound of the input range as the definite
output value. For `U-CONFIDENCE-INTERVAL`, selects the upper confidence
bound. For `U-EXACT`, returns the value unchanged. For
`U-DATA-QUALITY-INDICATOR`, uses the registered conservative default for
that quality tier.
**Determinism:** Fully deterministic.
**Use case:** Resolving uncertainty to a definite value for finality,
authorization, and registry submission contexts where the highest plausible
value is the conservative choice (e.g. emissions liability).

### OP-006 — Conservative Minimum Selection
**Version:** 1.0
**Input Classes:** All classes except `U-UNKNOWN-UNCERTAINTY`
**Output Class:** `U-EXACT`
**Semantic:** Selects the lower bound as the definite output value.
**Determinism:** Fully deterministic.
**Use case:** Contexts where the lowest plausible value is conservative
(e.g. sequestration claims where understating is the conservative choice).

### OP-007 — Upper Confidence Bound Selection
**Version:** 1.0
**Input Classes:** `U-CONFIDENCE-INTERVAL`
**Output Class:** `U-EXACT`
**Semantic:** Selects the upper bound of the stated confidence interval
as the definite output. Differs from OP-005 in that it operates only on
`U-CONFIDENCE-INTERVAL` and preserves the stated confidence level in the
propagation record.
**Determinism:** Fully deterministic.
**Use case:** CBAM embedded emissions where the statistical upper bound
at a declared confidence level is required.

### OP-008 — Threshold Comparison
**Version:** 1.0
**Input Classes:** All classes except `U-UNKNOWN-UNCERTAINTY`
**Output Class:** Finding outcome (`ADMISSIBLE`, `INADMISSIBLE`, `FLAGGED`)
**Semantic:** Compares the uncertainty range or value against a declared
threshold from a version-bound policy artifact. If the upper bound exceeds
the threshold: produces `INADMISSIBLE` or `FLAGGED` per the policy. If the
entire range is below the threshold: produces `ADMISSIBLE`.
**Determinism:** Fully deterministic given the policy version.
**Use case:** Admissibility gates in Phase 3 surfaces; statutory kill
criteria in Phase 4.

### OP-009 — Data Quality Tier Mapping
**Version:** 1.0
**Input Classes:** `U-DATA-QUALITY-INDICATOR`
**Output Class:** `U-BOUNDED-RANGE`
**Semantic:** Maps a declared data quality tier to a registered uncertainty
range using the tier-to-range table declared in the governing policy artifact.
The mapping table must be version-bound to the policy artifact version.
**Determinism:** Fully deterministic given the policy version.
**Use case:** Converting IPCC Tier 1/2/3 classifications into numerical
uncertainty ranges for propagation.

### OP-010 — Worst-Case Aggregation
**Version:** 1.0
**Input Classes:** `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`
**Output Class:** `U-BOUNDED-RANGE`
**Semantic:** Produces the widest possible range by taking the minimum of
all lower bounds and the maximum of all upper bounds across all input ranges.
Does not assume independence or correlation between inputs.
**Determinism:** Fully deterministic.
**Use case:** Multi-supplier aggregation where correlation structure is
unknown and worst-case conservative bounds are required.

### OP-011 — Seed-Bound Monte Carlo Simulation
**Version:** 1.0
**Input Classes:** `U-DECLARED-DISTRIBUTION`
**Output Class:** `U-CONFIDENCE-INTERVAL`
**Semantic:** Executes a Monte Carlo simulation over one or more declared
input distributions using a fixed declared integer seed. The seed, number
of iterations, and distribution parameters must be recorded in the
`uncertainty_propagation_steps` record. Replay must reproduce identical
output using the same seed and parameters.
**Determinism:** Fully deterministic given identical seed, iteration count,
and input distribution parameters.
**Prerequisites:** Seed must be declared and persisted. Unseeded execution
is constitutionally prohibited.
**Use case:** Supply chain embedded emissions aggregation where input
distributions are declared and Monte Carlo is required by the governing
methodology.

---

## Approved Distribution Types for U-DECLARED-DISTRIBUTION

The following distribution types are approved for use with `U-DECLARED-DISTRIBUTION`
class and `OP-011`. A distribution type not listed here is constitutionally
prohibited.

| Distribution ID | Name | Required Parameters |
|---|---|---|
| DIST-001 | Normal (Gaussian) | mean, standard_deviation |
| DIST-002 | Log-Normal | log_mean, log_standard_deviation |
| DIST-003 | Uniform | lower_bound, upper_bound |
| DIST-004 | Triangular | lower_bound, mode, upper_bound |
| DIST-005 | Beta | alpha, beta, scale_lower, scale_upper |

---

## Approved Data Quality Tiers for U-DATA-QUALITY-INDICATOR

The following quality tiers are approved for use with `U-DATA-QUALITY-INDICATOR`
class. Policy artifacts that use `OP-009` must declare a version-bound
tier-to-range mapping table referencing these tier IDs.

| Tier ID | Name | Description |
|---|---|---|
| DQ-TIER-1 | Directly Measured | In-situ continuous measurement with calibrated instruments |
| DQ-TIER-2 | Calculated from Measured Activity | Activity data measured; emission factor from approved registry |
| DQ-TIER-3 | Estimated from Proxy | Activity data estimated from proxy indicators |
| DQ-TIER-4 | Default Factor Applied | Jurisdiction-default emission factor applied without site-specific data |
| DQ-TIER-5 | Expert Judgment | No systematic measurement; expert estimate with declared basis |

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
Operator definition sovereignty for all uncertainty propagation within
Symphony.

**Sovereignty domains this registry must not redefine:**
Uncertainty representation classes (governed by
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`); authority transfer
modes (governed by `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`);
methodology execution mechanics (governed by Phase 5 adapter framework).

**Replay obligations:**
Every registered operator is version-bound. The operator version cited in
a `uncertainty_propagation_steps` record governs replay reconstruction.
Operator versions are never deleted; they are superseded by new versions
with preserved prior-version accessibility.

**Phases this registry applies to:**
Phase 3 (definition and registration). Phases 5, 6, 7, 8A, 8B, 8D, 8E
(consumption). No consuming phase may register new operators.
```

---

# DOCUMENT 3 — NEW
**Target:** `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`

```markdown
# AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: none
Depends-On:
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md
  - docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

---

## Purpose

This doctrine defines the constitutional semantics for authority ownership
transfer within Symphony. It fills the gap identified in
`AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`: that doctrine defines what
authority scope is and that conflicts must not be resolved without governing
doctrine, but it does not define what happens to authority ownership when
authority moves from one doctrine surface, component, or decision context
to another.

Without this definition, task packs implementing escalation, arbitration,
contradiction quarantine, regulator routing, uncertainty finding handoffs,
or delegation chains are vulnerable to silently implementing incompatible
authority transfer models. Two implementations that appear compliant could
replay differently if one assumes exclusive transfer and another assumes
shared concurrent authority.

This doctrine prevents that class of constitutional inconsistency.

---

## 1. The Four Transfer Modes

Authority transfer occurs when an authority that holds decision rights over
a question moves those rights to another authority, surface, or doctrine.
There are exactly four constitutionally recognized transfer modes.

No implementation, task pack, or phase may invent a fifth mode locally.

### Mode AT-EXCLUSIVE
**Definition:** The originating authority loses all decision rights over the
transferred question upon transfer. From the moment of transfer, only the
receiving authority may adjudicate, finalize, or override the transferred
question. The originating authority retains no concurrent rights, no
advisory role, and no override mechanism.

**Replay implication:** A replay of a decision made under AT-EXCLUSIVE must
show that the originating authority took no further action after the transfer
event. Evidence of originating-authority action after an AT-EXCLUSIVE
transfer constitutes a constitutional contradiction (classifiable under
`CONTRADICTION_CLASSIFICATION_DOCTRINE.md`).

**When constitutionally appropriate:** When the question requires a single
definitive resolution authority to prevent ambiguity; when the receiving
authority has superior constitutional standing over the transferred question;
when concurrent adjudication would create unresolvable replay divergence.

### Mode AT-SHARED
**Definition:** Multiple authorities hold concurrent decision rights over
the same question after transfer. Both the originating authority and the
receiving authority may independently adjudicate. Their findings coexist
as domain-specific determinations and neither finding nullifies the other.
Resolution of apparent conflicts between concurrent findings requires a
declared arbitration rule from `CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md`.

**Replay implication:** Both authorities' findings must be preserved and
replay-visible. A replay that shows only one concurrent authority's finding
is constitutionally incomplete.

**When constitutionally appropriate:** When the question has multiple
sovereignty-domain aspects that are orthogonal (e.g. regulator-partitioned
uncertainty findings where each regulator's admissibility determination is
independent); when non-collapse doctrine requires preservation of both
domain-specific findings.

### Mode AT-DELEGATED
**Definition:** The receiving authority acts temporarily on behalf of the
originating authority. The originating authority retains ultimate decision
rights and may revoke the delegation within the bounds declared in the
delegation record. The delegation is time-bound or condition-bound as
declared. The receiving authority's findings carry the originating
authority's constitutional standing for the duration of the delegation.

**Replay implication:** The delegation record must be replay-visible. The
receiving authority's findings during the delegation period must be
attributable to the originating authority's constitutional standing. Revocation
of delegation is a new event in the replay sequence, not a retroactive
nullification of findings made during the delegation.

**When constitutionally appropriate:** When the originating authority must
temporarily extend its reach through a subordinate surface; when the
delegation is explicitly time-bounded or task-bounded; when the originating
authority is the constitutional owner of the question but delegates execution.

### Mode AT-ADVISORY
**Definition:** The receiving authority may produce findings and
recommendations but may not finalize, block, or override. Only the
originating authority holds finalization rights. The receiving authority's
findings are inputs to the originating authority's decision; they do not
constitute independent constitutional findings.

**Replay implication:** Advisory findings must be recorded and replay-visible.
The originating authority's final decision must be traceable to whether and
how the advisory finding was considered. An originating authority that
consistently ignores advisory findings without explanation does not constitute
a constitutional violation, but the advisory findings remain in the
evidentiary record.

**When constitutionally appropriate:** When a downstream surface has relevant
information but does not hold the constitutional standing to finalize; when
the originating authority must remain the single source of finalization for
constitutional continuity reasons; when advisory findings enrich but do not
determine the outcome.

---

## 2. Transfer Record Obligation

Every authority transfer must produce an `authority_transfer_records` entry.
This record is append-only, replay-addressable, and constitutionally
permanent.

Required fields:

- `transfer_id` — UUID, primary key
- `originating_authority` — declared authority identity or surface ID of
  the transferring authority
- `receiving_authority` — declared authority identity or surface ID of the
  receiving authority
- `transfer_mode` — one of: `AT-EXCLUSIVE`, `AT-SHARED`, `AT-DELEGATED`,
  `AT-ADVISORY`
- `question_class` — the class of question being transferred (e.g.
  `uncertainty_admissibility`, `contradiction_quarantine`,
  `regulator_arbitration`, `dwell_time_enforcement`)
- `question_id` — FK to the specific question record being transferred
  (e.g. `uncertainty_findings.finding_id`)
- `governing_doctrine_ref` — citation to this doctrine and to any
  surface-specific declaration that invokes this transfer
- `policy_version_id` — FK to the policy version governing the transfer
- `transferred_at` — timestamp
- `delegation_expiry` — timestamp or condition string for AT-DELEGATED mode
  (null for other modes)
- `revocation_record_id` — FK to a subsequent revocation record if the
  delegation was revoked (null until revocation occurs; AT-DELEGATED only)
- `transfer_hash` — SHA-256 of the canonical JSON of this record

---

## 3. Phase 3 Surface Transfer Mode Declarations

The following table declares the constitutionally required transfer mode for
each Phase 3 surface that involves authority transfer in the context of
uncertainty findings. Task packs implementing these surfaces must cite this
table and must not implement a different mode.

| Originating Surface | Receiving Surface | Question Class | Mode | Rationale |
|---|---|---|---|---|
| `P3-SURF-013` (Uncertainty) | `P3-SURF-003` (Legitimacy) | `uncertainty_admissibility` | `AT-EXCLUSIVE` | Once an uncertainty finding makes a projection inadmissible, the legitimacy surface holds exclusive blocking authority. The uncertainty surface retains the measurement record but not the admissibility decision. |
| `P3-SURF-013` (Uncertainty) | `P3-SURF-004` (Contradiction) | `uncertainty_admissibility` | `AT-SHARED` | A contradiction finding and an uncertainty finding over the same record are orthogonal determinations from orthogonal surfaces. Both must be preserved. Neither nullifies the other. Non-collapse doctrine requires shared concurrent authority. |
| `P3-SURF-013` (Uncertainty) | `P3-SURF-007` (Regulator Partition) | `regulator_uncertainty_admissibility` | `AT-SHARED` | Each regulator regime holds independent admissibility authority over uncertainty findings within its domain. Regulator non-collapse doctrine prohibits exclusive transfer to any single regulator surface. |
| `P3-SURF-013` (Uncertainty) | `P3-SURF-009` (Spatial/DNSH) | `spatial_uncertainty_resolution` | `AT-DELEGATED` | The spatial surface executes the resolution on behalf of the uncertainty surface for bounded-nondeterministic spatial evaluations. The uncertainty surface retains constitutional ownership of the measurement record. Delegation expires when the spatial finding is finalized. |
| `P3-SURF-013` (Uncertainty) | `P3-SURF-010` (Dwell-Time Forensic) | `temporal_threshold_straddling` | `AT-EXCLUSIVE` | When a dwell-time anomaly straddles a threshold due to uncertainty, the forensic surface holds exclusive authority to flag or block. The uncertainty surface provides the input measurement; it does not retain override rights over the temporal enforcement decision. |
| `P3-SURF-013` (Uncertainty) | `P3-SURF-005` (Failure Composition) | `uncertainty_failure_classification` | `AT-ADVISORY` | Uncertainty findings are inputs to failure composition but do not determine the failure classification. The failure composition surface retains full finalization authority over the structured failure record. Uncertainty findings enrich but do not determine the failure output. |

---

## 4. Cross-Phase Transfer Mode Declarations

The following table declares the constitutionally required transfer mode for
authority handoffs involving uncertainty across phase boundaries.

| Originating Phase/Surface | Receiving Phase/Surface | Question Class | Mode | Rationale |
|---|---|---|---|---|
| Phase 3 `P3-SURF-013` | Phase 4 statutory enforcement | `uncertainty_kill_criterion` | `AT-EXCLUSIVE` | Once an uncertainty finding exceeds the Phase 4 statutory threshold, Phase 4 holds exclusive kill authority. Phase 3 does not retain override rights over the statutory enforcement decision. |
| Phase 3 `P3-SURF-013` | Phase 5 adapter execution | `operator_execution` | `AT-DELEGATED` | Phase 5 executes Phase 3 registered operators on behalf of Phase 3's constitutional authority over propagation semantics. Phase 3 retains constitutional ownership of the operator registry. Delegation is task-bounded: expires when the adapter's propagation step is finalized and the `uncertainty_propagation_steps` record is committed. |
| Phase 3 `P3-SURF-013` | Phase 8A authorization | `authorization_uncertainty_resolution` | `AT-EXCLUSIVE` | Once an uncertainty value is resolved to a definite value for inclusion in a sovereign authorization request, Phase 8A holds exclusive authority over that resolved value. The original uncertainty range cannot be re-opened by Phase 3. |
| Phase 5 Industrial Ontology | Phase 8D CBAM Evidence Runtime | `embedded_emissions_uncertainty` | `AT-DELEGATED` | Phase 8D packages Phase 5's embedded emissions uncertainty findings for external declaration. Phase 5 retains constitutional ownership of the computation. Phase 8D acts on Phase 5's behalf for the disclosure packaging. Delegation expires when the CBAM certificate filing is finalized. |
| Phase 5 Supply Chain Provenance | Phase 8D Declarant/Importer Separation | `producer_uncertainty_declaration` | `AT-ADVISORY` | The EU importer's CBAM declaration receives the Zambian producer's uncertainty declaration as an advisory input. The importer's declaration authority is independent. The producer's uncertainty record is preserved permanently as the evidential basis; the importer's use of it does not transfer or revoke the producer's constitutional evidence ownership. |

---

## 5. Forward-Reference Gate Rule

This doctrine constitutes a constitutional compile-time dependency for all
Phase 3 task packs and all downstream phase task packs that involve authority
transfer at uncertainty-related decision points.

**The gate rule is:**

> No task pack may assume, implement, or hardcode any authority transfer
> ownership mode unless this doctrine exists and the specific transfer is
> declared in §3 or §4 of this doctrine, or in a constitutionally valid
> surface-specific implementation plan that cites this doctrine.

Until a transfer is declared:
- implementations must stop at the transfer boundary
- doctrine-gap artifacts must be emitted
- or the work must be reclassified as doctrine-definition work

This rule applies to all phases from Phase 3 through Phase 8E.

---

## 6. Relationship to Existing Authority Doctrine

This doctrine extends, and does not supersede, `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`.

The relationship is:

| Existing Doctrine Governs | This Doctrine Adds |
|---|---|
| What authority scope is | What happens to scope when authority moves |
| That delegation requires explicit records | Which of the four modes governs each class of transfer |
| That conflict detection is permitted | That conflict resolution requires a declared transfer mode |
| That detection ≠ resolution without governing doctrine | That resolution ≠ constitutionally valid without a declared mode |

Prohibited Misinterpretation: This doctrine does not modify any SQLSTATE
assignments, trigger chains, or runtime enforcement surfaces. It governs the
constitutional semantics of authority transfer. Runtime implementations must
implement the declared mode but are governed by the implementation surface's
own constitutional constraints.

---

## 7. Prohibited Misinterpretations

**PM-AT-01 — Local Mode Invention:**
It is constitutionally prohibited for any task pack, adapter, agent, or
implementation to invent a transfer mode not defined in §1 of this doctrine.
A fifth mode does not exist. If a situation does not fit any of the four
modes, it must be escalated as a doctrine gap, not resolved locally.

**PM-AT-02 — Exclusive Transfer as Default:**
AT-EXCLUSIVE is not the default mode. No mode is a default. Every transfer
must declare its mode explicitly in a `authority_transfer_records` entry
citing this doctrine.

**PM-AT-03 — Shared Mode as Hierarchical:**
AT-SHARED does not establish hierarchy between the concurrent authorities.
Both authorities' findings are independently authoritative within their
respective sovereignty planes. Non-collapse doctrine prohibits treating one
concurrent finding as superior to another without a declared arbitration rule.

**PM-AT-04 — Delegated Mode as Permanent:**
AT-DELEGATED transfers are time-bound or condition-bound. A delegation that
does not declare an expiry or condition is constitutionally incomplete. An
undated delegation is not equivalent to AT-EXCLUSIVE.

**PM-AT-05 — Advisory Finding as Non-Evidence:**
AT-ADVISORY findings are constitutional evidence. They are permanently
preserved in the evidentiary record. They are not discarded after the
originating authority makes its final decision. The advisory finding and
the final decision coexist as independent evidence artifacts.

**PM-AT-06 — Transfer Record as Optional:**
Every authority transfer must produce an `authority_transfer_records` entry.
A transfer that occurs without a transfer record is constitutionally
unverifiable and produces a replay gap.

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
Authority transfer ownership semantics across all Phase 3 surfaces and all
downstream phase boundaries involving uncertainty, escalation, arbitration,
and delegation.

**Sovereignty domains this doctrine must not redefine:**
Authority scope definitions (governed by
`AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`); constitutional priority
ordering (governed by
`CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md`); sovereignty domain
boundaries (governed by `SYSTEM_SOVEREIGNTY_MODEL.md`).

**Replay obligations preserved:**
Every transfer record is append-only and replay-addressable. The
reconstruction of any authority transfer requires the `authority_transfer_records`
entry, the `question_id` record it references, and the governing doctrine
version active at transfer time.

**Phases this doctrine applies to:**
Phase 3 through Phase 8E. Any phase whose task packs involve authority
transfer at uncertainty-related, escalation, arbitration, or delegation
decision points must cite this doctrine.

**Constitutional layers with override authority:**
ROOT-rank constitutional instruments only.
```

---

# DOCUMENT 4 — NEW
**Target:** `docs/PHASE3/implementation_plans/TSK-P3-CAP-014_uncertainty_semantics.md`

```markdown
# TSK-P3-CAP-014 Uncertainty And Estimation Semantics Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-014
Execution-Surface: P3-SURF-013
DAG-Nodes: TSK-P3-WP-013; TSK-P3-SUPPORT-OBS-001; TSK-P3-SUPPORT-DOC-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-005_wave5_verifier_segregation_closeout.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  replay_owner: docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  verifier_owner: scripts/audit/verify_p3_uncertainty_semantics.sh
  persistence_owner: future Phase 3 uncertainty records
Replay-Criticality: replay-derived
State-Mutability: supersedable-projection
Ontology-Classification: admissibility-projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: >
  Methodology-specific uncertainty computation routes to Phase 5.
  Industrial carbon ontology routes to Phase 5.
  Supply chain provenance graph routes to Phase 5.
  External disclosure packaging routes to Phase 8D.
  CBAM evidence runtime routes to Phase 8D.
  No other future-phase absorption permitted.

---

## Purpose

This document is the surface-specific implementation plan for `P3-SURF-013`
— the Uncertainty And Estimation Semantics Surface.

It refines the Wave 5 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-013`
- the `P3-SURF-013` share of `TSK-P3-SUPPORT-OBS-001`
- the `P3-SURF-013` contribution to `TSK-P3-SUPPORT-DOC-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-013` owns uncertainty representation, operator registry governance,
admissibility classification, and replay-visible uncertainty finding
production for Phase 3.

The surface must establish:

- constitutional persistence schemas for all six uncertainty classes plus
  `U-UNKNOWN-UNCERTAINTY`;
- operator registry governance ensuring only registered operators may be
  applied to uncertainty values;
- admissibility rules classifying uncertainty findings as `ADMISSIBLE`,
  `INADMISSIBLE`, `FLAGGED`, `UNKNOWN_UNCERTAINTY`, or
  `DRAFT_PENDING_RESOLUTION`;
- authority transfer record production for every uncertainty finding that
  triggers an authority handoff to another Phase 3 surface;
- replay-safe observability for uncertainty finding outcomes.

This surface does not own:

- methodology-specific propagation execution (Phase 5);
- industrial carbon ontology or embedded emissions formulas (Phase 5);
- supply chain traceability graph (Phase 5);
- external CBAM evidence packaging (Phase 8D);
- user-facing uncertainty display (Phase 6);
- statistical dashboards or uncertainty analytics.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-013` | `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`; `UNCERTAINTY_OPERATOR_REGISTRY.md`; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | Uncertainty representation, propagation schema, and admissibility must be deterministic, replay-derived, and operator-registry-constrained. Authority transfer modes must be declared per the transfer ownership doctrine. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-013` share) | `EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `TASK_GENERATION_CONSTITUTION.md` | Observability must remain machine-readable internal constitutional traceability for uncertainty finding outcomes only. |
| `TSK-P3-SUPPORT-DOC-001` (`P3-SURF-013` contribution) | `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Documentation must cover uncertainty replay specification, operator catalog, and deterministic constraint declarations without becoming doctrine invention. |

## Pre-Conditions For Task Pack Creation

The following must exist and be canonical before `TSK-P3-WP-013` may enter
`CREATE-TASK`:

1. `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`
   — must be created and canonical.
2. `docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md`
   — must be created and canonical.
3. `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`
   — must be created and canonical.

These are forward-reference gate dependencies. Without them, task creation
is constitutionally blocked.

## Sequencing And Shared-Ownership Rules

- `TSK-P3-WP-013` becomes runnable only after `TSK-P3-WP-011` and
  `TSK-P3-WP-012` are complete per the Wave 5 serial sequence.
- `TSK-P3-WP-013` must consume Wave 1 through Wave 4 authority/policy
  lineage, contradiction outputs, failure taxonomy, and regulator partition
  outputs as already-declared replay substrates; it may not reinterpret those
  substrates locally.
- `TSK-P3-SUPPORT-OBS-001` is shared across `P3-SURF-003`, `P3-SURF-004`,
  `P3-SURF-005`, `P3-SURF-007`, `P3-SURF-009`, and `P3-SURF-013`.
- `TSK-P3-SUPPORT-DOC-001` covers all surfaces `P3-SURF-000` through
  `P3-SURF-013`.
- No shared support node may be frozen unilaterally under this plan.

## Integration With Existing Phase 3 Surfaces

The following existing Phase 3 surfaces consume `P3-SURF-013` outputs.
Each consumption point involves an authority transfer governed by
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §3:

| Consuming Surface | Transfer Mode | Question Class |
|---|---|---|
| `P3-SURF-003` (Legitimacy) | `AT-EXCLUSIVE` | `uncertainty_admissibility` |
| `P3-SURF-004` (Contradiction) | `AT-SHARED` | `uncertainty_admissibility` |
| `P3-SURF-005` (Failure Composition) | `AT-ADVISORY` | `uncertainty_failure_classification` |
| `P3-SURF-007` (Regulator Partition) | `AT-SHARED` | `regulator_uncertainty_admissibility` |
| `P3-SURF-009` (Spatial/DNSH) | `AT-DELEGATED` | `spatial_uncertainty_resolution` |
| `P3-SURF-010` (Dwell-Time Forensic) | `AT-EXCLUSIVE` | `temporal_threshold_straddling` |

## Wave 5 Obligations Bound To This Surface

- Uncertainty representation must be deterministic, replay-derived, and
  class-constrained to the seven classes declared in the doctrine.
- `U-UNKNOWN-UNCERTAINTY` must never be treated as equivalent to `U-EXACT`.
- All propagation schema must be defined in Phase 3; execution belongs to
  Phase 5.
- Authority transfer records must be produced for every finding that
  triggers a handoff to another surface.
- Observability must remain internal and machine-readable only.

## Future Atomic Task Candidates

| Future Task | Title | Phase | Acceptance Criteria | Verifier | Stop Conditions |
|---|---|---:|---|---|---|
| `TSK-P3-WP-013` | Uncertainty representation, operator registry, and replay verification | 3 | All seven uncertainty classes are persistable; only registered operators are applicable; `UNKNOWN_UNCERTAINTY` is flagged not defaulted to exact; authority transfer records are produced for all surface handoffs; replay reconstructs identical findings. | `scripts/audit/verify_p3_uncertainty_semantics.sh` | Stop if the task executes methodology-specific propagation, invents new uncertainty classes, or absorbs industrial ontology or CBAM evidence packaging. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-013` slice) | Uncertainty finding observability | 3 | Observability is machine-readable, replay-safe, limited to internal uncertainty finding outcomes. | Later observability verification must prove internal traceability without UI drift. | Stop if observability expands into dashboards or statistical displays. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. `CREATE-TASK`
requires:

- all three pre-condition doctrine documents exist and are canonical;
- `TSK-P3-WP-011` and `TSK-P3-WP-012` are complete;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 5 broad plan, and all three
  governing doctrines.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-013` is refined without absorbing Phase 5 computation or Phase
  8D disclosure semantics;
- the `P3-SURF-013` slices of shared observability and documentation nodes
  are explicit;
- all six integration points with existing Phase 3 surfaces are declared
  with their transfer modes;
- the three forward-reference gate pre-conditions are identified;
- no atomic task pack files are created by this planning step.
```

---

# DOCUMENT 5 — ADDENDUM
**Target:** `docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md`
**Nature:** Addendum sections to be appended. Do not alter existing content.

```markdown
---
## ADDENDUM: CBAM-Driven Capability Extensions
## Addendum-Status: PLANNING
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

This addendum extends the Phase 3 master implementation plan to register the
CBAM-driven capability additions identified through constitutional review of
the CBAM analysis and subsequent phased scope definition.

### New Execution Surface

| Surface | Title | Authority Class | Replay Criticality | State Mutability | Ontology | Determinism | Doctrine Outcome |
|---|---|---|---|---|---|---|---|
| P3-SURF-013 | Uncertainty And Estimation Semantics Surface | authoritative | replay-derived | supersedable-projection | admissibility-projection | deterministic | IMPLEMENT |

This surface is added to the Execution Surface Universe table. It is the
thirteenth Phase 3 surface. All prior surfaces (P3-SURF-000 through
P3-SURF-012) are unchanged.

### New Task Universe Entries

The following nodes are added to the Wave 5 task universe:

#### Wave 5 Additions

| DAG Node | Surface | Status | Doctrine Outcome | Purpose |
|---|---|---|---|---|
| TSK-P3-WP-013 | P3-SURF-013 | planned | IMPLEMENT | Uncertainty representation, operator registry governance, admissibility classification, and authority transfer record production. |

`TSK-P3-SUPPORT-DOC-001` surface coverage is extended from
`P3-SURF-000 through P3-SURF-011` to `P3-SURF-000 through P3-SURF-013`.

### New Wave 5 Serial Sequence

The updated Wave 5 canonical serial sequence is:

1. `TSK-P3-WP-012`
2. `TSK-P3-WP-011`
3. `TSK-P3-WP-013`
4. `TSK-P3-SUPPORT-DOC-001`

### New Support Domain Entry

| Support Domain | DAG Node | Constitutional Justification | Prohibited Expansion |
|---|---|---|---|
| Uncertainty semantics | TSK-P3-WP-013 | Constitutional uncertainty admissibility and replay for all evidence-bearing surfaces | Methodology execution, industrial ontology, external disclosure, dashboard display |

### New Surface-Specific Implementation Plan Registry Entry

| Plan ID | Expected File | Surface | DAG Node | Status |
|---|---|---|---|---|
| TSK-P3-CAP-014 | `TSK-P3-CAP-014_uncertainty_semantics.md` | P3-SURF-013 | TSK-P3-WP-013 | created-planning |

### New Pre-Condition Doctrine Documents

The following three doctrine documents must be created and canonical before
`TSK-P3-WP-013` may enter `CREATE-TASK`. They are constitutional
pre-conditions, not merely dependencies:

1. `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`
2. `docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md`
3. `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`

### Future-Phase Routing Additions

The following candidates are added to the Future-Phase Routing table:

| Candidate | Outcome |
|---|---|
| Industrial Carbon Ontology | DEFER to Phase 5 |
| Supply Chain Carbon Provenance Graph | DEFER to Phase 5 |
| Embedded Emissions Computation Engine | DEFER to Phase 5 |
| Shipment-Level Replay Model | DEFER to Phase 8D |
| Declarant/Importer Separation Model | DEFER to Phase 8D |
| CBAM Evidence Runtime | DEFER to Phase 8D |
| Enterprise Evidence API with Scoped Evidence Rooms | DEFER to Phase 8D |
| CBAM, ESRS E1, ISSB S2 Disclosure Adapters | DEFER to Phase 8D |
| Green Bond Uncertainty Provenance | DEFER to Phase 8E |
```

---

# DOCUMENT 6 — ADDENDUM
**Target:** `docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md`
**Nature:** Addendum sections to be appended.

```markdown
---
## ADDENDUM: CBAM-Driven Capability Boundary Extensions
## Addendum-Status: AUTHORITATIVE
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

### New Authorized Capability Domain

The following domain is added to the Authorized Capability Domains list as
item 12:

> **12. Uncertainty And Estimation Semantics**
> Representation, admissibility classification, operator registry governance,
> and replay-visible uncertainty finding production for all evidence-bearing
> surfaces within Phase 3.

### Capability-to-Doctrine Matrix Addition

| Capability Domain | Status | Governing Doctrine | Tasks May Define | Tasks Must Not Define | Blocker Status |
|---|---|---|---|---|---|
| Uncertainty And Estimation Semantics | Authorized | `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`; `UNCERTAINTY_OPERATOR_REGISTRY.md`; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | uncertainty class schemas, operator registry references, admissibility gates, authority transfer records, replay structures | methodology execution formulas, industrial emissions ontology, new uncertainty classes beyond the seven declared classes, new operators beyond the registered set | Unblocked when all three governing doctrine documents are canonical |

### Prohibited Capability Routing Additions

The following capabilities are added to the Prohibited Capability Routing
table:

| Prohibited Capability | Correct Phase |
|---|---|
| Industrial Carbon Ontology | Phase 5 |
| Supply Chain Carbon Provenance Graph | Phase 5 |
| Embedded Emissions Computation | Phase 5 |
| Shipment-Level Replay Model | Phase 8D |
| Declarant/Importer Separation Model | Phase 8D |
| CBAM Evidence Runtime | Phase 8D |
| Enterprise Evidence API | Phase 8D |
| CBAM, ESRS E1, ISSB S2 Disclosure Adapters | Phase 8D |
| Green Bond Uncertainty Provenance | Phase 8E |

### Required Doctrine Inventory Additions

| Doctrine | Status | Required For |
|---|---|---|
| `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` | Required | uncertainty class definitions, admissibility rules, replay obligations |
| `UNCERTAINTY_OPERATOR_REGISTRY.md` | Required | operator definitions and version governance |
| `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | Required | authority transfer mode declarations for all surfaces involving uncertainty finding handoffs |

### New Prohibited Misinterpretation

**PM-CB-05 — Uncertainty Engine as CBAM Runtime:**
Phase 3's uncertainty engine is constitutional substrate for evidence
admissibility. It is not a CBAM compliance runtime. CBAM evidence packaging,
embedded emissions calculations, and declarant/importer separation are Phase
8D capabilities constitutionally prohibited in Phase 3.

**PM-CB-06 — Unknown Uncertainty as Admissible:**
It is constitutionally prohibited to treat `U-UNKNOWN-UNCERTAINTY` as an
admissible state equivalent to `U-EXACT`. Any implementation, adapter, or
phase that defaults missing uncertainty declarations to exact precision is
constitutionally non-compliant with
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`.
```

---

# DOCUMENT 7 — ADDENDUM
**Target:** `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`
**Nature:** Addendum — new invariants INV-311 and INV-312.

```markdown
---
## ADDENDUM: Uncertainty Semantics Invariants
## Addendum-Status: AUTHORITATIVE
## Addendum-Authority: TSK-P3-CAP-014
## Addendum-Date: 2026-05-17

The following invariants are added to the Phase 3 invariant register using
the next available identifiers from the INV-311 through INV-399 reserved
range.

---

### INV-311 — Uncertainty Class Completeness And Non-Default

| Field | Value |
|---|---|
| Constitutional Requirement | Every evidence artifact carrying a measured, estimated, or inferred value declares an explicit uncertainty class; missing declarations produce `U-UNKNOWN-UNCERTAINTY` and are held in draft; `U-UNKNOWN-UNCERTAINTY` is never treated as equivalent to `U-EXACT` |
| Phase Spec Reference | Phase 3 CBAM-driven scope addition; `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | `docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| Evidence Path | `evidence/phase3/inv_311_uncertainty_class_completeness.json` |
| Negative Test (unknown-as-exact) | Accept an evidence artifact without an uncertainty class declaration; verify it receives `U-UNKNOWN-UNCERTAINTY`, is held in draft status, and is rejected by any downstream finality gate |
| Negative Test (undeclared class) | Attempt to file an uncertainty record with a class not in the seven declared classes; must fail with SQLSTATE P3011 |
| Proof Limitations | Does not verify substantive correctness of uncertainty values — only that the class is declared and that the non-default rule is enforced at the DB layer |

---

### INV-312 — Authority Transfer Record Completeness

| Field | Value |
|---|---|
| Constitutional Requirement | Every authority transfer involving an uncertainty finding that moves decision rights between Phase 3 surfaces produces a complete `authority_transfer_records` entry citing the declared transfer mode from `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` |
| Phase Spec Reference | Phase 3 CBAM-driven scope addition; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | `docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| Evidence Path | `evidence/phase3/inv_312_authority_transfer_record_completeness.json` |
| Negative Test (missing transfer record) | Trigger an uncertainty finding that routes to `P3-SURF-003`; verify an `authority_transfer_records` entry is produced with mode `AT-EXCLUSIVE` before the legitimacy surface acts |
| Negative Test (undeclared mode) | Attempt to insert an `authority_transfer_records` entry with a mode value not in the four declared modes; must fail with SQLSTATE P3012 |
| Proof Limitations | Verifies structural completeness of transfer records and mode validity; does not independently verify that the correct mode was selected for the question class — that requires a human constitutional review |
```

---

# DOCUMENT 8 — NEW
**Target:** `docs/architecture/PHASE_SPECIFICATION_CBAM_CAPABILITY_AUGMENTATION.md`

This document augments `Symphony-Phase-Specification-Document_v1.md` for
Phases 4 through 8E with CBAM-driven capability additions. It follows the
established augmentation pattern of the existing
`Symphony Constitutional Phase Specification Augmentation Draft` in the same
file.

```markdown
# PHASE_SPECIFICATION_CBAM_CAPABILITY_AUGMENTATION.md

Constitutional-Status: INTERPRETIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 6
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md

---

## Purpose

This document augments the Phase Specification with CBAM-driven capability
additions across Phases 3 through 8E. It was produced through constitutional
review of the EU Carbon Border Adjustment Mechanism's architectural
implications for Symphony's evidence legitimacy substrate.

The augmentation is structured as addenda to each affected phase's
specification. It does not replace or contradict the original phase
specification. Where this augmentation adds a capability, that capability
is within the existing phase's constitutional scope as declared by the
phase specification and its governing doctrines.

---

## Cross-Phase Invariants

These rules govern all phases from Phase 3 through Phase 8E for all
CBAM-derived capabilities. They take precedence over any phase-specific
implementation convenience.

**XI-1 — Type Lock:**
No phase after Phase 3 may introduce a new uncertainty representation class.
New classes require a Phase 3 constitutional amendment to
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`.

**XI-2 — Operator Lock:**
No phase after Phase 3 may introduce a new propagation operator. New operators
require a Phase 3 amendment to `UNCERTAINTY_OPERATOR_REGISTRY.md`.

**XI-3 — Unknown-Uncertainty Rule:**
Missing uncertainty class = `U-UNKNOWN-UNCERTAINTY` in all phases. Never
defaulted to `U-EXACT`. Always flagged. Always held pending review before
any finality gate.

**XI-4 — Resolution Before Finality:**
Uncertainty must be resolved to a definite value before entering: settlement
finality, authorization request packs, registry submissions, or statutory
calculations. Resolution must produce an `uncertainty_propagation_steps`
record.

**XI-5 — Replay Continuity:**
Every uncertainty propagation step and authority transfer record is a Phase
3 evidence record subject to all permanence guarantees in
`EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` EPG-1 through EPG-7.

**XI-6 — No Presentation-Layer Calculation:**
Phases 6, 8D, and 8E display and package uncertainty findings. They do not
recalculate them. Any calculation appearing in a presentation-layer phase
is a constitutional phase-boundary violation.

**XI-7 — Authority Transfer Gate:**
No task pack at any phase may assume an authority transfer ownership mode
unless `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` exists and the
specific transfer is declared in that doctrine.

---

## Phase 3 Augmentation

### New Capability: 3.9 Uncertainty And Estimation Semantics

**Constitutional Purpose:** Establishes uncertainty as a first-class
evidentiary property with deterministic representation, operator-registry-
constrained propagation, admissibility classification, and replay-visible
findings.

**What this capability builds:**

- Constitutional persistence schemas for seven uncertainty classes
  (`U-EXACT`, `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`,
  `U-DECLARED-DISTRIBUTION`, `U-DATA-QUALITY-INDICATOR`,
  `U-METHODOLOGICAL-ASSUMPTION`, `U-UNKNOWN-UNCERTAINTY`)
- `UNCERTAINTY_OPERATOR_REGISTRY.md` with eleven registered operators
  (OP-001 through OP-011)
- `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` defining the four
  transfer modes (AT-EXCLUSIVE, AT-SHARED, AT-DELEGATED, AT-ADVISORY)
- `authority_transfer_records` persistence schema for replay-visible
  authority handoffs
- Verifier `scripts/audit/verify_p3_uncertainty_semantics.sh`
- Invariants INV-311 and INV-312

**What this capability does not build:**
Methodology-specific propagation execution (Phase 5); industrial carbon
ontology (Phase 5); CBAM evidence packaging (Phase 8D).

**Exit criteria addition to Phase 3:**
In addition to the existing Phase 3 exit criteria, Phase 3 is not complete
until: all seven uncertainty classes are persistable and schema-validated;
`U-UNKNOWN-UNCERTAINTY` is enforced as a non-default flag state at the DB
layer; authority transfer records are produced for all Phase 3 surface
handoffs involving uncertainty findings; INV-311 and INV-312 are promoted
to `status: implemented`.

---

## Phase 4 Augmentation

### Uncertainty Consumption Additions to §4.9 Statutory Kill Criteria

**New Kill Criterion 4.9.5 — Uncertainty Threshold Exceeded:**
A statutory calculation whose inputs carry `uncertainty_findings` with
outcome `INADMISSIBLE` or `UNKNOWN_UNCERTAINTY` must trigger an automatic
halt. The calculation may not proceed until the uncertainty is resolved to
a definite value via a Phase 3 registered decision policy.

**New Kill Criterion 4.9.6 — Unresolved Uncertainty in Settlement Input:**
Any evidence artifact carrying `U-UNKNOWN-UNCERTAINTY` may not serve as
an input to a settlement finality calculation. The artifact must be resolved
or reclassified before the settlement path can proceed.

### Financial Calculation Uncertainty Gate

**New §4.10 — Financial Calculation Uncertainty Gate:**
Phase 4 must declare, for each statutory calculation surface, which input
fields may carry uncertainty and which must be `U-EXACT`. The declaration
must be version-bound to the governing policy artifact. Fields not declared
as uncertainty-eligible are implicitly `U-EXACT` and must fail with SQLSTATE
P4001 if a non-exact uncertainty measurement is submitted.

BoZ FX reference rates are constitutionally classified as `U-EXACT` class
inputs. They may not be treated as estimates, ranges, or distributions. Any
financial calculation treating a BoZ rate as an uncertainty-bearing input
is constitutionally invalid.

**Authority Transfer at Phase 4:**
When a Phase 3 uncertainty finding triggers a Phase 4 kill criterion, the
transfer mode is `AT-EXCLUSIVE` per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4. Phase 4 holds
exclusive statutory enforcement authority from the moment the threshold is
exceeded. Phase 3 does not retain override rights over the kill decision.

**What Phase 4 must not build:**
New uncertainty representation types; uncertainty propagation operators;
any recalculation of Phase 3 uncertainty findings; authority transfer mode
definitions.

---

## Phase 5 Augmentation

### New §5.13 — Industrial Carbon Ontology

**Constitutional Purpose:** Represent industrial process emissions in a
machine-verifiable, adapter-governed form that consumes Phase 3 uncertainty
primitives.

**What this builds:**
- Ontology schemas for: smelting processes, refining processes, electricity
  attribution (direct and grid-average), precursor emissions (embedded in
  purchased inputs), embedded emissions decomposition (separating direct,
  process, and energy-source emissions)
- Coverage for: copper cathode production, aluminium smelting, cement
  manufacturing, fertilizer production, hydrogen production
- Integration with Phase 3 uncertainty classes: activity quantities,
  emission factors, and energy source attributions may carry `U-BOUNDED-RANGE`
  or `U-CONFIDENCE-INTERVAL` classes; the ontology schema must declare
  the uncertainty class for each field
- Version-bound ontology artifacts: each ontology version is a policy
  artifact under `POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`

**What this does not build:**
New uncertainty classes (Phase 3 lock); CBAM-specific regulatory
calculations (Phase 8D); external registry emissions factors (Phase 8B).

### New §5.14 — Supply Chain Carbon Provenance Graph

**Constitutional Purpose:** Track upstream inputs and embedded emissions
across supplier relationships in a replay-visible graph structure that
extends the Phase 3 typed dependency graph.

**What this builds:**
- Supply chain graph schema extending `P3-SURF-001` typed dependency graph
  into multi-enterprise scope
- Supplier relationship records: each supplier relationship carries a
  declared emissions intensity, uncertainty class, and provenance source
- Precursor emissions tracking: for each product, the graph records which
  input materials contributed embedded emissions and at what uncertainty class
- Chain-of-custody carbon propagation: embedded emissions from upstream
  inputs propagate through the graph using Phase 3 registered operators
  (OP-001 through OP-010)
- Cross-enterprise boundary markers: the graph declares where evidence
  transitions from internally-measured to supplier-declared data, with
  appropriate uncertainty class assignment (`U-METHODOLOGICAL-ASSUMPTION`
  or `U-DATA-QUALITY-INDICATOR` at the boundary)

**What this does not build:**
External registry integrations (Phase 8B); CBAM cross-enterprise evidence
sharing (Phase 8D); new uncertainty operators (Phase 3 lock).

### New §5.15 — Embedded Emissions Computation Engine

**Constitutional Purpose:** Execute uncertainty-aware product-level carbon
calculations within the adapter framework, consuming Phase 3 operators and
the Phase 5 industrial carbon ontology.

**What this builds:**
- Adapter execution of embedded emissions calculations using only Phase 3
  registered operators from `UNCERTAINTY_OPERATOR_REGISTRY.md`
- Deterministic sandbox: rejects any adapter calling a non-deterministic
  function during embedded emissions calculation
- Temporal compatibility: uncertainty inputs from prior reporting periods
  carry the uncertainty model version under which they were declared; an
  adapter recalculating historical values must use the historical uncertainty
  model version
- Adapter certification additions: an adapter performing embedded emissions
  calculations must declare: which input fields carry uncertainty, which
  Phase 3 operators are applied, what the admissibility threshold policy is,
  and which industrial ontology version governs the calculation. An adapter
  without these declarations cannot be certified.
- `uncertainty_propagation_steps` record production: every embedded emissions
  calculation step populates the Phase 3 persistence schema; the Phase 5
  adapter executes; Phase 3 schema records the step

**Authority Transfer at Phase 5:**
Phase 5 executes Phase 3 operators under `AT-DELEGATED` mode per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4. Phase 3 retains
constitutional ownership of the operator registry. Phase 5's delegation
expires when the adapter's propagation step is finalized and the
`uncertainty_propagation_steps` record is committed.

**What this does not build:**
New uncertainty representation classes; new operators; CBAM regulatory
calculations; industrial ontology definition (that is §5.13 above).

### Additions to §5.5 — Adapter Certification

The following uncertainty-related requirements are added to adapter
certification:

- Adapter must declare its uncertainty model: which input fields may carry
  uncertainty, which classes are permitted for each field, which registered
  operators are applied.
- Adapter must declare its admissibility threshold policy with policy version
  binding.
- An adapter that applies `U-UNKNOWN-UNCERTAINTY` inputs to any calculation
  without first resolving them must fail certification.
- An adapter that calls any function not in `UNCERTAINTY_OPERATOR_REGISTRY.md`
  during uncertainty propagation must fail certification.

---

## Phase 6 Augmentation

### Additions to §6.3 — Intake Boundary

**Uncertainty Class Declaration at Intake:**
Field capture forms must surface uncertainty class declaration at intake.
When a field measurement is recorded, the operator must declare the
measurement class from the seven classes defined in
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`. This declaration is
captured as an `uncertainty_measurements` record with full provenance at
intake time — not after, not retroactively.

**Offline Capture Uncertainty Rule:**
Offline submissions without an explicit uncertainty class declaration receive
`U-UNKNOWN-UNCERTAINTY` on sync — not `U-EXACT`. They are flagged for
review. An offline capture system that defaults missing uncertainty to exact
is constitutionally non-compliant.

### Additions to §6.4 — Draft-to-Admitted Transition

**Uncertainty Gate at Admission:**
Evidence with `U-UNKNOWN-UNCERTAINTY` or with an `uncertainty_findings`
outcome of `INADMISSIBLE` must remain in draft status. Admission requires
either: resolution to a definite value via a Phase 3 registered decision
policy, or explicit constitutional exemption with a recorded justification.
The admission gate is enforced at the DB layer; application-layer-only
enforcement is constitutionally insufficient.

### Additions to §6.8 — VVB Portals

**Uncertainty Finding Display:**
VVB portals must display for each evidence item under review: the declared
uncertainty class, the operator applied (if any), and the `uncertainty_findings`
outcome. This is a read surface over Phase 3 data. VVB portals may not
modify uncertainty class declarations or produce new uncertainty findings.
Their role is verification, not reclassification.

### Additions to §6.9 — Regulator Review Workspaces

**Uncertainty Replay View:**
Regulator Review Workspaces must include the uncertainty propagation chain
in the replay view. A regulator replaying a legitimacy decision must see
the uncertainty inputs, each propagation step, the operator applied, and
the final finding. This chain must be reconstructable from persisted Phase
3 records without runtime service calls.

---

## Phase 7 Augmentation

### Additions to §7.1 — Zero Platform Schema Changes

**Uncertainty Substrate Non-Modification:**
The second methodology must not require modification to Phase 3 uncertainty
schemas, operator registry, or admissibility rules. If the second methodology
requires a new uncertainty class or operator, this constitutes a platform
schema change and fails Phase 7 certification. The correct resolution is a
Phase 3 constitutional amendment before Phase 7 certification proceeds.

### Additions to §7.4 — Strict Adapter Isolation

**Cross-Methodology Uncertainty Isolation:**
Uncertainty findings produced for Methodology A must not influence
admissibility determinations for Methodology B. The `cross_entity_replay_isolation`
property extends to uncertainty findings across methodology domains. An
adapter for Methodology B that reads uncertainty records produced by
Methodology A's adapter is constitutionally prohibited.

### New §7.7 — Uncertainty Methodology Neutrality Proof

**Proof Obligation:**
Phase 7 must prove that the uncertainty substrate is methodology-neutral by
demonstrating that the second methodology adapter:

- Uses only Phase 3 registered operators from `UNCERTAINTY_OPERATOR_REGISTRY.md`
  with no new registrations required
- Assigns only Phase 3 declared uncertainty classes with no new classes required
- Produces `uncertainty_propagation_steps` records using the same schema as
  the first methodology with no schema additions required
- Passes the same `verify_p3_uncertainty_semantics.sh` verifier as Phase 3

Failure of any of these proof obligations constitutes a Phase 7 exit
criteria failure.

### Additions to §7.5 — Unified DNSH Constraints

**DNSH Uncertainty Handling:**
Both methodologies must use the same spatial uncertainty operators when
evaluating DNSH constraints, proving that Phase 3's bounded-nondeterministic
spatial surface (`P3-SURF-009`) and the uncertainty engine are compositionally
compatible. A methodology that requires different spatial uncertainty
operators fails unified DNSH constraint certification.

---

## Phase 8A Augmentation

### New §8A.5 — Uncertainty Resolution Gate

**Pre-Authorization Uncertainty Resolution:**
All evidence destined for inclusion in a machine-readable host-country
authorization request pack must pass through an uncertainty resolution gate
before inclusion. Evidence carrying `U-UNKNOWN-UNCERTAINTY` or
`uncertainty_findings` outcome `INADMISSIBLE` may not be included.

Resolution must:
- Apply a registered Phase 3 decision policy, typically `DP-CONSERVATIVE-DEFAULT`
  or `DP-UPPER-BOUND`, to produce a definite `U-EXACT` value
- Produce an `uncertainty_propagation_steps` record documenting the resolution
- Produce an `uncertainty_findings` record with outcome `ADMISSIBLE` citing
  the resolved value

### §8A Corresponding Adjustment Uncertainty Rule

Corresponding Adjustment bindings must be on `U-EXACT` resolved values. A
Corresponding Adjustment that references an `uncertainty_measurements` record
with a range-bearing class is constitutionally invalid.

### §8A First-Transfer Proof Attachment

First-transfer proof attachments must include the `uncertainty_propagation_steps`
record proving the value used in the authorization was derived via a
registered conservative operator from the declared uncertainty inputs.

**Authority Transfer:**
Once an uncertainty value is resolved for authorization purposes, the
transfer mode is `AT-EXCLUSIVE`. The original uncertainty range cannot be
re-opened by Phase 3 for the purposes of the authorization record. The
original measurement remains in the Phase 3 evidence corpus permanently;
the authorization record is bound to the resolved value only.

---

## Phase 8B Augmentation

### New §8B.5 — Registry Submission Uncertainty Requirements

**Pre-Submission Uncertainty Verification:**
All quantities in a Verra issuance package or ZEMA notification must have
passed through Phase 8A's uncertainty resolution gate (for Article 6 credits)
or through a Phase 4 financial calculation uncertainty gate (for domestic
calculations). Raw uncertainty ranges must not appear in registry submissions.

**Uncertainty Audit Trail in Registry Packages:**
Where the target registry's schema supports provenance metadata, the
uncertainty resolution audit trail reference (the `uncertainty_propagation_steps`
record chain) must be included as supporting metadata. ZEMA receives the
definite resolved quantity; the audit trail documents its derivation.

**Bidirectional Reconciliation:**
Credit state reconciliation treats credit quantities as `U-EXACT`. Any
discrepancy between the registry's recorded quantity and Symphony's resolved
quantity triggers a contradiction finding under `P3-SURF-004`, not an
uncertainty reclassification.

---

## Phase 8D Augmentation

### New §8D.5 — CBAM Evidence Runtime

**Constitutional Purpose:** Produce machine-readable evidence packages for
EU CBAM declarations that carry full uncertainty provenance from Phase 3
through Phase 5.

**What this builds:**
- CBAM-compatible evidence packages containing: declared embedded emissions
  with confidence intervals, supplier uncertainty declarations, energy
  provenance with uncertainty class, methodology assumptions, and the Phase
  3 uncertainty propagation chain as the machine-readable assurance trail
- Authority transfer records documenting the transfer mode governing the
  producer-to-importer evidence handoff (AT-ADVISORY per
  `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4)
- Shipment-period accounting: evidence packages are scoped to declared
  shipment periods with temporal bounds; each package freezes the evidentiary
  state active at the time of the shipment declaration

**What this does not build:**
New uncertainty classes; new propagation operators; recalculation of
embedded emissions (Phase 5 outputs are consumed, not recomputed).

### New §8D.6 — Shipment-Level Replay Model

**Constitutional Purpose:** Freeze the exact evidentiary state used for
each export shipment declaration to support dispute resolution years after
the shipment date.

**What this builds:**
- Shipment replay records that capture: the uncertainty inputs active at
  declaration time, the propagation chain applied, the authority transfer
  records governing the producer-to-importer handoff, the policy versions
  active at declaration time, and the resolved definite values used in the
  CBAM certificate filing
- Replay reconstruction path: given a shipment ID and historical date,
  replay must reproduce the identical CBAM evidence package that was
  produced at declaration time
- Immutability: shipment replay records are append-only from the moment of
  declaration. No operational act may alter a finalized shipment replay
  record.

### New §8D.7 — Declarant/Importer Separation Doctrine

**Constitutional Purpose:** Separate the Zambian producer's evidence
ownership from the EU importer's declaration responsibility.

**What this builds:**
- Producer evidence scope: the Zambian producer's `uncertainty_measurements`,
  `uncertainty_propagation_steps`, and `uncertainty_findings` records remain
  under the producer's constitutional evidence sovereignty. The EU importer
  receives a scoped, read-only evidence room containing only the evidence
  relevant to the specific shipment(s) declared.
- Importer declaration scope: the EU importer's CBAM certificate filing
  references the producer's evidence package but is an independent declaration
  act. The importer holds declaration authority; the producer holds evidence
  authority.
- Authority transfer: the producer's uncertainty declaration is an `AT-ADVISORY`
  input to the importer's declaration. The importer's declaration authority
  is independent. The producer's uncertainty record is permanently preserved
  as the evidential basis; the importer's use of it does not transfer or
  revoke the producer's evidence ownership.
- Access scoping: the Enterprise Evidence API (§8D.8) enforces this
  separation by providing importer-scoped evidence rooms that expose only
  the uncertainty findings and propagation chain relevant to the declared
  shipment, without exposing the producer's full operational record.

### New §8D.8 — Enterprise Evidence API

**Constitutional Purpose:** Provide buyer-scoped evidence rooms and
machine-readable assurance interfaces for CBAM declarants, corporate
disclosure reporters, and financial auditors.

**What this builds:**
- Buyer-scoped evidence rooms: each buyer receives an evidence room scoped
  to their declared relationship with the producer (shipment-level,
  product-level, or period-level). Evidence rooms are read-only.
- Uncertainty scoping: the granularity of uncertainty exposure is determined
  by the buyer's disclosure obligation — a CBAM declarant receives the full
  confidence interval chain; a high-level disclosure recipient receives the
  resolved conservative value
- Machine-readable assurance trail: the trail demonstrates that confidence
  ranges are derived from Phase 3-registered operators applied to declared
  inputs, not invented at disclosure time. The trail is auditable without
  access to Symphony's runtime.
- Authority transfer records in the API response: where the producer-to-buyer
  handoff involves an authority transfer, the transfer record is included in
  the evidence room to document the transfer mode.

### New §8D.9 — Disclosure Adapters (ESRS E1, ISSB S2, CBAM)

**Constitutional Purpose:** Package Phase 3 uncertainty findings and Phase
5 propagation records into format-specific disclosure artifacts for corporate
climate reporting obligations.

**What these adapters build:**

*ESRS E1 Adapter:*
- Populates ESRS E1 Scope 1, 2, and 3 uncertainty fields from
  `uncertainty_findings` and `uncertainty_propagation_steps` records
- Maps Phase 3 uncertainty classes to ESRS E1 estimation uncertainty
  disclosure categories
- Version-bound to the ESRS E1 standard version declared in the governing
  interpretation pack

*ISSB S2 Adapter:*
- Populates ISSB S2 significant estimation uncertainty fields from Phase
  3/5 outputs
- Maps confidence intervals to ISSB S2 disclosure requirements
- Version-bound to the ISSB S2 standard version declared in the governing
  interpretation pack

*CBAM Adapter:*
- Produces the CBAM-compatible XML/JSON evidence package defined in §8D.5
- Applies `DP-UPPER-BOUND` decision policy by default for embedded emissions
  (conservative maximum as the regulatory conservative choice)
- Includes the full shipment-level replay record reference per §8D.6

**What these adapters must not do:**
Recalculate uncertainty values; introduce new uncertainty classes; define
new operators; alter Phase 3 evidence records.

### §8D Exit Criteria Additions

Phase 8D is not complete until:
- CBAM evidence packages are machine-readable and include full uncertainty
  provenance chains
- Shipment-level replay is demonstrably reproducible from persisted Phase
  3 records without runtime service calls
- Declarant/importer separation is enforced at the API access-control layer
- All three disclosure adapters produce outputs that trace to Phase 3
  `uncertainty_findings` records without recalculation

---

## Phase 8E Augmentation

### New §8E.5 — Green Bond Uncertainty Provenance

**Constitutional Purpose:** Expose uncertainty-resolved impact evidence to
capital market participants with full uncertainty provenance for the life of
the bond.

**What this builds:**
- BoZ/SEC green bond use-of-proceeds evidence packs that include the
  `uncertainty_propagation_steps` record chain proving that the reported
  impact quantity was derived conservatively from declared uncertainty inputs
- Impact-to-capital traceability chains: for each reported unit of impact
  (tonne CO2e, MWh renewable), the chain traces to the `uncertainty_measurements`
  record, declared class, and resolution operator applied
- Underwriter evidence rooms: read-only surfaces that display the uncertainty
  propagation summary alongside the impact claim, structured for audit
  without requiring access to Symphony's operational runtime
- Extended retention: `uncertainty_propagation_steps` records that supported
  a green bond issuance must be flagged for retention for the full term of
  the bond, not only the standard 7-year default. This is enforced by a
  bond-term retention record that FK-references the relevant propagation
  step IDs.

**What this does not build:**
New uncertainty classes; new operators; recalculation of impact quantities;
modification of Phase 3 evidence records.

### §8E Exit Criteria Additions

Phase 8E is not complete until:
- BoZ-format loan compliance reports trace impact quantities to Phase 3
  uncertainty findings without recalculation
- Bond-term retention records exist for all `uncertainty_propagation_steps`
  records that underpin issued green bonds
- Underwriter evidence rooms are demonstrably auditable without runtime
  service dependency

---

## Phase Ownership Summary (Complete)

| Capability | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 | Phase 8A | Phase 8B | Phase 8D | Phase 8E |
|---|---|---|---|---|---|---|---|---|---|
| Uncertainty representation classes (7) | Owns | — | Consumes | Consumes | Proves neutral | — | — | Consumes | — |
| Operator registry (11 operators) | Owns | — | Executes | — | Proves adapter-agnostic | — | — | — | — |
| `U-UNKNOWN-UNCERTAINTY` (non-default flag) | Owns | — | — | Enforces at intake | — | — | — | — | — |
| Authority transfer doctrine (4 modes) | Owns | Must cite | Must cite | Must cite | Must cite | Must cite | — | Must cite | — |
| Authority transfer records schema | Owns | — | Populates | Populates | — | Populates | — | Populates | — |
| Uncertainty admissibility verifier | Owns | — | Extends to sandbox | — | — | — | — | — | — |
| Statutory kill criterion (uncertainty threshold) | — | Owns | — | — | — | — | — | — | — |
| Financial calculation uncertainty gate | — | Owns | — | — | — | — | — | — | — |
| Industrial Carbon Ontology | — | — | Owns | — | — | — | — | Consumes | — |
| Supply Chain Provenance Graph | — | — | Owns | — | — | — | — | Extends externally | — |
| Embedded Emissions Computation | — | — | Owns | — | — | — | — | Consumes | — |
| Adapter certification (uncertainty model) | — | — | Owns | — | — | — | — | — | — |
| Field capture uncertainty declaration | — | — | — | Owns | — | — | — | — | — |
| Draft-to-admitted uncertainty gate | — | — | — | Owns | — | — | — | — | — |
| VVB uncertainty finding display | — | — | — | Owns | — | — | — | — | — |
| Regulator replay uncertainty view | — | — | — | Owns | — | — | — | — | — |
| Cross-methodology uncertainty isolation proof | — | — | — | — | Owns | — | — | — | — |
| Uncertainty methodology neutrality proof | — | — | — | — | Owns | — | — | — | — |
| Authorization uncertainty resolution gate | — | — | — | — | — | Owns | — | — | — |
| Corresponding Adjustment uncertainty rule | — | — | — | — | — | Owns | — | — | — |
| Registry submission uncertainty verification | — | — | — | — | — | — | Owns | — | — |
| CBAM Evidence Runtime | — | — | — | — | — | — | — | Owns | — |
| Shipment-Level Replay Model | — | — | — | — | — | — | — | Owns | — |
| Declarant/Importer Separation | — | — | — | — | — | — | — | Owns | — |
| Enterprise Evidence API | — | — | — | — | — | — | — | Owns | — |
| ESRS E1 / ISSB S2 / CBAM Adapters | — | — | — | — | — | — | — | Owns | — |
| Green bond uncertainty provenance | — | — | — | — | — | — | — | — | Owns |
| Bond-term retention extension | — | — | — | — | — | — | — | — | Owns |
| Underwriter uncertainty evidence rooms | — | — | — | — | — | — | — | — | Owns |

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
CBAM-derived capability phase routing across Phases 3 through 8E.

**Sovereignty domains this document must not redefine:**
Phase constitutional boundaries (governed by
`Symphony-Phase-Specification-Document_v1.md`); uncertainty semantics
(governed by `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`); authority
transfer modes (governed by
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`).

**Phases this document applies to:**
Phases 3 through 8E. Global for CBAM-derived capabilities only.

**Constitutional layers with override authority:**
`Symphony-Phase-Specification-Document_v1.md` (Authority-Rank 7) and the
constitutional corpus. This augmentation (Authority-Rank 6) operates within
those constraints.

**Lower-layer documents prohibited from reinterpretation:**
Phase-specific implementation plans, wave plans, and task packs may not
reinterpret the phase ownership assignments in the summary table above.
Reassigning a capability to a different phase requires an amendment to this
augmentation document.
```

---

All eight documents are complete. Here is the production summary:

| # | Document | Type | Target Path | Status |
|---|---|---|---|---|
| 1 | `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` | New | `docs/constitutional/` | Complete |
| 2 | `UNCERTAINTY_OPERATOR_REGISTRY.md` | New | `docs/constitutional/` | Complete |
| 3 | `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` | New | `docs/constitutional/` | Complete |
| 4 | `TSK-P3-CAP-014_uncertainty_semantics.md` | New | `docs/PHASE3/implementation_plans/` | Complete |
| 5 | `PHASE3_MASTER_IMPLEMENTATION_PLAN.md` addendum | Addendum | `docs/PHASE3/` | Complete |
| 6 | `PHASE3_CAPABILITY_BOUNDARY.md` addendum | Addendum | `docs/PHASE3/` | Complete |
| 7 | `PHASE3_INVARIANT_REGISTER.md` addendum | Addendum | `docs/PHASE3/` | Complete — INV-311, INV-312 |
| 8 | `PHASE_SPECIFICATION_CBAM_CAPABILITY_AUGMENTATION.md` | New | `docs/architecture/` | Complete — covers Phases 4–8E |