# Policy Precedence (Canonical)

This document defines conflict resolution order for governance rules.

## Precedence Order

1. `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
2. `docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md`
3. `docs/operations/TASK_CREATION_PROCESS.md`
4. `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
5. `AGENTS.md`
6. `.agent/**`
7. `.codex/**`
8. `docs/operations/DEV_WORKFLOW.md`

## Domain-Canonical Rule

Rank order governs broad authority. For narrowly scoped domains, the explicitly designated canonical document owns detailed rules and higher-ranked documents must defer rather than restate.

Examples:
- Lifecycle taxonomy: `docs/operations/PHASE_LIFECYCLE.md`
- Remediation trigger thresholds: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- Branch/commit formats: `docs/operations/GIT_CONVENTIONS.md`
- Invariant identity and status: `docs/invariants/INVARIANTS_MANIFEST.yml`
- Invariant verifier/evidence mapping: `docs/invariants/INVARIANT_ENFORCEMENT_MATRIX.md`
- CI job semantics and local parity behavior: `.github/workflows/invariants.yml`, `scripts/dev/pre_ci.sh`
- Governance baseline docs (`docs/governance/*.md`) are derivative and must defer to the sources above plus `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

## Conflict Handling

If two documents conflict:
1. Apply this precedence order.
2. If the conflict is within a domain-canonical island, defer to that domain document.
3. Record remediation trace and update downstream references.
