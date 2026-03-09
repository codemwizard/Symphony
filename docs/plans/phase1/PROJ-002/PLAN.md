# PROJ-002 PLAN

Task: PROJ-002
Owner role: SUPERVISOR
Depends on: PROJ-001, CQRS-002
failure_signature: PHASE1.PROJ.002.REQUIRED

## objective
External query API projection cutover

## scope
- Move targeted external query surfaces to projection-backed stores only.
- Preserve tenant/object authorization rigor on all projected reads.
- Expose projection freshness metadata and stale-state semantics.

## acceptance_criteria
- No targeted external query surface reads hot operational tables directly.
- Tenant/object authorization remains enforced on projected reads.
- Clients can distinguish current vs stale projection state.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `dotnet test services/ledger-api/dotnet/tests --filter QueryProjection`
- `bash scripts/audit/verify_no_hot_table_external_reads.sh`
- `python3 scripts/audit/validate_evidence.py --task PROJ-002 --evidence evidence/phase1/proj_002_external_query_cutover.json`

## no_touch_warnings
- Do not keep silent fallbacks to write-table reads for convenience.
- Do not bypass freshness semantics to simulate synchronous truth.

## evidence_output
- `evidence/phase1/proj_002_external_query_cutover.json`

## verification_commands_run
- `scripts/audit/verify_agent_conformance.sh`
- `dotnet test services/ledger-api/dotnet/tests --filter QueryProjection`
- `bash scripts/audit/verify_no_hot_table_external_reads.sh`
- `python3 scripts/audit/validate_evidence.py --task PROJ-002 --evidence evidence/phase1/proj_002_external_query_cutover.json`
