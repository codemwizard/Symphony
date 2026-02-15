# TSK-P0-156 Plan

failure_signature: P0.PERF.TIMEOUT_POSTURE.GAP
origin_task_id: TSK-P0-156
first_observed_utc: 2026-02-14T00:00:00Z

## Mission
Close the explicit Phase-0 DB timeout posture gap by adding a deterministic mechanical verifier and gate/evidence wiring.

## Scope
In scope:
- Add `scripts/db/verify_timeout_posture.sh` to assert timeout posture in verifier/migration DB sessions.
- Emit `evidence/phase0/db_timeout_posture.json` for PASS/FAIL.
- Wire into ordered checks and pre-CI parity.
- Register non-colliding control-plane gate and Phase-0 contract row.

Out of scope:
- Runtime throughput/latency benchmarking.
- Infra redundancy posture checks.

## Correctness Notes
- Existing integrity gates already occupy INT-G22..INT-G31.
- This task must use a new non-colliding gate (recommended INT-G32).

## Acceptance
- Verifier fails closed when timeout posture is missing or out of bounds.
- Evidence is always written with observed settings.
- Ordered-check parity preserved between local and CI.

## Verification Commands
- `scripts/db/verify_timeout_posture.sh`
- `scripts/audit/run_phase0_ordered_checks.sh`
- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_phase0_contract_evidence_status.sh`
