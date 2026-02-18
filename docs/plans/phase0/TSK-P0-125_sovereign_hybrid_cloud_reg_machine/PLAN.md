# Implementation Plan (TSK-P0-125)

source_doc: archive/Soverign-Hybrid-Cloud.md
refinement_doc: Soverign-Hybrid-Cloud_Refinement-Draft.md
scope: "Phase-0: mechanical gates, evidence, parity. No runtime adapters. No production traffic."

## Intent (what this plan is and is not)
This plan is the Phase-0 translation of the Sovereign Hybrid Cloud workstream into Symphony's mechanical enforcement model.
It is intentionally written so implementers can land changes without:
- invariant ID collisions
- control-plane drift
- contract evidence "missing evidence" failures (SKIPPED enforcement traps)

Out of scope for this Phase-0 plan:
- runtime rail adapters and ISO 20022 reversal workflows
- jurisdiction-coupled "payment finality" enforcement (Phase-1 activation, already modeled as roadmap invariants)

## Tightening Rules (to prevent drift and scope creep)
### A. Gate naming / plane mapping consistency
This plan treats control plane assignment as part of the contract:
- `SEC-*` gates: prevent leakage and enforce security guardrails (data exposure, unsafe patterns, toolchain fail-closed posture).
- `INT-*` gates: prove DB state, schema posture, and mechanical correctness (catalog verifiers, schema hooks, invariants posture).

This is why:
- `INV-112` PII leakage lint stays under Security (`SEC-G17`) even though it supports compliance.
- `INV-111` BoZ read-only role and `INV-113` anchor-sync hooks are Integrity (`INT-G23/INT-G24`) because they are DB structural proofs.

### B. Canonical ordering rule (single source of truth)
Phase-0 ordered execution is defined by `scripts/audit/run_phase0_ordered_checks.sh`.
- New gates MUST be inserted via the ordered runner (directly or by updating the scripts it invokes).
- CI workflows MUST call the ordered runner rather than adding "CI-only" gate steps.

### C. Toolchain prerequisites (Phase-0 checklist)
- [ ] Toolchain bootstrap is present and used for local parity: `scripts/audit/bootstrap_local_ci_toolchain.sh`
- [ ] `bash`, `git`, `python3` are available
- [ ] `rg` (ripgrep) is available (repo-wide scans must be deterministic)
- [ ] `docker` is available for local DB parity runs (`scripts/dev/pre_ci.sh`)
- [ ] `psql` is available for DB verifiers (INV-031, BoZ role verifier, anchor-sync verifier)
- [ ] Security plane tools are pinned/installed where required (e.g., `semgrep` via the repo's CI toolchain parity mechanism)

## Goal
Translate the Sovereign Hybrid Cloud "High-Efficiency Regulatory Machine" proposal into Symphony Phase-0 primitives:
- `invariant -> gate -> verifier -> evidence -> contract`
- local `scripts/dev/pre_ci.sh` parity with CI ordering
- non-colliding IDs (existing gate/invariant IDs must remain stable)

## Constraints (Repo Contracts)
- No runtime DDL in production paths.
- Forward-only migrations; never edit applied migrations.
- SECURITY DEFINER hardening: `SET search_path = pg_catalog, public`.
- Revoke-first privilege posture; runtime roles must not regain CREATE on schemas.
- CI and local pre-CI parity must be maintained (same scripts, same ordering).

## Methodical Document Intake (archive/Soverign-Hybrid-Cloud.md)
The source document evolves from broad "stack + workstreams" to a concrete patch bundle. This plan carries forward the refined intent while reconciling with repo reality:

### A. Phase Placement (what stays Phase-0 vs deferred)
Phase-0 (implement now, mechanical only):
- Migration expand/contract policy enforcement (already implemented as `INV-097` + `INV-098`).
- Table conventions verification (already implemented as `INV-099`).
- ZDPA-oriented PII leakage prevention lint on regulated surfaces (fail-closed).
- Regulator read-only observability posture (structural, DB-enforced, tested).
- Hybrid anchor-sync structural readiness verifier (schema shape and contract readiness).

Phase-1/2 (P0-severity but deferred enforcement, already modeled in repo):
- `INV-114` (alias: `INV-BOZ-04` payment finality / instruction irrevocability): Phase-1 activation.
- `INV-115` (alias: `INV-ZDPA-01` right-to-be-forgotten survivability with cryptographic validity): Phase-1/2 activation.
- `INV-116` (alias: `INV-IPDR-02` rail truth-anchor sequence continuity): Phase-1 activation.

Clarification (to avoid misinterpretation):
- These roadmap invariants are Phase-0 declared (P0-severity) so they are audit-visible now.
- What is deferred is runtime enforcement (Phase-1/2), not the acknowledgement/ownership/severity.

Deferred (Phase-0 optional, not required for Phase-0 closeout unless explicitly added to contract):
- Evidence signing enforcement (Phase-0 desired in the source doc, but not currently a Phase-0 contract requirement).
- AI change-trace gate and redaction wrapper (valuable; requires deliberate policy scope and gate IDs).
- OPA/Conftest repo policy pack (requires toolchain bootstrap + ruleset governance).
- Native .NET analyzers expansion (goes beyond Semgrep; requires careful CI/runtime cost control).

### B. Collision Reconciliation (non-negotiable)
The patch bundle embedded in the source document proposes gate IDs that collide with existing repo IDs:
- Existing gates already occupy: `GOV-G01..GOV-G02`, `INT-G01..INT-G21`, `SEC-G01..SEC-G16`.
Therefore this plan allocates new gates beyond the current max ranges (see "Gate/Invariant Allocation").

## Gate/Invariant Allocation (planned, non-colliding)
Repo reality note (from `docs/invariants/INVARIANTS_MANIFEST.yml`):
- Expand/contract and PK/FK stability enforcement already exist as `INV-097` and `INV-098`.
- Table conventions verification already exists as `INV-099`.
This plan does not duplicate those invariants.

New invariants (add to `docs/invariants/INVARIANTS_MANIFEST.yml`):
- `INV-111` BoZ observability seat (DB role `boz_auditor` is provably read-only) (P0, implemented)
- `INV-112` ZDPA PII leakage payload lint (regulated payload surfaces) (P0, implemented)
- `INV-113` Hybrid anchor-sync hooks present (schema supports local signing -> remote anchoring lifecycle) (P0, implemented; Phase-0 structural)

New gates (add to `docs/control_planes/CONTROL_PLANES.yml`):
- Integrity plane:
  - `INT-G23` -> DB verifier: BoZ/regulator observability role is read-only
  - `INT-G24` -> DB verifier: anchor-sync structural readiness
- Security plane:
  - `SEC-G17` -> PII leakage payload lint

Evidence paths (all under `evidence/phase0/`):
- `boz_observability_role.json`
- `pii_leakage_payloads.json`
- `anchor_sync_hooks.json`

## Explicit Mapping (invariant -> gate -> verifier -> evidence)
This section exists to prevent later ambiguity and control-plane drift.

- Note: `INT-G22` is reserved for `INV-031` (Phase-0 performance hot-path posture) and is not available for this cluster.
- `INV-112` -> `SEC-G17` -> `scripts/audit/lint_pii_leakage_payloads.sh` -> `evidence/phase0/pii_leakage_payloads.json`
- `INV-111` -> `INT-G23` -> `scripts/db/verify_boz_observability_role.sh` -> `evidence/phase0/boz_observability_role.json`
- `INV-113` -> `INT-G24` -> `scripts/db/verify_anchor_sync_hooks.sh` -> `evidence/phase0/anchor_sync_hooks.json`

## Anchor-Sync Readiness Checklist (Phase-0 structural only)
Phase-0 does not introduce operational queue semantics (no job tables). Readiness means the schema already contains the structural hooks needed for Phase-1 anchoring workflows.

Acceptance checklist for `scripts/db/verify_anchor_sync_hooks.sh`:
- Table: `public.evidence_packs` exists.
- Columns exist on `public.evidence_packs` (from `schema/migrations/0023_evidence_packs_signing_anchoring_hooks.sql`):
  - `signer_participant_id` (nullable)
  - `signature_alg` (nullable)
  - `signature` (nullable)
  - `signed_at` (nullable timestamptz)
  - `anchor_type` (nullable)
  - `anchor_ref` (nullable)
  - `anchored_at` (nullable timestamptz)
- Index exists to support anchor lookups:
  - `idx_evidence_packs_anchor_ref` on `public.evidence_packs(anchor_ref)` with predicate `WHERE anchor_ref IS NOT NULL`

Non-goals (explicit):
- Do not add an `evidence_anchor_jobs` or similar job table in Phase-0 for this cluster.

## Implementation Order (natural progression)
0. Reconcile plan semantics with existing invariants (done as part of this planning cluster):
   - Reuse `INV-097`, `INV-098`, `INV-099` rather than introducing duplicates.
1. Implement verifiers/lints (scripts and DB migration where required; no control-plane wiring until integration task):
   - `scripts/audit/lint_pii_leakage_payloads.sh` (TSK-P0-127)
   - `schema/migrations/0025_boz_observability_role.sql` + `scripts/db/verify_boz_observability_role.sh` (TSK-P0-128)
   - `scripts/db/verify_anchor_sync_hooks.sh` (TSK-P0-129)
2. Wire the new gates into the control plane + contract ordering (TSK-P0-130):
   - Add gates to `docs/control_planes/CONTROL_PLANES.yml`
   - Register invariants in `docs/invariants/INVARIANTS_MANIFEST.yml`
   - Add ordering to `scripts/audit/run_phase0_ordered_checks.sh` and local parity runner (`scripts/dev/pre_ci.sh`)
   - Ensure CI workflow calls the same ordering script(s)
3. Verify end-to-end parity:
   - `scripts/dev/pre_ci.sh`
   - CI full Phase-0 run with artifacts checked via `scripts/audit/verify_phase0_contract_evidence_status.sh`

## Contract/Evidence Strategy (to avoid CI "missing evidence" failures mid-flight)
Decision (repo policy): Approach B (planned gates land early with deterministic SKIPPED evidence until implemented).
- Policy: `docs/PHASE0/PLANNED_SKIPPED_GATES_POLICY.md`.
- Declare gates in `docs/control_planes/CONTROL_PLANES.yml` early to reserve IDs and lock semantics.
- Provide deterministic `SKIPPED` evidence stubs for planned gates until real PASS/FAIL implementation lands.

Operational rule (explicit):
- Contract promotion (making evidence required in `docs/PHASE0/phase0_contract.yml`) must only happen after a gate emits deterministic PASS/FAIL (not SKIPPED) in both local pre-CI and CI.

## Remediation Trace Gate Compatibility (required for production-affecting surfaces)
Any PR touching trigger surfaces (e.g., `scripts/**`, `schema/**`, `.github/workflows/**`, `docs/PHASE0/**`) must satisfy `INV-105` (`scripts/audit/verify_remediation_trace.sh`).
This plan uses TSK casefiles as the satisfying remediation trace vehicle:
- each TSK plan folder MUST include the remediation markers:
  - `failure_signature`
  - `repro_command`
  - `verification_commands_run`
  - `final_status`
  - and one of `origin_task_id` or `origin_gate_id`

## Acceptance Criteria (cluster)
- All new gates emit evidence JSON (PASS/FAIL) even on failure.
- CI and local pre-CI run the same gate ordering, and no gate is "CI-only hidden".
- `scripts/audit/verify_phase0_contract_evidence_status.sh` is PASS (no missing evidence paths for required gates).
- No gate ID collisions; existing gate IDs remain stable.

## Task Breakdown (this plan’s tasks)
- TSK-P0-125: This plan + task scaffolding + bundle alignment review (docs-only).
- TSK-P0-127: Implement PII leakage payload lint script (no wiring).
- TSK-P0-128: Implement regulator read-only role (forward-only migration) + DB verifier (no wiring).
- TSK-P0-129: Implement anchor-sync readiness DB verifier (Phase-0 structural only; no job table) (no wiring).
- TSK-P0-130: Wire gates into CONTROL_PLANES + Phase-0 contract + CI/pre-CI ordering (integration task).

## Phase-0 Performance Cluster (Added)
Phase-0 performance work is limited to structural and static guarantees:
- prevent migration-induced incidents (blocking DDL, table rewrites, long locks)
- require minimum index posture for critical access patterns
- enforce fail-fast DB timeouts (statement/lock/idle-in-tx) at the DB/role level

Tasks (scaffolded; no implementation performed in this planning pass):
- TSK-P0-142: Performance invariant declaration & manifest reconciliation (bookkeeping; no new gates).
- TSK-P0-143: Phase-0 performance evidence contract definition (naming/shape/boundary).
- TSK-P0-144: Performance guardrail verifier scripts (static/catalog checks; deterministic evidence).
- TSK-P0-145: Control-plane wiring for performance invariants (parity + ordering; no CI-only gates).
- TSK-P0-146: Phase-0 performance closeout & regulator narrative (audit-legible, maps to mechanical enforcement).

## Notes / Open Questions (for review before implementation)
- Regulator seat role name is `boz_auditor` (jurisdiction-specific, Zambia Phase-0).
- Anchor-sync readiness is satisfied in Phase-0 by existing structural hooks (e.g., `public.evidence_packs` anchor columns from migration 0023) plus a mechanical verifier. A job-tracking table is Phase-1 operational scaffolding and is intentionally out of Phase-0 scope.

## Path Hygiene Note (Tier-1 packaging)
The source document path retains legacy spelling for stability:
- `archive/Soverign-Hybrid-Cloud.md`
If we want to present a cleaner pre-audit package, do a controlled rename in a dedicated task (with remediation trace satisfied) and update all references.
