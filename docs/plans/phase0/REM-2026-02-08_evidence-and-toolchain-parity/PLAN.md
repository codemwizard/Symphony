# Remediation Plan

failure_signature: CI.PHASE0.PARITY.EVIDENCE_FINGERPRINT_AND_SEMGREP_DRIFT
origin_task_id: TSK-P0-122
first_observed_utc: 2026-02-08T00:00:00Z

## production-affecting surfaces
- scripts/**
- .github/workflows/**
- docs/operations/**

## repro_command
- Inspect `phase0-evidence` artifacts for inconsistent `schema_fingerprint`.
- Inspect `phase0-evidence-security` artifacts for `semgrep_sast.json` SKIPPED due to missing semgrep.

## scope_boundary
In scope:
- Normalize evidence fingerprint semantics across all evidence producers.
- Install pinned Semgrep in all CI jobs that emit Phase-0 security evidence.
- Add fail-closed guardrails so CI cannot silently degrade to SKIPPED due to missing toolchain.

Out of scope:
- Changing Semgrep ruleset or adding new security controls beyond parity.

## proposed_tasks
- TSK-P0-122: evidence fingerprint semantics normalization (baseline canonical + migrations_fingerprint).
- TSK-P0-123: install pinned Semgrep in security_scan CI job.
- TSK-P0-124: fail closed if Semgrep/toolchain is missing or drifted.

## acceptance
- `phase0-evidence` artifact: all evidence JSON files share a single `schema_fingerprint`.
- `phase0-evidence-security` artifact: `semgrep_sast.json` is PASS with pinned semgrep version.
- CI fails if Semgrep is missing (no SKIPPED due to missing toolchain).

