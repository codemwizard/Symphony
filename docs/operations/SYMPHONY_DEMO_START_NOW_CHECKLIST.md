# Symphony Demo Start-Now Checklist

Status: strict go/no-go startup checklist for host-based demo deployment
Audience: operator deciding whether to start end-to-end deployment and testing now
Default mode: `rehearsal-only`

## 1. Purpose
Use this checklist to decide whether the current system is ready to **start** host-based end-to-end deployment and testing.

This checklist is intentionally narrower than the full runbook.
It answers one operator question:
- are we ready to begin the end-to-end rehearsal now?

It does not treat start readiness as full-demo signoff readiness.

Canonical references:
- `docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md`
- `docs/security/SYMPHONY_DEMO_KEY_AND_ROTATION_POLICY.md`
- `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`

## 2. Immediate Default Decision
Start in:
- `rehearsal-only`

Do not start in:
- `full-demo`

Continue if:
- the goal is to prove the host deployment and end-to-end flow now

Stop if:
- the goal is to claim full-demo signoff before the first rehearsal run proves the stronger signoff conditions

## 3. Start Conditions

### 3.1 Deployment source gate
Required state:
- you are not doing development work on `main`
- the deployment checkout is a clean deployment checkout, not an active development branch
- `git fetch origin` succeeds
- current `HEAD` is reachable from fetched `origin/main`
- current working tree is clean

Continue if:
- all deployment source checks pass

Stop if:
- fetch fails
- checkout is dirty
- commit is not on the merged `origin/main` line

Operator action:
- refresh the deployment checkout before any app start attempt

### 3.2 Host prerequisites
Required state:
- PostgreSQL is reachable on `127.0.0.1:5432`
- port `8080` is free, or is owned by a known prior Symphony process that can be torn down deterministically
- required binaries exist:
  - `dotnet`
  - `docker`
  - `psql`
  - `curl`
  - `jq`

Continue if:
- DB is reachable and host runtime prerequisites are present

Stop if:
- DB is unreachable
- unknown process owns `8080`
- any required binary is missing

### 3.3 Required environment contract
Required environment:
- `SYMPHONY_DEMO_MODE=rehearsal-only`
- `SYMPHONY_RUNTIME_PROFILE=pilot-demo`
- `ASPNETCORE_URLS=http://0.0.0.0:8080`
- `DATABASE_URL`
- `INGRESS_STORAGE_MODE=db_psql`
- `SYMPHONY_UI_TENANT_ID`
- `SYMPHONY_UI_API_KEY`
- `INGRESS_API_KEY`
- `ADMIN_API_KEY`
- `SYMPHONY_KNOWN_TENANTS`

Current demo contract:
- `SYMPHONY_UI_API_KEY == INGRESS_API_KEY`
- `SYMPHONY_UI_TENANT_ID` is present in `SYMPHONY_KNOWN_TENANTS`

Continue if:
- all vars are present and the current demo contract passes

Stop if:
- any env var is missing
- UI/read key mismatch exists
- tenant is not allowlisted

### 3.4 Mode classification
Required classification:
- this run is labeled `rehearsal-only`
- the operator does not represent the run as `full-demo`

Continue if:
- all participants understand this is a rehearsal-only startup and execution pass

Stop if:
- anyone intends to use this start decision as a full-demo signoff claim

## 4. Start Sequence

### 4.1 Capture baseline snapshot
Run first:
```bash
bash scripts/dev/capture_demo_server_snapshot.sh --run-id <run_id>
```

Continue if:
- the run bundle is created
- host, git, env-contract, listener, DB, and process posture are recorded

Stop if:
- snapshot creation fails
- snapshot output is incomplete or unsafe

### 4.2 Run preflight posture checks
Use the runner dry-run posture:
```bash
SYMPHONY_DEMO_MODE=rehearsal-only bash scripts/dev/run_demo_e2e.sh --run-id <run_id> --dry-run
```

Continue if:
- source gate passes
- env contract passes
- DB posture passes
- no unknown `8080` conflict exists

Stop if:
- any preflight check fails

### 4.3 Apply database migration
Run:
```bash
bash scripts/db/migrate.sh
```

Continue if:
- migration exits successfully

Stop if:
- migration fails
- schema/parity checks fail

### 4.4 Publish the host app
Run the canonical host publish step for the current checkout.

Continue if:
- publish completes successfully
- the expected host binary or published artifacts exist

Stop if:
- publish fails
- expected host artifact output is missing

### 4.5 Start Kestrel under supervision
Required process posture:
- explicit PID file
- explicit stdout and stderr logs
- trap-based cleanup
- single active run on host

Continue if:
- process starts cleanly
- logs are being written
- no unresolved stale PID collision remains

Stop if:
- process crashes
- stale PID or process conflict cannot be resolved safely

### 4.6 Wait for health
Use the health contract selected by the runner and runbook for this checkout.

Current branch truth:
- `/health` is the stable mandatory host health route
- additional readiness routes are used only when the runner confirms them for the current checkout

Continue if:
- liveness passes
- readiness passes within timeout

Stop if:
- readiness times out
- mandatory health endpoint fails
- the script and runbook disagree on endpoint truth

## 5. End-to-End Rehearsal Checks

### 5.1 Tenant onboarding
Run the deterministic tenant onboarding entrypoint defined in the provisioning runbook.

Continue if:
- tenant onboarding succeeds
- tenant evidence is recorded

Stop if:
- tenant onboarding fails

### 5.2 Server-side API smoke
Run server-side checks, not browser checks:
- supervisory route
- pilot-success route
- reveal route
- export route
- required auth-context checks

Continue if:
- required routes respond as expected
- server-side auth and route behavior are correct

Stop if:
- any required route fails
- privileged route behavior is wrong

### 5.3 Pilot harness, demo rehearsal, and proof-pack verification
Run:
- pilot harness
- rehearsal flow
- proof-pack verifier

Continue if:
- all three complete successfully
- evidence artifacts are emitted

Stop if:
- any harness, rehearsal, or proof-pack verifier step fails

### 5.4 Dell/browser smoke
Use the Dell only for browser-visible checks.

Record each browser check as:
- `manual-confirmed`
- `not-run`
- `waived`

Continue if:
- the supervisory UI is reachable in the browser
- the expected browser-visible flow renders and behaves correctly for rehearsal

Stop if:
- the browser path is not reachable
- the UI is materially broken for rehearsal

## 6. Result Classification

### 6.1 Successful start-now outcome
The system is ready to start end-to-end deployment and testing now when all of the following are true:
- start conditions pass
- deployment begins in `rehearsal-only`
- host startup and health pass
- tenant onboarding passes
- server-side API smoke passes
- pilot harness, rehearsal, and proof-pack verification pass
- Dell/browser smoke is confirmed or explicitly marked
- the run summary is emitted

This is a **successful end-to-end rehearsal**.

### 6.2 Not yet full-demo signoff
Do not classify the run as `full-demo` signoff unless all of these are also proven:
- OpenBao posture satisfies the demo key and rotation policy
- INF-006 passes for the intended signoff run
- programme context is confirmed for the real demo flow
- active policy version is confirmed
- supplier allowlist state is confirmed
- reporting and evidence routing targets are confirmed
- closeout and rotation requirements are satisfied or explicitly waived

## 7. Operator Answer
If the start conditions pass, the correct operator answer is:
- **Yes, start the end-to-end deployment and testing now in `rehearsal-only` mode.**

If the stronger signoff conditions are not yet proven, the correct operator answer is still:
- **Yes, start now for rehearsal.**
- **No, do not represent the result as full-demo signoff yet.**
