# Architectural Invariant Adoption Plan (Agent-Ready)

Status: proposed
Owner: Supervisor + Invariants Curator
Scope: adopt useful master architectural invariants into Symphony canonical invariant system

## Purpose
This document maps high-value architectural invariants into Symphony's enforceable model (`docs/invariants/INVARIANTS_MANIFEST.yml`, verifiers, evidence). It is written for direct agent execution.

## Canonical Rule
No invariant is considered adopted until all are true:
1. Manifest row exists with final ID, owner, verification command.
2. Verifier exists and returns non-zero on violation.
3. Evidence artifact is emitted and schema-valid.
4. Invariant appears in `INVARIANTS_QUICK.md` and `INVARIANTS_IMPLEMENTED.md` (or `ROADMAP` if deferred).

## Mapping: Useful Invariants Not Yet Enforced in Symphony

| Proposed ID | Source Invariant | Current Symphony Status | Target Phase | Enforcement Seam | Required Verifier | Required Evidence |
|---|---|---|---|---|---|---|
| INV-135 | INV-FLOW-02 No backward calls | Missing explicit runtime block invariant | P1 | Runtime + CI | `scripts/audit/verify_no_backward_calls.sh` | `evidence/phase1/no_backward_calls.json` |
| INV-136 | INV-FLOW-04 Atomic OU ownership | Missing explicit ownership registry invariant | P1 | DB + docs + CI | `scripts/db/verify_ou_ownership_registry.sh` | `evidence/phase1/ou_ownership_registry.json` |
| INV-137 | INV-FLOW-05 Plane isolation (control plane cannot write data plane) | Partially implied, not explicit mechanical gate | P1 | DB privileges + CI | `scripts/db/verify_plane_isolation.sh` | `evidence/phase1/plane_isolation.json` |
| INV-138 | INV-FIN-01 Continuous zero-sum proof | Missing | P2 | DB verifier job | `scripts/db/verify_ledger_zero_sum.sh` | `evidence/phase2/ledger_zero_sum_continuity.json` |
| INV-139 | INV-FIN-04 Distinct debit/credit counterparty | Missing | P2 | DB constraints + tests | `scripts/db/verify_distinct_counterparty.sh` | `evidence/phase2/distinct_counterparty.json` |
| INV-140 | INV-FIN-05 Posting idempotency (ledger-level) | Missing explicit posting-level invariant | P2 | DB unique constraints + posting API | `scripts/db/verify_posting_idempotency.sh` | `evidence/phase2/posting_idempotency.json` |
| INV-141 | INV-FIN-06 Currency explicitness + FX linking | Missing | P2 | DB constraints + posting API | `scripts/db/verify_currency_explicitness.sh` | `evidence/phase2/currency_explicitness_fx_link.json` |
| INV-142 | INV-SEC-01 Identity provenance immutability | Partially present, not explicit immutable-context invariant | P1 | Runtime middleware + tests | `scripts/audit/verify_identity_provenance_immutability.sh` | `evidence/phase1/identity_provenance_immutability.json` |
| INV-143 | INV-OPS-02 Audit precedence before external side-effects | Missing explicit global gate | P1 | Runtime + integration tests | `scripts/audit/verify_audit_precedence.sh` | `evidence/phase1/audit_precedence.json` |
| INV-144 | INV-PCI-01 Card data non-presence | Not explicitly enforced | P1 | SAST/lint + schema lint | `scripts/security/verify_card_data_non_presence.sh` | `evidence/phase1/card_data_non_presence.json` |
| INV-145 | INV-PERSIST-01 Persistence reality (no mock/in-memory beyond allowed stage) | Conflicts with current Phase-1 flexibility | P3 | Contract gate + runtime flags | `scripts/audit/verify_persistence_reality.sh` | `evidence/phase3/persistence_reality.json` |

## Phase Policy
1. Implement now in Phase-1: INV-135, INV-136, INV-137, INV-142, INV-143, INV-144.
2. Schedule for Phase-2 (ledger accounting domain): INV-138, INV-139, INV-140, INV-141.
3. Keep deferred for Phase-3 due current workflow constraints: INV-145.

## Agent Execution Procedure (Deterministic)
1. Create task pack(s) for each target invariant under `tasks/` with canonical `meta.yml` template.
2. Add invariant rows to `docs/invariants/INVARIANTS_MANIFEST.yml` with status `planned`.
3. Implement verifier script at the path specified in the table.
4. Add evidence schema under `evidence/schemas/phase1/` or `phase2/` as mapped.
5. Wire verifier into relevant gate runner (`scripts/audit/run_invariants_fast_checks.sh` or `scripts/db/verify_invariants.sh`).
6. Run `scripts/dev/pre_ci.sh` and capture outputs.
7. Generate evidence JSON with required fields: `check_id`, `timestamp_utc`, `git_sha`, `schema_fingerprint`, `status`, `details`.
8. Validate evidence with `scripts/audit/validate_evidence_schema.sh`.
9. Move invariant row to `implemented` only after verifier and evidence both pass.

## Required Contract Changes
1. Add new gate IDs for each adopted invariant in `docs/control_planes/CONTROL_PLANES.yml`.
2. Add verifier-evidence mapping entries to `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`.
3. If Phase-1 scoped, add required rows to `docs/PHASE1/phase1_contract.yml`.

## Non-Negotiables
1. Do not mark an invariant implemented from documentation alone.
2. Do not accept warning-only verifiers for regulated-surface invariants.
3. Do not reuse evidence paths across different invariants.
4. Do not add runtime DDL or mutate applied migrations.

## Immediate Backlog Creation (Ready-to-Create Task IDs)
1. `TSK-P1-INV-135-no-backward-calls-runtime`
2. `TSK-P1-INV-136-ou-ownership-registry`
3. `TSK-P1-INV-137-plane-isolation-enforcement`
4. `TSK-P1-INV-142-identity-provenance-immutability`
5. `TSK-P1-INV-143-audit-precedence`
6. `TSK-P1-INV-144-card-data-non-presence`

## Definition of Done Per Invariant
1. Verifier fails on negative fixture and passes on positive fixture.
2. Evidence artifact exists, schema-valid, and linked in registry.
3. Manifest row status is `implemented` with canonical verifier command.
4. `scripts/dev/pre_ci.sh` passes with new gate wired.
