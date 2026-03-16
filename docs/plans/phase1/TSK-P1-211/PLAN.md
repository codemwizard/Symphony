# TSK-P1-211 Plan

Task ID: TSK-P1-211

## objective
Fix the billable_clients conflict target defect permanently through the migration chain.

## implementation_directives
- The migration must achieve these non-negotiable outcomes:
  - drop the bad partial/bare index
  - create a real table-level unique constraint on `client_key`
  - verify `pg_constraint.contype = 'u'`
- The `USING INDEX` clause is strictly forbidden, as it produces a partial constraint inheriting the previous `WHERE` clause.
- `DROP INDEX` must be used without `CONCURRENTLY` to allow execution inside the migration transaction.
- The migration must be forward-only and idempotent against:
  - clean schema
  - schema with bare index
  - schema manually patched in the field

## hardening_rules
1. No interim workaround may remain in the supported deployment or onboarding path after this task closes.
2. Hardened GreenTech4CE flows must prefer durable system design over operator memory, shell sequencing, or manual reseeding.
3. Runtime security decisions must not depend on browser-held admin credentials or unaudited environment-variable shortcuts when this task is in scope to remove them.
4. Documentation, gates, and runtime behavior must converge on one supported hardened path; fallback modes may exist only when explicitly marked as developer-only and out of scope.

## acceptance_focus
- Remove the provisional workaround described in task notes, if any.
- Update docs, verifiers, and bootstrap expectations so the permanent design is the only supported design.
- Explicitly update `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md` to replace the manual SQL workaround instructions with the single supported migration-backed path.
- Prove the final state with evidence and fail-closed verification.

## remediation_trace
failure_signature: PHASE1.P1.211.CONSTRAINT_REPAIR
repro_command: see task verifier commands in meta.yml
verification_commands_run: []
final_status: planned
origin_task_id: TSK-P1-211
origin_gate_id: PHASE1.P1.211.CONSTRAINT_REPAIR
