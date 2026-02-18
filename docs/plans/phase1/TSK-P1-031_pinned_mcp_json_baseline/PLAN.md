# TSK-P1-031 Plan

## Mission
Defer MCP configuration baseline rollout from Phase-1 to Phase-2 (Option A cleanup).

## Scope
- Remove `mcp.json` from Phase-1.
- Remove MCP policy verification from Phase-1 pre-CI execution chain.
- Remove MCP policy evidence obligations from the Phase-1 contract.
- Preserve this document as an archive placeholder for Phase-2 re-issuance.

## Constraints
- No MCP config artifact may be added back to Phase-1 without a new Phase-2 task/contract.
- Phase-1 gates must remain deterministic and MCP-free after cleanup.

## Verification
- `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh`

## Evidence
No Phase-1 evidence. Implementation deferred to Phase-2.
