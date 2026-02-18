# Agentic SDLC Policy for Symphony Phase-1 (Canonical)

Date: 2026-02-16
Owner: Architecture / Platform
Applies to: Phase-1 execution only
Status: Canonical policy for agentic Phase-1 execution

## 1) Objective
Deliver Phase-1 improvements without weakening Phase-0 guarantees.

Phase-0 remains the hardened baseline. Phase-1 may add capability only when it is mechanically verifiable, deterministic, and CI/pre-CI aligned.

## 2) Non-Negotiables
A change is acceptable only when all are true:
1. Task meta declares:
- invariants impacted
- verifiers to run
- evidence paths to produce
- control-plane ownership
2. `PLAN.md` exists and is referenced by task meta.
3. `EXEC_LOG.md` exists and records commands executed.
4. Declared verifiers pass.
5. Required evidence exists at fixed paths and is schema-valid.
6. CI/pre-CI parity gates pass (ordering + diff semantics).

If any item fails, workflow stops and remediation trace is required.

## 2A) One-Shot Cutover Rule (No Legacy Retention)
When a governance artifact, evidence path, or verifier contract is changed, migration must be single-cutover:
1. No dual-write period.
2. No fallback reads from legacy paths.
3. No compatibility shims/adapters for retired artifacts.
4. All task/meta/plan/contract/verifier references must be updated in the same change set.
5. Legacy artifact definitions and references must be removed before merge.

Fail condition:
- If any legacy reference remains after cutover, the change is non-compliant and must fail closed.

## 3) Scope Guard (Phase-1)
This policy does not authorize:
1. Phase-2/3 expansion.
2. Smart-routing/fraud-AI feature work without explicit phase approval.
3. Product API expansion without contract + gate + tests + authz assertions + evidence.
4. Gate bypass or evidence path drift.

## 4) Deterministic Evidence Contract
Every required evidence artifact must include at minimum:
- `check_id`
- `timestamp_utc`
- `git_sha`
- `status` (`PASS|FAIL|SKIPPED` only if contract-allowed)
- `inputs` (explicit execution context: refs, env flags, DB target, diff mode)
- `details` (machine-readable result payload)

Determinism rule:
- same commit + same declared inputs => same pass/fail semantics.

## 5) Diff Semantics Policy (Mandatory)
Any gate that selects files by changed content must use one shared diff contract.

Canonical interfaces:
1. `scripts/lib/git_diff.sh` (library contract)
2. `scripts/audit/git_diff_cli.sh` (CLI wrapper)

Allowed mode for parity-critical enforcement:
- `range` only

Allowed modes for non-enforcement local ergonomics tooling:
- `staged`
- `worktree`

Rules:
1. Audit-relevant and parity-critical gates must use commit-range semantics in CI and pre-CI.
2. Every diff-based gate must log mode + refs/base in evidence or diagnostics.
3. No implicit fallback from range to staged/worktree in enforcement gates.

Implementation status:
- Phase-0 canonicalization is already implemented via `TSK-P0-152`, `TSK-P0-154`, and `TSK-P0-155`.
- Phase-1 strengthening is tracked under `TSK-P1-027` to close remaining range-only gaps in parity-critical paths.

## 6) Tool Trust Policy
1. Local repo + shell: allowed.
2. Network: disallowed unless explicitly authorized per task.
3. MCP: read-only context retrieval only.
4. Secrets: never exposed to agent output.
5. If external sources are used, `PLAN.md` must include:

```yaml
sources:
  - url: "<source>"
    retrieved_at_utc: "<timestamp>"
    purpose: "<why needed>"
```

6. If task meta has `external_sources_used=true`, source block is mandatory and verifiable.

## 7) Role Model (Minimal + One Advisory MCP Role)
Execution authority roles:
1. Architect Agent
- defines scope
- binds constraints to invariant IDs
- declares verifiers + evidence paths
- proposes gate wiring changes

2. Implementer Agent
- implements code/scripts/docs within scope
- updates verifiers/evidence emitters
- runs full verification chain

Advisory-only MCP role (no execution authority):
3. Requirements & Policy Integrity Agent
- analyzes requirements and maps them to invariants/gates/evidence bindings
- proposes wording hardening to remove loopholes and ambiguity
- must output constraint IDs, invariant IDs, gate IDs, verifier commands, evidence paths, and wording-risk notes
- cannot approve implementation or mutate gates directly

## 8) Stop Conditions
Agents must stop immediately if:
1. any required gate fails
2. required evidence missing/invalid
3. task meta diverges from implementation
4. CI/pre-CI parity mismatch is detected
5. required approval metadata is absent

## 9) Mechanical Checklist (Auditable)
Run/verify all required commands (context-dependent):
1. `bash scripts/audit/verify_task_plans_present.sh`
2. `bash scripts/audit/run_invariants_fast_checks.sh`
3. `bash scripts/audit/run_security_fast_checks.sh`
4. `bash scripts/audit/verify_diff_semantics_parity.sh`
5. `bash scripts/db/verify_invariants.sh` (DB-touching changes)
6. `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh` (Phase-1 scope)
7. `CI_ONLY=1 bash scripts/ci/check_evidence_required.sh evidence/phase0` (when phase0 evidence contract is touched)
8. `bash scripts/dev/pre_ci.sh`
9. Validate one-shot cutover completeness when artifact paths/contracts are changed:
- no legacy paths referenced in task meta, plans, contracts, or verifier scripts
- no dual-write behavior in verifier/evidence emitters

Expected policy semantics:
- no silent bypass
- no required artifact missing
- no contract drift for required Phase-1 evidence

## 10) Definition of Done for Agentic Phase-1 Adoption
Adoption is complete when:
1. Two tasks run end-to-end with no bypasses:
- task meta -> plan -> implementation -> verifiers -> evidence -> contract checks -> parity
2. Diff semantics are unified for all audit-relevant diff-based gates.
3. `verify_phase1_contract.sh` is enforced in pre-CI/CI for Phase-1 work.
4. Evidence pass/fail semantics are reproducible across two consecutive runs.

## 11) Authority Model
This document is canonical for Phase-1 agentic process policy.
Supporting documents:
- `docs/operations/AGENTIC_SDLC_IMPLEMENTATION_PLAYBOOK_2026-02-16.md` (implementation runbook)
- `docs/operations/MCP_AGENT_STRATEGY_FOR_PAYMENT_ORCHESTRATION_ZAMBIA_2026-02-16.md` (constraint mapping appendix)
