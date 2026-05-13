# Baseline Register vs Remediation Report — Reconciliation Verdict

Effective-Date: 2026-05-12
Method: Claim-by-claim mapping of the Constitutional Baseline Register v2 against
        (a) what the codebase actually contains, and
        (b) what the remediation report addresses.

---

## The Core Question

Does the Constitutional Baseline Register v2 invalidate the remediation report?
Does the report address what the baseline register says is missing?

**Short answer:** The remediation report is not invalidated. But it addresses a
different layer than most of what the baseline register describes. The two documents
are largely non-overlapping. The remediation report solves the infrastructure wiring
problem. The baseline register describes a constitutional semantics problem that is
mostly ahead of Phase 3 and cannot be fully resolved by schema changes alone.

---

## Part 1: Mapping the Baseline Register Claims Against the Codebase

The baseline register makes claims across 15 doctrines (D-01 through D-15) and
16 Phase 3 risk register items (P3-01 through P3-16). The claims are not uniformly
unverified — some are confirmed by the codebase, some are partially addressed, and
some describe gaps that no schema work alone can close.

---

### D-01 — Constitutional State vs Operational Exhaust

**Claim:** No classification registry distinguishes constitutional state from
operational exhaust. Operational exhaust is silently accumulating into permanent storage.

**Codebase reality:** The 822 task directories confirm the accumulation claim exactly.
There is no `archived` flag on tasks. The CI traverses all of them. The `constitutional_data_class`
enum proposed in the remediation report (Action 2) is the direct mechanical answer to
D-01 for `evidence_nodes`. It distinguishes `evidentiary` / `provenance` / `replay`
(constitutional state) from `operational` (exhaust).

**Does the remediation report address it?** Yes, partially. The `data_class` column
on `evidence_nodes` (Action 2) and the `data_class_registry.yml` (Action 6 companion)
are the materialisation of the D-01 classification requirement for the evidence layer.
The task archival problem (CI traversing 822 directories) is acknowledged but not
assigned a concrete task in the remediation report — this is an operational gap in
the report itself.

**Verdict:** Partially addressed. The evidence layer is covered. The task corpus
archival is not.

---

### D-02 — Admissibility Determinism Principle

**Claim:** Equivalent replay inputs must produce equivalent admissibility outcomes.
Replay must not depend on wall-clock, nondeterministic state, external mutable APIs,
or environmental randomness.

**Codebase reality:** This is substantially implemented. Migration 0131-0133
(`execution_records_determinism_columns`, `_constraints`, `_triggers`) explicitly
enforce determinism columns. The `policy_versions` table (migration 0005) with its
single-active constraint enforces that replay sees the same policy. The
`interpretation_packs` table (migration 0116) with `effective_from`/`effective_to`
temporal resolution means replay uses the same interpretation version active at
decision time. The `wave8_cryptographic_enforcement` function (migration 0190) binds
to `canonical_payload_bytes` — the same input always produces the same verification.

**Does the remediation report address it?** Not directly — because it is largely
already addressed in the schema. The report correctly does not propose adding
determinism infrastructure that already exists.

**Verdict:** Already implemented in the codebase. Neither the baseline register's
claim nor the remediation report's omission of this is problematic.

---

### D-03 — Constitutional Query Constraints

**Claim:** Constitutional interpretation must remain bounded by verifiable sources.
All conclusions must include interpretation version, source lineage, uncertainty
status, and sovereignty applicability scope.

**Codebase reality:** This is a governance and AI inference constraint, not a schema
constraint. The `interpretation_packs` and `policy_versions` tables provide versioned
interpretation binding at the DB layer. The `CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md`
and `NON_INFERENCE_AND_INTERPRETATION_LIMITS.md` documents address this at the doctrine
layer. There is no runtime enforcement of this principle in the application layer —
nothing prevents an API from returning an interpretation without source lineage.

**Does the remediation report address it?** No. This is out of scope for the report's
six infrastructure actions. It is a Phase 3 API contract concern, not a schema gap.

**Verdict:** Not addressed by the remediation report, correctly so — it is not a
schema wiring problem. It is a Phase 3 API and admissibility engine design problem
(addressed by TSK-P3-W2-API-004, Legitimacy Proof API, in the Phase 3 task plan).

---

### D-04 — Formal Constitutional Ontology

**Claim:** State classes, authority classes, replay classes, retention classes,
sovereignty classes, admissibility classes, revocation classes, fraud classes, and
transition classes must all be machine-readable and versioned.

**Codebase reality:**
- State classes: `data_authority_level` ENUM exists (migration 0137) with `authoritative_signed`,
  `superseded`, `invalidated`, etc. Partial.
- Retention classes: `constitutional_data_class` does not yet exist (proposed in Action 2).
- Replay classes: no explicit enum. `replay_critical` does not exist on any table.
- Authority classes: `attestation_source_type` ENUM exists (migration 0168). Partial.
- Sovereignty classes: no machine-readable registry. Referenced in doctrine only.
- Admissibility classes: no machine-readable registry.
- Revocation classes: no explicit enum distinguishing prospective vs retroactive.
- Fraud classes: no machine-readable fraud taxonomy.
- Transition classes: OPEN, REVIEW, CHALLENGED, CLOSED, SUPERSEDED, INVALIDATED,
  ARCHIVED, FORKED — partially present via `state_transitions` table (migration 0137)
  and `data_authority_level` ENUM, but incomplete. CHALLENGED, FORKED are not present.

**Does the remediation report address it?** Partially. The `constitutional_data_class`
ENUM (Action 2) covers the retention class domain. The remaining classes (sovereignty,
admissibility, revocation, fraud, full transition) are not addressed — they are Phase 3
Wave 3, 4, 5, 6, and 9 work per the task plan.

**Verdict:** The remediation report addresses one of nine ontology domains. The others
are Phase 3 implementation work, not pre-Phase-3 wiring gaps.

---

### D-05 — Constitutional Closure Doctrine

**Claim:** Closure conditions, replay sealing, and what closure does and does not
seal must be formally defined and mechanically enforced.

**Codebase reality:** The `state_transitions` table (migration 0137) with
`data_authority_level` captures authority at transition time. The `proof_pack_batches`
table (migration 0066) is the Merkle-based closure/seal mechanism — but is dormant.
There is no explicit `CLOSED` state in any currently populated table. The `policy_versions`
table captures the active policy at closure time. The invariant register has `superseded_by`
for lineage continuity.

**Does the remediation report address it?** Yes — Action 4 (Epoch Sealing Process)
directly activates the dormant `proof_pack_batches` closure mechanism. This is the
concrete operational implementation of D-05's "seal witnesses attest closure" and
"replay checkpoint integrity."

**Verdict:** Directly and specifically addressed by Action 4 of the remediation report.

---

### D-06 — Revocation & Invalidation Doctrine

**Claim:** Both prospective revocation and retroactive invalidation must be replay-visible
with preserved pre- and post-revocation state.

**Codebase reality:** Migration 0179 (`wave8_key_lifecycle_enforcement`) handles key
revocation. The `data_authority_level` ENUM includes `superseded` and `invalidated`.
The Wave 8 enforcement function checks `signer_is_active`, `valid_until`, and
`superseded_by`. Prospective revocation is well-modeled. Retroactive invalidation —
the ability to retroactively mark a historical decision as invalidated and have that
visible in replay — has no dedicated table or mechanism. The `invalidated` state exists
as an ENUM value but there is no `invalidation_events` append-only log.

**Does the remediation report address it?** No. This is correct omission — retroactive
invalidation is Phase 3 Wave 6 (Conflict-of-Interest Enforcement) and Wave 9 (Failure
Composition) work in the task plan, not a pre-Phase-3 wiring gap.

**Verdict:** Not addressed by the remediation report. This is Phase 3 task pack work
(specifically TSK-P3-W9-DIAG-001 through -005), not pre-Phase-3 infrastructure.

---

### D-07 — Constitutional Minimality Principle

**Claim:** Only replay-critical state may become constitutionally permanent. Every
constitutional artifact must prove replay necessity, bounded survivability, and minimal
governance surface.

**Codebase reality:** No admission review process exists. The 822 task directories
demonstrate that no artifact has ever been rejected from permanence. The `proof_pack_batches`
dormancy is itself a symptom — epoch checkpointing exists precisely to implement bounded
replay, but nothing uses it.

**Does the remediation report address it?** Yes — the constitutional compilation pipeline
(Action 6) is the admission review process. It enforces that every declared invariant
has explicit evidence of its enforcement chain before it can be registered as blocking.
The `data_class` column (Action 2) establishes the classification that allows operational
exhaust to be marked for permitted deletion.

**Verdict:** Addressed at the schema and tooling layer by Actions 2 and 6.

---

### D-08 — Trust Root Rotation & Cryptographic Evolution

**Claim:** Cryptographic assumptions are temporary. Replay must survive algorithm migration.
Witness notarization, re-signature lineage, and multi-root attestation are needed.

**Codebase reality:** Migration 0179 (`wave8_key_lifecycle_enforcement`) implements key
lifecycle with `valid_from`, `valid_until`, `superseded_by`, and `superseded_at`. The
`signer_resolution` surface has `entity_type` restrictions. This handles key rotation
within the current algorithm. Multi-algorithm migration (e.g., moving from Ed25519 to a
post-quantum algorithm) is not addressed. There is no `algorithm_version` column on
`public_keys_registry` (migration 0165), no witness notarization table, no re-signature
lineage.

**Does the remediation report address it?** No. This is correctly out of scope. D-08
describes a multi-year cryptographic evolution problem. The `wave8_crypto` extension
verification (Action 1) is the relevant immediate action — confirming the current
algorithm works operationally. Long-horizon algorithm migration is Phase 8A+ work.

**Verdict:** Not addressed by the remediation report, correctly so.

---

### D-09 — Constitutional Reopening Doctrine

**Claim:** Replay systems must support bounded reopening with evidentiary thresholds,
replay-governed petitions, and preserved original + superseding lineage.

**Codebase reality:** There is no reopening mechanism anywhere in the schema. The
`state_transitions` table has an `invalidated` authority level, but there is no
`reopening_petitions` table, no `invalidation_lineage`, no fork semantics. The
`invariant_registry` has `superseded_by` — this covers linear supersession but not
parallel forked lineages.

**Does the remediation report address it?** No. This is Phase 3 Wave 8-9 work, not
a pre-Phase-3 infrastructure gap. The report correctly does not attempt to address it.

**Verdict:** Not addressed by the remediation report, correctly so. This is Phase 3
task pack work (TSK-P3-W8-REP-* and TSK-P3-W9-DIAG-*).

---

### D-10 — Constitutional State Transition Algebra

**Claim:** All constitutional transitions must be explicit, admissible, replay-verifiable,
and monotonic unless explicitly reversible. Required states: OPEN, REVIEW, CHALLENGED,
CLOSED, SUPERSEDED, INVALIDATED, ARCHIVED, FORKED.

**Codebase reality:** The `data_authority_level` ENUM (migration 0137) covers:
`phase1_indicative_only`, `non_reproducible`, `derived_unverified`, `policy_bound_unsigned`,
`authoritative_signed`, `superseded`, `invalidated`. Migration 0137 also implements
`enforce_state_transition_authority()` which enforces valid transition sequences. This
is the closest existing implementation of D-10's transition algebra.

What is missing: OPEN, REVIEW, CHALLENGED, ARCHIVED, FORKED as explicit states. The
authority upgrade/downgrade trigger handles the ladder from non_reproducible to
authoritative_signed to superseded/invalidated — this is a partial transition algebra
for the data authority dimension, not the full constitutional lifecycle described in D-10.

**Does the remediation report address it?** No. The `data_class` column (Action 2)
adds lifecycle classification but not the full transition state machine. The full
transition algebra is Phase 3 Wave 10 (TSK-P3-W10-CERT-005, exit gate orchestrator)
and beyond.

**Verdict:** Partially present in the codebase (data_authority_level transitions).
Not extended by the remediation report. This is Phase 3 and later work.

---

### D-11 — Replay vs Truth Doctrine

**Claim:** Replayability proves reconstructability, not truth. The system must not
claim infallibility.

**Codebase reality:** This is a constitutional doctrine constraint, not a schema
constraint. The `REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md` document addresses it at the
doctrine layer. No schema enforcement exists or is possible for a philosophical claim.

**Does the remediation report address it?** No. This is not a schema wiring problem.

**Verdict:** Not applicable to the remediation report.

---

### D-12 — Fraud Ontology Doctrine

**Claim:** Fraud classes (Forgery, Evidence Fraud, Procedural Fraud, Collusion, Sovereign
Fraud, Negligent Attestation, Replay Fraud) must each have defined evidentiary thresholds,
burden of proof, reopening authority, invalidation scope, retroactivity semantics.

**Codebase reality:** No fraud ontology table exists. The regulatory incident workflow
(migration 0060, `gf_regulatory_plane`) captures incident types including fraud-related
ones. The Wave 8 enforcement function fires `P7809` for signature failures — this is
one class of fraud detection (forgery). The `wave8_attestation_nonces` table catches
replay fraud. But there is no unified fraud classification registry.

**Does the remediation report address it?** No. This is Phase 3 Wave 5 work (TSK-P3-W5-
REG-005, Fraud Escalation Evidence Package Generator) per the task plan.

**Verdict:** Not addressed by the remediation report, correctly so.

---

### D-13 — Temporal Identity Continuity Doctrine

**Claim:** Replay must preserve successor/predecessor lineage for renamed, split, merged,
or dissolved authorities.

**Codebase reality:** `signer_resolution` surface has `superseded_by` and `superseded_at`
for key supersession. The `invariant_registry` has `superseded_by` for linear supersession.
Neither covers organisational identity transformation (ministry renamed, regulator dissolved).
There is no `authority_identity_continuity` table.

**Does the remediation report address it?** No. This is long-horizon work, Phase 8A+.

**Verdict:** Not addressed by the remediation report, correctly so.

---

### D-14 — Economic Survivability Doctrine

**Claim:** Every constitutional guarantee must declare storage cost, replay cost,
archival cost, sovereignty replication cost. Replay cost must remain bounded.

**Codebase reality:** No economic cost modeling exists anywhere. The `proof_pack_batches`
table with Merkle trees IS the replay cost-bounding mechanism — but dormant. The
`archive_verification_runs` table IS the archival economics monitoring tool — but dormant.

**Does the remediation report address it?** Yes — Action 4 (Epoch Sealing Process)
activates both `proof_pack_batches` and `archive_verification_runs`. This directly
implements the D-14 "replay cost must remain bounded" requirement by enabling epoch
checkpointing. The additional performance task (TSK-P3-PERF-006) proposed in the
Phase 3 task pack assessment covers performance boundary declarations.

**Verdict:** Partially addressed by Action 4 of the remediation report.

---

### D-15 — Institutional Failure Doctrine

**Claim:** Constitutional systems must assume institutional failure. Multi-party attestation,
sovereign redundancy, witness diversity, independent replay, and institutional supersession
lineage are needed.

**Codebase reality:** Multi-party attestation: Wave 8 has a single signing authority per
batch — not multi-party. Sovereign redundancy: no off-system sovereign escrow. Independent
replay: the `TamperEvidentChain.cs` application chain is independent of the DB, but not
independently sovereign. Institutional supersession: no mechanism.

**Does the remediation report address it?** No. Action 5 (connecting application chain
to DB Merkle system) is a step toward independent replay but not sovereign redundancy.
This is long-horizon multi-year work.

**Verdict:** Not addressed by the remediation report, correctly so.

---

## Part 2: The Phase 3 Risk Register (P3-01 through P3-16)

The 16 items listed in Part 4 of the baseline register are described as "active and
unresolved." Let me map them against what exists and what the report addresses.

| Risk | Description | In Codebase? | In Remediation Report? |
|------|-------------|--------------|----------------------|
| P3-01 | Governance lifecycle absence | Partially (data_authority_level) | Yes — Action 2 (data_class) |
| P3-02 | Governance recursion explosion | No — 822 tasks, no archival | Acknowledged, not tasked |
| P3-03 | Missing constitutional admissibility core | No dedicated admissibility table | Phase 3 task plan work |
| P3-04 | Replay unboundedness | Schema exists, dormant | Yes — Action 4 (epoch sealing) |
| P3-05 | Constitutional semantics embedded in runtime | Partially (YAML doctrine exists) | Yes — Action 6 (compilation pipeline) |
| P3-06 | Missing typed constitutional registry | No — doctrine is prose only | Yes — Actions 2+6 (data_class YAML + compiler) |
| P3-07 | Weak evidence validation | Wave 8 is strong; evidence_nodes is weak | Partially — Action 2 adds class metadata |
| P3-08 | Contradiction replay undefined | No contradiction tables yet | Phase 3 Wave 3 work |
| P3-09 | Metadata explosion risk | Active — no archival mechanism | Partially acknowledged |
| P3-10 | Missing carry-forward governance registry | phase3_contract.yml exists; CF-2 tracked | Yes — Actions 3+6 address this |
| P3-11 | Replay vs retention conflation | No classification on evidence_nodes | Yes — Action 2 separates them |
| P3-12 | Missing sovereignty boundary semantics | Doctrine exists; no machine registry | Phase 3 Wave 5 work |
| P3-13 | Missing interpretation version binding | Implemented (migration 0116, 0156-0159) | Already present; not needed |
| P3-14 | Replay checkpoint safety rules | Schema in 0066, dormant | Yes — Action 4 activates |
| P3-15 | Missing phase legality enforcement | TSK-P3-SEC-007 in task plan | Yes — referenced in task plan assessment |
| P3-16 | Replay-critical ontology registry | No — no replay_critical column | Partially — Action 2 adds data_class |

**Notable finding on P3-13:** Interpretation version binding is NOT missing. Migrations
0116, 0156, 0158, and 0159 implement and enforce `interpretation_version_id` as a NOT NULL
column on the relevant tables, with a `resolve_interpretation_pack()` SECURITY DEFINER
function for temporal resolution. The baseline register's claim that this is missing is
incorrect — it is one of the most complete implementation areas in the schema.

---

## Part 3: What the Remediation Report Gets Right, What It Misses, and What the Baseline Register Gets Wrong

### What the remediation report gets right

The six actions are precisely calibrated to the pre-Phase-3 wiring gaps. They activate
infrastructure that exists but is dormant (Actions 4, 5), add the one missing schema
column that blocks everything downstream (Action 2), and create the governance tooling
that prevents future drift (Actions 3, 6). None of these actions are invalidated by
the baseline register.

### What the remediation report does not address (and correctly so)

The baseline register describes problems at three distinct layers:

**Layer 1 — Infrastructure wiring (what the report addresses):** Actions 1-6 close
the six gaps at this layer. D-01 (classification), D-05 (closure sealing), D-07
(minimality enforcement), D-14 (replay cost bounding) are addressed.

**Layer 2 — Phase 3 implementation (what the task plan addresses):** D-06 (revocation),
D-09 (reopening), D-10 (transition algebra), D-12 (fraud ontology), P3-03, P3-08,
P3-12, P3-15 all live here. These are the 116 Phase 3 tasks, not pre-Phase-3 wiring work.

**Layer 3 — Long-horizon constitutional problems (post-Phase 3):** D-08 (algorithm
migration), D-13 (identity continuity), D-15 (institutional failure), multi-sovereign
deadlock resolution, reopening thresholds, appeals semantics. These are the "remaining
unknowns" the baseline register honestly labels as undefined. No schema change resolves
them.

### What the baseline register gets wrong

**P3-13 (Interpretation version binding):** Already implemented through migrations 0116,
0156, 0158, and 0159. The `interpretation_version_id` NOT NULL constraint is enforced
at the DB layer. This is not missing.

**D-02 (Admissibility determinism):** Substantially implemented through the determinism
columns (migrations 0131-0133), policy version ledger (migration 0005), and interpretation
pack temporal resolution (migration 0116). The baseline register frames this as an unmet
requirement when it is one of the better-implemented aspects of the system.

**The framing of Wave 8 as incomplete:** The baseline register's implicit suggestion
(based on prior analysis) that Wave 8 cryptographic enforcement is a placeholder is
contradicted by migration 0190. As documented in the remediation report, this was
resolved — only the operational confirmation of the extension (Action 1) remains.

---

## Part 4: Does the Baseline Register Invalidate the Remediation Report?

**No.** The baseline register and the remediation report address different problems at
different altitudes.

The remediation report answers: *"What six things must be wired before Phase 3
implementation tasks can safely begin?"*

The baseline register answers: *"What are all the constitutional problems Symphony
must eventually solve, across its full multi-year arc?"*

These are compatible, not contradictory. The six actions in the remediation report
are necessary preconditions for the Phase 3 task plan. The baseline register describes
the full constitutional horizon that the Phase 3 task plan begins to address and that
later phases must complete.

---

## Part 5: One Gap the Remediation Report Should Add

Reading the baseline register against the report, one gap is present in the baseline
register that the report does not address and should:

**The task corpus archival problem (P3-02 — Governance Recursion Explosion)**

822 task directories. No archival mechanism. CI traverses all of them. Every new
task adds to the permanent traversal surface. This is D-07 (Constitutional Minimality)
applied to the task system itself.

The remediation report notes this but does not assign a task to it. A concrete action
is needed:

**TSK-P3-GOV-003 — Task Corpus Archival Gate**

Add an `archived: false` boolean field to all task `meta.yml` files (starting from
the `_template`). Modify the CI scripts (`verify_task_meta_schema.sh`,
`verify_task_plans_present.sh`) to skip tasks where `archived: true`. Add a
constitutional rule: any task with `status: completed` and no current Phase 3
dependencies may be archived by human authorization. This does not delete tasks —
it excludes them from active CI traversal, which is the D-01 distinction between
constitutional state and operational exhaust applied to the task system.

This is the one addition the remediation report should include. It is small in
implementation, large in operational impact.

---

## Final Verdict

| Question | Answer |
|----------|--------|
| Does the baseline register invalidate the remediation report? | No |
| Does the remediation report address all baseline register concerns? | No — and it shouldn't. They operate at different altitudes |
| Are the six remediation actions still correct? | Yes, confirmed against both codebase and baseline register |
| Is anything in the baseline register factually wrong? | Yes — P3-13 (interpretation binding) and D-02 (admissibility determinism) are substantially implemented |
| Is there one gap the remediation report should add? | Yes — TSK-P3-GOV-003, task corpus archival gate |
| What does the baseline register correctly identify that no current work addresses? | D-08 (algorithm migration), D-09 (reopening), D-10 (full transition algebra), D-13 (identity continuity), D-15 (institutional failure) — all post-Phase-3 frontier |

The remediation report stands. Add TSK-P3-GOV-003. The baseline register is an honest
constitutional horizon document, not a refutation of the wiring-level remediation plan.
