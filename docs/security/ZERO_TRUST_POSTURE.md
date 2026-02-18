# Zero Trust Architecture Posture (Phase-0)

Status: Phase-0 posture document (mechanical hooks and gates; runtime enforcement Phase-1+).

## Purpose
Describe the Zero Trust posture Symphony is implementing and the Phase-0 mechanical foundations that make it credible.

This document does not claim compliance or certification with any Zero Trust standard.

## Principles (Phase-0)
- Identity is the primary perimeter.
- Least privilege is enforced mechanically (deny-by-default posture).
- Policy and controls must be evidence-backed, not narrative-only.

## Phase-0 Mechanical Foundations (What Exists Today)
- Deny-by-default database privileges and "no runtime DDL" posture.
- SECURITY DEFINER hardening with pinned search_path.
- Evidence artifacts for gates include provenance (timestamp, git_sha, optional schema_fingerprint).

## Minimum Telemetry Expectations
For audit-grade traceability, durable records and logs should carry (where applicable):
- `tenant_id`
- `participant_id`
- `correlation_id`

Phase-0 establishes schema hooks for correlation stitching and evidence grouping.

## Phase-1/2 Follow-ups (Not Implemented Here)
- Workload identity model (e.g., SPIFFE/SPIRE or equivalent).
- Explicit PDP/PEP decomposition and policy decision workflow.
- Centralized telemetry and continuous verification.

