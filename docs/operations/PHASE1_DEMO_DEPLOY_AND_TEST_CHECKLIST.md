# Phase-1 Demo Deploy and Test Checklist

## Purpose
This checklist now points operators to the canonical **host-based** demo path.

Primary operator document:
- `docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md`

This checklist is now a compact entrypoint and evidence checklist, not the authoritative run sequence.

## Canonical Local Path
Use the host-based runbook for the current server.

Required posture:
- use a clean deployment checkout tracking `origin/main`
- do not run the demo from an active development checkout
- Dell laptop remains browser-only
- do not use `pre_ci.sh` as the operator deploy step for this local path

Primary commands:
```bash
bash scripts/dev/run_demo_e2e.sh --run-id <run_id> --dry-run
bash scripts/dev/run_demo_e2e.sh --run-id <run_id>
```

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
