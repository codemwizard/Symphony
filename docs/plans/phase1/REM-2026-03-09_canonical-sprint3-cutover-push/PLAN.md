# Remediation Plan

failure_signature: PUSH.REMEDIATION_TRACE.MISSING_CASEFILE
origin_task_id: CUT-001
first_observed_utc: 2026-03-09T03:48:00Z

## production-affecting surfaces
- services/ledger-api/dotnet/**
- scripts/audit/**
- scripts/db/**
- docs/invariants/**
- docs/PHASE1/**
- docs/architecture/**
- docs/operations/**
- tasks/CUT-001/**
- tasks/CUT-002/**
- tasks/CUT-003/**
- tasks/CUT-004/**

## repro_command
- `git push -u origin canonical/sprint3-cutover`

## scope_boundary
In scope: add the required remediation casefile for the Sprint 3 production-affecting branch push and document the guarded push path.
Out of scope: changing Sprint 3 cutover scope, widening CQRS/projection semantics, or altering unrelated Phase 1 controls.

## proposed_tasks
- Add this REM casefile so `verify_remediation_trace.sh` can bind the Sprint 3 production-affecting diff to an explicit remediation record.
- Re-run guarded verification and push after the Sprint 3 wave commit is in place.

## acceptance
- `bash scripts/audit/verify_remediation_trace.sh` passes for the branch diff against `origin/main`.
- `git push -u origin canonical/sprint3-cutover` succeeds after the casefile commit.
