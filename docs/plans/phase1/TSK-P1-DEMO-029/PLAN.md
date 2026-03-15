# TSK-P1-DEMO-029 Plan

## mission
Create the governed demo provisioning sample pack and signoff threshold guide so operators have one fixed GreenTech4CE sample configuration set and exact repo-backed sample commands without conflating sample values with full-demo signoff.

## constraints
- No runtime, schema, or workflow changes.
- No direct push to `main` and no direct pull from `main` into working branches.
- Pack must use current repo-backed endpoint truth only and must not invent unsupported programme or routing APIs.
- Pack must state clearly that sample values reduce ambiguity but do not by themselves grant full-demo signoff.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_029.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-029 --evidence evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `docs/operations/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_029_provisioning_sample_pack.json`
