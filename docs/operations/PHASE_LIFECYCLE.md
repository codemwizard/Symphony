# Symphony Phase Lifecycle Definition

Date: 2026-03-07
Status: Proposed canonical policy baseline
Owner: Architecture / Platform

## 1) Purpose

Define what a phase is in Symphony and provide explicit, auditable definitions for Phase-0 through Phase-4, with detailed forward definitions for Phase-2, Phase-3, and Phase-4.

This document follows existing contract patterns from:
- `docs/PHASE0/PHASE0_CONTRACT.md`
- `docs/PHASE1/PHASE1_CONTRACT.md`
- `docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md`
- `docs/operations/DEV_WORKFLOW.md`

## 2) Core Definition

A phase is a named, contracted, evidenced capability boundary.

A phase is considered real and delivery-claimable only when all are true:
1. Named: phase key and human-readable name are declared.
2. Contracted: machine + human contract pair exists.
3. Evidenced: phase evidence namespace is defined and used by required gates.
4. Capability-bounded: scope and non-goals are explicitly documented.

## 2A) Canonical Taxonomy and Reserved Terms

This document is the authoritative definition of lifecycle phase keys in Symphony.

For delivery-governed metadata and claims, unqualified `phase` means `lifecycle_phase` as defined here.

The following terms are distinct and must not be conflated:
1. `lifecycle_phase`: canonical delivery capability boundary defined by this document.
2. `remediation_phase`: security/remediation sequencing taxonomy; not equivalent to lifecycle phase.
3. `roadmap_phase`: planning/strategy grouping; not sufficient for delivery claims.
4. `wave`: sequencing subdivision within one lifecycle phase.

Lifecycle phase keys are restricted to the approved integer-string set:
1. `0`
2. `1`
3. `2`
4. `3`
5. `4`

The following are not valid lifecycle phase keys:
1. Dotted remediation identifiers such as `0.1`, `0.2`, `0.5`.
2. Named values such as `Hardening`.
3. Any wave identifier.

If another taxonomy is used, it must be explicitly namespaced in schema and documentation.

## 3) Required Artifacts Per Phase

For Phase-N, the required artifact set is:
1. Human contract: `docs/PHASE<N>/PHASE<N>_CONTRACT.md`
2. Machine contract: `docs/PHASE<N>/phase<n>_contract.yml`
3. Policy guard: `docs/operations/AGENTIC_SDLC_PHASE<N>_POLICY.md`
4. Verifier: `scripts/audit/verify_phase<n>_contract.sh`
5. Evidence namespace: `evidence/phase<n>/**`
6. Phase-opening approval artifact set:
- `approvals/YYYY-MM-DD/PHASE<N>-OPENING.md`
- `approvals/YYYY-MM-DD/PHASE<N>-OPENING.approval.json`
- Must conform to repository approval schema/policy rules in `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

Until these exist in one approved change set, Phase-N keys must not be used for delivery claims in task metadata, branch naming, commit headers, approval records, release notes, roadmap claims, status dashboards, or evidence-folder naming used as implied proof.

## 4) Common Status Semantics

Each phase contract row must use a constrained status set:
1. `phase<n-1>_prerequisite`: enforced by prior phase.
2. `planned`: declared but not required yet.
3. `implemented`: required and fail-closed.
4. `deferred_to_phase<n+1>`: explicitly out of current phase scope.

Example alignment with existing Phase-1 semantics:
- Phase-1 uses `phase0_prerequisite`, `planned`, `implemented`, `deferred_to_phase2`.

## 5) Wave Semantics

Waves are sub-divisions within a single phase, not independent phase boundaries.

Rules:
1. A wave may structure delivery sequencing within Phase-N.
2. Wave completion does not replace phase closeout criteria.
3. Waves do not get separate phase contracts; they deliver against the parent phase contract.
For the full construction rule, dependency constraints, and enforcement
expectations for wave schedules, see:
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`

## 6) Entry and Exit Rules (Global)

Phase-N entry requires:
1. Prior phase definition of done is met and evidenced.
2. Required Phase-N artifacts from Section 3 are created.
3. Explicit human approval artifact records phase opening.

Phase-N closeout requires:
1. Required `implemented` rows pass under phase gate flag.
2. Required evidence exists and validates in `evidence/phase<n>/**`.
3. Any `deferred_to_phase<n+1>` rows are explicitly carried forward into Phase-(N+1) planning.

## 6A) Phase-0 Normalization Against Core Definition

Name: Phase-0 - Hardened Baseline
Key: `0`

Section-2 mapping:
1. Named: established in `docs/PHASE0/*`.
2. Contracted: `docs/PHASE0/PHASE0_CONTRACT.md` (+ supporting Phase-0 contract artifacts).
3. Evidenced: authoritative evidence under `evidence/phase0/**`.
4. Capability-bounded: Phase-0 governance and baseline constraints are explicitly documented in `docs/PHASE0/**` and operations policy docs.

Deferred linkage:
- Phase-0 deferrals feed into Phase-1 and above via explicit contract/status carry-forward.

## 6B) Phase-1 Normalization Against Core Definition

Name: Phase-1 - Deterministic Pilot Expansion
Key: `1`

Section-2 mapping:
1. Named: declared in `docs/PHASE1/*` and `AGENTIC_SDLC_PHASE1_POLICY.md`.
2. Contracted: `docs/PHASE1/PHASE1_CONTRACT.md` + `docs/PHASE1/phase1_contract.yml`.
3. Evidenced: new Phase-1 rows use `evidence/phase1/**`; prerequisites may retain prior evidence paths.
4. Capability-bounded: `docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md` defines scope guard and definition of done.

Deferred linkage:
- `deferred_to_phase2` rows define Phase-2 intake boundary.

## 7) Phase-2 Definition

Name: Phase-2 - Controlled Expansion and Governance Automation
Key: `2`

### 7.1 Capability Boundary

Phase-2 extends beyond deterministic pilot readiness (Phase-1) into controlled expansion of governance and runtime capabilities without weakening Phase-0/1 guarantees.

Descriptive scope text is explanatory only; contract rows, verifier behavior, and evidence bindings are authoritative for delivery claims.

### 7.2 In-Scope Capability Classes

1. Policy lifecycle expansion beyond ACTIVE-only operation (for example, rotation workflows).
2. AI-review and detector artifact governance (schema or wrapper-evidence formalization).
3. Explicitly approved runtime expansion previously blocked by Phase-1 scope guard.
4. Product/API growth only when contract + gate + evidence bindings are declared.

### 7.3 Non-Goals

1. Large-scale autonomous adaptation without deterministic guardrails.
2. Cross-domain federation work not yet contract-bound.
3. Any gate bypass or evidence path drift.

### 7.4 Contract and Gate Semantics

1. Contract pair:
- `docs/PHASE2/PHASE2_CONTRACT.md`
- `docs/PHASE2/phase2_contract.yml`
2. Verifier:
- `scripts/audit/verify_phase2_contract.sh`
3. Gate flag:
- `RUN_PHASE2_GATES=1` enables fail-closed evaluation.
4. Contract row schema (Phase-1 pattern, invariant-centric):
- `invariant_id`
- `status`
- `required`
- `gate_id`
- `verifier`
- `evidence_path`

### 7.5 Status Set

1. `phase1_prerequisite`
2. `planned`
3. `implemented`
4. `deferred_to_phase3`

### 7.6 Evidence Namespace

1. New Phase-2 runtime rows: `evidence/phase2/**`
2. Prerequisites retain prior authoritative paths (`evidence/phase0/**`, `evidence/phase1/**` as applicable).

### 7.7 Entry Threshold

1. Phase-1 definition of done satisfied.
2. `verify_phase1_contract` enforced for relevant workflows.
3. Phase-2 contracts and policy are approved and merged.
4. Explicit phase-opening approval artifact set exists (Section 3, item 6).

### 7.8 Exit Threshold

1. Required Phase-2 rows pass fail-closed under `RUN_PHASE2_GATES=1`.
2. Phase-2 evidence is reproducible with deterministic pass/fail semantics.
3. Deferred rows are explicitly staged for Phase-3.

## 8) Phase-3 Definition

Name: Phase-3 - Scaled Runtime Assurance
Key: `3`

### 8.1 Capability Boundary

Phase-3 operationalizes Phase-2 capabilities at scaled production posture with stronger runtime assurance, reliability, and governance continuity guarantees.

Descriptive scope text is explanatory only; contract rows, verifier behavior, and evidence bindings are authoritative for delivery claims.

### 8.2 In-Scope Capability Classes

1. Scale-hardening of Phase-2 controls (throughput, reliability, and deterministic behavior under stress).
2. Runtime governance convergence across expanded product/API surfaces.
3. Enforcement of long-horizon audit/replay and recovery readiness as required rows.
4. Broader production-grade operational controls that remain mechanically verifiable.

### 8.3 Non-Goals

1. Unbounded adaptive/autonomous policy mutation without contract controls.
2. Cross-organization federation without explicit Phase-4 contracts.
3. Relaxing determinism or evidence requirements for speed.

### 8.4 Contract and Gate Semantics

1. Contract pair:
- `docs/PHASE3/PHASE3_CONTRACT.md`
- `docs/PHASE3/phase3_contract.yml`
2. Verifier:
- `scripts/audit/verify_phase3_contract.sh`
3. Gate flag:
- `RUN_PHASE3_GATES=1`
4. Contract row schema (Phase-1 pattern, invariant-centric):
- `invariant_id`
- `status`
- `required`
- `gate_id`
- `verifier`
- `evidence_path`

### 8.5 Status Set

1. `phase2_prerequisite`
2. `planned`
3. `implemented`
4. `deferred_to_phase4`

### 8.6 Evidence Namespace

1. New Phase-3 runtime rows: `evidence/phase3/**`
2. Prior prerequisites retain authoritative prior paths.

### 8.7 Entry Threshold

1. Phase-2 closeout complete.
2. Phase-3 contracts/policy/verifier wiring approved.
3. Explicit phase-opening approval artifact set exists (Section 3, item 6).

### 8.8 Exit Threshold

1. Required Phase-3 rows pass under `RUN_PHASE3_GATES=1`.
2. Reliability and assurance checks are reproducible and schema-valid.
3. Deferred rows are explicitly staged for Phase-4.

## 9) Phase-4 Definition

Name: Phase-4 - Continuous Assurance and Evolution Governance
Key: `4`

### 9.1 Capability Boundary

Phase-4 governs continuous evolution at mature operational posture: controlled change velocity, durable assurance, and institutionalized compliance evidence continuity.

Descriptive scope text is explanatory only; contract rows, verifier behavior, and evidence bindings are authoritative for delivery claims.

### 9.2 In-Scope Capability Classes

1. Continuous governance operations with formalized change controls.
2. Long-term assurance continuity (replayability, archival integrity, and approval lineage).
3. Mature cross-surface policy governance with strict contract discipline.
4. Incremental capability evolution under fail-closed verification gates.

### 9.3 Non-Goals

1. Governance-free rapid changes.
2. Informal/manual-only assurance workflows.
3. Any weakening of regulated-surface approval requirements.

### 9.4 Contract and Gate Semantics

1. Contract pair:
- `docs/PHASE4/PHASE4_CONTRACT.md`
- `docs/PHASE4/phase4_contract.yml`
2. Verifier:
- `scripts/audit/verify_phase4_contract.sh`
3. Gate flag:
- `RUN_PHASE4_GATES=1`
4. Contract row schema (Phase-1 pattern, invariant-centric):
- `invariant_id`
- `status`
- `required`
- `gate_id`
- `verifier`
- `evidence_path`

### 9.5 Status Set

1. `phase3_prerequisite`
2. `planned`
3. `implemented`
4. `deferred_to_phase5`

### 9.6 Evidence Namespace

1. New Phase-4 runtime rows: `evidence/phase4/**`
2. Prior prerequisites retain authoritative prior paths.

### 9.7 Entry Threshold

1. Phase-3 closeout complete.
2. Phase-4 contract/policy/verifier set approved.
3. Explicit phase-opening approval artifact set exists (Section 3, item 6).

### 9.8 Exit Threshold

1. Required Phase-4 rows pass under `RUN_PHASE4_GATES=1`.
2. Continuous-assurance evidence remains reproducible and auditable.
3. Next-phase deferrals are explicitly declared (if applicable).

### 9.9 Phase-5 Reservation

1. `deferred_to_phase5` is a reserved lifecycle status target only.
2. Phase-5 is not defined by this document and is not delivery-claimable until a formally approved Phase-5 lifecycle contract and policy baseline are published.

## 10) Immediate Documentation Follow-On

To operationalize this definition, add or update:
1. `docs/operations/POLICY_PRECEDENCE.md` (reference this file in precedence chain).
2. `docs/operations/DEV_WORKFLOW.md` (link phase entry/exit semantics here).
3. `docs/operations/TASK_CREATION_PROCESS.md` (require phase key determination rules against this lifecycle definition).
4. `docs/operations/GIT_CONVENTIONS.md` (canonical branch/commit format must reference this document for phase/wave key resolution).
5. `.agent/workflows/git-conventions.md` (retire or rewrite to defer to `GIT_CONVENTIONS.md`).
6. `docs/PHASE2/*`, `docs/PHASE3/*`, `docs/PHASE4/*` contract placeholders before phase claims are used in delivery metadata.

## 11) Schema Lineage Note (Phase-0 vs Phase-1+)

Phase-0 and Phase-1 use different contract row schemas today:

1. Phase-0 (task-centric legacy pattern) commonly uses fields such as:
- `task_id`
- `status`
- `verification_mode`
- `evidence_required`
- `evidence_paths`
- `evidence_scope`

2. Phase-1 (invariant-centric canonical forward pattern) uses:
- `invariant_id`
- `status`
- `required`
- `gate_id`
- `verifier`
- `evidence_path`

Forward rule:
- Until a formally approved migration occurs, Phase-0 remains a legacy schema exception.
- Lifecycle claims for Phase-1 and above must use the invariant-centric schema.
- Any cross-phase reporting that mixes Phase-0 and Phase-1+ must use an approved translation layer.
- Phase-2 and above must follow the Phase-1 invariant-centric schema unless an approved contract revision explicitly changes it.
