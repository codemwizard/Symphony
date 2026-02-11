# Verify Agent Conformance Specification

failure_signature: PHASE1.AGENT_CONFORMANCE.SPEC
origin_task_id: TSK-P1-004
first_observed_utc: 2026-02-11T00:00:00Z

## Mission
Capture the full specification for `scripts/audit/verify_agent_conformance.sh`, including regulated-surface approval metadata, stop/esc escalation rules, evidence output schema, failure codes, and approval artifact schema, then document it in `docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md` so the script can be implemented with deterministic governance enforcement.

## Scope
In scope:
- Write the spec doc with purpose, inputs, requested checks, regulated surfaces, failure codes, and evidence requirements.
- Define approval metadata + sidecar schema and templates under `docs/operations/`.
- Ensure the spec references the canonical manual and the mission-level requirements.

Out of scope:
- Implementation of the script itself (covered by TSK-P1-003).

## Acceptance
- `docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md` exists, references the manual, and includes detailed sections for purpose, non-negotiables, inputs, regulated surfaces, check definitions, failure codes, evidence output, approval artifacts, PII heuristics, and integration requirements.
- Spec explicitly states that updates must follow the manual’s approval/evidence process and points to sidecar/schema docs.
