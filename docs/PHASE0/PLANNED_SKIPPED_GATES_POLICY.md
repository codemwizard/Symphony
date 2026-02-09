# Planned/SKIPPED Gates Policy (Phase-0)

This document defines the **canonical Phase-0 process** for introducing new gates and invariants without causing:
- contract evidence “missing evidence” failures, or
- control-plane drift (gates declared but not wired), or
- CI-only hidden checks (parity violations).

This repo explicitly standardizes on **Approach B** (declare early + SKIPPED stubs), with guardrails that make it safe.

## Definitions

### Gate
A gate is a control-plane enforcement unit declared in `docs/control_planes/CONTROL_PLANES.yml` with:
- `gate_id`
- `script`
- `evidence` (an `evidence/phase0/*.json` artifact)

### Evidence
Evidence is a JSON file under `evidence/phase0/` produced by a gate script.

Required fields (minimum):
- `check_id`
- `timestamp_utc`
- `git_sha`
- `schema_fingerprint`
- `status` in `{PASS, FAIL, SKIPPED}`

### Contract
The Phase-0 contract is `docs/PHASE0/phase0_contract.yml`.
The contract determines whether evidence is **required** and therefore whether CI/local pre-CI must fail if it is missing.

## Two Approaches (A vs B)

### Approach A (late-binding contract)
Approach A allows you to create gates only when the full implementation exists.

Rules:
- Do not add a new gate to `CONTROL_PLANES.yml` until the script exists.
- Do not add evidence paths to `phase0_contract.yml` until the gate emits deterministic PASS/FAIL in CI and local pre-CI.

This approach minimizes stubs, but it increases the risk that planned controls “disappear” from the repo until late.

### Approach B (canonical for Symphony): declare early + SKIPPED stubs
Approach B makes planned controls **auditor-visible** and **drift-resistant** while preventing contract failures.

Rules (mandatory):
1. Add the gate entry to `docs/control_planes/CONTROL_PLANES.yml` using the next non-colliding `SEC-*` / `INT-*` / `GOV-*` ID.
2. Land a **stub script** immediately if the real verifier is not ready.
3. Wire the script into a canonical runner so `verify_control_planes_drift.sh` passes:
   - security scripts: `scripts/audit/run_security_fast_checks.sh`
   - invariants/governance scripts: `scripts/audit/run_invariants_fast_checks.sh`
   - DB verifiers: executed in DB-capable contexts (local `scripts/dev/pre_ci.sh`, CI DB job via `scripts/db/verify_invariants.sh`)
4. Stub scripts MUST emit deterministic evidence with `status: "SKIPPED"` and a machine-readable `reason`.
5. Do NOT make a stub gate contract-required unless the contract explicitly allows SKIPPED for that task state.

## Promotion Policy (the critical safety rule)

### When you may promote a gate to contract-required evidence
You may add the gate’s evidence path to `docs/PHASE0/phase0_contract.yml` with `evidence_required: true` only when:
- the gate script exists and is executable,
- the gate is wired in **both** local pre-CI and CI (parity),
- the gate emits evidence JSON on **every** run,
- the gate emits deterministic `PASS` or `FAIL` (not SKIPPED) in CI and local pre-CI for the intended Phase-0 posture.

### What “promotion” means operationally
Promotion changes failure mode:
- Before promotion: drift checks ensure the gate exists and is wired; the gate may SKIP.
- After promotion: contract evidence gates will fail the run if evidence is missing or does not satisfy status semantics.

## Stub Script Standard (improvement: uniform SKIPPED semantics)

All stubs MUST:
- write the expected evidence file path every run
- include `status: "SKIPPED"`
- include `reason` (string)
- include `gate_id` (string) and `invariant_id` (string) when known
- exit code MUST be `0` (SKIPPED is not a failure)

Stubs MUST include the marker comment:
- `# symphony:skipped_stub`

## Parity Requirements

Single source of truth:
- Phase-0 ordered execution is defined by `scripts/audit/run_phase0_ordered_checks.sh`.
- CI must call the ordered runner rather than adding CI-only hidden gates.

Local parity rule:
- `scripts/dev/pre_ci.sh` is the local parity runner.
- Default is `FRESH_DB=1` so DB verifiers run against an ephemeral DB per run.

## Common Failure Modes (and how this policy prevents them)

- Missing evidence explosions:
  Prevention: don’t promote to contract-required until deterministic PASS/FAIL exists, or the contract explicitly allows SKIPPED.
- Control-plane drift:
  Prevention: declare gate + wire script immediately; drift check ensures it remains wired.
- CI-only checks:
  Prevention: all gates must be reachable via the canonical ordered runner and parity runner.

## Checklist (Approach B)

- [ ] Gate declared in `docs/control_planes/CONTROL_PLANES.yml` with non-colliding `gate_id`.
- [ ] Script exists (real verifier or stub).
- [ ] Script is wired in canonical runners (drift check passes).
- [ ] Evidence JSON emitted every run (PASS/FAIL/SKIPPED).
- [ ] Contract promotion only when deterministic PASS/FAIL is achieved (or SKIPPED is explicitly allowed by contract semantics).

