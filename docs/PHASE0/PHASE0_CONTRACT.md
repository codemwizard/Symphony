# Phase‑0 Contract (Evidence Gate)

## Purpose
This contract is the **single source of truth** for Phase‑0 task status and evidence enforcement. The CI evidence gate only enforces evidence for tasks marked **completed** and **evidence_required=true** in the contract. This prevents phantom evidence failures while keeping enforcement strict for completed work.

## Files
- `docs/PHASE0/phase0_contract.yml` — machine‑readable contract (authoritative)
- `docs/PHASE0/PHASE0_CONTRACT.md` — human‑readable summary

## Required Fields (per task)
Each entry **must** include:
- `task_id` — e.g., `TSK-P0-012`
- `status` — `roadmap | planned | in_progress | completed`
- `verification_mode` — `local | ci | both | none`
- `evidence_required` — `true | false`
- `evidence_paths` — list of explicit relative paths (avoid globs when possible)
- `evidence_scope` — `repo | ci_artifact`
- `notes` — optional

## Enforcement Rules
1. Evidence is required **only** when:
   - `status=completed` AND `evidence_required=true`
2. `verification_mode=local` tasks are **skipped** in CI evidence checks.
3. Evidence paths are normalized in CI so both layouts are accepted:
   - `<base>/<file>`
   - `<base>/evidence/phase0/<file>`

## Validation
`scripts/audit/verify_phase0_contract.sh` enforces:
- Schema/field correctness
- Every `tasks/TSK-P0-*/meta.yml` appears in the contract
- No duplicate or unknown task IDs
- Evidence path rules are respected

Evidence:
- `./evidence/phase0/phase0_contract.json`

