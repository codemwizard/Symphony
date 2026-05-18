# Phase 3 Uncertainty And Estimation Semantics Contract

Constitutional-Status: IMPLEMENTED
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 3
Phase-Scope: PHASE-3
Surface: P3-SURF-013
Task: TSK-P3-WP-013

## Purpose

This contract makes Phase 3 uncertainty semantics machine-inspectable. It
covers the seven doctrinal uncertainty classes, registered-operator
constraints, admissibility-safe finding classes, and replay-visible authority
transfer requirements.

## Canonical Uncertainty Classes

- `U-EXACT`
- `U-BOUNDED-RANGE`
- `U-CONFIDENCE-INTERVAL`
- `U-DECLARED-DISTRIBUTION`
- `U-DATA-QUALITY-INDICATOR`
- `U-METHODOLOGICAL-ASSUMPTION`
- `U-UNKNOWN-UNCERTAINTY`

`U-UNKNOWN-UNCERTAINTY` is never equivalent to `U-EXACT`.
U-UNKNOWN-UNCERTAINTY is never equivalent to `U-EXACT`.

## Admissibility-Safe Finding Classes

- `ADMISSIBLE`
- `INADMISSIBLE`
- `FLAGGED`
- `UNKNOWN_UNCERTAINTY`
- `DRAFT_PENDING_RESOLUTION`

## Registered-Operator Constraint

Only operators declared in `UNCERTAINTY_OPERATOR_REGISTRY.md` may be used:

- `OP-001`
- `OP-002`
- `OP-003`
- `OP-004`
- `OP-005`
- `OP-006`
- `OP-007`
- `OP-008`
- `OP-009`
- `OP-010`
- `OP-011`

Methodology-specific computation or propagation execution remains deferred to
Phase 5. This Phase 3 contract defines the schema and constraint set only.

## Replay-Visible Authority Transfer Requirements

Every uncertainty finding that hands off to another surface must declare a
transfer mode. The canonical transfer-mode set is:

- `AT-EXCLUSIVE`
- `AT-SHARED`
- `AT-DELEGATED`
- `AT-ADVISORY`

## Phase 3 Integration Points

| Consuming Surface | Question Class | Transfer Mode |
|---|---|---|
| `P3-SURF-003` | `uncertainty_admissibility` | `AT-EXCLUSIVE` |
| `P3-SURF-004` | `uncertainty_admissibility` | `AT-SHARED` |
| `P3-SURF-005` | `uncertainty_failure_classification` | `AT-ADVISORY` |
| `P3-SURF-007` | `regulator_uncertainty_admissibility` | `AT-SHARED` |
| `P3-SURF-009` | `spatial_uncertainty_resolution` | `AT-DELEGATED` |
| `P3-SURF-010` | `temporal_threshold_straddling` | `AT-EXCLUSIVE` |

## Deferred And Excluded Scope

- No methodology-specific statistical execution.
- No industrial ontology or embedded-emissions formula execution.
- No supply-chain graph execution.
- No user-facing uncertainty display or dashboards.
- No CBAM runtime packaging or disclosure behavior.
