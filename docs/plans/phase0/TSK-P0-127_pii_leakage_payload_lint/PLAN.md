# Implementation Plan (TSK-P0-127)

failure_signature: P0.REG.PII_LEAKAGE_LINT.MISSING
origin_task_id: TSK-P0-127
repro_command: bash scripts/audit/lint_pii_leakage_payloads.sh

## Goal
Add a Phase-0 mechanical gate that fails closed if raw PII leaks into regulated payload/log/evidence surfaces.

## Scope
In scope:
- `scripts/audit/lint_pii_leakage_payloads.sh` (fail-closed, deterministic)
- Evidence JSON at `evidence/phase0/pii_leakage_payloads.json`
- Minimal unit/self-test script under `scripts/audit/tests/`

Out of scope:
- Implementing `INV-ZDPA-01` (tokenization/erasure survivability) (roadmap `INV-115`)
- Runtime redaction wrappers (Phase-0 optional unless contract requires)

## Acceptance
- Lint emits evidence on PASS and FAIL.
- Lint fails on clear PII patterns in regulated contexts unless explicitly marked as redacted test fixture.
- CI and local pre-CI parity: gate runs in both via ordered runner once wired (TSK-P0-130).

## Toolchain prerequisites (checklist)
- [ ] `rg` (ripgrep) available (fail-closed if missing).
- [ ] `python3` available (used to emit evidence JSON).

verification_commands_run:
- "PENDING: bash scripts/audit/lint_pii_leakage_payloads.sh"
- "PENDING: bash scripts/audit/tests/test_lint_pii_leakage_payloads.sh"

final_status: OPEN
