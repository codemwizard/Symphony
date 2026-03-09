# Remediation Plan

failure_signature: PUSH.REMEDIATION_TRACE.MISSING_CASEFILE
origin_task_id: CQRS-001
first_observed_utc: 2026-03-09T02:30:00Z

## production-affecting surfaces
- services/ledger-api/dotnet/**
- schema/migrations/**
- scripts/audit/**
- scripts/db/**
- docs/invariants/**
- docs/control_planes/**
- docs/PHASE1/**
- tasks/CQRS-001/**
- tasks/CQRS-002/**
- tasks/PROJ-001/**
- tasks/PROJ-002/**

## repro_command
- `git push -u origin canonical/sprint2-cqrs-projections`

## scope_boundary
In scope: add the required remediation casefile for the Sprint 2 production-affecting branch push and document the guarded push path.
Out of scope: changing Sprint 2 task scope, widening CQRS/projection requirements, or altering unrelated Phase 1 semantics.

## proposed_tasks
- Add this REM casefile so `verify_remediation_trace.sh` can bind the Sprint 2 production-affecting diff to an explicit remediation record.
- Re-run guarded verification and push after the Sprint 2 wave commit is in place.

## acceptance
- `bash scripts/audit/verify_remediation_trace.sh` passes for the branch diff against `origin/main`.
- `git push -u origin canonical/sprint2-cqrs-projections` succeeds after the casefile commit.
