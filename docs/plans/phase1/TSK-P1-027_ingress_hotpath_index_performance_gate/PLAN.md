# TSK-P1-027 Plan

failure_signature: P1.PERF.INGRESS_HOTPATH_INDEX.GAP
origin_task_id: TSK-P1-027
first_observed_utc: 2026-02-14T00:00:00Z

## Mission
Add an explicit ingress hot-path index mechanical gate so front-door performance regressions cannot ship silently.

## Scope
In scope:
- Add `scripts/db/tests/test_ingress_hotpath_indexes.sh` to verify required ingress index posture.
- Emit `evidence/phase1/ingress_hotpath_indexes.json` deterministically.
- Wire non-colliding control-plane gate and Phase-1 contract row.
- Enforce under `RUN_PHASE1_GATES=1`.

Out of scope:
- Benchmark-based latency SLO enforcement.
- Partitioning, payload-offloading, or infra redundancy controls.

## Correctness Notes
- Existing integrity gates already occupy INT-G22..INT-G31.
- This task must use a new non-colliding gate (recommended INT-G33).

## Acceptance
- Missing/invalid ingress hot-path indexes fail the verifier.
- Evidence enumerates each required index and result.
- Phase-1 contract enforces this evidence when gates are enabled.

## Verification Commands
- `scripts/db/tests/test_ingress_hotpath_indexes.sh`
- `scripts/dev/pre_ci.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`
- `scripts/audit/verify_phase1_contract.sh`
