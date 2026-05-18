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