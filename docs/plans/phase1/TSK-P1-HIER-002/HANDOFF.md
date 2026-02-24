# TSK-P1-HIER-002 HANDOFF

## Current blocker
- `scripts/db/verify_tsk_p1_hier_002.sh` still fails even though the schema exists and all checks appear correct.
- Recent runs (with `DATABASE_URL=postgresql://symphony_admin:symphony_pass@127.0.0.1:55432/symphony`) exit immediately with status 1 and no printed error. The script logs show the first constraint failures (such as `members_person_fk`), even though the foreign key definitions are present.
- I streamlined the verifier to use `PSQL_CMD`/`PSQL_OPTS` and reworded the checks to rely on indexes and `pg_constraint` statements, but the run still writes `errors>0` and leaves the evidence file blank, so the task cannot be marked `completed` yet.

## Evidence and artifacts
- Baseline/metadata updated: `schema/baselines/2026-02-24/0001_baseline.sql`, `baseline.meta.json`, `baseline.cutoff`, `schema/baseline.sql`, `schema/baselines/current/` files.
- New migration: `schema/migrations/0047_hier_002_programs_person_member_bridge.sql` (creates `persons`/`members` tables and indexes). Verified by migration log in `/tmp/preci.log`.
- Verifier script (`scripts/db/verify_tsk_p1_hier_002.sh`) currently in modified state with `PSQL_CMD` array and constraint/index checks; the evidence path is `evidence/phase1/tsk_p1_hier_002__programs_program_escrow_id_bridge.json` (currently unpopulated because run exits before writing).
- Task metadata/plan still marked `in_progress`/`planned` in `tasks/TSK-P1-HIER-002/meta.yml`, `docs/plans/phase1/TSK-P1-HIER-002/PLAN.md`, and `EXEC_LOG.md`.
- Pre-CI run (with the new baseline) completed successfully earlier, generating the required `phase0`/`phase1` evidence files (which are intentionally cleaned). The outputs are logged in `/tmp/preci.log` (extracts show gate success). Baseline drift/perf/evidence gates all passed.

## Next actions for unblock
1. Debug why `scripts/db/verify_tsk_p1_hier_002.sh` still reports failures: examine the script output (logs show failing check IDs like `members_person_fk` even though the foreign keys exist). Maybe the `verify` statements are not reading the correct connection info or `pg_constraint` pattern is too strict; adjust the queries accordingly and rerun the verifier until it exits with status 0 and writes a valid JSON artifact.
2. Once the verifier passes, ensure the resulting evidence file contains `task_id == TSK-P1-HIER-002`, `status` in {PASS,DONE,OK}, the check records, and matches the planned path. You may need to re-run `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh` to re-generate `phase1` artifacts now that the verifier succeeds.
3. Update `docs/plans/phase1/TSK-P1-HIER-002/PLAN.md` + `EXEC_LOG.md` to describe the successful verification commands, and set `tasks/TSK-P1-HIER-002/meta.yml` status to `completed` with the verifier evidence path recorded.
4. Clean `evidence/phase0`/`evidence/phase1` directories if necessary (`scripts/ci/clean_evidence.sh` or `git clean -fd`), stage the intended files (`baseline`, `migration`, `verifier`, `plan/log`, `task meta`, `docs/tasks/phase1_prompts.md` updates if any), commit, and push the branch `task/TSK-P1-HIER-002` once everything is green.

## References
- Pre-CI log: `/tmp/preci.log` (contains the successful run post-baseline update). use `grep -n TSK-P1-HIER-002` to find relevant lines.
- Migration file: `schema/migrations/0047_hier_002_programs_person_member_bridge.sql` (new tables, indexes, triggers).
- Plan/log files: `docs/plans/phase1/TSK-P1-HIER-002/PLAN.md` and `EXEC_LOG.md`.
- Task metadata: `tasks/TSK-P1-HIER-002/meta.yml` (still `in_progress`).
- Verifier script: `scripts/db/verify_tsk_p1_hier_002.sh` (needs debug/unblock).

Please pick up from here once you have a moment; the baseline/migration boil is done but the verifier needs to pass before we can commit/push.
