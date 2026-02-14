# Phase-1 Pilot Onboarding Checklist

Use this checklist for a limited customer-facing sandbox pilot handoff.

## Technical Preconditions
- API consumer receives tenant UUID and participant identifier.
- Consumer can call ingress endpoint with deterministic payload contract.
- Consumer can call evidence-pack endpoint with `x-tenant-id`.
- Consumer can call exception case-pack endpoint with `x-tenant-id`.

## Compliance Preconditions
- Regulated surface changes include approval metadata (`evidence/phase1/approval_metadata.json`).
- Agent conformance evidence is green (`evidence/phase1/agent_conformance.json`).
- PII lint and security fast checks pass in `scripts/dev/pre_ci.sh`.

## Replay Validation
- Run `scripts/dev/run_phase1_pilot_harness.sh`.
- Confirm:
  - `evidence/phase1/pilot_harness_replay.json` has `status=PASS`.
  - `evidence/phase1/pilot_onboarding_readiness.json` has `status=PASS`.

## Handoff Artifacts
- Pilot contract: `docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md`
- Onboarding checklist: `docs/operations/PHASE1_PILOT_ONBOARDING_CHECKLIST.md`
- Deterministic machine evidence in `evidence/phase1/**`
