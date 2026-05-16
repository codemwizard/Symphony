# PHASE3_CI_TIER_MODEL.md

Status: OPENED-PHASE GOVERNANCE
Phase: 3
Authority: `docs/operations/PHASE_EXECUTION_ENVELOPE.md`

## Purpose

This document defines the CI tier model for Phase 3 task creation and
implementation. The goal is to make every Phase 3 task declare how quickly it
must fail, what constitutional scope it exercises, and what escalation path
applies when it breaks.

The tier model is a governance contract for:

- task-pack authors
- verifier authors
- `scripts/dev/pre_ci.sh`
- the Phase 3 task registry

It does not replace task-specific verifiers. It classifies them.

## Tier Summary

| Tier | Trigger | Target Runtime | Typical Scope | Failure Posture |
|---|---|---:|---|---|
| `T0` | bootstrap, runtime prerequisite, extension or executable availability | <= 15s | single binary, extension, or minimal environment contract | fail closed immediately; block all downstream Phase 3 work |
| `T1` | planning, governance, nomenclature, schema, or registry integrity | <= 60s | docs plus deterministic verifier | fail closed for task creation and governance workflows |
| `T2` | single-surface implementation verifiers | <= 5m | one execution surface plus local fixtures | block downstream nodes that depend on the surface |
| `T3` | cross-surface integration or replay-path validation | <= 15m | multiple surfaces, migration/backfill, or composed proofs | quarantine the affected branch path until repaired |
| `T4` | full parity or release-grade constitutional proof | best effort, may exceed 15m | full `pre_ci`, broad replay suites, or release gating | stop push/merge readiness and require remediation trace |

## Invariant Coverage By Tier

| Tier | Phase 3 invariants checked by default |
|---|---|
| `T0` | `INV-301`, `INV-309`, `INV-310` |
| `T1` | `INV-301`, `INV-302`, `INV-303`, `INV-309`, `INV-310` |
| `T2` | `INV-302`, `INV-303`, `INV-304`, `INV-305`, `INV-306`, `INV-307`, `INV-308`, `INV-309` |
| `T3` | `INV-302` through `INV-310` |
| `T4` | all `INV-301` through `INV-310` plus any inherited parity gates |

## Tier Definitions

### `T0` Bootstrap Gate

Trigger conditions:

- database extension availability
- runtime cryptographic primitive presence
- environment contract required before any Phase 3 task can execute

Contents:

- one deterministic verifier
- one evidence artifact
- zero optional dependencies

Escalation policy:

- any `T0` failure blocks all Phase 3 execution immediately
- retry only after the root cause is fixed
- no downstream task may claim completion while a required `T0` gate fails

### `T1` Governance Gate

Trigger conditions:

- nomenclature rules
- registry schema
- planning/doc integrity
- task-pack creation/validation scaffold

Contents:

- deterministic doc or schema checks
- registry shape checks
- validator behavior checks

Escalation policy:

- fail the task-creation path
- block generation of new Phase 3 packs until repaired
- remediation stays local to governance/task-authoring surfaces

### `T2` Surface Implementation Gate

Trigger conditions:

- one execution surface is being implemented
- one verifier proves local enforcement with negative tests

Contents:

- task-specific implementation verifier
- evidence validation
- local fixture checks

Escalation policy:

- block dependent nodes in the DAG
- do not escalate to branch-wide halt unless the broken surface is shared

### `T3` Cross-Surface Integration Gate

Trigger conditions:

- legitimacy traversal spans multiple surfaces
- contradiction, authority, or failure composition requires composed state

Contents:

- multi-step replay or composition verifiers
- persistence plus projection cross-checks
- stronger negative-test coverage

Escalation policy:

- quarantine the branch path for affected surfaces
- open remediation trace if two repair attempts fail

### `T4` Full Readiness Gate

Trigger conditions:

- branch push readiness
- release-grade parity
- full opened-phase readiness or closeout candidate work

Contents:

- `scripts/dev/pre_ci.sh`
- task-pack readiness
- evidence validation
- agent conformance

Escalation policy:

- stop push/merge readiness
- require remediation trace before further completion claims

## Tier Assignment Rules

Phase 3 tasks assign `ci_tier` by task family and work type:

| Task family / type | Default tier |
|---|---|
| `PRE-001` style bootstrap/environment checks | `T0` |
| `ACT`, `CLEAN`, `GOV`, registry, nomenclature, schema, validator, generator scaffold | `T1` |
| runtime `WP`, `W1`, `W8`, `SUPPORT` implementation tasks with one owned surface | `T2` |
| cross-surface implementation or replay composition tasks | `T3` |
| branch-wide readiness gates and full parity | `T4` |

Wave influence:

- early scaffold waves (`ACT`, `PRE`, `CLEAN`, `GOV`) bias to `T0` or `T1`
- runtime waves (`W1` to `W10`, `WP`, `SUPPORT`) start at `T2`
- any task that runs full parity or composes multiple execution surfaces is
  promoted to `T3` or `T4`

## Escalation Matrix

| Failure tier | Immediate action | Downstream effect |
|---|---|---|
| `T0` | stop all Phase 3 work | global block |
| `T1` | stop task creation and governance edits | no new task packs until repaired |
| `T2` | block dependent DAG nodes | local block |
| `T3` | quarantine branch path and open remediation if needed | multi-surface block |
| `T4` | stop push-ready or release claims | branch-wide readiness block |

## Usage Rules

- every new Phase 3 task pack must declare a `wave`
- every new Phase 3 task pack must declare a `ci_tier` in the task registry
- verifier authors should prefer the lowest tier that honestly captures the
  blast radius
- raising a task from `T1` to `T3` is allowed; silently lowering it is not

