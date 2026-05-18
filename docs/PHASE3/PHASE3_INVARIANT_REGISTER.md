# PHASE3_INVARIANT_REGISTER.md

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ENFORCEMENT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 8
Phase-Scope: PHASE-3
Supersedes: PHASE3_INVARIANT_REGISTER.md (initial draft — missing verifier paths, defective INV-305 scope)
Depends-On:
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/invariants/INVARIANTS_MANIFEST.yml
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md

Effective-Date: 2026-05-10

---

## Purpose

Registers constitutional invariants introduced in Phase 3 — the Constraint and
Legitimacy Engine phase. All invariants are scoped to the Phase 3 capability
boundary defined in PHASE3_CAPABILITY_BOUNDARY.md.

Invariants INV-301 through INV-313 are filed at `status: roadmap`. They are
constitutional promises, not yet enforcement obligations. Each will be promoted
to `status: implemented` when its verifier script exists, passes against the
codebase, and is wired into CI with evidence emission. This distinction is
mandatory and must not be collapsed.

---

## Supersession Notice — INV-305

The initial INV-305 filing was titled "MADD-MAIN Evidence Continuity" and was
constitutionally defective for two reasons:

1. It introduced "MADD" and "MAIN" as if they were undefined concepts, when in
   fact they are fully constitutionally defined in
   docs/constitutional/MADD_MAIN_INTEGRATION_DOCTRINE.md (Authority-Rank 8, ROOT).

2. MADD/MAIN integration is Phase 8A scope (Sovereign Authorization Layer), not
   Phase 3 scope (Constraint and Legitimacy Engine). A Phase 3 invariant enforcing
   MADD/MAIN continuity would constitute a phase-illegal scope crossing per
   TASK_GENERATION_CONSTITUTION.md §2.5 PHL-D3.

INV-305 is hereby re-scoped to "Cross-System Evidence Exchange Continuity" — the
legitimate Phase 3 concern of ensuring that evidence records traversing internal
system boundaries preserve their provenance lineage and remain replay-survivable.
MADD/MAIN-specific integration invariants will be filed under Phase 8A when that
phase is constitutionally opened.

---

## Assigned Invariants

### INV-301 — Regulatory Sovereignty Partitioning

| Field | Value |
|---|---|
| Constitutional Requirement | Legitimacy engine enforces regulator-specific rule sets independently; no cross-regime equivalence is asserted |
| Phase Spec Reference | §3.6 Regulator Override Rules; §3.3 Contradiction Detection |
| Governing Doctrine | [docs/constitutional/REGULATORY_ALIGNMENT_CONSTITUTION.md](docs/constitutional/REGULATORY_ALIGNMENT_CONSTITUTION.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-platform, team-invariants |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh` |
| Evidence Path | `evidence/phase3/inv_301_regulatory_sovereignty_partitioning.json` |
| Negative Test | Attempt to apply regulator-A rule to a regulator-B decision context; must reject with SQLSTATE P3001 |
| Proof Limitations | Does not verify substantive correctness of any individual regulator's rule set — only that the engine applies them independently |

---

### INV-302 — Typed Dependency Graph Completeness

| Field | Value |
|---|---|
| Constitutional Requirement | Every decision record declares its typed upstream dependencies; the dependency graph is machine-traversable |
| Phase Spec Reference | §3.1 Typed Dependency Graph |
| Governing Doctrine | [docs/constitutional/CONSTITUTIONAL_GRAPH.md](docs/constitutional/CONSTITUTIONAL_GRAPH.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_typed_dependency_graph.sh` |
| Evidence Path | `evidence/phase3/tsk_p3_wp_001_typed_dependency_graph.json` |
| Negative Test | Insert a decision record without dependency declarations; must fail NOT NULL / FK constraint |
| Proof Limitations | Does not verify semantic correctness of dependency relationships — only structural completeness |

---

### INV-303 — Recursive Legitimacy Chain Enforced

| Field | Value |
|---|---|
| Constitutional Requirement | Any decision with an illegitimate ancestor is blocked; legitimacy is evaluated recursively upward |
| Phase Spec Reference | §3.2 Recursive Legitimacy Engine |
| Governing Doctrine | [docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md](docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_recursive_legitimacy_engine.sh` |
| Evidence Path | `evidence/phase3/inv_303_recursive_legitimacy_engine.json` |
| Negative Test | Insert decision chain where ancestor is marked illegitimate; descendant decision must be blocked with SQLSTATE P3002 |
| Proof Limitations | Legitimacy evaluation is against declared rule sets; does not independently verify the substantive validity of the rules themselves |

---

### INV-304 — Contradiction Detection Active

| Field | Value |
|---|---|
| Constitutional Requirement | Direct, temporal, and authority-based contradictions are mechanically blocked; contradiction records are append-only |
| Phase Spec Reference | §3.3 Contradiction Detection |
| Governing Doctrine | [docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md](docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_contradiction_detection.sh` |
| Evidence Path | `evidence/phase3/inv_304_contradiction_detection.json` |
| Negative Test (direct) | Insert two decisions asserting incompatible facts on the same resource; second must be blocked with SQLSTATE P3003 |
| Negative Test (temporal) | Insert decision conflicting with prior temporal window; must be blocked with SQLSTATE P3004 |
| Negative Test (authority) | Insert decision outside authority scope; must be blocked with SQLSTATE P3005 |
| Proof Limitations | Contradiction detection operates over declared fact schemas; does not detect semantic contradictions not expressible in the declared schema |

---

### INV-305 — Cross-System Evidence Exchange Continuity

| Field | Value |
|---|---|
| Constitutional Requirement | Evidence records traversing internal system boundaries preserve complete provenance lineage and remain replay-survivable |
| Phase Spec Reference | §3.4 Failure Composition Engine; §3.2 Recursive Legitimacy Engine (evidence ancestor tracing) |
| Governing Doctrine | [docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md](docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-platform, team-db |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_cross_system_evidence_continuity.sh` |
| Evidence Path | `evidence/phase3/inv_305_cross_system_evidence_continuity.json` |
| Negative Test | Introduce an evidence record with a broken provenance chain at an internal boundary; legitimacy engine must reject downstream decisions citing it |
| Proof Limitations | Does not enforce MADD/MAIN external integration (Phase 8A scope). Does not verify external system availability. Verifies internal boundary continuity only. |
| Supersedes | Initial INV-305 "MADD-MAIN Evidence Continuity" — defective scope, phase-illegal, re-scoped by human custodian decree 2026-05-10 |

---

### INV-306 — Failure Composition Machine-Readable

| Field | Value |
|---|---|
| Constitutional Requirement | All rejections produce structured, traversable failure records; failure records are append-only constitutional evidence |
| Phase Spec Reference | §3.4 Failure Composition Engine |
| Governing Doctrine | [docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md](docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md) |
| Status | roadmap |
| Severity | P1 |
| Owners | team-platform |
| SLA Days | 30 |
| Verifier | `scripts/audit/verify_p3_failure_composition_engine.sh` |
| Evidence Path | `evidence/phase3/inv_306_failure_composition_engine.json` |
| Negative Test | Trigger a legitimacy rejection; verify failure record exists, is append-only, and is machine-parseable |
| Proof Limitations | Does not verify human interpretability of failure records — only machine-parseable structure and append-only enforcement |

---

### INV-307 — Authority Scope Engine Enforced

| Field | Value |
|---|---|
| Constitutional Requirement | Every authority claim is scoped to its declared resource; delegation is traceable through the dependency graph |
| Phase Spec Reference | §3.5 Authority Scope Engine |
| Governing Doctrine | [docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md](docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-security |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_authority_scope_engine.sh` |
| Evidence Path | `evidence/phase3/inv_307_authority_scope_engine.json` |
| Negative Test | Attempt resource access with out-of-scope authority claim; must reject with SQLSTATE P3006 |
| Proof Limitations | Authority scope is verified against declared resource bindings; does not independently validate the appropriateness of the declared bindings |

---

### INV-308 — Conflict-of-Interest DB-Layer Enforced

| Field | Value |
|---|---|
| Constitutional Requirement | Submitters cannot be verifiers for the same decision or asset; enforcement is at DB layer, not application layer only |
| Phase Spec Reference | §3.7 Conflict-of-Interest Enforcement; extends INV-169 (Reg 26 separation of duties) to all decision types |
| Governing Doctrine | [docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md](docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-security |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_conflict_of_interest_enforcement.sh` |
| Evidence Path | `evidence/phase3/inv_308_conflict_of_interest_enforcement.json` |
| Negative Test | Attempt verification by the same actor who submitted the decision; must reject with SQLSTATE GF001 (extends check_reg26_separation pattern) |
| Proof Limitations | Enforcement is against declared role assignments; does not detect undeclared role conflicts outside the recorded role binding |

---

### INV-309 — Spatial Legality and DNSH Gates Generalised

| Field | Value |
|---|---|
| Constitutional Requirement | Spatial legality and DNSH enforcement apply to all decision types, not only project registration; extends INV-178 to platform-wide gate |
| Phase Spec Reference | §3.8 Spatial Legality and DNSH Gates; extends INV-178 (project DNSH spatial check) |
| Governing Doctrine | [docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md](docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform, team-security |
| SLA Days | 14 |
| Verifier | `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` |
| Evidence Path | `evidence/phase3/inv_309_spatial_legality_dnsh_gates.json` |
| Negative Test | Attempt to register a decision for a resource in a protected spatial zone; must reject with SQLSTATE GF057 (extends existing DNSH enforcement) |
| Proof Limitations | Spatial checks depend on PostGIS extension availability and versioned protected-area dataset currency; dataset staleness is a declared proof limitation |

---

### INV-310 — Dwell-Time Forensic Enforcement (CF-2 Resolution)

| Field | Value |
|---|---|
| Constitutional Requirement | Temporal anomalies in decision timelines are mechanically detected and enforced; decisions that have dwelled in intermediate states beyond authorized periods are blocked or flagged |
| Phase Spec Reference | §3.2 Recursive Legitimacy Engine (temporal legitimacy); §3.3 Contradiction Detection (temporal contradiction class); CF-2 from PHASE2_CLOSEOUT_CARRY_FORWARD_OBLIGATIONS.md |
| Governing Doctrine | [docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md](docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md) |
| Status | roadmap |
| Severity | P1 |
| Owners | team-security, team-platform |
| SLA Days | 30 |
| Verifier | `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` |
| Evidence Path | `evidence/phase3/inv_310_dwell_time_forensic_enforcement.json` |
| Negative Test | Insert a decision with a dwell period exceeding the authorized window; must trigger forensic flag or rejection per declared policy |
| Proof Limitations | Dwell-time policy thresholds are configurable; enforcement depends on correct threshold declaration. Does not retroactively enforce dwell-time on pre-Phase-3 records. |
| CF Resolution | This invariant constitutes the Phase 3 entry condition for CF-2 (Dwell-Time Forensic Enforcement). CF-2 is resolved when this invariant is promoted to `status: implemented`. |

---

### INV-311 — Uncertainty Class Completeness And Non-Default

| Field | Value |
|---|---|
| Constitutional Requirement | Every evidence artifact carrying a measured, estimated, or inferred value declares an explicit uncertainty class; missing declarations produce `U-UNKNOWN-UNCERTAINTY` and are held in draft; `U-UNKNOWN-UNCERTAINTY` is never treated as equivalent to `U-EXACT` |
| Phase Spec Reference | §3.9 Uncertainty And Estimation Semantics; `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | [docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md](docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md) |
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
| Phase Spec Reference | §3.9 Uncertainty And Estimation Semantics; `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §2 |
| Governing Doctrine | [docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md](docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| Evidence Path | `evidence/phase3/inv_312_authority_transfer_record_completeness.json` |
| Negative Test (missing transfer record) | Trigger an uncertainty finding that routes to `P3-SURF-003`; verify an `authority_transfer_records` entry is produced with mode `AT-EXCLUSIVE` before the legitimacy surface acts |
| Negative Test (undeclared mode) | Attempt to insert an `authority_transfer_records` entry with a mode value not in the four declared modes; must fail with SQLSTATE P3012 |
| Proof Limitations | Verifies structural completeness of transfer records and mode validity; does not independently verify that the correct mode was selected for the question class — that requires a human constitutional review |

---

### INV-313 — AI Output Admissibility Gate

| Field | Value |
|---|---|
| Constitutional Requirement | Any AI-generated evidence proposal must cite a registered model/version, a replay-addressable inference log record, and a valid confidence-to-uncertainty mapping before it may be admitted above `DRAFT_ONLY`; unregistered, unlogged, or unmapped AI outputs are constitutionally inadmissible |
| Phase Spec Reference | §3.10 AI Governance and Model Provenance; `AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md` §2, §4, §5, §8 |
| Governing Doctrine | [docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md](docs/constitutional/AI_ASSISTED_ESTIMATION_AND_DECISION_SUPPORT_DOCTRINE.md) |
| Status | roadmap |
| Severity | P0 |
| Owners | team-db, team-platform |
| SLA Days | 14 |
| Verifier | `scripts/audit/verify_p3_ai_output_admissibility.sh` |
| Evidence Path | `evidence/phase3/inv_313_ai_output_admissibility_gate.json` |
| Negative Test (unregistered model) | Attempt to admit an AI output whose `model_id` / `model_version` is not present in the Model Registry; admission must fail with a Phase 3 AI admissibility error |
| Negative Test (missing inference log) | Attempt to admit an AI output without a corresponding inference log record and confidence-to-uncertainty mapping; it must remain inadmissible and fail constitutional gating |
| Proof Limitations | Verifies provenance, mapping, and admissibility gating only. It does not verify substantive correctness of model output or downstream Phase 5 execution behavior |

---

## Allocation Range Reservation

The identifier range INV-314 through INV-399 is reserved for additional Phase 3
invariants. No identifiers in this range may be claimed by Phase 4 or later phases.

---

## Verifier Path Promotion Protocol

Every invariant above is filed at `status: roadmap`. Promotion to `status: implemented`
requires ALL of the following per docs/governance/invariant-register-v1.md:

1. Verifier script exists at the declared path and returns non-zero on violation.
2. Verifier runs in a blocking CI job (not advisory-only).
3. Evidence schema and artifact path are deterministic and produced on every run.
4. Negative test(s) pass, proving the enforcement surface rejects what it must reject.
5. The invariant entry in docs/invariants/INVARIANTS_MANIFEST.yml is updated to
   `status: implemented` with the verifier path confirmed.

Promotion is a human-authorized constitutional act. No agent may self-promote an
invariant from roadmap to implemented without evidence artifact production and
CI-gate wiring confirmation.
