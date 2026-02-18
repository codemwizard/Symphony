# Secure SDLC Policy (Phase-0 Stub)

Status: Phase-0 policy stub (mechanical gates first; deeper runtime controls Phase-1+).

## Purpose
Define minimum secure development and delivery controls that must be enforced mechanically in Phase-0.

## Principles
- Mechanical gates are the source of truth. Documentation without enforcement is non-authoritative.
- Local and CI runs must be aligned (parity). Where parity is intentionally asymmetric, it must be explicit and evidence-backed.
- Exceptions must be explicit, timeboxed, and recorded with evidence.

## Required Phase-0 Gates (Minimum)
- Secrets scanning.
- Dependency vulnerability audit (.NET).
- Secure configuration lint (infra + workflows).
- Insecure patterns lint (static).
- DDL risk guardrails (lock-risk lint + allowlist governance).
- Evidence schema validation and Phase-0 contract validation.

## SAST Baseline (Phase-0)
- Phase-0 adopts Semgrep as the baseline SAST tool.
- CI must run the Semgrep baseline and fail on findings.
- Local runs may emit SKIPPED evidence if Semgrep is not installed, but must not emit PASS when Semgrep is missing.

## Change Management and Exceptions
- Any exception to a gate must be explicitly recorded:
  - include rationale
  - include scope
  - include expiration date
  - include approval record (Phase-1+ workflow)

