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