# Remediation Plan

failure_signature: CI.PHASE0_CONTRACT_EVIDENCE_STATUS.GATE_NOT_DECLARED
origin_gate_id: INT-G19
first_observed_utc: 2026-02-08T00:00:00Z

## production-affecting surfaces
- docs/control_planes/**
- docs/PHASE0/**
- scripts/audit/**

## repro_command
bash scripts/audit/verify_phase0_contract_evidence_status.sh

## scope_boundary
In scope: ensure any `gate_ids` referenced by `docs/PHASE0/phase0_contract.yml` are declared in `docs/control_planes/CONTROL_PLANES.yml` with evidence paths.
Out of scope: changing Phase-0 evidence semantics or weakening fail-closed behavior.

## proposed_tasks
- Add a properly-named GOV gate for remediation trace and declare it in control planes.
- Update contract/task references from ad-hoc gate IDs to the canonical gate ID.
- Verify control-plane drift and contract evidence status checks pass.

## acceptance
- `bash scripts/audit/verify_phase0_contract_evidence_status.sh` passes in CI.
- `bash scripts/audit/verify_control_planes_drift.sh` passes.

