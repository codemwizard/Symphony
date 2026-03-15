# TSK-P1-DEMO-022 Plan

## mission
Reconcile the provisioning and checklist docs with the strict host-based execution contract so operators stop improvising around conflicting instructions.

## constraints
- Remove or clearly deprecate contradictory legacy wording.
- No new product features.
- Provisioning guidance must become deterministic inside the E2E flow.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_022.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-022 --evidence evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `docs/operations/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_022_doc_reconciliation.json`
