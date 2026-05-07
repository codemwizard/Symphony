# DRD Lite

## Metadata
- Template Type: Lite
- Incident Class: CI Pipeline Non-Convergence
- Severity: L1
- Status: Open
- Owner: Architect / DB Foundation Agent
- Date: 2026-05-07
- Task: CIBIN — CI Binary Ownership Fix
- Branch: (current working branch)

## Summary

The `pre_ci.sh` pipeline is non-convergent (`NONCONVERGENCE_COUNT=1`,
`FAILURE_SIGNATURE=PRECI.DB.ENVIRONMENT`) because
`scripts/db/verify_projection_freshness_and_scope.sh` runs `dotnet test` inside
a Docker container that mounts the host source tree.  Docker runs as **root**,
creating root-owned `bin/` and `obj/` directories.  A post-test `rm -rf` was
added inside the container to prevent downstream non-root scripts from failing
when they cannot delete root-owned artifacts.  However, this cleanup destroys
the binaries that multiple downstream scripts depend on via `dotnet run --no-build`.

## First Failing Signal
- Artifact/log path: `pre_ci.sh` output — `PRECI.DB.ENVIRONMENT` gate
- Error signature: `NONCONVERGENCE_COUNT=1 FAILURE_SIGNATURE=PRECI.DB.ENVIRONMENT`

## Impact
- What was blocked: Entire CI pipeline — all gates after the projection
  verification script fail, including TSK-P1-212, self-tests, SEC-000,
  perf smoke, and UI wire verifiers.
- Delay: Full pipeline non-convergence; no downstream gates can pass.
- Attempts before record: 1 (first-strike non-convergence)

## Diagnostic Trail
- Command(s):
  - `grep -rl "rm -rf" scripts/ | xargs grep -l "dotnet"` — identified scripts
    combining destructive cleanup with dotnet operations
  - `grep -rl "\-\-no-build" scripts/` — identified all downstream consumers
    relying on pre-existing binaries
  - `grep -r "rm -rf" scripts/ | grep -v "mktemp" | grep -v "tmp"` — isolated
    non-temporary destructive operations
  - Manual review of `scripts/db/verify_projection_freshness_and_scope.sh`
    line 16 (the Docker `run` command)
- Result(s):
  - Root cause confirmed: Docker container runs as root, `rm -rf` destroys
    host-mounted `bin/obj` directories
  - 6 downstream scripts identified as failing due to missing binaries
  - Ownership conflict confirmed: non-root host user cannot delete
    root-created artifacts

## Root Cause
- Confirmed: Docker container in `verify_projection_freshness_and_scope.sh`
  runs as root (default), creating root-owned build artifacts on the
  host-mounted volume.  The `rm -rf` workaround inside the container solves
  the ownership problem but introduces a binary lifecycle problem by
  destroying artifacts needed by downstream `--no-build` scripts.

## Fix Applied
- Files changed:
  1. `scripts/db/verify_projection_freshness_and_scope.sh` — Add
     `--user "$(id -u):$(id -g)"` to Docker run; set `DOTNET_CLI_HOME` and
     `NUGET_PACKAGES` to `/tmp` paths; remove `rm -rf` cleanup.
  2. `scripts/dev/pre_ci.sh` — Add centralized `dotnet build` step after
     Docker-based testing to ensure binaries exist with correct ownership.
  3. `scripts/audit/run_perf_smoke.sh` — Add defensive existence check
     before `rm -rf` of AOT output directory.
- Why it should work: Running the container as the host user creates binaries
  with correct ownership, eliminating the need for the destructive cleanup.
  The centralized rebuild step provides belt-and-suspenders assurance.

## Verification Outcomes
- Command(s): 
  - `bash scripts/db/verify_projection_freshness_and_scope.sh` (Ownership check)
  - `PRE_CI_CONTEXT=1 bash scripts/audit/verify_tsk_p1_212.sh` (Binary lifecycle check)
  - `bash scripts/audit/run_perf_smoke.sh` (Downstream consumer check)
- PASS/FAIL: PASS (Binaries survived Docker run with host ownership, TSK-P1-212 passed, and Perf Smoke publish passed).

## Escalation Trigger
- Escalate to Full if:
  - Docker `--user` flag causes container permission failures
  - `NONCONVERGENCE_COUNT` does not drop to 0 after fix
  - Additional root-owned artifact creation points are discovered
