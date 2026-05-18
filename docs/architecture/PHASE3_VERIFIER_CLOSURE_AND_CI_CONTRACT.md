# Phase 3 Verifier Closure And CI Contract

Constitutional-Status: IMPLEMENTED
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 3
Phase-Scope: PHASE-3
Surface: P3-SURF-011
Task: TSK-P3-WP-011

## Purpose

This contract closes Phase 3 verifier ownership. It defines exhaustive
invariant disposition, blocking CI semantics, evidence expectations,
negative-test obligations, and capability-boundary contamination checks.

## CI Posture

- CI is blocking, not advisory-only.
- Evidence emission must follow legal execution of the verifier.
- Negative tests are mandatory where declared by the task pack.
- Contamination checks must fail if verifier or CI surfaces back-introduce
  forbidden future-phase semantics.
- This contract does not own runtime/verifier segregation implementation.

## Invariant Disposition Model

Every enforceable Phase 3 invariant must be mapped to one of:

- `verifier-covered`
- `constitutionally exempted`
- `formally deferred with justification`

No enforceable invariant may remain silently unmapped.

## Exhaustive Invariant-To-Verifier Disposition

| Invariant | Disposition | Primary Verifier |
|---|---|---|
| INV-301 | verifier-covered | `scripts/db/verify_p3_typed_dependency_graph.sh` |
| INV-302 | verifier-covered | `scripts/db/verify_p3_policy_authority_lineage.sh` |
| INV-303 | verifier-covered | `scripts/db/verify_p3_recursive_legitimacy_engine.sh` |
| INV-304 | verifier-covered | `scripts/db/verify_p3_contradiction_detection.sh` |
| INV-305 | verifier-covered | `scripts/audit/verify_p3_failure_composition_engine.sh` |
| INV-306 | verifier-covered | `scripts/db/verify_p3_authority_scope_engine.sh` |
| INV-307 | verifier-covered | `scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh` |
| INV-308 | verifier-covered | `scripts/db/verify_p3_conflict_of_interest_enforcement.sh` |
| INV-309 | verifier-covered | `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` |
| INV-310 | verifier-covered | `scripts/audit/verify_p3_dwell_time_forensic_enforcement.sh` |
| INV-311 | verifier-covered | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| INV-312 | verifier-covered | `scripts/audit/verify_p3_uncertainty_semantics.sh` |
| INV-313 | verifier-covered | `scripts/audit/verify_tsk_p3_gov_005_ai_governance.sh` |

## Capability-Boundary Contamination Checks

- No doctrine creation by verifier or CI configuration.
- No runtime/verifier trust-boundary implementation inside CI closure.
- No user-facing workflow UX or operator console semantics.
- No reinterpretation of lineage, projection, contradiction, failure,
  authority, regulator, COI, spatial, temporal, uncertainty, or AI governance
  semantics.

## Promotion Discipline

Invariant promotion remains evidence-backed rather than prose-backed. A claimed
closure state is valid only when the mapped verifiers exist, are blocking, and
emit admissible evidence.
