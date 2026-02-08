# Implementation Plan (TSK-P0-145)

failure_signature: P0.PERF.WIRING.NOT_FIRST_CLASS_GATES
origin_task_id: TSK-P0-145
repro_command: bash scripts/dev/pre_ci.sh

## Purpose
Make Phase-0 performance invariants first-class gates (control-plane declared, ordered, parity-correct), without introducing SKIPPED or missing-evidence traps.

## Scope
In scope:
- Register performance gates in `docs/control_planes/CONTROL_PLANES.yml`
- Insert into canonical ordering via `scripts/audit/run_phase0_ordered_checks.sh` (no CI-only gates)
- Ensure `scripts/dev/pre_ci.sh` and CI invoke the ordered runner

Rules:
- No contract entry until verifier exists and emits evidence deterministically (Approach A).
- No ID collisions.

verification_commands_run:
- "PENDING: bash scripts/dev/pre_ci.sh"

final_status: OPEN

