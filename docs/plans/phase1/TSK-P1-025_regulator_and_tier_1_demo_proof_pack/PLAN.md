# TSK-P1-025 Plan

failure_signature: PHASE1.TSK.P1.025
origin_task_id: TSK-P1-025
first_observed_utc: 2026-02-13T00:00:00Z

## Mission
Produce deterministic regulator and tier-1 demo-proof packs that map executive claims to machine-generated evidence artifacts.

## Scope
In scope:
- Script and record BoZ/tier-1 demonstration scenarios.
- Emit demo-pack artifacts referencing underlying evidence paths.

Out of scope:
- New feature implementation beyond evidence-backed demonstration packaging.

## Acceptance
- Demo scenarios are replayable from scripted commands.
- Every claim in demo-pack artifacts maps to machine evidence.

## Verification Commands
- `scripts/dev/pre_ci.sh`
