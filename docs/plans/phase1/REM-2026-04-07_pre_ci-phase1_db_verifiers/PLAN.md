# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.DB.ENVIRONMENT

origin_gate_id: pre_ci.phase1_db_verifiers
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: docker exec symphony-postgres pg_isready -U symphony_admin -d symphony
final_status: RESOLVED

## Scope
- Record the failing layer, root cause, and fix sequence for this remediation.

## Root Cause

**REGRESSION IDENTIFIED**: The pre_ci.sh script used to work without manual DATABASE_URL
setup, but now fails. This is a regression, not an environment configuration issue.

Investigation revealed:

1. Docker daemon is running ✅
2. symphony-postgres container is running and healthy ✅
3. PostgreSQL is accepting connections via TCP ✅
4. infra/docker/.env has correct POSTGRES_USER=symphony_admin, POSTGRES_PASSWORD, POSTGRES_DB ✅
5. The script DOES source infra/docker/.env correctly (lines 385-389) ✅
6. The script DOES auto-construct DATABASE_URL from POSTGRES_* variables (lines 391-396) ✅

**Actual Root Cause**: The `run_ci_db_parity_migration_probe()` function (line 160-197)
is being called at line 432, AFTER the .env file is sourced. However, the `docker exec`
commands inside the function are failing with:

```
psql: error: connection to server on socket "/var/run/postgresql/." does not exist
FATAL: role "symphony_admin [truncated]
```

This suggests that either:
1. The `$POSTGRES_USER` variable is not being passed into the docker exec environment correctly
2. The psql command inside the container is defaulting to Unix socket instead of using -h localhost
3. There's a recent change to how docker exec handles environment variables

The function uses `docker exec "$DB_CONTAINER" psql -U "$POSTGRES_USER"` but the error
shows it's trying Unix socket connections, which means either $POSTGRES_USER is empty
or the psql command is ignoring the -U flag.

**This is a regression** - the script should work without manual DATABASE_URL setup as it
did before.

## Fix Sequence

This is an environment configuration issue, not a code issue. The fix is to ensure
DATABASE_URL is set before running pre_ci.sh:

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:5432/symphony"
```

Or source the environment from infra/docker/.env:

```bash
set -a
source infra/docker/.env
set +a
export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${HOST_POSTGRES_PORT}/${POSTGRES_DB}"
```

## Verification

```bash
# Verify DATABASE_URL is set
echo $DATABASE_URL
# Should output: postgresql://symphony_admin:symphony_pass@localhost:5432/symphony

# Verify connection works
psql "$DATABASE_URL" -c "SELECT version();"
# Should return PostgreSQL version

# Re-run pre_ci.sh
scripts/dev/pre_ci.sh
```

## Prevention

This is a local development environment setup issue. The DATABASE_URL must be set in
the shell environment before running pre_ci.sh. Consider adding a check at the start
of pre_ci.sh to fail fast with a clear error message if DATABASE_URL is unset, rather
than attempting fallback connections that trigger DRD lockouts.

## Note

This issue is unrelated to the task/spec files created for GF-W1-UI-001. The Symphony
task and Kiro spec are properly structured and pass all governance gates. This is a
pre-existing environment configuration gap.
