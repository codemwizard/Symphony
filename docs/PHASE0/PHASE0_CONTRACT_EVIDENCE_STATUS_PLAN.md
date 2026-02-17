# Phase‑0 Contract Evidence Status Checker — Fix Plan

## Context / Trigger
The contract evidence gate (`scripts/audit/verify_phase0_contract_evidence_status.sh`) is
responsible for enforcing PASS/SKIPPED semantics for Phase‑0 tasks. During CI/pre‑CI
runs, it was observed to:

- parse `docs/PHASE0/phase0_contract.yml` as JSON (YAML‑native parse fails),
- run with an incorrect repo root (ROOT_DIR not exported early),
- hard‑fail if `CONTROL_PLANES.yml` is missing even when no `gate_ids` are present,
- fail before writing evidence on contract parse errors.

These behaviors violate “native‑first / fail‑closed with evidence” requirements and
create false CI failures.

## Prior Tasks That Surfaced the Issue
- **TSK‑P0‑037 / TSK‑P0‑040**: contract + evidence gate wiring
- **TSK‑P0‑051**: control‑plane declaration and drift checker
- **TSK‑P0‑061**: pre‑CI/CI execution order alignment

The checker must be corrected before contract‑scoped evidence gating can be relied upon.

## Mitigation (Native‑First)
1. **YAML‑native parsing** of `phase0_contract.yml` via `yaml.safe_load`.
2. **Export ROOT_DIR and `cd` to repo root before Python** to ensure deterministic paths.
3. **Always emit evidence on failures**, including contract parse errors.
4. **Control‑planes conditional requirement**:
   - If `gate_ids` are absent in the contract, missing `CONTROL_PLANES.yml` → **SKIPPED**.
   - If any `gate_ids` are present, missing `CONTROL_PLANES.yml` → **FAIL**.
5. Preserve PASS/SKIPPED semantics:
   - completed ⇒ evidence must be **PASS**
   - not completed ⇒ evidence must be **PASS or SKIPPED**

## Tasks
- **TSK‑P0‑063**: Fix contract evidence checker (YAML + fail‑closed evidence)
- **TSK‑P0‑064**: Add regression tests for contract checker (bootstrap + gate)

## Acceptance Criteria (Global)
- Contract YAML parses correctly.
- Evidence JSON written on **every** failure path.
- Missing CONTROL_PLANES does not fail unless `gate_ids` are used.
- PASS/SKIPPED policy enforced consistently.

## Verification
- `CI_ONLY=1 scripts/audit/verify_phase0_contract_evidence_status.sh`
- `scripts/audit/tests/test_phase0_contract_checker.sh`

