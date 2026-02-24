# TSK-P1-HIER-002 PLAN

failure_signature: PHASE1.HIER.002.BRIDGE
origin_task_id: TSK-P1-HIER-002

## repro_command
- `bash scripts/db/verify_tsk_p1_hier_002.sh --evidence evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json`

## Scope
- Build the Phase-1 `persons` and `members` tables that reuse `public.programs` and `public.tenant_members`.
- Enforce tenant-scoped uniqueness, status/check constraints, and bridging indexes for program/escrow lookups.
- Provide deterministic governance evidence via `scripts/db/verify_tsk_p1_hier_002.sh` and the Phase-1 contract entry.

## verification_commands_run
- `DATABASE_URL=postgresql://symphony_admin:symphony_pass@127.0.0.1:55432/symphony bash scripts/db/verify_tsk_p1_hier_002.sh --evidence evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
