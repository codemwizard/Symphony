---
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 9
Phase-Scope: GLOBAL
Supersedes: informal capability status descriptions in prior forensic reports
Depends-On:
  - docs/operations/PHASE_LIFECYCLE.md (phase key definitions, Section 2–9)
  - docs/operations/WAVE_EXECUTION_SEMANTICS.md (wave-vs-phase boundary)
  - docs/invariants/INVARIANTS_MANIFEST.yml (canonical invariant status)
  - docs/PHASE1/phase1_contract.yml (Phase-1 contract row status semantics)
  - docs/PHASE2/phase2_contract.yml (Phase-2 contract row status semantics)
  - docs/architecture/evidence_schema.json (evidence admissibility constitution)
  - scripts/audit/enforce_invariant_promotion.sh (promotion legality gate)
  - scripts/audit/verify_phase_claim_admissibility.sh (claim legality gate)
---

# PHASE_CAPABILITY_LEGALITY_MATRIX.md

## Purpose

This document defines the constitutional legality of every capability state a
Symphony system component may occupy across lifecycle phases. It establishes
which absence states are constitutionally legal, which constitute violations,
and which are reserved constitutional territory that must not be reclassified
as defects, dead schema, or missing implementation.

This document governs:

- how capability states are interpreted for admissibility, audit, and delivery
  claims across Phase-0 through Phase-4 and deferred reservations;
- the distinction between waves (execution-sequencing subdivisions) and phases
  (constitutional capability boundaries);
- the legality of dormant, scaffolded, and deferred substrate;
- the conditions under which capability absence constitutes a constitutional
  violation rather than a legal non-activation.

---

## 1. Foundational Definitions

### 1.1 Capability State Taxonomy

The following capability states are canonically defined for Symphony. No state
outside this taxonomy is constitutionally recognised for delivery or audit
purposes.

**STATE-1: CONSTITUTIONALLY REQUIRED**
A capability that must exist and be mechanically enforced within the current
phase for the phase to be delivery-claimable. Absence is a constitutional
violation. Governed by `required: true` rows with `status: implemented` in the
phase contract.

**STATE-2: PLANNED**
A capability declared in the phase contract with `status: planned`. The
capability is within scope for the current phase but has not yet completed
implementation. Absence is legal during the phase. Planned status does not
constitute delivery-claimable presence.

**STATE-3: DECLARED BUT INACTIVE**
A capability named in `INVARIANTS_MANIFEST.yml` with `status: roadmap`. The
capability has been constitutionally reserved by declaration. No verifier or CI
gate exists. No evidence path is defined. Absence of enforcement is legal.
The declaration is not a delivery claim.

**STATE-4: SCAFFOLDED BUT UNWIRED**
A capability whose schema substrate exists (table, constraint, trigger, or
function) but whose CI gate, evidence path, or invariant contract row does not
yet exist. The substrate is constitutionally reserved. The capability is not
delivery-claimable. Scaffolded substrate must not be classified as dead schema
or duplicate implementation.

**STATE-5: RUNTIME-DISABLED BUT SCHEMA-BACKED**
A capability whose schema enforcement exists at the database layer (trigger
active, constraint live) but which operates in a declared limited posture
pending future-phase wiring. This state is constitutionally legal when the
limited posture is explicitly documented in evidence or in contract notes. The
capability is partially enforced at the runtime layer and partially reserved at
the governance layer.

**STATE-6: CI-GATED BUT PHASE-UNOPENED**
A capability whose verifier script exists and is wired in CI, but whose
associated phase has not been formally opened via the required approval artifact
set (PHASE_LIFECYCLE.md Section 3, item 6). The CI gate may fire (enforcing
or advisory), but delivery claims referencing the phase key are inadmissible
until the phase is opened. This state is constitutionally legal.

**STATE-7: DEFERRED TO FUTURE PHASE**
A capability explicitly declared in the current phase contract with
`status: deferred_to_phase<n+1>`. The capability is out of the current phase's
capability boundary. Absence in the current phase is constitutionally required.
The deferral carries a forward obligation: the capability must appear in the
next phase's planning with a downstream owner, target phase mapping, dependency
declaration, and carry-forward artifact.

**STATE-8: SOVEREIGN EXPANSION SEAM**
Substrate that carries no current enforcement function and is not referenced in
any active contract row, but which constitutionally reserves a future authority
domain against parallel replacement. A sovereign expansion seam is not absent
capability; it is prospective authority reservation. Examples include
`key_rotation_drills`, `historical_verification_runs`, `resign_sweeps`
(Wave 4 signing lifecycle tables), and the `canonicalization_versions` registry
entries beyond v1.

---

## 2. Constitutional Legality Rules

### 2.1 What Is Legal to Be Absent

The following absences are constitutionally legal and must not be classified as
defects, violations, or incomplete implementation:

**R-LEGAL-01**: A capability in STATE-3 (Declared But Inactive) that has no
verifier, no CI gate, and no evidence path is legally absent. The manifest
entry is a constitutional declaration, not a delivery claim. Examples:
INV-039 (fail-closed under DB exhaustion), INV-168 (pilot SCOPE.md
declarations), INV-170 through INV-174 (supervisory dashboard invariants).

**R-LEGAL-02**: A capability in STATE-4 (Scaffolded But Unwired) whose
schema substrate exists but whose contract row, verifier, and evidence path
do not yet exist is legally absent as a delivery capability. The substrate
is a constitutional seam. Examples: `key_rotation_drills` table (migration
0065), `historical_verification_runs` table (migration 0065), `resign_sweeps`
table (migration 0065), proof-pack backfill infrastructure (migration 0066).

**R-LEGAL-03**: A capability in STATE-7 (Deferred) with a valid deferral
record satisfying PHASE_LIFECYCLE.md Section 2E is legally absent from the
current phase. The deferral is not a gap; it is an explicit constitutional
forward-reservation. Phase-1 examples: INV-039 (`deferred_to_phase2`,
`phase1_contract.yml`), INV-048 (`deferred_to_phase2`, `phase1_contract.yml`).

**R-LEGAL-04**: Phase-4 capabilities, as defined in PHASE_LIFECYCLE.md
Section 9, are legally absent from the current repository state. Their absence
does not constitute a defect. Their constitutional territory is reserved.
Scaffolding them before Phase-4 opens is a sovereign expansion seam activity,
not premature implementation.

**R-LEGAL-05**: A capability in STATE-5 with an explicitly documented limited
posture is legally absent from full enforcement. Example: INV-125
(finality seam stub, `perf_005a_finality_seam_stub.json`) declares itself as
a simulated stub with explicit pending Phase-2 live finality wiring. The
stub posture is legally enforced; the full posture is constitutionally deferred.

**R-LEGAL-06**: The absence of unopened future-phase directories, contract
files, verifier scripts, and opening approval artifacts remains legally
required under the current constitutional state for those future phases. For
Phase 3 specifically, once the full required artifact set
(PHASE_LIFECYCLE.md Section 3) exists and the opening approval artifact is
merged, Phase-3 lifecycle and activation claims become constitutionally
admissible subject to the active execution envelope.

**R-LEGAL-07**: A wave schedule that partitions Phase-N tasks into named
execution batches does not constitute a phase boundary. Wave absence, wave
incompleteness, or wave re-sequencing does not affect phase legality.
Wave completion is not phase closeout. This rule is absolute.

### 2.2 What Constitutes a Constitutional Violation

The following states constitute constitutional violations and must be treated
as blocking conditions for delivery claims and phase closeout:

**V-VIOLATION-01 — Required Row Absent From Contract**
A capability with `required: true` and `status: implemented` in the phase
contract whose verifier emits a FAIL or whose evidence path does not exist
constitutes a constitutional violation. Gate flag must be set to fail-closed
(`RUN_PHASE<N>_GATES=1`) before closeout. Applicable to all phase contract
rows with `required: true`.

**V-VIOLATION-02 — Delivery Claim Without Phase Opening**
Using a phase key in task metadata, branch naming, commit headers, approval
records, release notes, roadmap claims, status dashboards, or evidence-folder
naming before the phase-opening approval artifact set exists constitutes a
constitutional violation. Mechanically enforced by
`scripts/audit/verify_phase_claim_admissibility.sh`, wired in both `pre_ci.sh`
and `.github/workflows/invariants.yml`. Applies to all phase keys 0 through 4.

**V-VIOLATION-03 — Task-ID Row in Invariant-Centric Contract**
A Phase-2 or later phase contract row whose `invariant_id` field contains a
task identifier (pattern `^TSK-`) rather than an invariant identifier (pattern
`^INV-`) constitutes a constitutional violation of the schema lineage rule
(PHASE_LIFECYCLE.md Section 11). Currently present in `phase2_contract.yml`
for rows from the early planning state; these must be remediated before
Phase-2 can formally open.

**V-VIOLATION-04 — Task-Runner Verifier in Invariant-Centric Contract**
A Phase-2 or later phase contract row whose `verifier` field references a
task-runner script (e.g. `scripts/agent/run_task.sh`) rather than a
deterministic invariant verifier script constitutes a constitutional
violation. Verifiers must be self-contained scripts that emit schema-valid
evidence and return 0 for PASS or non-zero for FAIL.

**V-VIOLATION-05 — Deferral of a Failed Required Invariant**
Marking a required invariant row as `deferred_to_phase<n+1>` after its
verifier has been run and reported FAIL is a constitutional violation.
A failing required invariant is failed, not deferred. Deferral requires
satisfying all conditions of PHASE_LIFECYCLE.md Section 2E; failure of a
required verifier does not satisfy those conditions.

**V-VIOLATION-06 — Inadmissible Delivery Claim Language**
Use of the phrases "Phase complete", "Phase ready", "Phase done",
"Phase aligned", or any broader language implying an entire phase is finished,
without a formal phase closeout approval artifact, constitutes a constitutional
violation. Mechanically blocked by `verify_phase_claim_admissibility.sh`.

**V-VIOLATION-07 — Promotion of Invariant Without Verifier**
Changing an invariant's status in `INVARIANTS_MANIFEST.yml` from `roadmap` to
`implemented` without satisfying all four promotion conditions (non-empty
owners, non-TODO verification reference, presence in `INVARIANTS_IMPLEMENTED.md`,
absence from `INVARIANTS_ROADMAP.md`) constitutes a constitutional violation.
Mechanically blocked by `scripts/audit/enforce_invariant_promotion.sh`,
exit code 2.

**V-VIOLATION-08 — Wave Used as Phase Boundary**
Treating a wave completion as a phase closeout condition constitutes a
constitutional violation. WAVE_EXECUTION_SEMANTICS.md Section 5 states
explicitly: "A Wave does not create a separate contract from the parent phase."
A wave schedule is a named execution batch derived from the canonical linear
sequence. It carries no phase-level admissibility.

**V-VIOLATION-09 — Parallel Replacement of Reserved Infrastructure**
Creating a new table, function, or registry that duplicates the constitutional
territory of an existing append-only ledger, supersession chain, or temporally
bounded registry without migrating through the existing lineage constitutes a
constitutional violation of the Extension-over-Replacement Doctrine. Examples
of reserved territory that must not be replaced in parallel: `invariant_registry`
(append-only, linear supersession), `public_keys_registry` (temporal exclusion
gist constraint), `interpretation_packs` (temporal overlap exclusion),
`canonicalization_versions`, `proof_pack_batches`.

---

## 3. Capability Legality Matrix by Phase

### 3.1 Phase-0 (Hardened Baseline)

**Constitutional posture**: CLOSED (formally closed).

| Capability State | Legality | Condition |
|---|---|---|
| Required rows pass `verify_phase0_contract.sh` | REQUIRED | Phase closeout is constitutionally dependent on this |
| Evidence under `evidence/phase0/**` is schema-valid | REQUIRED | Phase-0 closeout evidence must be reproducible |
| Phase-0 legacy schema rows (task-centric pattern) | LEGAL | Phase-0 is the canonical exception to the invariant-centric schema requirement |
| Phase-0 non-regression under Phase-1+ codebase | REQUIRED | All phases carry Phase-0 non-regression obligation |
| Absent Phase-1 capabilities | LEGAL | Phase-0 has no obligation to anticipate Phase-1 capability classes |

**Replay obligation**: Phase-0 evidence is the constitutional baseline for all
subsequent replay operations. No Phase-0 evidence artifact may be removed or
overwritten without an approved one-shot cutover that preserves replay continuity.

### 3.2 Phase-1 (Deterministic Pilot Expansion)

**Constitutional posture**: CLOSED (formally closed).

| Capability | State | Legality | Authoritative Source |
|---|---|---|---|
| INV-111 through INV-119, INV-120–129, INV-135–137, INV-142–144, INV-146–155 | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED — verifiers exist, evidence exists, gate is wired | `phase1_contract.yml`, implemented rows |
| INV-039 | STATE-7: DEFERRED | LEGAL — explicit deferral to Phase-2 in `phase1_contract.yml` | `phase1_contract.yml`, `deferred_to_phase2` row |
| INV-048 | STATE-7: DEFERRED | LEGAL — explicit deferral to Phase-2 in `phase1_contract.yml` | `phase1_contract.yml`, `deferred_to_phase2` row |
| INV-125 (PERF-005A finality seam stub) | STATE-5: RUNTIME-DISABLED BUT SCHEMA-BACKED | LEGAL — limited posture explicitly declared in evidence; live finality deferred | `evidence/phase1/perf_005a_finality_seam_stub.json` |
| Phase-2 capabilities | STATE-6 or STATE-7 | LEGAL to be absent — outside Phase-1 capability boundary | PHASE_LIFECYCLE.md Section 7 |
| Wave 1 through Wave N completion | Not a phase state | LEGALLY IRRELEVANT to Phase-1 closeout | WAVE_EXECUTION_SEMANTICS.md Section 5 |

**Replay obligation**: All Phase-1 evidence is replay-eligible. The
`interpretation_version_id` NOT NULL constraint on `execution_records` (INV-179,
INV-165, INV-167) ensures every execution record is replayable against the
interpretation pack that governed it. Phase-1 replay survivability is
constitutionally enforced at the DB layer by migration 0131–0133.

### 3.3 Phase-2 (Controlled Expansion and Governance Automation)

**Constitutional posture**: HISTORICAL AND SUPERSEDED BY OPEN PHASE-3 GOVERNANCE.

Phase-2 is no longer the active lifecycle surface. Phase-3 is open and governs
current execution posture. Phase-2 evidence remains historically admissible as
executed preparatory and delivery work within its own constitutional boundary,
but it is not the active phase-routing authority for current task creation.

| Capability | State | Legality | Authoritative Source |
|---|---|---|---|
| INV-156 (Sprint-5 gated lane boundary) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-157 (Internal ledger model) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-158 (Ledger proof jobs) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-175 (interpretation_version_id enforcement) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-176 (state machine trigger enforcement) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-177 (Phase-1 boundary markers in C# models) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `phase2_contract.yml`, implemented row |
| INV-178 (DNSH spatial enforcement) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens — verifier exists, evidence exists | `INVARIANTS_MANIFEST.yml`, INV-178 |
| INV-179 (execution truth anchor) | STATE-1: CONSTITUTIONALLY REQUIRED | REQUIRED once Phase-2 opens | `INVARIANTS_MANIFEST.yml`, INV-179 |
| TSK-P2-PREAUTH-005-00 through 005-08 rows in `phase2_contract.yml` | V-VIOLATION-03 | VIOLATION — task IDs in `invariant_id` field. Must be remediated before Phase-2 opens | `phase2_contract.yml`, non-compliant rows |
| `PHASE2_CONTRACT.md` | STATE-4: SCAFFOLDED BUT UNWIRED | LEGAL to be absent currently; becomes a REQUIRED artifact before Phase-2 opens | PHASE_LIFECYCLE.md Section 3 item 1 |
| `AGENTIC_SDLC_PHASE2_POLICY.md` | STATE-4: SCAFFOLDED BUT UNWIRED | LEGAL to be absent currently; becomes a REQUIRED artifact before Phase-2 opens | PHASE_LIFECYCLE.md Section 3 item 3 |
| `verify_phase2_contract.sh` | STATE-6: CI-GATED BUT PHASE-UNOPENED | LEGAL — script exists and is CI-wired; Phase-2 is not yet open | CI `invariants.yml`, `verify_phase2_contract.sh` |
| Wave 8 (currently active execution wave) | Not a phase state | LEGALLY IRRELEVANT to Phase-2 opening | WAVE_EXECUTION_SEMANTICS.md Section 5 |
| ~90 Phase-2 evidence artifacts under `evidence/phase2/` | STATE-6 | LEGAL to exist — preparatory work; not delivery-claimable until Phase-2 opens | PHASE_LIFECYCLE.md Section 2F |

**Pre-opening legality obligations**:

Before Phase-2 may formally open, the following must transition from their
current state to CONSTITUTIONALLY REQUIRED:

1. `phase2_contract.yml` contract-to-execution reconciliation — all executed
   work must be represented as INV-ID rows with existing verifier scripts and
   evidence paths. TSK-ID rows must be remediated.
2. `PHASE2_CONTRACT.md` must be created.
3. `AGENTIC_SDLC_PHASE2_POLICY.md` must be created.
4. `verify_phase2_contract.sh` must pass with `RUN_PHASE2_GATES=1` against the
   reconciled contract.
5. `approvals/YYYY-MM-DD/PHASE2-OPENING.md` and its sidecar JSON must be
   created and merged.

**Replay obligation**: Phase-2 replay survivability is constitutionally grounded
in `execution_records.interpretation_version_id` (INV-179, INV-165), the
`canonicalization_versions` registry, and the Merkle proof infrastructure
(migration 0066). Every Wave 8 execution that produces an evidence artifact
under `evidence/phase2/**` must be replayable against its git_sha. The
attestation kill switch (`validate_attestation_gate()`) ensures that all
`asset_batches` inserts carry a `registry_snapshot_hash` that binds the
issuance decision to the live invariant_registry state at the time of insertion.

### 3.4 Phase-3 (Scaled Runtime Assurance)

**Constitutional posture**: OPEN FOR ACTIVATION GOVERNANCE, RUNTIME IMPLEMENTATION STILL GATED.

| Capability | State | Legality | Authoritative Source |
|---|---|---|---|
| Phase-3 lifecycle artifact set | STATE-1 | REQUIRED and present for opened-phase activation claims | PHASE_LIFECYCLE.md Section 3; approvals/2026-05-16/PHASE3-OPENING.md |
| `docs/PHASE3/` directory | STATE-1 | REQUIRED and present | Active Phase-3 artifact set |
| `docs/PHASE3/PHASE3_CONTRACT.md` | STATE-1 | REQUIRED and present | PHASE_LIFECYCLE.md Section 3 |
| `docs/PHASE3/phase3_contract.yml` | STATE-1 | REQUIRED and present | PHASE_LIFECYCLE.md Section 3 |
| `scripts/audit/verify_phase3_contract.sh` | STATE-1 | REQUIRED and present | PHASE_LIFECYCLE.md Section 3 |
| Activation task metadata referencing `phase: '3'` | STATE-1 | LEGAL for opened-phase activation work when backed by approval and the active envelope | PHASE_EXECUTION_ENVELOPE.md |
| Broader Phase-3 runtime implementation tasks beyond the activation sequence | STATE-2 | PLANNED but not yet executable; gated by the active envelope | PHASE_EXECUTION_ENVELOPE.md |
| Historical Phase-3 planning and evidence artifacts | STATE-4 | LEGAL to exist but not automatically delivery-claimable until classified or regenerated | PHASE_EXECUTION_ENVELOPE.md Section 12 |

**Entry condition satisfied**: Phase-3 opening artifacts exist and Phase 3 is
constitutionally open for activation governance. Broader runtime implementation
remains subject to the active envelope and the remaining activation tasks.

### 3.4A Phase-3 Doctrine-Routed Task-Plan Legality

The following legality matrix applies to Phase 3 boundary and doctrine readiness.
It governs task-plan creation before atomic implementation tasks are generated.

| Capability Domain | Legality | Condition |
|---|---|---|
| Typed Dependency Graph | AUTHORIZED | Must cite policy lineage, authority lineage, and replay doctrine. |
| Recursive Legitimacy and Replay Projection | AUTHORIZED | Must cite `LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` and replay/temporal doctrine. |
| Contradiction Detection and Handling | AUTHORIZED | Must use classes in `CONTRADICTION_CLASSIFICATION_DOCTRINE.md`. |
| Failure Composition | AUTHORIZED | Must use categories in `FAILURE_COMPOSITION_TAXONOMY.md`. |
| Authority Scope and Delegation Enforcement | AUTHORIZED | Must cite `AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`. |
| Regulator-Aware Arbitration Mechanics | CONDITIONAL | Authorized only where governing regulator and precedence doctrine defines the rule. |
| Spatial Constraint and DNSH Gates | CONDITIONAL | Authorized only where a spatial policy artifact defines the mechanical rule and scope. |
| Cross-System Evidence Continuity | CONDITIONAL | Authorized only as internal evidence-continuity mechanics; external integrations are prohibited. |
| Dwell-Time Forensic Enforcement | AUTHORIZED | Must cite temporal replay and contradiction doctrine. |
| Phase 3 Verifier and CI Enforcement | AUTHORIZED | Must verify doctrine routing and phase-boundary compliance without defining doctrine. |
| Methodology Runtime | PROHIBITED | Routed to Phase 5. |
| BoZ statutory deductions or settlement finality | PROHIBITED | Routed to Phase 4. |
| ZDPA erasure workflows or VVB portal workflows | PROHIBITED | Routed to Phase 6. |
| MAIN/MADD authorization runtime or Article 6 packs | PROHIBITED | Routed to Phase 8A. |
| External registry bridges or exports | PROHIBITED | Routed to Phase 8B. |
| Tokenization or on-chain export | PROHIBITED | Routed to Phase 8C. |

Phase 3 task plans are legal only when the capability maps to a governing
doctrine and the task states what it may implement and what doctrine it must not
define.

### 3.5 Phase-4 (Continuous Assurance and Evolution Governance)

**Constitutional posture**: CONSTITUTIONALLY RESERVED, NOT OPENED.

Identical entry conditions to Phase-3 with Phase-3 substituted by Phase-4.
No delivery claims referencing Phase-4 capabilities are admissible. The
`deferred_to_phase5` status in PHASE_LIFECYCLE.md Section 9.5 is a reserved
forward-declaration only; Phase-5 is not defined by any current constitutional
document.

---

## 4. Dormant Reservation Legality

### 4.1 Definition

A dormant constitutional reservation is substrate that occupies one of the
following states:

- schema exists (table, constraint, trigger, function) but no active contract
  row references it
- an invariant is declared in `INVARIANTS_MANIFEST.yml` with `status: roadmap`
  and a verifier reference but no CI wiring
- an evidence path is declared in the manifest but the evidence file does not
  yet exist

Dormant constitutional reservations are constitutionally protected. They are
not subject to removal, replacement, or reclassification without a formal
constitutional amendment (new migration, manifest update, and governance
review).

### 4.2 Replay Infrastructure Reservation Legality

Replay infrastructure that is dormant or partially active carries
constitutional reservation against replacement. The following are replay
infrastructure reservations in good legal standing:

**REPLAY-RES-01**: `proof_pack_batches`, `proof_pack_batch_leaves`,
`canonicalization_versions`, `anchor_backfill_jobs`,
`archive_verification_runs` (migrations 0066, 0069). Status: schema present,
backfill execution not confirmed as completed. Legally dormant. Must not be
replaced with a parallel Merkle system.

**REPLAY-RES-02**: `wave8_attestation_nonces` PRIMARY KEY nonce registry
(migration 0183). Status: active. Nonce uniqueness enforced at the DB layer.
Replay anti-replay is constitutionally enforced.

**REPLAY-RES-03**: `execution_records` append-only ledger with
`interpretation_version_id` temporal binding (migrations 0118, 0131–0133).
Status: active. Every execution record is constitutionally replayable.

**REPLAY-RES-04**: `_migration_fn_hashes` advisory table (migration 0095).
Status: populated but advisory (WARNING only). This is a dormant enforcement
capability. The upgrade path from WARNING to EXCEPTION is a constitutional
amendment requiring a new migration. Until that migration is applied, the
table constitutes a dormant reservation of executable drift detection
authority.

### 4.3 Sovereign Expansion Seam Legality

The following tables constitute sovereign expansion seams. They are legally
present in the schema, carry no active contract row, and may not be removed
or replaced in parallel:

| Seam | Migration | Reserved Domain | Replacement Forbidden |
|---|---|---|---|
| `key_rotation_drills` | 0065 | Signing key rotation lifecycle authority | YES |
| `historical_verification_runs` | 0065 | Multi-key-version historical replay authority | YES |
| `resign_sweeps` | 0065 | Key rotation sweep and artifact re-signing authority | YES |
| `signing_audit_log` | 0065 | Signing event audit lineage | YES — no append-only trigger; this is the one signing surface without absolute write protection |
| `_migration_fn_hashes` | 0095 | Executable drift detection authority | YES — currently advisory; upgrade to blocking is a constitutional amendment |
| `public_keys_registry` validity bounds beyond currently active entries | 0165 | Future temporal key windows | YES — temporal exclusion gist constraint |
| `canonicalization_versions` entries beyond v1 | 0066 | Future canonicalization algorithm versions | YES |

---

## 5. Wave-vs-Phase Legality Distinctions

### 5.1 Constitutional Separation

Waves and phases are constitutionally distinct categories with no substitution
relationship. The following distinctions are absolute:

| Dimension | Wave | Phase |
|---|---|---|
| Constitutional unit | Execution batch | Capability boundary |
| Derives from | Canonical linear task order (WAVE_EXECUTION_SEMANTICS.md Section 4A) | Contracted invariant set with verifier and evidence bindings |
| Governs | Task sequencing within a phase | Delivery claims, capability admissibility, regulator evidence |
| Completion semantics | Named execution checkpoint | Formal closeout with verifier pass + evidence + approval artifact |
| Authority | Operational / scheduling | Constitutional |
| Replaces phase? | NEVER | N/A |
| Parallel contract? | NEVER — waves deliver against the parent phase contract | N/A |

### 5.2 Wave Legality Rules

**WL-01**: A wave schedule that partitions Phase-N tasks into named execution
batches is constitutionally legal under WAVE_EXECUTION_SEMANTICS.md, provided
it satisfies the serial derivation rule (Section 4A): the canonical serial order
is derived first, then wave boundaries are assigned as consecutive slices of
that order. A wave schedule derived by thematic grouping is non-canonical and
inadmissible for delivery planning.

**WL-02**: Wave completion is not phase closeout. Phase-N closeout requires:
all required contract rows pass under the phase gate flag
(`RUN_PHASE<N>_GATES=1`), evidence exists and validates under
`evidence/phase<n>/**`, deferred rows are carried forward with approved deferral
records, and a phase closeout approval artifact is created. Wave completion
satisfies none of these conditions independently.

**WL-03**: Wave identifiers (Wave 1 through Wave N, or Wave A through Wave Z)
are not valid lifecycle phase keys. The canonical lifecycle phase key set is
`{0, 1, 2, 3, 4}`. Any task metadata, branch name, commit header, or approval
record using a wave identifier as a phase key constitutes V-VIOLATION-02.

**WL-04**: The current active execution wave at the time this document was
produced is Wave 8 of Phase-2. Wave 8 completion does not constitute Phase-2
closeout. Phase-2 closeout requires satisfaction of all conditions stated in
Section 3.3 of this document.

**WL-05**: Domain-specific gate documents (e.g. `GF_PHASE2_ENTRY_GATE.md`)
constitute domain-specific prerequisites within a phase. They do not constitute
phase-opening approval artifacts. Passage of a domain gate is not equivalent
to phase opening under PHASE_LIFECYCLE.md Section 2B rank 6.

---

## 6. Phase-Aware Admissibility Semantics

### 6.1 Evidence Admissibility by Phase

Evidence is phase-scoped by its namespace and the phase gate under which it
was produced. The following rules govern cross-phase evidence admissibility:

**EA-01 — Phase-0 evidence (`evidence/phase0/**`)**
Admissible in all subsequent phases as `phase0_prerequisite` contract rows.
Evidence path must not be altered without an approved one-shot cutover. Phase-0
evidence is the constitutional replay baseline for all subsequent phases.

**EA-02 — Phase-1 evidence (`evidence/phase1/**`)**
Admissible in Phase-2 as `phase1_prerequisite` contract rows. Phase-1 evidence
from prior phases is admissible under Phase-N contracts provided the verifier
still emits PASS and the evidence remains schema-valid.

**EA-03 — Phase-2 evidence (`evidence/phase2/**`)**
Admissible for Phase-2 delivery claims only after Phase-2 formally opens.
Currently: evidence exists and is schema-valid, but is not delivery-claimable
because Phase-2 has no opening approval artifact.

**EA-04 — Evidence produced during Wave-N execution**
Evidence produced during Wave-N execution is valid as Phase-N evidence
provided: the producing verifier is declared in the phase contract, the
evidence file is schema-valid under `evidence_schema.json`, and the evidence
was produced in a run signed by `sign_evidence.py`. Evidence is not
admissible by wave identity alone.

**EA-05 — Evidence for deferred invariants**
Evidence produced against deferred invariants carries no admissibility
in the current phase. It may carry admissibility in the target phase once
that phase opens and the deferred row is carried forward into the new
phase's contract.

### 6.2 Delivery Claim Admissibility by Phase

A delivery claim referencing Phase-N is admissible only when the six
conditions of PHASE_LIFECYCLE.md Section 2F are satisfied. The conditions
are restated here for constitutional clarity:

1. Phase-N opening approval artifact exists and is merged.
2. Claim scope maps to a named, active Phase-N contract row.
3. Required verifier for that row exists and is executable.
4. Required evidence path for that row exists and is schema-valid.
5. Claim does not rely on roadmap-phase or remediation-phase substitution.
6. Claim uses exactly one of: `planned`, `implemented`,
   `deferred_to_phase<n+1>`, or `blocked` (with explicit blocking condition).

Broader language ("Phase complete", "Phase ready", "Phase done", "Phase
aligned") is inadmissible unless a formal phase closeout approval artifact
exists satisfying phase exit criteria.

---

## Constitutional Self-Validation

### Sovereignty Domains Governed

This document governs:

- the constitutional legality of capability states across lifecycle phases
  Phase-0 through Phase-4;
- the distinction between waves (sequencing subdivisions) and phases
  (capability boundaries);
- the admissibility rules for evidence, delivery claims, and deferral decisions
  across phases;
- the legality of dormant, scaffolded, and deferred substrate;
- the replay infrastructure reservation doctrine as applied to phase-level
  capability management.

### Sovereignty Domains This Document Must Not Redefine

This document must not redefine:

- the internal mechanics of any individual DB trigger or constraint (governed
  by the migration that created it);
- the authority precedence chain between governance documents (governed by
  PHASE_LIFECYCLE.md Section 2B);
- the wave construction algorithm (governed by WAVE_EXECUTION_SEMANTICS.md
  Section 4A);
- the evidence schema (governed by `docs/architecture/evidence_schema.json`);
- the invariant promotion gate mechanics (governed by
  `scripts/audit/enforce_invariant_promotion.sh`);
- the agent conformance specification (governed by
  `docs/operations/AI_AGENT_OPERATION_MANUAL.md` and `AGENTS.md`).

### Replay Obligations Preserved

This document preserves the following replay obligations:

1. Phase-0 evidence is the constitutional replay baseline. No Phase-0 evidence
   may be removed without an approved cutover preserving replay continuity.
2. Phase-1 evidence is replay-eligible under the `interpretation_version_id`
   binding on `execution_records` (INV-179, migrations 0131–0133).
3. Phase-2 evidence produced against `evidence/phase2/**` is replay-eligible
   once Phase-2 formally opens, under the same temporal binding.
4. Dormant replay infrastructure (REPLAY-RES-01 through REPLAY-RES-04) is
   constitutionally protected against removal or parallel replacement.

### Regulator Boundaries

This document acknowledges the following regulator-specific boundaries:

- BoZ observability role (INV-111): Phase-0 prerequisite, carries forward to
  all subsequent phases. Regulator-facing evidence must remain reproducible
  across phase transitions.
- ISO 20022 contract registry (INV-109): Phase-0 prerequisite. Rail message
  type constraints (pacs.008, camt.056 shape rules, INV-114) carry forward
  to all subsequent phases and must not be weakened.
- Regulation 26 separation of duties (INV-169): DB-enforced, Phase-0 scope,
  carries forward. No phase may weaken this constraint.
- ZDPA PII lint (INV-112): Phase-0 prerequisite, CI-enforced across all phases.

Regulators are sovereign observers with orthogonal evidence requirements.
Phase transitions do not alter regulator-facing evidence obligations unless
an explicit new obligation is declared in the phase contract.

### Phases This Document Applies To

This document applies globally to all lifecycle phases Phase-0 through Phase-4
and to the Phase-5 deferred reservation as declared in PHASE_LIFECYCLE.md
Section 9.9.

### Constitutional Layers Possessing Override Authority

The following layers possess override authority over this document, in
descending order of precedence per PHASE_LIFECYCLE.md Section 2B:

1. `docs/operations/PHASE_LIFECYCLE.md` — apex phase authority
2. `docs/PHASE<N>/phase<n>_contract.yml` — canonical machine contract for
   Phase-N
3. `docs/PHASE<N>/PHASE<N>_CONTRACT.md` — human contract narrative; cannot
   weaken machine contract
4. `docs/operations/AGENTIC_SDLC_PHASE<N>_POLICY.md` — operational policy
   guard

### Lower-Layer Documents Prohibited From Reinterpretation

The following lower-layer documents must not reinterpret any legality
classification made in this document:

- `docs/operations/DEV_WORKFLOW.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/GIT_CONVENTIONS.md`
- `.agent/workflows/git-conventions.md`
- Any domain-specific gate document (e.g. `GF_PHASE2_ENTRY_GATE.md`)
- Any wave plan, wave schedule, or wave completion document
- Any roadmap document

---

## Prohibited Misinterpretations

The following interpretations are explicitly prohibited. Each prohibition is
mandatory for NotebookLM stabilization and anti-drift enforcement.

**PROHIB-01 — Unopened Phase Capabilities Are Not Defects**
It is prohibited to interpret the absence of Phase-3 or Phase-4 capabilities,
contracts, verifiers, or directories as defects, gaps, or missing
implementation. These absences are constitutionally required under the current
phase posture.

**PROHIB-02 — Future-Phase Substrate Is Not Dead Schema**
It is prohibited to classify `key_rotation_drills`, `historical_verification_runs`,
`resign_sweeps`, `canonicalization_versions` beyond v1, and proof-pack
backfill tables as dead schema, unused code, or implementation debt. These
tables are sovereign expansion seams constitutionally reserved against
parallel replacement.

**PROHIB-03 — Reserved Infrastructure Is Not Duplication**
It is prohibited to classify Wave 4 signing infrastructure (`signing_authorization_matrix`,
`signing_audit_log`) as redundant with Wave 8 signing infrastructure
(`wave8_signer_resolution`, `public_keys_registry`). Wave 4 is
operational/runtime signing sovereignty. Wave 8 is provenance/cryptographic
sovereignty. They are orthogonal, not duplicate, authority surfaces.

**PROHIB-04 — Wave Completion Is Not Phase Completion**
It is prohibited to equate the completion of Wave N with Phase-N closeout,
phase opening, or phase delivery claims. A wave is a sequencing subdivision.
It carries no constitutional admissibility weight.

**PROHIB-05 — Phase-2 Evidence Existence Is Not Phase-2 Opening**
It is prohibited to interpret the existence of ~90 evidence files under
`evidence/phase2/**` as evidence that Phase-2 is the currently active phase,
or that later-phase routing may be ignored. Evidence artifacts
produced before phase opening are preparatory work; they become
delivery-claimable only after the opening approval artifact is merged.

**PROHIB-06 — Domain Gate Passage Is Not Phase Opening**
It is prohibited to interpret the passage of `GF_PHASE2_ENTRY_GATE.md`
criteria, or any domain-specific gate document, as equivalent to Phase-2
opening. Domain gates are rank-6 instruments under PHASE_LIFECYCLE.md
Section 2B. A canonical `PHASE2-OPENING.md` approval artifact is a rank-5
instrument. Rank-6 instruments cannot substitute for rank-5 instruments.

**PROHIB-07 — Roadmap Invariants Are Not Missing Implementation**
It is prohibited to classify any invariant with `status: roadmap` in
`INVARIANTS_MANIFEST.yml` as a defect, bug, or missed obligation. Roadmap
invariants are constitutional declarations. They are not delivery claims.
INV-039, INV-048, INV-130, INV-131, INV-162, INV-163, INV-164, INV-168,
INV-170 through INV-174 are all in constitutionally legal roadmap states.

**PROHIB-08 — Deferred Invariants Are Not Failed Invariants**
It is prohibited to classify `deferred_to_phase2` rows in
`phase1_contract.yml` (INV-039, INV-048) as failures of Phase-1.
These deferrals satisfy PHASE_LIFECYCLE.md Section 2E conditions and are
constitutionally valid. They carry forward obligations to Phase-2, not
Phase-1 failures.

**PROHIB-09 — Runtime Substrate Is Not Universally Sovereign**
It is prohibited to assert that database runtime enforcement (DB triggers,
SECURITY DEFINER functions) constitutes unconditional platform-wide sovereignty.
Superusers, BYPASSRLS-capable roles, and TRUNCATE operations are constitutionally
exempt from row-level trigger enforcement. Tenant isolation via RLS is scoped
to application roles. Runtime sovereignty is bounded by the deployment
privilege model.

**PROHIB-10 — Executable Function Bodies Are Not Immutable Constitutional Records**
It is prohibited to treat `CREATE OR REPLACE FUNCTION` as equivalent in
immutability to `CREATE TABLE` or `CREATE INDEX`. Migration files are immutable
once applied (Forward-Only Migration Doctrine). Function bodies within those
migrations are mutable via subsequent `CREATE OR REPLACE FUNCTION` calls. The
wave8 oscillation (migrations 0177–0187) is the authoritative proof of this
distinction. Constitutional continuity for executable function bodies is
maintained by the migration chronology, not by schema immutability.

**PROHIB-11 — Phase Admissibility Is Not Transitive From Prior Phases**
It is prohibited to infer that Phase-3 or Phase-4 capabilities are admissible
because Phase-1 or Phase-2 work is complete. Each phase requires its own
opening approval artifact, its own contract pair, its own verifier, and its
own evidence namespace. Phase-N completion grants no admissibility to Phase-N+1
delivery claims.

**PROHIB-12 — INV-ID Rows and TSK-ID Rows Are Not Interchangeable**
It is prohibited to treat task-identifier rows (`TSK-P2-PREAUTH-005-*`) and
invariant-identifier rows (`INV-156` through `INV-179`) as equivalent contract
row schemas. Task-ID rows in Phase-2 or later phase contracts are V-VIOLATION-03
violations and must be remediated before those phases may formally open.
