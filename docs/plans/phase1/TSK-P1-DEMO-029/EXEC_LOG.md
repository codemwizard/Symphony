# TSK-P1-DEMO-029 Execution Log

failure_signature: PHASE1.DEMO.029.SAMPLE_PACK_CONTRACT
origin_task_id: TSK-P1-DEMO-029
Plan: docs/plans/phase1/TSK-P1-DEMO-029/PLAN.md

## repro_command
`bash scripts/audit/verify_tsk_p1_demo_029.sh`

## verification_commands_run
- `bash scripts/audit/verify_agent_conformance.sh`
- `bash scripts/dev/pre_ci.sh`
- `bash scripts/audit/verify_tsk_p1_demo_029.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-029 --evidence evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`
- `bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy`
- `bash scripts/audit/verify_task_pack_readiness.sh --task TSK-P1-DEMO-029`

## final_status
COMPLETED

## execution_notes
- Task pack created because the existing provisioning runbook and start-now checklist do not define a governed sample data pack.
- Created the operator-readable sample pack at `docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.md`.
- Created the machine-readable mirror artifact at `docs/operations/GREENTECH4CE_DEMO_PROVISIONING_SAMPLE_PACK.sample.json`.
- Added `scripts/audit/verify_tsk_p1_demo_029.sh` to check fixed identifiers, repo-backed endpoint coverage, signoff limitation language, and doc/JSON agreement.
- First verifier run failed because the signoff-limitation sentence did not appear as the exact plain-text token expected by the verifier; updated the doc wording and reran successfully.
- Emitted passing task evidence at `evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`.

## Final summary
- `TSK-P1-DEMO-029` is implemented and completed.
- The branch now has a governed demo provisioning sample pack with one fixed tenant, programme, policy version, supplier set, programme-scoped allowlist outcomes, and reporting/evidence routing identifiers.
- The sample pack includes exact `curl` examples only for repo-backed endpoints on this branch and clearly separates operator-confirmed non-repo-backed signoff prerequisites from executable provisioning steps.
- The evidence artifact passes validation and records a passing verifier result.
