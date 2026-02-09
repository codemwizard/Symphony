# Implementation Plan (TSK-P0-130)

failure_signature: P0.REG.SOVEREIGN_GATES.NOT_WIRED_PARITY
origin_task_id: TSK-P0-130
repro_command: bash scripts/dev/pre_ci.sh

## Goal
Wire the Sovereign Hybrid Cloud Phase-0 gates into:
- control planes (`docs/control_planes/CONTROL_PLANES.yml`)
- invariant manifest (`docs/invariants/INVARIANTS_MANIFEST.yml`)
- Phase-0 contract (`docs/PHASE0/phase0_contract.yml`) only after scripts exist
- ordered runner (CI + local parity)

## Scope
In scope:
- Add new non-colliding gates:
  - Security: `SEC-G17` PII leakage lint
  - Integrity: `INT-G23` BoZ role verifier
  - Integrity: `INT-G24` anchor-sync hooks verifier
- Ensure ordered execution in both local and CI and fail-closed semantics.
- Ensure remediation trace gate can be satisfied by this task casefile (markers present).

Out of scope:
- Adding new runtime features or schema semantics beyond verifiers/role constraints.

## Acceptance
- Local and CI run the same ordering; no CI-only hidden gates.
- New gates emit evidence JSON and are included in expected Phase-0 artifacts.
- `verify_phase0_contract_evidence_status.sh` stays PASS after contract updates land.

## Toolchain prerequisites (checklist)
- [ ] `rg` (ripgrep) available (local toolchain bootstrap should install).
- [ ] `python3` available (used to emit evidence JSON).
- [ ] `psql` available (DB verifiers run in DB job / local docker).
- [ ] `docker` available for local pre-CI DB parity (`FRESH_DB=1` default).

verification_commands_run:
- "PENDING: bash scripts/dev/pre_ci.sh"
- "PENDING: (CI) run full Phase-0 ordered checks"

final_status: OPEN
