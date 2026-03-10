# Remediation Plan

failure_signature: CI.REMEDIATION_TRACE.MISSING_CASEFILE
origin_gate_id: GOV-REMEDIATION-TRACE
first_observed_utc: 2026-03-10T00:00:00Z

## production-affecting surfaces
- scripts/audit/**
- docs/tasks/**

## repro_command
bash scripts/audit/verify_remediation_trace.sh

## scope_boundary
In scope: add a remediation casefile for the branch `fix/bootstrap-and-governance-carryover` so the
production-affecting bootstrap and governance carryover changes satisfy remediation trace policy.

Out of scope: changing gate semantics, weakening remediation trace enforcement, or broadening the
branch content beyond the intended carryover fixes.

## proposed_tasks
- Add a `REM-*` casefile folder under `docs/plans/phase1/` with `PLAN.md` and `EXEC_LOG.md`.
- Record the branch-scoped failure signature, reproduction command, and verification commands.
- Re-run the remediation trace verifier and confirm it emits a PASS result with this casefile as the
  satisfying remediation documentation.

## acceptance
- `bash scripts/audit/verify_remediation_trace.sh` returns success for this branch.
- `evidence/phase0/remediation_trace.json` shows `status: PASS`.
- `evidence/phase0/remediation_trace.json` lists this casefile in `satisfying_docs`.
