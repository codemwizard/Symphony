# Phase-1 Demo Deploy and Test Checklist

## Purpose
This checklist now points operators to the canonical **host-based** demo path.

Primary operator document:
- `docs/operations/PILOT_DEMO_DEPLOYMENT.md`

This checklist is now a compact entrypoint and evidence checklist, not the authoritative run sequence.

## Canonical Local Path
Use the instructions in `PILOT_DEMO_DEPLOYMENT.md` for the current server deployment.

Required posture:
- use a clean deployment checkout tracking `origin/main`
- do not run the demo from an active development checkout
- Dell laptop remains browser-only
- OpenBao and PostgreSQL containers must be running locally

## Required Local Preconditions
- PostgreSQL reachable on `127.0.0.1:5432`
- required env contract populated
- OpenBao posture resolved for the intended run mode
- operator inputs for tenant/programme provisioning recorded

## Required Evidence For A Local Demo Run
Task/tooling evidence:
- `evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
- `evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
- `evidence/phase1/tsk_p1_demo_020_demo_runner.json`
- `evidence/phase1/tsk_p1_demo_021_key_rotation_policy.json`
- `evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`

Run evidence:
- `evidence/phase1/demo_run/<run_id>/server_snapshot.json`
- `evidence/phase1/demo_run/<run_id>/browser_smoke_checklist.json`
- `evidence/phase1/demo_run/<run_id>/run_summary.json`
- `evidence/phase1/pilot_harness_replay.json`
- `evidence/phase1/pilot_onboarding_readiness.json`
- `evidence/phase1/tsk_p1_demo_010_reveal_rehearsal.json`
- `evidence/phase1/regulator_demo_pack.json`
- `evidence/phase1/tier1_pilot_demo_pack.json`

## Provisioning Reference
Provisioning order and prerequisites remain in:
- `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`

For this branch, the repo-backed executable provisioning entrypoint is tenant onboarding via:
- `POST /v1/admin/tenants`

Programme context, policy binding, supplier allowlist state, and evidence/report routing still require explicit operator confirmation and must not be silently assumed.

## Kubernetes Appendix Status
Kubernetes remains a secondary path only.

It is:
- non-canonical for this local server
- not part of local demo readiness sign-off
- not validated on the current host baseline

Use the runbook appendix if you intentionally need the sandbox K8s reference path later.
