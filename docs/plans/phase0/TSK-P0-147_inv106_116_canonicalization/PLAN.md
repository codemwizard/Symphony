# Implementation Plan (TSK-P0-147)

failure_signature: P0.INVARIANTS.ID_COLLISION.INV_106_108
origin_task_id: TSK-P0-125
first_observed_utc: 2026-02-09T00:00:00Z

repro_command: bash scripts/audit/run_invariants_fast_checks.sh

## goal
Canonicalize `INV-106..INV-116` so that:
- `INV-106..INV-108` are reserved for Phase-0 governance stubs (policy + SDLC/SAST readiness), and
- the previously declared roadmap invariants (`INV-BOZ-04`, `INV-ZDPA-01`, `INV-IPDR-02`) retain their meaning under new IDs (`INV-114..INV-116`),
- control-plane gate IDs do not collide and are wired into the canonical runners (no drift).

## scope_boundary
In scope:
- Update `docs/invariants/INVARIANTS_MANIFEST.yml` to apply the canonical mapping.
- Update `docs/invariants/INVARIANTS_ROADMAP.md` and `docs/invariants/INVARIANTS_IMPLEMENTED.md` for doc-truth parity.
- Add the gate entries requested by `106-103_INV_IMP.txt` to `docs/control_planes/CONTROL_PLANES.yml`.
- Ensure every gate script exists and is wired into at least one runner checked by `scripts/audit/verify_control_planes_drift.sh`.

Out of scope:
- Implementing the full BoZ role migration/verifier (TSK-P0-128).
- Implementing the fail-closed PII leakage lint (TSK-P0-127).
- Implementing the anchor-sync catalog verifier (TSK-P0-129).

## canonical_mapping (source of truth: 106-103_INV_IMP.txt)
- INV-106: key management policy stub (implemented)
- INV-107: audit logging policy stub (implemented)
- INV-108: SDLC/SAST readiness (implemented)
- INV-109: ISO20022 contract registry presence (implemented)
- INV-110: sovereign VPC posture doc presence (implemented)
- INV-111: BoZ observability role (roadmap, placeholder gate)
- INV-112: PII leakage payload lint (roadmap, placeholder gate)
- INV-113: anchor-sync readiness hooks (roadmap, placeholder gate)
- INV-114: payment finality / instruction irrevocability (roadmap; alias INV-BOZ-04)
- INV-115: PII decoupling survivability (roadmap; alias INV-ZDPA-01)
- INV-116: rail truth-anchor sequence continuity (roadmap; alias INV-IPDR-02)

## gate_changes (CONTROL_PLANES.yml)
- SEC-G17: `scripts/audit/lint_pii_leakage_payloads.sh` -> `evidence/phase0/pii_leakage_payloads.json`
- INT-G23: `scripts/db/verify_boz_observability_role.sh` -> `evidence/phase0/boz_observability_role.json`
- INT-G24: `scripts/db/verify_anchor_sync_hooks.sh` -> `evidence/phase0/anchor_sync_hooks.json`
- GOV-G03: `scripts/audit/verify_sovereign_vpc_posture_doc.sh` -> `evidence/phase0/sovereign_vpc_posture_doc.json`

## implementation_strategy
- Implement `INV-106..INV-110` as real Phase-0 doc/presence gates with PASS/FAIL evidence.
- For `INV-111..INV-113`, land placeholder scripts that emit deterministic `SKIPPED` evidence until the owning tasks implement fail-closed enforcement.
- Do not add these new evidence paths to `docs/PHASE0/phase0_contract.yml` until the owning tasks emit PASS/FAIL deterministically in CI and local pre-CI.

## verification_commands_run
- bash scripts/audit/run_invariants_fast_checks.sh
- bash scripts/audit/run_security_fast_checks.sh
- bash scripts/audit/verify_control_planes_drift.sh
- scripts/dev/pre_ci.sh

## final_status
OPEN (to be updated to PASS when executed end-to-end after landing)
