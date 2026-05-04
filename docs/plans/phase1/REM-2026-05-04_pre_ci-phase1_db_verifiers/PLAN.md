# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Initial Hypotheses
- The `verify_tsk_p2_w8_sec_002.sh` script is building the `wave8_crypto` extension on the host machine but then attempting to run `CREATE EXTENSION` on the ephemeral DB container `$DB_CONTAINER` (`symphony-postgres`).
- Since the compiled `.so` extension file and its dependencies (`libsodium.so`) are not present within the container's `/usr/lib/postgresql/` paths, the `CREATE EXTENSION` command fails with `libsodium.so.23: cannot open shared object file: No such file or directory`.

## Root Cause
- The `wave8_crypto` extension files and its dynamic library dependency `libsodium.so.23` were not being copied into the ephemeral Postgres container before attempting to load the extension via `psql`.

## Fix Sequence
1. Modified `scripts/audit/verify_tsk_p2_w8_sec_002.sh` to extract the `pkglibdir` and `sharedir` from `pg_config`.
2. Added `docker cp` commands to copy the `.so` binary and the extension `.sql` and `.control` files into the running container.
3. Added logic to dynamically resolve the path of `libsodium.so.23` on the host via `ldd` and copy the shared library (along with any symlinks) directly into the container's library paths.
4. Run `ldconfig` in the container.
5. Re-run `CREATE EXTENSION`, which now successfully loads.
