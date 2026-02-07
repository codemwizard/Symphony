# Remediation Plan

failure_signature: CI.REMEDIATION_TRACE.MISSING_CASEFILE
origin_task_id: TSK-P0-115
first_observed_utc: 2026-02-07T00:00:00Z

## production-affecting surfaces
- scripts/**
- .github/**
- schema/**
- src/**
- infra/**

## repro_command
bash scripts/audit/verify_remediation_trace.sh

## scope_boundary
In scope: fix gating so CI changes that remediate failures must carry a remediation trace.
Out of scope: changing Phase-0 contract statuses or evidence generation semantics.

## proposed_tasks
- Ensure this PR contains a remediation casefile (this folder).
- Ensure verify_remediation_trace is invoked in pre-CI + CI in the correct order.

## acceptance
- verify_remediation_trace passes.
- remediation evidence artifact is emitted (if wired).

