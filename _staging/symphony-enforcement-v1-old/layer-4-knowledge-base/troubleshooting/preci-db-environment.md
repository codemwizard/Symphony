# Troubleshooting: PRECI.DB.ENVIRONMENT

**Failure signature:** `PRECI.DB.ENVIRONMENT`
**Gate:** `pre_ci.phase1_db_verifiers`
**Owner:** platform
**DRD level:** L1

## What this means

The pre-CI DB/environment gate failed. Docker is not running, `DATABASE_URL` is
unset, or the postgres container did not become healthy in time.

## Expected failure output

```
FAILURE_SIGNATURE=PRECI.DB.ENVIRONMENT
NONCONVERGENCE_COUNT=2
ESCALATION=DRD_FULL_REQUIRED
❌ DRD LOCKOUT WRITTEN: .toolchain/pre_ci_debug/drd_lockout.env
```

Or earlier (before lockout):

```
ERROR: docker daemon is not reachable
ERROR: DATABASE_URL not set and infra/docker/.env missing required POSTGRES_* values
ERROR: postgres container not ready
```

## Diagnostic steps

1. **Check Docker is running:**
   ```bash
   docker info
   ```
   If this fails, start Docker and re-run.

2. **Check the postgres container:**
   ```bash
   docker ps | grep symphony-postgres
   docker logs symphony-postgres --tail=50
   ```

3. **Check port 5432:**
   ```bash
   ss -ltn sport = :5432
   ```
   If occupied by another process, set `HOST_POSTGRES_PORT=55432` in your shell before running pre_ci.sh.

4. **Check DATABASE_URL and env file:**
   ```bash
   cat infra/docker/.env | grep POSTGRES
   ```
   `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` must all be set.

5. **Bring up the stack manually and verify:**
   ```bash
   docker compose -f infra/docker/docker-compose.yml --env-file infra/docker/.env up -d
   docker exec symphony-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
   ```

## Clearing the DRD lockout

After diagnosing and fixing the root cause, in this order:

```bash
# Step 1 — create the casefile
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug phase1-db-environment \
  --failure-signature PRECI.DB.ENVIRONMENT \
  --origin-gate-id pre_ci.phase1_db_verifiers \
  --repro-command "scripts/dev/pre_ci.sh"

# Step 2 — document root cause in the generated PLAN.md
# (open the file, fill in what caused the failure and how it was fixed)

# Step 3 — remove the lockout
rm .toolchain/pre_ci_debug/drd_lockout.env

# Step 4 — re-run
scripts/dev/pre_ci.sh
```
