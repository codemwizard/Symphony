# TSK-P1-HIER-006 PLAN

Task: TSK-P1-HIER-006
Owner role: SUPERVISOR
Depends on: TSK-P1-HIER-005

## objective
Complete HIER-006 using canonical execution metadata requirements:
- verifier script at `scripts/db/verify_tsk_p1_hier_006.sh`
- evidence at `evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json`
- terminal metadata in `tasks/TSK-P1-HIER-006/meta.yml`

## implementation
- Keep migration `0051_hier_006_supervisor_access_modes.sql` as the implemented schema object set for READ_ONLY/AUDIT/APPROVAL_REQUIRED supervisor-access semantics.
- Add verifier assertions for:
  - scope policy rows and semantic flags
  - audit token structures/indexes
  - approval queue function hardening and behavior
  - revoke-first posture
- Generate evidence JSON with task_id/status/pass contract.

## verification
- `scripts/audit/verify_agent_conformance.sh`
- `bash scripts/db/verify_tsk_p1_hier_006.sh --evidence evidence/phase1/tsk_p1_hier_006__append_only_member_device_events_anchored.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
completed
