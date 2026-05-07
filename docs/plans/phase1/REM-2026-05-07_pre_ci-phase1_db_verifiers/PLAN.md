# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: pending
final_status: OPEN

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Root Cause Analysis
1. **Ownership Conflict**: The `verify_projection_freshness_and_scope.sh` script runs `dotnet test` inside a Docker container without mapping the host user. Docker runs as root by default, so the `bin/` and `obj/` directories it creates on the host-mounted volume are owned by root.
2. **Destructive Workaround**: To allow subsequent runs, a workaround was added to `rm -rf` these directories inside the container. This destroyed the binaries.
3. **Downstream Failure**: Scripts like `verify_tsk_p1_212.sh` and `run_perf_smoke.sh` rely on `dotnet run --no-build` using the pre-existing binaries. Without them, the DB Environment verification gate fails (`PRECI.DB.ENVIRONMENT`).

## Fix Sequence
1. Modify Docker command in `verify_projection_freshness_and_scope.sh` to use `--user "$(id -u):$(id -g)"` and set `/tmp` for `DOTNET_CLI_HOME` and `NUGET_PACKAGES`.
2. Remove the destructive `rm -rf` cleanup.
3. Add a centralized `dotnet build` step in `pre_ci.sh` after Docker tests to guarantee clean binaries for downstream scripts.
