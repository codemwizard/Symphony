# TSK-P1-033 Plan

failure_signature: PHASE1.TSK.P1.033
origin_task_id: TSK-P1-033
first_observed_utc: 2026-03-10T00:00:00Z

## Mission
Close Phase-1 MCP reintroduction risk with a deterministic guard, explicit allowlists, fixture tests, and pre-CI wiring.

## Scope
In scope:
- deterministic no-MCP verifier
- pass/fail fixture tests
- allowlist semantics for deferred Phase-2 planning
- task-scoped evidence wrapper for closure

Out of scope:
- any MCP enablement work
- Phase-2 MCP planning changes beyond allowlisted references

## Acceptance
- The guard fails on banned MCP references in Phase-1 surfaces.
- The fixture suite proves both fail and allowlisted pass behavior.
- Task evidence proves the guard is operational and deterministic.

## Verification Commands
- `bash scripts/audit/verify_tsk_p1_033.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-033 --evidence evidence/phase1/tsk_p1_033_no_mcp_reintroduction_guard.json`
