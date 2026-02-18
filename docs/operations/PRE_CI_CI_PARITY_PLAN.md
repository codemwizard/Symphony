# Phase-0 Pre-CI vs CI Parity Plan

This document catalogs how the local `scripts/dev/pre_ci.sh` workflow matches GitHub Actions and establishes the guardrails that ensure every mechanical gate (remediation trace, evidence, task plans, agent conformance) sees the same inputs, flags, and outputs regardless of where it runs.

## Canonical Flags & Artifacts

The shared environment is defined in `scripts/audit/env/phase0_flags.sh`. Every runner that drives Phase-0 gating must `source` that file so the following exports are identical:

- `EVIDENCE_ROOT` – where Phase-0 evidence JSONs land (`evidence/phase0` by default).
- `CI_ONLY` – gate scripts treat `CI_ONLY=1` as CI-only, `0` as local-only; the parity script runs both contexts.
- `REMEDIATION_TRACE_DIFF_MODE` – always `range` to match the commit range evaluated in CI.
- `REMEDIATION_TRACE_BASE_REF` – defaults to `origin/rewrite/dotnet10-core` and mirrors the branch used in CI.

Each runner must also respect the Git SHA (`git rev-parse HEAD`) and schema fingerprint utilities in `scripts/lib/evidence.sh`, so evidence metadata is populated with real commit details, not placeholder values.

## Execution Graph

1. **Toolchain bootstrapping** – both local and CI install the same Python dependencies and ripgrep binary; the local script shares the bootstrap script used by CI.
2. **Structural detection** – GitHub Actions diffs `origin/main` (or PR base) vs HEAD; `pre_ci.sh` inherits a forced `BASE_REF`/`HEAD_REF` match for parity.
3. **Task plan / remediation trace gating** – `scripts/audit/verify_task_plans_present.sh`, `scripts/audit/verify_remediation_trace.sh`, and `scripts/audit/verify_agent_conformance.sh` are executed in the same order locally and on CI through the new parity verification script.
4. **Phase-0 contract evidence & ordered checks** – `scripts/audit/verify_phase0_contract_evidence_status.sh` runs with the same flags and evidences the exact JSON outputs expected on CI.
5. **DB & security gates** – both runners spin up the Dockerized PostgreSQL stack, create an ephemeral DB (`FRESH_DB=1`), and run the same invariant/verifier scripts from `scripts/db/*`.

## Verification Strategy

The new helper `scripts/audit/verify_phase0_parity.sh` executes the core gate trio twice:
1. **pre-CI mode** – sets `CI_ONLY=0`, runs the remediation trace, agent conformance, and contract evidence scripts while logging the outcome.
2. **CI mode** – sets `CI_ONLY=1`, reruns the same trio with identical environment flags.

Any mismatch in exit status, missing evidence, or missing metadata causes the verifier to stop the run before `run_phase0_ordered_checks.sh` executes, ensuring that the local developer sees the same failure surface as CI.

## Artifact Hygiene

Evidence-producing scripts derive their `git_sha` and timestamps from `scripts/lib/evidence.sh`. The Phase-0 evidence directory is curated by rerunning those scripts so every JSON file contains the actual commit SHA and timestamp. There are no placeholder values committed to the repo.

## Audit Checklist

- [x] `scripts/audit/env/phase0_flags.sh` defines canonical exports and writes them to `$GITHUB_ENV` when available.
- [x] `scripts/dev/pre_ci.sh` sources the env file and calls `scripts/audit/verify_phase0_parity.sh` before running other checks.
- [x] `.github/workflows/invariants.yml` sources the env file before running Phase-0 gates and invokes the parity script.
- [x] Evidence JSONs under `evidence/phase0` carry `git_sha` values generated from `git rev-parse HEAD`.

Any deviation from this loop (e.g., an ad-hoc flag on local machines or manual artifact edits) must be recorded in a remediation casefile and verified by the parity script before the Phase-0 contract evidence check runs.
