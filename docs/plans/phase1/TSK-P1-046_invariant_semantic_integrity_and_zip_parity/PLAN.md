# PLAN: Phase-1 Agent Conformance Qualification + Invariant Semantic Integrity + Zip/Offline Determinism

## Metadata
- plan_id: `TSK-P1-046_invariant_semantic_integrity_and_zip_parity`
- date: `2026-02-18`
- status: `proposed_for_review`
- program_type: `corrective_hardening`
- scope: Resolve semantic contract misuse (INV-105), keep qualified agent conformance in Phase-1, and prevent recurrence via mechanical semantic checks.

## Executive Decision (Approved Direction Captured)
Agent conformance remains in Phase-1 **only** as a regulated-surface change-control and approval-trace integrity control.

This plan adopts:
1. `INV-105` remains strictly remediation-trace semantics.
2. Agent conformance evidence moves to new invariant `INV-119`.
3. Phase-1 keeps no-MCP runtime posture while allowing governance conformance evidence.
4. Semantic parser gate is added to fail closed on any future invariant-ID semantic collision.

## Qualification Logic (Why Agent Conformance Stays In Phase-1)
Phase-1 definition: pilot-ready deterministic orchestration + regulator-grade defensibility without weakening Phase-0.

Agent conformance qualifies only where it reduces safety/auditability risk for production-affecting regulated surfaces.

### Qualifying Case A (Accepted)
Regulated-surface changes require non-bypass approval trace.
- Operational risk reduced: unsafe change introduction on regulated surfaces.
- Regulator risk reduced: missing approval lineage.
- Current enforcement anchors:
  - `scripts/dev/pre_ci.sh` runs `verify_agent_conformance.sh` before Phase-1 closeout (`scripts/dev/pre_ci.sh:176`)
  - regulated surfaces and metadata rules are canonicalized in `docs/operations/AI_AGENT_OPERATION_MANUAL.md:76` and `docs/operations/AI_AGENT_OPERATION_MANUAL.md:91`

### Qualifying Case B (Conditionally Accepted)
Prompt/process drift prevention qualifies **only if conformance is non-optional in deterministic gate chain**.
- Current chain does enforce conformance in pre-CI (`scripts/dev/pre_ci.sh:176`).
- This plan keeps it mandatory in Phase-1 gate path.

### Qualifying Case C (Accepted)
Approval markdown/sidecar cross-link integrity and PII fail-closed checks qualify as regulator-facing auditability controls.
- Enforced by `scripts/audit/verify_agent_conformance.sh:147` onward.

### Non-qualifying Boundary (Explicit)
Agent conformance does not impose approval-metadata requirements when regulated surfaces are unchanged.
- conditional logic in `scripts/audit/verify_agent_conformance.sh:129`.

## Root Cause and Current Structural Defect
Canonical manifest meaning and Phase-1 contract mapping diverged:
- `INV-105` in manifest is remediation trace (`docs/invariants/INVARIANTS_MANIFEST.yml:734`)
- `phase1_contract.yml` currently maps `INV-105` rows to `verify_agent_conformance.sh` evidence (`docs/PHASE1/phase1_contract.yml:73`)

This is a semantic integrity defect (ID meaning reused), even if gates currently pass.

## Program Objectives
1. Repair invariant semantics (`INV-105` only remediation trace).
2. Preserve qualified agent conformance in Phase-1 under new canonical invariant (`INV-119`).
3. Introduce semantic integrity verifier that blocks mismatch class forever.
4. Harden Phase-1 contract verifier for zip/no-git determinism.
5. Harden local toolchain bootstrap for offline determinism.

## Staged PR Program (Execution Order)

### PR-A: Semantic Repair and Re-homing (TSK-P1-046 + TSK-P1-047)
Goal: make invariant semantics truthful and explicit.

Changes:
- `docs/PHASE1/phase1_contract.yml`
  - Replace all `INV-105 -> verify_agent_conformance.sh` rows.
  - Add `INV-105` row mapped to remediation trace:
    - verifier: `scripts/audit/verify_remediation_trace.sh`
    - evidence: `evidence/phase0/remediation_trace.json`
  - Add three `INV-119` rows for:
    - `evidence/phase1/agent_conformance_architect.json`
    - `evidence/phase1/agent_conformance_implementer.json`
    - `evidence/phase1/agent_conformance_policy_guardian.json`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
  - Add exact new invariant:

```yaml
- id: "INV-119"
  aliases: ["I-AGENT-CONF-01"]
  status: implemented
  severity: P1
  title: "Agent-governed regulated-surface change control requires conformance + approval trace integrity"
  owners: ["team-security", "team-invariants"]
  sla_days: 30
  enforcement: "scripts/audit/verify_agent_conformance.sh"
  verification: "scripts/audit/verify_agent_conformance.sh; wired via scripts/dev/pre_ci.sh (pre-gates) and Phase-1 governance gate (INT-G28)"
  notes: >
    Phase-1 governance invariant for agent-mediated change control. Enforces: (1) role declaration + canonical reference requirements
    and mandatory stop/escalation conditions for governed change workflows; (2) conditional approval metadata enforcement when regulated
    surfaces are changed; (3) approval markdown + sidecar cross-link integrity (presence, shape, value consistency, hash match); and
    fail-closed PII leakage checks in approval metadata. Independent of MCP runtime enablement.
```

- `docs/invariants/INVARIANTS_IMPLEMENTED.md`
- `docs/invariants/INVARIANTS_QUICK.md`

Acceptance:
- `INV-105` no longer references agent conformance artifacts anywhere in Phase-1 contract.
- `INV-119` fully documents/enforces agent conformance semantics.

Verification:
- `bash scripts/audit/verify_phase1_contract.sh`
- `bash scripts/audit/verify_remediation_trace.sh`
- `bash scripts/audit/verify_agent_conformance.sh`

---

### PR-B: Semantic Integrity Guard (TSK-P1-048)
Goal: make this collision class mechanically impossible.

Add verifier:
- `scripts/audit/verify_invariant_semantic_integrity.sh`

Evidence:
- `evidence/phase1/invariant_semantic_integrity.json`

Rules (fail-closed):
1. Contract `invariant_id` must exist in manifest.
2. `contract.verifier` must equal manifest `enforcement` for that invariant.
3. Contract `evidence_path` must be emitted by declared verifier (via registry file below).
4. Manifest must have unique invariant IDs and unique aliases.
5. Optional gate checks: contract gate must exist in control-plane.

Add registry:
- `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`

Add tests:
- `scripts/audit/tests/test_invariant_semantic_integrity.sh`
- fixtures:
  - mismatch (INV-105->agent verifier) FAIL
  - wrong evidence path FAIL
  - happy path PASS

Wire into pre-CI:
- `scripts/dev/pre_ci.sh` under `RUN_PHASE1_GATES=1` before `verify_phase1_contract.sh`.

---

### PR-C: Zip/No-git Deterministic Contract Mode (TSK-P1-049)
Goal: explicit behavior in no-ref contexts (no silent semantic drift).

Update:
- `scripts/audit/verify_phase1_contract.sh`
- `scripts/audit/lib/approval_requirement.py`

Add modes:
- `PHASE1_CONTRACT_MODE=range` (default)
- `PHASE1_CONTRACT_MODE=zip_audit`

`zip_audit` semantics:
- No attempt to infer range diff from missing refs.
- Deterministic structure-mode verification only.
- Evidence must include `mode: zip_audit` and explicit `approval_requirement_mode`.
- Fail with clear error if caller requests `range` but no valid git refs/BASE_REF context exists.

Tests:
- extend `scripts/audit/tests/test_approval_metadata_requirements.sh`
- new fixture suite for zip/range mode semantics.

---

### PR-D: Offline Toolchain Determinism (TSK-P1-050)
Goal: remove opaque curl failures in airgapped/local offline runs.

Update:
- `scripts/audit/bootstrap_local_ci_toolchain.sh`
- `scripts/audit/verify_ci_toolchain.sh`
- `docs/operations/LOCAL_CI_PARITY.md`

Add:
- `SYMPHONY_OFFLINE=1` mode.
- In offline mode:
  - no network fetch attempt.
  - if pinned rg missing, deterministic FAIL with actionable remediation.
  - optional vendored binary path if provided.

---

### PR-E: Final Reconciliation + Closeout (TSK-P1-051 + TSK-P1-052)
Goal: prove end-to-end consistency and document closure.

Update:
- `docs/control_planes/CONTROL_PLANES.yml` (if required to include semantic integrity gate)
- `docs/PHASE1/phase1_contract.yml`
- `docs/audits/SYMPH2_PHASE1_ASSESSMENT_VALIDATION_2026-02-18.md`
- new closeout report: `docs/audits/PHASE1_AGENT_CONFORMANCE_SEMANTIC_REPAIR_CLOSEOUT_2026-02-18.md`

Final verification:
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`
- `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh`
- `bash scripts/audit/verify_invariant_semantic_integrity.sh`

## Task List (Detailed)

### TSK-P1-046 — Restore INV-105 semantic correctness in Phase-1 contract
- purpose: remove semantic overload from INV-105.
- owner_role: `INVARIANTS_CURATOR`
- depends_on: none
- touches:
  - `docs/PHASE1/phase1_contract.yml`
- deliverables:
  - INV-105 row mapped only to remediation trace verifier/evidence.
  - all INV-105 agent conformance rows removed.
- evidence targets:
  - `evidence/phase1/phase1_contract_status.json`
  - `evidence/phase0/remediation_trace.json`
- fail modes addressed:
  - invariant ID reused for unrelated semantics.

### TSK-P1-047 — Introduce INV-119 and re-home agent conformance
- purpose: keep qualified agent conformance in Phase-1 with correct invariant identity.
- owner_role: `INVARIANTS_CURATOR`
- depends_on: `TSK-P1-046`
- touches:
  - `docs/invariants/INVARIANTS_MANIFEST.yml`
  - `docs/PHASE1/phase1_contract.yml`
  - `docs/invariants/INVARIANTS_IMPLEMENTED.md`
  - `docs/invariants/INVARIANTS_QUICK.md`
- deliverables:
  - add INV-119 entry (exact text above)
  - map three agent conformance evidence files to INV-119.

### TSK-P1-048 — Add semantic integrity verifier + registry + fixtures
- purpose: permanently block invariant semantic collisions.
- owner_role: `INVARIANTS_CURATOR`
- depends_on: `TSK-P1-047`
- touches:
  - `scripts/audit/verify_invariant_semantic_integrity.sh`
  - `docs/operations/VERIFIER_EVIDENCE_REGISTRY.yml`
  - `scripts/audit/tests/test_invariant_semantic_integrity.sh`
  - `scripts/audit/tests/fixtures/semantic_integrity/*`
  - `scripts/dev/pre_ci.sh`
- output:
  - `evidence/phase1/invariant_semantic_integrity.json`

### TSK-P1-049 — Implement zip/no-git explicit mode in phase1 contract verifier
- purpose: deterministic behavior outside full git checkout.
- owner_role: `SUPERVISOR`
- depends_on: `TSK-P1-048`
- touches:
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/audit/lib/approval_requirement.py`
  - `scripts/audit/tests/test_approval_metadata_requirements.sh`
- output:
  - `evidence/phase1/phase1_contract_status.json` (with explicit mode fields)

### TSK-P1-050 — Add offline toolchain mode
- purpose: deterministic airgapped behavior.
- owner_role: `SECURITY_GUARDIAN`
- depends_on: `TSK-P1-049`
- touches:
  - `scripts/audit/bootstrap_local_ci_toolchain.sh`
  - `scripts/audit/verify_ci_toolchain.sh`
  - `docs/operations/LOCAL_CI_PARITY.md`

### TSK-P1-051 — Control-plane/contract reconciliation
- purpose: ensure gate topology and contract map are coherent after semantic repairs.
- owner_role: `SUPERVISOR`
- depends_on: `TSK-P1-050`
- touches:
  - `docs/control_planes/CONTROL_PLANES.yml`
  - `docs/PHASE1/phase1_contract.yml`

### TSK-P1-052 — Closeout report + regression-proof proof pack
- purpose: publish definitive before/after and anti-regression proof.
- owner_role: `SUPERVISOR`
- depends_on: `TSK-P1-051`
- touches:
  - `docs/audits/SYMPH2_PHASE1_ASSESSMENT_VALIDATION_2026-02-18.md`
  - `docs/audits/PHASE1_AGENT_CONFORMANCE_SEMANTIC_REPAIR_CLOSEOUT_2026-02-18.md`
  - task execution logs/plans

## Mechanical Semantic Parser Spec (Implemented in TSK-P1-048)
- check_id: `SEM-I01`
- hard-fail violations:
  - `SEM_I01_INVARIANT_UNKNOWN`
  - `SEM_I01_VERIFIER_MISMATCH`
  - `SEM_I01_EVIDENCE_NOT_EMITTED_BY_VERIFIER`
  - `SEM_I01_DUPLICATE_INVARIANT_ID`
  - `SEM_I01_DUPLICATE_ALIAS`
  - `SEM_I01_UNKNOWN_GATE` (if gate validation enabled)

Evidence schema minimum:
- `check_id`
- `timestamp_utc`
- `git_sha`
- `status`
- `violations[]` with:
  - `invariant_id`
  - `contract_row_ref`
  - `reason`
  - `expected`
  - `actual`

## Definition of Done
1. INV-105 contract rows exclusively represent remediation trace.
2. INV-119 owns all three agent conformance evidence files.
3. Semantic integrity verifier is enforced in pre-CI and fails on mismatch fixtures.
4. Phase-1 contract verifier has explicit zip/no-git mode semantics.
5. Offline toolchain mode is deterministic and documented.
6. `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh` passes in normal checkout after changes.

## Review Decisions Required
1. Approve `INV-119` allocation and text exactly as specified.
2. Approve `PHASE1_CONTRACT_MODE=zip_audit` as explicit structure-only mode.
3. Approve strict semantic mismatch policy (no default exceptions).
4. Choose offline policy default:
   - hard-fail with remediation hint, or
   - allow vendored pinned rg fallback.
