# TSK-P1-032 Plan

## Mission
Defer MCP connectivity/policy validation rollout from Phase-1 to Phase-2 (Option A cleanup).

## Scope
- Remove MCP connectivity verification from Phase-1 pre-CI execution chain.
- Remove MCP runtime evidence obligations from the Phase-1 contract.
- Preserve this document as an archive placeholder for Phase-2 re-issuance.

## Constraints
- No MCP runtime checks may be added back to Phase-1 without a new Phase-2 task/contract.
- Phase-1 gates must remain deterministic and MCP-free after cleanup.

## Verification
- `RUN_PHASE1_GATES=1 bash scripts/audit/verify_phase1_contract.sh`

## Evidence
No Phase-1 evidence. Implementation deferred to Phase-2.
