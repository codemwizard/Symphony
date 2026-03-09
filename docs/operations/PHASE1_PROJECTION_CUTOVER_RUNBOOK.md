# Phase-1 Projection Cutover Runbook

## Purpose
This runbook governs the Phase-1 cutover from mixed operational-query posture to projection-backed external read posture.

## Preconditions
1. `PROJ-001` evidence is present and PASS.
2. `PROJ-002` evidence is present and PASS.
3. `CUT-001` and `CUT-002` verifiers pass locally.
4. No open remediation trace gaps exist for the release branch.

## Freeze Point
1. Stop feature edits to projection-backed query surfaces.
2. Regenerate only deterministic evidence required by Sprint 3.
3. Run `scripts/dev/pre_ci.sh` from the branch to prove parity.

## Cutover Sequence
1. Run `bash scripts/audit/verify_cut_001_one_shot_projection_cutover.sh`.
2. Run `bash scripts/audit/verify_cut_002_query_surface_boundary.sh`.
3. Run `bash scripts/audit/verify_cut_003_projection_cutover_runbook.sh`.
4. Run `bash scripts/audit/verify_cut_004_projection_cutover_gate.sh`.
5. Review emitted evidence under `evidence/phase1/`.

## Stop Conditions
1. Any cutover verifier returns non-zero.
2. Any Phase-1 evidence path is missing or invalid.
3. Any legacy query/read contract reference survives in active cutover artifacts.
4. Any public read route regresses into direct operational-table access.

## Rollback
1. Stop the cutover and do not promote the branch.
2. Open a remediation trace casefile for the failing seam.
3. Fix forward on the feature branch; do not dual-write and do not add compatibility shims.
4. Re-run the full cutover verification sequence.

## Evidence Outputs
- `evidence/phase1/cut_001_one_shot_projection_cutover.json`
- `evidence/phase1/cut_002_query_surface_boundary.json`
- `evidence/phase1/cut_003_projection_cutover_runbook.json`
- `evidence/phase1/cut_004_projection_cutover_gate.json`

## Explicit Non-Goals
1. No reintroduction of direct hot-table reads for public query surfaces.
2. No dual-write period.
3. No compatibility adapter or legacy-path retention for retired projection contracts.
