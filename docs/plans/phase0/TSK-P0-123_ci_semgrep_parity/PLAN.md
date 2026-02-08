# Implementation Plan (TSK-P0-123)

failure_signature: CI.SECURITY.SEMGREP.SKIPPED_TOOLCHAIN_MISSING
origin_gate_id: SEC-G11
repro_command: run Phase I.5 security_scan and inspect phase0/semgrep_sast.json

## Goal
Install pinned Semgrep (and python deps) in all CI jobs that emit Phase-0 security evidence, so security evidence is parity-correct.

## Problem Statement
The dedicated `security_scan` job uploads `phase0-evidence-security` but did not install Semgrep.
This allowed `semgrep_sast.json` to be emitted as `SKIPPED` with `semgrep_not_installed`, which is not acceptable for Tier-1 parity.

## Scope
In scope:
- Update `.github/workflows/invariants.yml` `security_scan` job to install python toolchain (pyyaml/jsonschema/semgrep/pytest) pinned by `scripts/audit/ci_toolchain_versions.env`.

Out of scope:
- Changing Semgrep ruleset.

## Acceptance Criteria
- `phase0-evidence-security` contains `semgrep_sast.json` with `status: PASS` and pinned semgrep version.

## Verification Commands
- (CI) inspect `phase0-evidence-security` artifact.

verification_commands_run:
- CI run (Phase I.5 security_scan)

final_status: OPEN

