# Remediation Plan

failure_signature: PUSH.REMEDIATION_TRACE.MISSING_CASEFILE
origin_task_id: FP-001
first_observed_utc: 2026-03-09T01:34:00Z

## production-affecting surfaces
- services/supervisor_api/**
- services/ledger-api/dotnet/**
- scripts/security/**
- scripts/audit/**
- scripts/db/**
- docs/invariants/**
- docs/PHASE1/**

## repro_command
- `git push -u origin canonical/sprint1-foundation`

## scope_boundary
In scope: add the required remediation casefile for the Sprint 1 production-affecting branch push and document the guarded push path.
Out of scope: changing Sprint 1 implementation scope, verifier semantics, or Phase 1 contract meaning.

## proposed_tasks
- Add this REM casefile so `verify_remediation_trace.sh` can bind the production-affecting diff to an explicit remediation record.
- Re-run guarded push after the casefile is committed.

## acceptance
- `bash scripts/audit/verify_remediation_trace.sh` passes for the branch diff against `origin/main`.
- `git push -u origin canonical/sprint1-foundation` succeeds after the casefile commit.

