# TASK_ID_NOMENCLATURE.md

Status: Canonical for Phase 3 task creation
Authority: `docs/operations/PHASE_EXECUTION_ENVELOPE.md`

## Purpose

This document defines the machine-checkable task ID rules used by the Phase 3
generator, validator, registry, and readiness gates.

## Canonical Shape

Base format:

```text
TSK-P<phase>-<group>(-<subgroup>)*-<sequence>
```

Rules:

- `TSK` is the literal task prefix.
- `P<phase>` is the lifecycle phase key.
- `<group>` is the primary task family.
- `<subgroup>` is optional and may repeat for domain or surface specialization.
- `<sequence>` is exactly three digits.

Phase 3 canonical regex:

```regex
^TSK-P3-(ACT|PRE|CLEAN|GOV|WP|SUPPORT|CI|W(?:10|[1-9]))(?:-[A-Z0-9]+)*-\d{3}$
```

Interpretation:

- `ACT`, `PRE`, `CLEAN`, `GOV`, `WP`, `SUPPORT`, and `CI` are named Phase 3
  governance/runtime families.
- `W1` through `W10` are wave families that may carry additional subgroups such
  as `DB`, `ARCH`, or `SEAL`.

## Approved Phase 3 Group Registry

| Group | Meaning | Example |
|---|---|---|
| `ACT` | phase activation and opening alignment | `TSK-P3-ACT-003` |
| `PRE` | foundational pre-runtime scaffold | `TSK-P3-PRE-005` |
| `CLEAN` | cleanup and truth-repair | `TSK-P3-CLEAN-007` |
| `GOV` | governance compiler or registry work | `TSK-P3-GOV-002` |
| `WP` | canonical runtime work-package node | `TSK-P3-WP-001` |
| `SUPPORT` | runtime support domain | `TSK-P3-SUPPORT-DB-001` |
| `CI` | CI-only or verifier-only task family | `TSK-P3-CI-001` |
| `W1`..`W10` | legacy or explicitly wave-scoped runtime family | `TSK-P3-W1-DB-007` |

Wave field mapping:

- `ACT` task IDs map to `wave: ACT`
- `PRE` task IDs map to `wave: PRE`
- `CLEAN` task IDs map to `wave: CLEAN`
- `GOV` task IDs map to `wave: GOV`
- `WP` task IDs map to `wave: WP`
- `SUPPORT` task IDs map to `wave: SUPPORT`
- `W1`..`W10` map directly to the same `wave` value
- `CI` maps to `wave: CI`

## Legacy Inventory With Usage Counts

The repo contains older task families that remain historically valid for their
own phases but are not automatically admissible for new Phase 3 task creation.

| Legacy family | Observed usage count |
|---|---:|
| `TSK-P0` | 143 |
| `TSK-P1` | 128 |
| `TSK-HARD` | 57 |
| `DEMO` | 31 |
| `R` | 27 |
| `GF-W1-UI` | 24 |
| `GOV-CONV` | 20 |
| `PREAUTH-007` | 20 |
| `TASK-GOV` | 19 |
| `INT` | 13 |
| `W5-FIX` | 13 |
| `TASK-UI-WIRE` | 12 |
| `W8-DB` | 11 |
| `HIER` | 11 |
| `PREAUTH-005` | 10 |
| `PLT` | 10 |
| `RLS-BYPASS` | 9 |
| `PERF` | 7 |
| `TASK-INVPROC` | 6 |
| `INF` | 6 |

Legacy note:

- these families are documented for inventory and migration awareness only
- they do not become valid Phase 3 groups unless explicitly added to the Phase
  3 group registry above
- inventory anchors: TSK-P0 | 143, TSK-P1 | 128, TASK-GOV | 19

## Validation Rules

- Phase 3 task IDs must match the Phase 3 canonical regex.
- Phase 3 task IDs must derive a valid `wave` from the approved registry.
- Legacy families from Phases 0-2 are rejected for new Phase 3 task packs.
- A Phase 3 task may use subgroup tokens after the primary family, but the
  primary family must still be approved.

## Examples

Valid:

- `TSK-P3-PRE-003`
- `TSK-P3-WP-001`
- `TSK-P3-SUPPORT-DB-001`
- `TSK-P3-W8-ARCH-001`

Invalid for Phase 3:

- `TSK-P3-PREAUTH-001`
- `TSK-P3-TASK-GOV-001`
- `TSK-P3-XYZ-001`
