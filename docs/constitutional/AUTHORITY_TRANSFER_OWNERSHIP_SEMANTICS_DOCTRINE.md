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