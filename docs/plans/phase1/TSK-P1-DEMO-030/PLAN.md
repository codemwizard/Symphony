# TSK-P1-DEMO-030 Plan

## mission
Repair the demo task-line collision by restoring canonical `TSK-P1-DEMO-024..028`, moving the provisioning sample-pack task to `TSK-P1-DEMO-029`, and relocating deployment repair work onto the clean branch `feat/demo-deployment-repair` created from parity-restored local `main`.

## constraints
- Do not merge `main` into `feat/ui-wire-wave-e`.
- Do not rebase `feat/ui-wire-wave-e` onto `main`.
- Do not force-pull or force-reset as a shortcut.
- First fast-forward local `main` to `origin/main`; then use local `main` as the baseline.
- Move the dirty working tree off `feat/ui-wire-wave-e` onto `feat/demo-deployment-repair` instead of rewriting Wave-E branch history.
- Remove stale Wave-E approval artifacts from the repaired branch and emit branch-linked approval artifacts for `feat/demo-deployment-repair`.
- Refresh approvals only after the repaired branch task line is coherent.
- If `TSK-P1-063` fails after the branch move, open a remediation casefile before editing the Git mutation audit document and rerun the targeted verifier before any broader parity retry.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_030.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-030 --evidence evidence/phase1/tsk_p1_demo_030_branch_repair.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `tasks/**`, `docs/plans/**`, `docs/tasks/**`, `approvals/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_030_branch_repair.json`
