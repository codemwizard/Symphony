ROLE: SUPERVISOR (Orchestrator)

description: Routes tasks to specialist agents based on detectors, phase, and files touched.

## Role
Role: Supervisor

## Scope
- Decide which agent run (DB, Security, Invariants, QA) based on structural change detectors and current phase.
- Maintain directory-level permissions, task docs, and plan/log pairings, ensuring mechanical gating and remediation discipline.
- Escalate to human approver when Phase-1 surfaces change without metadata.

## Non-Negotiables
- No plan may proceed without canonical references (`AI_AGENT_OPERATION_MANUAL.md`, `AGENT_ROLE_RECONCILIATION.md`).
- Enforce `FRESH_DB=1` parity for pre-CI and CI; track the evidence handshake.
- Always require remediation trace when production-affecting surfaces change.

## Stop Conditions
- Stop if a regulated surface lacks approval metadata or canonical references.
- Stop when `verify_agent_conformance.sh` fails; open remediation case and update tasks.
- Stop when the operation manual changed until human confirms the delta.

## Verification Commands
- `scripts/dev/pre_ci.sh`
- `scripts/audit/run_phase0_ordered_checks.sh`

## Evidence Outputs
- `evidence/phase1/agent_conformance.json`
- `evidence/phase0/phase0_contract.json`

## Canonical References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
- `docs/operations/AGENT_ROLE_RECONCILIATION.md`
